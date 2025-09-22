% Ralf Mouthaan & Freja Hoier & Emi Hughes
% University of Adelaide & DTU
% October 2024
% 
% Script to process full B-scan measurement for all .mat files in the pwd, taking care to subtract
% reference and sample. Dispersion compensation is set in raw2ascan.

%% User-defined

clc;
clearvars -except Cam Controller dq offsetPI HomeOffset;
addpath('Functions\')

Foldername = pwd;

files = dir(fullfile(Foldername, '*.mat'));
numFiles = numel(files);
fileNames = {files.name};
for j = 1:numFiles
RawData =  load([Foldername '\' fileNames{j}]);

%%

Ref = RawData.ReferenceArm;

for i= 1:size(RawData.OCTSpectrum, 3) % Iterates over A-scans

    Data = RawData.OCTSpectrum(:, :, i);
    Sample = RawData.SampleArm(:, :, i);
    [z, OCTImage(:, i)] = raw2ascan3(Data,Ref,Sample);
    %[z, OCTImage(:, i)] = raw2ascan2(Data);

end 

%% 

figure('Position', [200 200 300 800]);
OCTImage = OCTImage/max(median(OCTImage.'));
OCTImagedB = 20*log10(OCTImage);
imagesc(RawData.x*1e3, z*1e6, OCTImagedB);
xlabel('\mum'); ylabel('\mum');
clim([-45 max(max(OCTImagedB))])
colormap(gray)
axis image
set(gca, 'FontSize', 14)
xtickangle(45)
colorbar;
title({['Offset = ' num2str((RawData.Offset - RawData.HomeOffset)*268.2) '\mum'], ['Exposure = ' num2str(RawData.Exposure) 'ms'], ['Gain = ' num2str(RawData.Gain) 'dB']});
FigName = erase(fileNames{j}, '.mat');
set(gcf, 'Name', FigName);
saveas(gcf, [Foldername '\' FigName, '.png']);
saveas(gcf, [Foldername '\' FigName, '.fig'])




% end
end

