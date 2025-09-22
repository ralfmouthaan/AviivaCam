% Ralf Mouthaan and Emi
% University of Adelaide
% August 2025
%
% Function to convert raw image data (assumed to be captured on AviivaCam
% camera, but others might also work) into an a-scan.
%  - Crops out the region where the spectrum is non-zero
%  - Applies a wavelength calibration
%  - Converts to regularly spaced k-vectors
%  - Dispersion compensation
%  - Inverse Fourier transform
%
% This function only does this for the reference and sample arms individually,
% Not the interference pattern to construct the OCT image itself itself, use raw2ascan2 for actual oct image processing !
%
% Finally, the data is trimmed to give one half of the symmetrical trace
% and the DC component is removed.

function [ref_arr, sample_arr] = raw2ascan_refandsample(ReferenceArm, SampleArm)

% Note, all data is in column format.

% Dispersion correction parameters
%a2 = -1e-6;
%a3 = -35e-9;
a2 = 0;
a3 = 0;

% Crops
pix = (2:2000).'; % Spectral domain crop
ncrop = 30; % DC crop

% Calibration
%lam_cal = [832 846 860].'*1e-9;
%pix_cal = [1048 1253 1419].'; % Low power
%pix_cal = [1094 1316 1502].'; % High power
%pix_cal = [625 1253 1750].';
%     lam_cal = [849-18 849 849+18].'*1e-9;
%     pix_cal = [500 1000 1400].';
lam_cal = [827.47 858.76].'*1e-9; % measured with oceab HR spectrometer 8/8/2025
pix_cal = [646 1.4903e+03].';
%
% Use calibration to determine which pixel is which wavelength

% Fitting function expects data in column format.
fres = fit(pix_cal, lam_cal, 'poly1');
lam = feval(fres, pix.');

% Convert to regularly-spaced k-vectors
k = 2*pi./lam;
Dk = max(k) - min(k);
dk = Dk/length(k);
dz = 1/Dk;
kfit = (min(k):dk:max(k)).';
kdisp = -length(kfit)/2 + 1/2:length(kfit)/2 - 1/2;
dispcomp = exp(1i*(a2*kdisp.^2 + a3*kdisp.^3));


SampleArm = double(SampleArm);
ReferenceArm = double(ReferenceArm);

% Process ReferenceArm
for i = 1:size(ReferenceArm, 1)

    datarow = ReferenceArm(i,:);

    % Interpolate data to obtain values at regularly-spaced ks.
    datarow = datarow(pix);
    datarow = interp1(k, datarow, kfit.','spline');

    % Dispersion compensation
    kdisp = -length(kfit)/2 + 1/2:length(kfit)/2 - 1/2;
    dispcomp = exp(1i*(a2*kdisp.^2 + a3*kdisp.^3));
    datarow = datarow.*dispcomp;

    % Inverse Fourier transform
    datarow = abs(ifft(datarow));
    NewReferenceArm(i,:) = datarow;

end
ref_arr = mean(NewReferenceArm, 1);

% Process SampleArm
for i = 1:size(SampleArm, 1)

    datarow = SampleArm(i,:);

    % Interpolate data to obtain values at regularly-spaced ks.
    datarow = datarow(pix);
    datarow = interp1(k, datarow, kfit.','spline');

    % Dispersion compensation
    kdisp = -length(kfit)/2 + 1/2:length(kfit)/2 - 1/2;
    dispcomp = exp(1i*(a2*kdisp.^2 + a3*kdisp.^3));
    datarow = datarow.*dispcomp;

    % Inverse Fourier transform
    datarow = abs(ifft(datarow));
    NewSampleArm(i,:) = datarow;

end


 sample_arr = NewSampleArm(:,ncrop:length(NewSampleArm)/2);

ref_arr = ref_arr(ncrop:length(ref_arr)/2);
%     % Only take the one half of the spectrum/data
%     % Removal of DC
% z = (1:length(data))*dz/2*6.06; % Divide to account for double-pass? 9.3 even bigger fudge factor?

end
