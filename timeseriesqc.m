function qc = timeseriesqc(imgs, flags)
% Timeseries QC
% FORMAT [imdiff, g, slicediff] = timeseriesqcs(imgs, flags)
%
% imgs  - string or cell or spm_vol list of images
% flags - specify options; if contains:
%           m   - create mean var image (vmean*), max slice var image
%                 (vsmax*) and scan to scan variance image (vscmean*)
%           v   - create variance image for between each time point
%
% qc    - QC measures
%   imgs    - input
%   global  - for each volume
%       mean    - mean voxel signal intensity for each volume
%       svd     - mean squared voxel difference (SVD) between each image in time series
%       fft     - Fast Fourier Transform of the mean corrected for global mean
%   slice   - for volume x slice
%       mean    - mean voxel signal intensity for image x slices
%       svd     - slice by slice squared voxel difference (SVD) between each image
%       fft     - Fast Fourier Transform of the mean corrected for slice means
%
% DTP is a difference time point (2:T)
% SVD is squared voxel difference (relative to the previous timepoint)
% MSVD is the mean of this measure across voxels (one value)
%
% Matthew Brett 17/7/2000
% Narender Ramnani & Tibor Auer 26/2/2018
% Tibor Auer 23/3/2024

qc.imgs = imgs;

Vs = spm_vol(char(imgs));
V1 = Vs(1);
Vr = Vs(2:end);

nDTP = numel(Vs)-1;
nSlice = V1.dim(3);

Yp = spm_read_vols(V1);
g = [mean(Yp(:)); zeros(nDTP,1)]; % global mean
slicemean = [squeeze(mean(Yp,[1,2]))'; zeros(nDTP,nSlice)];
slicesvd = zeros(nDTP,nSlice); % MSVD

if any(flags == 'v')  % write individual SVD for each DTP
    Vsvd = V1;
    Vsvd.fname = spm_file(Vsvd.fname,'prefix','svd');
end

if any(flags == 'm')
    Vmax = V1; Vmax.fname = spm_file(Vmax.fname,'prefix','maxsvd'); Vmax.dt(1) = spm_type('float32');
    maxSVDslice = zeros(1,size(Yp,3)); % slicewise max SVD
    maxSVD = zeros(size(Yp)); % voxelwise max SVD
    Vmean = V1; Vmean.fname = spm_file(Vmean.fname,'prefix','meansvd'); Vmean.dt(1) = spm_type('float32');
    sumSVD = zeros(size(Yp)); % voxelwise sum SVD for mean
    Vvar = V1; Vvar.fname = spm_file(Vvar.fname,'prefix','varsvd'); Vvar.dt(1) = spm_type('float32');
    sY = zeros(size(Yp)); % voxelwise max SVD
    ssqY = zeros(size(Yp)); % voxelwise max SVD
end

for i = 1:nDTP
    Y = spm_read_vols(Vr(i));

    % mean
    g(i+1) = mean(Y(:));
    slicemean(i+1,:) = squeeze(mean(Y,[1,2]));

    % SVD
    svdY = (Y - Yp).^2;
    slicesvd(i,:) = squeeze(mean(svdY,[1,2]));
    Yp = Y;

    if any(flags == 'v')
        Vsvd.n(1) = i;
        spm_write_vol(Vsvd,svdY);
    end

    if any(flags == 'm')
        selSlice = slicesvd(i,:) > maxSVDslice;
        maxSVD(:,:,selSlice) = svdY(:,:,selSlice);
        maxSVDslice(selSlice) = slicesvd(i,selSlice);

        sumSVD = sumSVD + svdY; % sum up SVDs for mean SVD (across time points)
        sY = sY + Y; % sum up data for simple variance calculation
        ssqY = ssqY + Y.^2; % sum up squared data for simple variance calculation
    end
end

if any(flags == 'm')
    spm_write_vol(Vmax,maxSVD);
    spm_write_vol(Vmean,sumSVD/nDTP);
    spm_write_vol(Vvar,(ssqY-(sY.^2)/nDTP)./(nDTP-1));
end

qc.global.mean = g;
qc.global.svd = mean(slicesvd,2);
gfft = abs(fft(g-mean(g))); qc.global.fft = gfft(2:end-1);

qc.slice.mean = slicemean;
qc.slice.svd = slicesvd;
slicemean_norm = slicemean - repmat(mean(slicemean,1),size(slicemean,1),1);
sfft = abs(fft(slicemean_norm)); qc.slice.fft = sfft(2:end-1,:);
