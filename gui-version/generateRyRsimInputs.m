function []=generateRyRsimInputs(outDir,imres)
%Author: Vijay Rajagopal
%Date: 29/11/2011
%A matlab script to generate two txt files: (i) A list of all available voxels on which RyRs can be simulated and (ii) the shortest distance to the z-disk plan from each of the available voxels.
% Uses the ryrgaps file generated by connected threshold segmentation to
% get at the available positions for ryrs. 
%% INPUTS
%read in ryr gaps image stack
sarclength = 1.8;
total_sarc_slices = round(sarclength/imres(3));
myofibril_file = 'Myofibrils_halfSarc.tif';
sarcolemma_file='Sarcolemma_halfSarc.tif';
ryrgaps_file = 'RyRGaps_halfSarc.tif';
%% PROGRAM EXECUTION
mffile = [outDir myofibril_file];
mfinfo = imfinfo(mffile);
num_images = numel(mfinfo);
mfy = mfinfo(1).Height;
mfx = mfinfo(1).Width;
mfz = num_images; %
mf = uint8(zeros(mfy,mfx,mfz)); 
for i = 1:mfz
    image = imread(mffile,i,'Info',mfinfo);
    mf(:,:,i) = image;
end

%read in sarcolemma stack
slfile = [outDir sarcolemma_file];
slinfo = imfinfo(slfile);
num_images=numel(slinfo);
sly = slinfo(1).Height;
slx = slinfo(1).Width;
sl = zeros(sly,slx,mfz);
for i = 1:mfz
    image = imread(slfile,i,'Info',slinfo);
    sl(:,:,i) = image;
end

%read in ryr gap  stack to use for calculation of "available".
mMfile = [outDir ryrgaps_file];
mMinfo = imfinfo(mMfile);
num_images=numel(mMinfo);
mMy = mMinfo(1).Height;
mMx = mMinfo(1).Width;
mM = uint8(zeros(mMy,mMx,mfz));
for i = 1:mfz
    image = imread(mMfile,i,'Info',mMinfo);
    mM(:,:,i) = image;
end

available = zeros(mfy,mfx,mfz);

for i=1:mfz
    slbw = im2bw(sl(:,:,i));
    available(:,:,i) = im2bw(immultiply(slbw,mM(:,:,i)));%originally mf
end
%CALCULATING ALL THE AVAILABLE VOXELS FOR RYR SIMULATION.
[avy,avxz] = find(available==1);
avInds = find(available==1);
[avx,avz] = ind2sub([mfx,mfz],avxz);
av = [avx,avy,avz]; %need to update av with real coordinates using resolution information!

av_um = bsxfun(@times, av - ones(size(av)), imres);

%find the middle of the stack and call it the z-disc. Create another
%3D image stack that only contains the z-disc. Calculate distance transform
%from all voxels to this z-disc. This part should only calculate distance
%from myofibrillar regions of the z-disc- look up image stack of myofibrils
%alone.

%NEED TO CHANGE CODE HERE - READ COMMENT ABOVE. CALCULATE DISTANCE OF ALL
%AVAILABLE VOXELS FROM MYOFIBRILLAR REGIONS.

z_discInd = round((size(mf,3))/2);
z_disc = mf(:,:,z_discInd);
discStack = uint8(zeros(mfy,mfx,mfz));
discStack(:,:,z_discInd) = z_disc;

%The background distance transform calculates the euclidean distance
%between a pixel and the nearest non-zero pixel of BW. We can use this
%function to calculate the distance function - distance of a voxel from the
%z-disk.
%create binary of discStack
discStackbw = logical(zeros(size(discStack)));
for i=1:mfz
    discStackbw(:,:,i) = im2bw(discStack(:,:,i),0.9 );
end

[dFuncImg,pxmap] = bwdist((discStackbw));
d_axial = zeros(size(discStack,1),size(discStack,2),size(discStack,3));
d_radial = zeros(size(discStack,1),size(discStack,2),size(discStack,3));
for i = 1:size(discStack,1)
    for j = 1:size(discStack,2)
        for k = 1:size(discStack,3)
            [closest_i,closest_j,closest_k] = ind2sub(size(mf),pxmap(i,j,k));
            z_dist = abs(double(k)-double(closest_k));
            d_axial(i,j,k) = z_dist;
            rad_dist = sqrt((double(j)-double(closest_j))^2+(double(i)-double(closest_i))^2);
            d_radial(i,j,k) = rad_dist;
        end
    end
end

daxial_avs = d_axial(avInds);
dradial_avs = d_radial(avInds);
voxres_euclid = sqrt(imres(1)^2+imres(2)^2+imres(3)^2);
voxres_euclid_axi = imres(3);
voxres_euclid_rad = sqrt(imres(1)^2+imres(2)^2);
daxial_avs_um = daxial_avs*voxres_euclid_axi;
dradial_avs_um = dradial_avs*voxres_euclid_rad;


fileID = fopen([outDir 'd_axial_pixel.txt'],'w');
fprintf(fileID,'d\r\n');
fclose(fileID);
dlmwrite([outDir 'd_axial_pixel.txt'],daxial_avs,'-append','newline','pc');

fileID = fopen([outDir 'd_axial_micron.txt'],'w');
fprintf(fileID,'d\r\n');
fclose(fileID);
dlmwrite([outDir 'd_axial_micron.txt'],daxial_avs_um,'-append','newline','pc');

fileID = fopen([outDir 'd_radial_pixel.txt'],'w');
fprintf(fileID,'d\r\n');
fclose(fileID);
dlmwrite([outDir 'd_radial_pixel.txt'],dradial_avs,'-append','newline','pc');

fileID = fopen([outDir 'd_radial_micron.txt'],'w');
fprintf(fileID,'d\r\n');
fclose(fileID);
dlmwrite([outDir 'd_radial_micron.txt'],dradial_avs_um,'-append','newline','pc');

fileID = fopen([outDir 'W_pixel.txt'],'w');
fprintf(fileID,'x,y,z\r\n');
fclose(fileID);
dlmwrite([outDir 'W_pixel.txt'],av,'-append','newline','pc');

fileID = fopen([outDir 'W_micron.txt'],'w');
fprintf(fileID,'x,y,z\r\n');
fclose(fileID);
dlmwrite([outDir 'W_micron.txt'],av_um,'-append','newline','pc');
%we only need the distance function for the available voxels for ryr simulation in the image
%stack

