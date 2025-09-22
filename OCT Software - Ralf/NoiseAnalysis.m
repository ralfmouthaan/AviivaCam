% Ralf Mouthaan
% University of Adelaide
% July 2025
% 
% Script for noise analysis of B-scan data

%% User-defined

clc;
clearvars -except Cam Controller dq offsetPI HomeOffset;
addpath('Functions\')

Foldername = 'Results/20250814/';
Filename = '20250814_Polyfilm_Offset =0.0mm_Exposure =80_Gain =-5.mat';
RawData =  load([Foldername Filename]);

%%

Ref = RawData.ReferenceArm;

for i= 1:size(RawData.OCTSpectrum, 3) % Iterates over A-scans

    Data = RawData.OCTSpectrum(:, :, i);
    Sample = RawData.SampleArm(:, :, i);
    %[z, OCTImage(:, i)] = raw2ascan2(Data, Ref, Sample);
    %[z, OCTImage(:, i)] = raw2ascan2(Data);
    [z, AScan] = raw2ascan2(Data);

    % Find range of z where we will find the first surface
    [~, idxminz] = min(abs(z - 400e-6));
    [~, idxmaxz] = min(abs(z - 600e-6));
    [~, idxmax] = max(AScan(idxminz:idxmaxz));
    idxmax = idxmax + idxminz + 1;
    OCTImage(:, i) = AScan(idxmax - 30:idxmax + 300);
    z = z(idxmax - 30:idxmax + 300);

    if i == 1
        SumImage = OCTImage(:, i);
    else
        SumImage = SumImage + OCTImage(:, i);
    end

end 

[~, idxminz] = min(abs(z - 445e-6));
[~, idxmaxz] = min(abs(z - 470e-6));
I_500 = max(SumImage(idxminz:idxmaxz));
[~, idxminz] = min(abs(z - 799e-6));
[~, idxmaxz] = min(abs(z - 840e-6));
I_1400 = max(SumImage(idxminz:idxmaxz));
[~, idxminz] = min(abs(z - 1340e-6));
[~, idxmaxz] = min(abs(z - 1390e-6));
I_2000 = max(SumImage(idxminz:idxmaxz));
[~, idxminz] = min(abs(z - 2200e-6));
[~, idxmaxz] = min(abs(z - 2300e-6));
I_back = mean(SumImage(idxminz:idxmaxz));
fprintf('SBR_500 = %0.2f\n', 10*log10(I_500/I_back));
fprintf('SBR_1400 = %0.2f\n', 10*log10(I_1400/I_back));
fprintf('SBR_2000 = %0.2f\n', 10*log10(I_2000/I_back));

figure(10); 
[~, idxminz] = min(abs(z - 400e-6));
[~, idxmaxz] = min(abs(z - 500e-6));
plot(z*1e6, 20*log10(SumImage/max(SumImage(idxminz:idxmaxz))));
hold on
title({['Offset = ' num2str((RawData.Offset - RawData.HomeOffset)*268.2) '\mum'], ['Exposure = ' num2str(RawData.Exposure) 'ms']})
xlabel('z (\mum)')
ylabel('Signal (dB)')

return;

%% 

figure('Position', [200 200 300 800]);
OCTImage = OCTImage/max(median(OCTImage.'));
OCTImagedB = 20*log10(OCTImage);
imagesc(RawData.x*1e3, z*1e6, OCTImagedB);
xlabel('\mum'); ylabel('\mum');
clim([min(min(OCTImagedB)) max(max(OCTImagedB))])
colormap(gray)
set(gca, 'FontSize', 14)
xtickangle(45)
colorbar;

%%
ax = gca
cmap = copper(10)
ax.ColorOrder = cmap
title('OCT signal for different spatial offset values')
legend('0.0mm','0.1mm','0.2mm','0.3mm','0.4mm','0.5mm','0.6mm','0.7mm','0.8mm')