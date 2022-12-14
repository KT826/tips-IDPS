%{
Processing of IDPS imaging data from inscopix miniscope.

<Procedure>
(1) Find out frames with large z-artifact. Calculate correlation coefficient b/w frames and convert low-CC of them to "droped" frame.
(2) Preprocessing for the post dropped data. (Resampling -> Bandpass filter -> Motion correction -> dF/F, CNMFe)

%}
%%
clc; clear all; close all
global Dir
global crop_rect
global TimeTook


%%%%% inputs %%%%%
Dir.script = ''; %directory where this script locates. AKA pwd
Dir.isxd = ''; %directory of isxd data
Dir.matlabAPI = 'C:\Program Files\Inscopix\Data Processing'; %your directory of matlab API
%%%%%%%%%%%%%%%%%%

crop_rect = [];
addpath(Dir.matlabAPI)
cd(Dir.script)
Dir.export = ([Dir.script]); %,'\matlab-export']);
mkdir(Dir.export)

list = dir([Dir.isxd,'/*.isxd']); %list = dir([Dir.isxd,'/*.tiff']); In case of tiff data

%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Detection of drop frames %%%%
%       Use cropped FOV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1 : size(list,1)
    disp(['Processing...',num2str(i),' / ', num2str(size(list,1))])
    filename = getfield(list,{i},'name'); 
    extention = filename(numel(filename)-4:end);
    filename = filename(1:numel(filename)-5); %delete ".isxd" or "tiff"
    ZArtifact.DetectDelete_ZArtifactFrames(i,filename,extention)
end

%%
%%%%%%%%%%%%%%%%%%%%%%%
%%%% Preprocessing %%%%
% PP-SB-MC-DFF-CNMFe
%%%%%%%%%%%%%%%%%%%%%%%
Dir.IDPS = [Dir.isxd,'/IDPS'];
mkdir(Dir.IDPS)
TimeTook =[];
for i = 1 : size(list,1)
    disp(['Processing...',num2str(i),' / ', num2str(size(list,1))])    
    filename = getfield(list,{i},'name'); 
    filename = filename(1:numel(filename)-5); %delete ".isxd"

    if exist(fullfile(Dir.isxd,[filename,'_drop.isxd']))
        filename_PP = [filename,'_drop'];
    else
        filename_PP = filename;
    end

    ZArtifact.Processing_PP_to_CNMFe(filename_PP,i)
end
