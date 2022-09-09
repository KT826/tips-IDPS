function DROPDATA(i,filename,extention)

global Dir
global crop_rect

%%%% Check Field of View. If need, get crop window size %%%%
if isempty(crop_rect)
    movie = isx.Movie.read(fullfile(Dir.isxd,[filename,extention])); 
    frame = movie.get_frame_data(2);
    imshow(frame,[min(min(frame)),max(max(frame))]);
    [xi,yi] = getpts; close; clear movie
    crop_rect = uint64([yi(1),xi(2),yi(3),xi(4)]); %4 pixel locations that determines the crop rectangle.[top left bottom right]
end

%%%% Preprocess %%%%
path_input = fullfile(Dir.isxd,[filename,extention]);
path_output = [Dir.export,'/',filename,'-PP-temp.isxd']; 
isx.preprocess(path_input, path_output, 'spatial_downsample_factor', 3,'crop_rect',crop_rect);

%%% Lowpass filter %%%
path_input = path_output;
path_output = [Dir.export,'/',filename,'-PP-BP-temp.isxd']; 
isx.spatial_filter(path_input, path_output, 'low_cutoff', 0.030, 'high_cutoff', 0.5);

%%% Motion correct%%%
movie = isx.Movie.read(path_output); 
path_input = path_output;
path_output = [Dir.export,'/',filename,'-PP-BP-MC-temp.isxd']; 
isx.motion_correct(path_input, path_output,...
    'max_translation', 20,...
    'low_bandpass_cutoff', 0, ...
    'high_bandpass_cutoff',  0)

%{ 
% In case of ROI 
frame_data = movie.get_frame_data(1);
frame_data_size = size(frame_data); clear movie
ROI = [...
    round(frame_data_size(1)*0.2),round(frame_data_size(2)*0.2);...
    round(frame_data_size(1)*0.8),round(frame_data_size(2)*0.8);...
    round(frame_data_size(1)*0.2),round(frame_data_size(2)*0.8);...
    round(frame_data_size(1)*0.8),round(frame_data_size(2)*0.2);...
    ];
isx.motion_correct(path_input, path_output,...
    'max_translation', 20,...
    'low_bandpass_cutoff', 0, ...
    'high_bandpass_cutoff',  0,...
    'roi', ROI)
%}

%%% Load and resize MC-temp file %%%
movie = isx.Movie.read(path_output); 
Frame_num = movie.timing.num_samples;
Frame_idx = 0 : 1 : Frame_num-1;
frame_data_size = size(movie.get_frame_data(1));

%resize the matrix (25%)%%%
div_frame = round(min(frame_data_size)/4);%フレームを N x N に分割する
Frame_size = movie.spacing.num_pixels;
div = fix(Frame_size/div_frame);
FrameResize= {};
%tic
for f = 1: Frame_num
    loadFrame = Frame_idx(f);
    frame_data = movie.get_frame_data(loadFrame);
    FrameResize{f,1} = imresize(frame_data,[div_frame,div_frame]);
end
%toc; 
clear movie

%{
%delet temporal files
files2 = dir([Dir.export,'/*-temp.isxd']);
file_name_cell_array = {files2.name}; % cell配列
for i = 1 : numel(file_name_cell_array)
    delete([Dir.export,'/',file_name_cell_array{i}])
end
%}

%%% Calculate correlation coefficient %%%
CC = zeros(Frame_num,Frame_num);
%tic
parfor f = 1 : Frame_num
    base_frame_data = FrameResize{f,1};
    CCout = ZArtifact.cal_CC(base_frame_data,f,Frame_num,FrameResize)
    CC(f,:) = CCout;
end
%toc
CC = single(CC);
CC_mean = nanmean(CC);
DropFrame = [find(isnan(CC_mean)),find(isoutlier(CC_mean,'grubbs'))];

%%% figure %%%
figure
subplot(5,1,1:3)
imagesc(CC); colorbar('north'); title(filename)
subplot(5,1,4)
imagesc(CC_mean); colorbar('north'); subtitle('mean'); yticklabels([])

subplot(5,1,5)
plot([1:numel(CC_mean)],CC_mean)
hold on
scatter(DropFrame,zeros(1,numel(DropFrame))+min(CC_mean),'*')
title(['N of dropped frame = ', num2str(numel(DropFrame))])
saveas(gcf,[Dir.export,'/DroppedFrameInfo',filename,'.tif'])
close
%%% Drop frames with z-artifact%%%
if ~isempty(DropFrame)
    DropFrame = DropFrame';
    crop_segments = [];
    k = 1; 
    m = 1;
    while k < numel(DropFrame)
        k2 = k+1;
        k3 = 0;
        Loop = true;
        try
            while Loop
                if DropFrame(k2)-DropFrame(k) == 1 + k3
                    k2 = k2+1;
                    k3 = k3 + 1;
                else
                    Loop = false;
                end
            end
        catch
                k2 = numel(DropFrame)+1;
        end

        k2  = k2-1;
        crop_segments(m,[1:2]) = [DropFrame(k),DropFrame(k2)];
        k = k2 +1;
        m = m + 1;
    end
    crop_segments = crop_segments - 1; %現状では、1 frame目（IDPS/pythonでの 0 frame目） をdrop できなくなっている.
    %{
    一括でdropする際のmatrixが少しトリッキー.
    10-12 frame cropの際には..."[10,10;12,12] "　とし、２行使う必要あり.
    %}
    crop_segments2 = zeros(size(crop_segments,1)*2,2);
    for i = 1 : size(crop_segments,1)
        crop_segments2(2*i-1,:) = [crop_segments(i,1),crop_segments(i,1)];
        crop_segments2(2*i,:) = [crop_segments(i,2),crop_segments(i,2)];
    end
    input_movie_file = fullfile(Dir.isxd,[filename, extention]);
    output_movie_file = [Dir.isxd,'/',filename,'_drop.isxd'];
    isx.trim_movie(input_movie_file , output_movie_file, crop_segments2)
    save([Dir.export,'/CorCoef_',filename '.mat'],'CC','FrameResize','Frame_num','DropFrame')
end

end