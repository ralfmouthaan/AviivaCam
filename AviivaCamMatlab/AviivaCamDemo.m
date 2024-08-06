% Ralf Mouthaan
% University of Adelaide
% August 2024
% 
% Example script to show how to control AviivaCam from Matlab. Relies on
% AviivaCam.dll and AviivaCam.h, which were written to replace Mingzhou's
% dll which no longer works. Written for Freja Hoier.

clc; clear variables; close all;

%%

% Start up camera
Cam = AviivaCam();
Cam = Cam.Startup();

% Set parameters
Cam.SetGain(-20);
Cam.SetExposure(75);

% Determine camera properties
Width = Cam.GetWidth();
Height = Cam.GetHeight();
Gain = Cam.GetGain();
Exposure = Cam.GetExposure();

% Display camera properties
fprintf('Camera properties:\n');
fprintf(['  Width: ' num2str(Width) ]);
fprintf(['  Height: ' num2str(Height) '\n']);
fprintf(['  Gain: ' num2str(Gain) '\n']);
fprintf(['  Exposure: ' num2str(Exposure) '\n'])

% Start streaming
Cam = Cam.StartStreaming();

% Acquire 500 images
figure;
for i = 1:500

    Image = Cam.GetImage();
    imagesc(Image);
    clim([0 255]);
    axis image;
    colormap gray;
    title(i);
    drawnow;

end

% Stop streaming
Cam = Cam.StopStreaming();
Cam = Cam.Shutdown();