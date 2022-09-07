%{
Processing of IDPS imaging data from inscopix miniscope.

<Procedure>
(1) Find out frames with large z-artifact. Calculate correlation coefficient b/w frames and convert them into "drop frame"

%}
%%
clc; clear all; close all
global Dir
global crop_rect

%%%%% inputs %%%%%
Dir.script = ''; %directory where this script locates. AKA pwd
Dir.isxd = 'D:\To git\Session-testdata'; %directory of isxd data
Dir.matlabAPI = 'C:\Program Files\Inscopix\Data Processing'; %directory of matlab API
%%%%%%%%%%%%%%%%%%

crop_rect = [];
addpath(Dir.matlabAPI)
cd(Dir.script)
Dir.export = ([Dir.script ,'\matlab-export']);
mkdir(Dir.export)

%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Detection of drop frames %%%%
%       Use cropped FOV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
list = dir([Dir.isxd,'/*.isxd']);
for i = 1 : size(list,1)
    disp(['Processing...',num2str(i),' / ', num2str(size(list,1))])
    filename = getfield(list,{i},'name'); 
    filename = filename(1:numel(filename)-5); %delete ".isxd"
    ZArtifact.DetectDelete_ZArtifactFrames(i,filename)
end
       
%%
%%%%%%%%%%%%%%%%%%%%%%%
%%%% Preprocessing %%%%
% PP-SB-MC-DFF-CNMFe
%%%%%%%%%%%%%%%%%%%%%%%

Dir.IDPS = [Dir.isxd,'/IDPS'];
mkdir(Dir.IDPS)
clc
for i = 1 : size(list,1)
    disp(['Processing...',num2str(i),' / ', num2str(size(list,1))])    
    filename = getfield(list,{i},'name'); 
    filename = filename(1:numel(filename)-5); %delete ".isxd"

    if exist(fullfile(Dir.isxd,[filename,'_drop.isxd']))
        filename_PP = [filename,'_drop'];
    else
        filename_PP = filename;
    end

    ZArtifact.Processing_PP_to_CNMFe(filename_PP)
end
