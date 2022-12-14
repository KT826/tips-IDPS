function Processing_PP_to_CNMFe(filename_PP)
global Dir

path_input = fullfile(Dir.isxd,[filename_PP,'.isxd']);
path_output = [Dir.IDPS,'/',filename_PP,'-PP.isxd']; 
isx.preprocess(path_input, path_output,...
    'spatial_downsample_factor', 2,...
    'temporal_downsample_factor', 1,...
    'fix_defective_pixels',true,...
    'trim_early_frames',false);
%temporal_downsample_factor: to be 10Hz

%%% Lowpass filter %%%
path_input = path_output;
path_output = [Dir.IDPS,'/',filename_PP,'-PP-BP.isxd']; 
isx.spatial_filter(path_input, path_output, 'low_cutoff', 0.005, 'high_cutoff', 0.500);

%%% Motion correct%%%
movie = isx.Movie.read(path_output); 
frame_data = movie.get_frame_data(1);
frame_data_size = size(frame_data); clear movie
ROI = [...
    round(frame_data_size(1)*0.2),round(frame_data_size(2)*0.2);...
    round(frame_data_size(1)*0.8),round(frame_data_size(2)*0.8);...
    round(frame_data_size(1)*0.2),round(frame_data_size(2)*0.8);...
    round(frame_data_size(1)*0.8),round(frame_data_size(2)*0.2);...
    ];
path_input = path_output;
path_output = [Dir.IDPS,'/',filename_PP,'-PP-BP-MC.isxd']; 
isx.motion_correct(path_input, path_output,...
    'max_translation', 20,...
    'low_bandpass_cutoff', 0, ...
    'high_bandpass_cutoff',  0,...
    'roi', ROI,...
    'reference_frame_index',100)

%%% Max Projection image %%%
max_proj_file = [Dir.IDPS,'/',filename_PP,'-PP-BP-MC_ProjMax.isxd'];
isx.project_movie(path_output, max_proj_file, 'stat_type', 'max');

%%% DF/F on the motion corrected movies + MaxProjection%%%
mc_files =  [Dir.IDPS,'/',filename_PP,'-PP-BP-MC.isxd']; 
path_output = [Dir.IDPS,'/',filename_PP,'-PP-BP-MC-DFF.isxd'];
isx.dff(mc_files, path_output, 'f0_type', 'mean');
max_proj_file = [Dir.IDPS,'/',filename_PP,'-PP-BP-MC-DFF_ProjMax.isxd'];
isx.project_movie(path_output, max_proj_file, 'stat_type', 'max');


%%% CNMFe %%%
input_movie_files = mc_files;
output_cell_set_files = [Dir.IDPS,'/',filename_PP,'-PP-BP-MC-CNMFe.isxd'];
output_dir = Dir.IDPS;
isx.cnmfe(input_movie_files, output_cell_set_files, Dir.script,...
    'cell_diameter', 5,...
    'min_corr', 0.7,...
    'min_pnr', 10, ...
    'bg_spatial_subsampling', 2,...
    'ring_size_factor', 1.4,...
    'gaussian_kernel_size', 3,...
    'closing_kernel_size', 1,...
    'merge_threshold',0.6,...
    'processing_mode', 2,...
    'num_threads', 4,...
    'patch_size', 150,...
    'patch_overlap',30,...
    'output_unit_type', 1)

end
