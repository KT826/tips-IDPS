clear all;clc
addpath('C:\Program Files\Inscopix\Data Processing')
path_to_cell_set= [pwd, '/testdata-CNMFe.isxd']; %path to your IDPS data cotaining ROI information.

%%
cell_set = isx.CellSet.read(path_to_cell_set);
overlay = [];

for c = 1 : cell_set.num_cells
    cell_image = double(cell_set.get_cell_image_data(c-1));
    cell_image = cell_image .* (cell_image > (0.8 * max(cell_image(:))));       
    num_pixels = cell_set.spacing.num_pixels;
    [X, Y] = meshgrid(0.5:num_pixels(2), 0.5:num_pixels(1));
    centroid = [X(:), Y(:)]' * cell_image(:) / sum(cell_image(:));

    ROIsmap{c,1} = cell_image;
    ROIscentroid{c,1} = centroid;
    
    if c == 1
        overlay = cell_image;
    else
        overlay = overlay + cell_image;
    end
end
savename = 'ROIposi';
save(savename,'ROIsmap','ROIscentroid','path_to_cell_set')

close all
imshow(overlay./c)