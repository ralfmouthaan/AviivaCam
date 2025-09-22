% Ralf Mouthaan & Freja Hoier
% University of Adelaide & DTU
% October 2024
% 
% Script to run live A-scan, showing camera image, raw spectrum and A-scan.

clc; close all;
clearvars -except Cam Controller dq offsetPI HomeOffset;

%% Set up

% Define the placement on the galvo mirror (x y)
write(dq, [0 0]);

% Moving the sample to the offset

global_offset = 0.0
Offset = HomeOffset + global_offset;
movePI(offsetPI,Offset,'1')
global_exposure =200
global_gain = -20
% Ensure that the exposure time is the correct on
Cam = Cam.StopStreaming();
Cam.SetExposure(global_exposure); % in us
Cam.SetGain(global_gain);
Cam = Cam.StartStreaming();

maxval_arr = zeros(10,1)
%% Live A-scan
i = 1
figure;
while true
        
    % Collect and process data
    Image = Cam.GetImage();
    [z, dataOCTlin] = raw2ascan2(Image); 
    
    % Show raw image
    subplot(2, 2, [3, 4])
    imagesc(Image);
    clim([0 255]);
    axis image;
    colormap gray;
    
    % Show raw spectrum
    subplot(2,2,1)
    plot(Image(50,:))
    hold on
    yline(60, ':')
    hold off
    ylim([0 255])
    xlim([0, 2048])

    % Show A-scan
    subplot(2,2,2)
    plot(z*1e3, dataOCTlin)
    xlabel('z (mm)')
%          ylim([0, 0.25])
%     xlim([0.25, 0.75])

    maxval = max(max(dataOCTlin(1:end)));
     maxval_arr(i) = maxval;

    maxidx = find(dataOCTlin == maxval);
    maxidx = maxidx(1);
    maxpos = z(maxidx)*1e3;

    fprintf('Max: %0.1fum, %0.2f\n', maxpos*1000, max(max(dataOCTlin)));

    drawnow;
i= i +1
end


%%
fprintf('%0.2f\n',mean(maxval_arr(1:10)))
fprintf('%0.5f',std(maxval_arr))

writematrix(dataOCTlin, 'myfile.csv', 'WriteMode', 'append');
