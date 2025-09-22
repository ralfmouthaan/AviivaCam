% Ralf Mouthaan & Freja Hoier
% University of Adelaide & DTU
% October 2024
% 
% Script to run full B-scan measurement, including reference arm
% measurement and sample arm measurement, and iterating over different
% offsets. The raw data is saved to a file and is subsequently processed by
% ProcessFullBscan.m.

%% Clear variables from last run

clearvars -except Cam Controller dq offsetPI HomeOffset global_offset global_gain global_exposure;
clc; close all 

%% Manual changeable settings - Initial values

date = '20250910' ; % Date of the experiments


RefHeight = '0.5mm'; % Reference focus height
SampleHeight = '0.5mm'; % Sample height setting

PowerSetting = 'HP'; % LP (low power) or HP (High power)
Offset = HomeOffset + global_offset; % Offset in mm as set on the motor

Exposure = global_exposure;

Gain = global_gain;

Sample = strcat('Spacer_PH50__Offset = ', num2str(Offset-HomeOffset),'mm_Exposure = ', num2str(Exposure),'_Gain = ', num2str(Gain)); % Type of sample

% Galvo
MiddleV = 0.0; % This voltage corresponds to the mid-point of the range where the spot is not aberrated
SpotSize = 30; % Spot size in um
xrange_um = 8000; % Scan range in um
NoAscans = round(xrange_um/SpotSize*2);
GalvoCal = 3287; % um per V
xrange_V = xrange_um/GalvoCal;
GalvoV = linspace(MiddleV - xrange_V/2, MiddleV + xrange_V/2, NoAscans);
x = (GalvoV - min(GalvoV))*GalvoCal/1000; % x coordinates in mm


Cam = Cam.StopStreaming();
Cam.SetExposure(Exposure); % in us
Cam.SetGain(Gain);
Cam = Cam.StartStreaming();

% Offset motor
movePI(offsetPI, Offset, '1');

%% Collect image

input('PLEASE BLOCK SAMPLE ARM...');

% REFERENCE SIGNAL
fprintf('Measuring reference arm only...\n')
ReferenceArm = Cam.GetImage();

% SAMPLE + REFERENCE SIGNAL
input('PLEASE UNBLOCK SAMPLE ARM...')
fprintf('Measuring sample and reference arms...\n')
for n = 1:NoAscans % Iterating over a-scans
    write(dq,[GalvoV(n) 0]); % Move Galvo
    OCTSpectrum(:, :, n) = Cam.GetImage();
    fprintf('   Ascan %d \n',n)
end
beep
%SAMPLE SIGNAL
input('PLEASE BLOCK REFERENCE ARM...');
fprintf('Measuring sample arm only...\n')
for n = 1:NoAscans
    fprintf('   Ascan %d \n',n)
    write(dq,[GalvoV(n) 0]); % Move Galvo
    SampleArm(:,:,n) = Cam.GetImage();
end
beep

%% Save the data

fprintf("Saving Data...\n")

% Folder to save the images in
FolderName = 'Results\';
Filename = sprintf('%s_%s.mat', date, Sample);
if isfile([FolderName Filename])
    fprintf('File already exists.\n')
    return;
end
save([FolderName Filename],...
    'Sample', ...
    'OCTSpectrum',...
    'ReferenceArm',...
    'SampleArm',...
    'Exposure',...
    'Gain', ...
    'Offset', ...
    'HomeOffset', ...
    'GalvoV', ...
    'x', ...
    'SampleHeight', ...
    'RefHeight')
