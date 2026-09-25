%% Extract fluorescence signals from ImageJ ROIs
%
% This script extracts the mean fluorescence intensity from each ROI
% across all frames of one or more TIFF image stacks.
%
% Before running:
%   1. Draw ROIs in Fiji/ImageJ and save them as an ROI Set (.zip).
%   2. Prepare the TIFF image files to be analyzed.
%   3. Image files should be named using the format:
%
%          MMM_DDD_NNN_MotCor.tif
%
%      where NNN is the ID of the recording.
%
% Output:
%   A MATLAB file containing the variable "activs" is saved for each
%   TIFF file in the same folder as the image.
%
%   activs is organized as:
%       rows    = image frames
%       columns = ROIs
%
% Required functions:
%   ReadImageJROI
%   load_tiffs_fast


%% 1. Load ROI set

[ROIName, ROIPath] = uigetfile('*set.zip', 'Select ImageJ ROI set');

sROI = ReadImageJROI(fullfile(ROIPath, ROIName));

% Extract ROI coordinates and close each polygon
coords = cellfun(@(x) ...
    [x.mnCoordinates; x.mnCoordinates(1,:)], ...
    sROI, 'UniformOutput', false);


%% 2. Select TIFF image files

[FileName, FolderPath] = uigetfile( ...
    '*MotCor.tif', ...
    'Select image file(s)', ...
    'MultiSelect', 'on');

% Convert FileName to a cell array for consistent processing
if iscell(FileName)
    FN = FileName(:);
else
    FN = {FileName};
end


%% 3. Get image dimensions and number of frames

% Use the first selected image to obtain image information
firstFile = fullfile(FolderPath, FN{1});

% Read the number of frames from the TIFF metadata
T = Tiff(firstFile);
imageDescription = T.getTag('ImageDescription');
T.close();

k = strfind(imageDescription, 'images=') + 7;
nframes = str2double( ...
    imageDescription((1:find(imageDescription(k:end) == newline, 1)) + k - 1));

% Get image dimensions
imageInfo = imfinfo(firstFile);
imsize = [imageInfo.Width, imageInfo.Height];


%% 4. Convert ROIs to binary masks

masks = cellfun(@(x) ...
    poly2mask(x(:,1), x(:,2), imsize(2), imsize(1)), ...
    coords, 'UniformOutput', false);


%% 5. Extract fluorescence signals from each image

for fileN = 1:length(FN)

    % Full path to current TIFF file
    currentFile = fullfile(FolderPath, FN{fileN});

    % Load TIFF stack into a matrix
    im = load_tiffs_fast(currentFile, 'nframes', nframes);
    d_im = double(im);

    % Calculate mean fluorescence intensity within each ROI for each frame
    activs = cellfun(@(mask) ...
        squeeze(sum(sum(d_im .* mask, 1), 2)) / sum(mask(:)), ...
        masks, 'UniformOutput', false);

    % Combine ROI signals into one matrix:
    % rows = frames; columns = ROIs
    activs = horzcat(activs{:});

    % Save ROI fluorescence signals
    outputName = [FN{fileN}(1:end-4), 'ROI analysis.mat'];
    save(fullfile(FolderPath, outputName), 'activs');

end