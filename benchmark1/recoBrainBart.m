clear all; clc; close all; 

% Path to BART toolbox
setenv('TOOLBOX_PATH', '/opt/bart-0.6.00');
addpath(strcat(getenv('TOOLBOX_PATH'),'/matlab'));

%% Load data
rawdata_real    = h5read('data/rawdata_brain_radial_96proj_12ch.h5','/rawdata');
trajectory      = h5read('data/rawdata_brain_radial_96proj_12ch.h5','/trajectory');

rawdata = rawdata_real.r+1i*rawdata_real.i; clear rawdata_real;
rawdata = permute(rawdata,[4,3,2,1]); % Dimension convention of BART
trajectory = permute(trajectory,[3,2,1]); % Dimension convention of BART
[~,nFE,nSpokes,nCh] = size(rawdata);

%% Demo: NUFFT reconstruction with BART
% inverse gridding
img_igrid = bart('nufft -i -t', trajectory, rawdata);

%% Espirit coil sensitivities
kspace_calib = bart('fft -u 3', img_igrid);
[calib emaps] = bart('ecalib -r 30', kspace_calib);
smaps = bart('slice 4 0', calib);

%% L2-SENSE reco for reference
img_ref = bart('pics -l2 -r 0.001 -i 100 -t', trajectory, rawdata, smaps);

%% undersampled L2-SENSE reco for different undersampling factors
rf = [1,2,3,4];
times = zeros(1, length(rf));
img_cg = {};
for i=1:length(rf)
    traj_sub = trajectory(:,:,1:rf(i):nSpokes);
    rawdata_sub = rawdata(:,:,1:rf(i):nSpokes,:);
    tic();
    img_cg{i} = bart('pics -l2 -r 0.001 -i 20 -t', traj_sub, rawdata_sub, smaps);
    times(i) = toc();
end

%% write output images and reco times to files
writematrix(times, 'reco/bart/recoTimesBart.csv', 'WriteMode', 'append');
for i=1:length(rf)
   h5create('reco/img_cg_bart.h5',['/rf' num2str(rf(i))],[300,300])
   h5write('reco/img_cg_bart.h5', ['/rf' num2str(rf(i))], mydata)
end