% Ralf Mouthaan & Freja Hoier
% University of Adelaide & DTU
% October 2024
% 
% Script to run quick B-scan measurement without reference subtraction
% or sample arm subtraction

clc; close all;
clearvars -except Cam Controller dq offsetPI HomeOffset Offset global_offset global_exposure global_gain;

%% Set up

pause(0.5)
% Define the placement on the galvo mirror (x y)
write(dq, [0 0]);

% Moving the sample to the 0-offset
Offset = HomeOffset + global_offset ;
movePI(offsetPI,Offset,'1')

MiddleV = 0.0; % This voltage corresponds to the mid-point of the range where the spot is not aberrated
SpotSize = 11; % Spot size in um
xrange_um = 8000; % Scan range in um
oversampleFactor = 1;
NoAscans = round(xrange_um/SpotSize*2)/oversampleFactor;
GalvoCal = 3287; % um per V
xrange_V = xrange_um/GalvoCal;
GalvoV = linspace(MiddleV - xrange_V/2, MiddleV + xrange_V/2, NoAscans);
x = (GalvoV - min(GalvoV))*GalvoCal/1000; % x coordinates in mm

% Cam = Cam.StopStreaming();
% Cam.SetExposure(750); % in us
% Cam.SetGain(0);
% Cam = Cam.StartStreaming();


%% Take measurement

clear OCTImage

NoOverExposed = 0;
for n = 1:NoAscans

    fprintf('Image collection: Ascan %d \n',n)
    write(dq, [GalvoV(n) 0]); % Move galvo
    Image = Cam.GetImage();
    if sum(sum(Image == 255)) > size(Image, 1)*size(Image, 2) * 0.02
        NoOverExposed = NoOverExposed + 1;
    end
    [z, dataOCTlin] = raw2ascan2(Image);
    OCTImage(:, n) = dataOCTlin;

    display(max(max(OCTImage(:, n))))
end

fprintf('Overexposed Percentage = %0.2f\n', NoOverExposed/NoAscans*100)


%% Plot

OCTImagedB = 20*log10(OCTImage);

figure;
imagesc(x*1e3, z*1e6, OCTImagedB)
axis image
colormap(gray)
clim([-35 max(max(OCTImagedB))+1])
xlabel('x (\mum)');
ylabel('z (\mum)');
title(['Offset = ' num2str((Offset - HomeOffset)*268.2) 'um'])

figure;
plot(z,mean(OCTImage,2))
xlabel('z(\mum)')
ylabel('mean intensity')
ylim([0,0.9])
% 
% 
% figure;
% plot(std(OCTImage, 0, 2))
% xlabel('z(\mum)')
% ylabel('std intensity')