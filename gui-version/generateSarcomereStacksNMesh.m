function []=generateSarcomereStacksNMesh(slfile,mffile,mtfile,mMfile,imres,mesh_outDir,stack_outDir)
%Author: Vijay Rajagopal
%Date: 29/11/2011
%A matlab script to generate two txt files: (i) A list of all available voxels on which RyRs can be simulated and (ii) the shortest distance to the z-disk plan from each of the available voxels.
% Uses the ryrgaps file generated by connected threshold segmentation to
% get at the available positions for ryrs. 


%read in ryr gaps image stack
sarclength = 0.9;
total_sarc_slices = round(sarclength/imres(3));

%% read in sarcolemma stack

slinfo = imfinfo(slfile);
slz=numel(slinfo);
sly = slinfo(1).Height;
slx = slinfo(1).Width;
sl = uint8(zeros(sly,slx,slz));
for i = 1:slz
    image = imread(slfile,i,'Info',slinfo);
    sl(:,:,i) = image;
end

%% read in myofibrils stack

mfinfo = imfinfo(mffile);
mfz = numel(mfinfo);
mfy = mfinfo(1).Height;
mfx = mfinfo(1).Width;

mf = uint8(zeros(mfy,mfx,mfz)); 
for i = 1:mfz
    image = imread(mffile,i,'Info',mfinfo);
    mf(:,:,i) = image;
end

%% read in mitochondria stack
mtinfo = imfinfo(mtfile);
mtz=numel(mtinfo);
mtx = mtinfo(1).Height;
mty = mtinfo(1).Width;
mt = uint8(zeros(mtx,mty,mfz));
for i = 1:mtz
    image = imread(mtfile,i,'Info',mtinfo);
    mt(:,:,i) = image;
end

%% read in ryr gap  stack to use for calculation of "available".
mMinfo = imfinfo(mMfile);
mMz=numel(mMinfo);
mMy = mMinfo(1).Height;
mMx = mMinfo(1).Width;
mM = uint8(zeros(mMy,mMx,mMz));
for i = 1:mMz
    image = imread(mMfile,i,'Info',mMinfo);
    mM(:,:,i) = image;
end
%% pad the boundaries and write out for meshing purposes.

out_mMFile=[stack_outDir 'RyRGaps_padded.tif']
out_slFile=[stack_outDir 'Sarcolemma_padded.tif']
out_mfFile=[stack_outDir 'Myofibrils_padded.tif']
out_mtFile=[stack_outDir 'Mitochondria_padded.tif']

% add some padding to the boundaries because segmentations go right to the
% boundaries
mM = padarray(mM,[2,2,0],255);
sl = padarray(sl,[2,2,0],0);
mf = padarray(mf,[2,2,0],0);
mt = padarray(mt,[2,2,0],0);

% write out first slice
imwrite(mM(:, :, 1), out_mMFile,'WriteMode','overwrite','Compression','none');
imwrite(sl(:, :, 1), out_slFile,'WriteMode','overwrite','Compression','none');
imwrite(mf(:, :, 1), out_mfFile,'WriteMode','overwrite','Compression','none');
imwrite(mt(:, :, 1), out_mtFile,'WriteMode','overwrite','Compression','none');

%append the rest.
for z=2:mfz
   imwrite(mM(:, :, z), out_mMFile,'WriteMode','append','Compression','none');
   imwrite(sl(:, :, z), out_slFile,'WriteMode','append','Compression','none');
   imwrite(mf(:, :, z), out_mfFile,'WriteMode','append','Compression','none');
   imwrite(mt(:, :, z), out_mtFile,'WriteMode','append','Compression','none');

end
%update mfx, mfy etc because of padding
mfy = size(sl,1);
mfx = size(sl,2);
%% extend the four image stacks into sarcomeres
extent_slices = total_sarc_slices-mfz;
extension = zeros(mfy,mfx,extent_slices);
for z = 1:extent_slices
    sl(:,:,mfz+z) = extension(:,:,z);
    mf(:,:,mfz+z) = extension(:,:,z);
    mM(:,:,mfz+z) = extension(:,:,z);
    mt(:,:,mfz+z) = extension(:,:,z);

end

mid_slice = round(mfz/2);
%divide total sarc slices into two groups with mid-slice being in the
%middle.
half_sarc_slices = round(total_sarc_slices/2);
%shift the mf slices into the mid-region of mf_sarc.
shift_val = half_sarc_slices-mid_slice;
shift_start = 1+shift_val;
shift_end = shift_start+mfz-1;

for z = 1:mfz
    mf(:,:,shift_start+z-1)= mf(:,:,z);
    sl(:,:,shift_start+z-1)= sl(:,:,z);
    mM(:,:,shift_start+z-1)= mM(:,:,z);
    mt(:,:,shift_start+z-1)= mt(:,:,z);

end
%extruding the mf by copying first and last slice into the top and bottom
%empty sections of mf_sarc
top_sec = shift_start-1;
mftop = mf(:,:,1);
sltop = sl(:,:,1);
mMtop = mM(:,:,1);
mttop = mt(:,:,1);

mfbot = mf(:,:,mfz);
slbot = sl(:,:,mfz);
mMbot = mM(:,:,mfz);
mtbot = mt(:,:,mfz);

for z =1:top_sec
    mf(:,:,z) = mftop;
    sl(:,:,z) = sltop;
    mM(:,:,z) = mMtop;
    mt(:,:,z) = mttop;

end
bot_sec = shift_end+1;
for z =bot_sec:total_sarc_slices
    mf(:,:,z) = mfbot;
    sl(:,:,z) = slbot;
    mM(:,:,z) = mMbot;
    mt(:,:,z) = mtbot;

end
%change mfz to sarcomere slices
mfz = total_sarc_slices;
%write out the extruded sarcomeres for later use in kernel density
%estimation
%sarc_mfFile=[outDir 'MyoBinaryTIFFStack_Sarc.tiff']
sarc_mfFile=[stack_outDir 'Myofibrils_halfSarc.tif']
sarc_mMFile=[stack_outDir 'RyRGaps_halfSarc.tif']
sarc_slFile=[stack_outDir 'Sarcolemma_halfSarc.tif']
sarc_mtFile=[stack_outDir 'Mitochondria_halfSarc.tif']

% write out first slice
imwrite(mf(:, :, 1), sarc_mfFile,'WriteMode','overwrite','Compression','none');
imwrite(mM(:, :, 1), sarc_mMFile,'WriteMode','overwrite','Compression','none');
imwrite(sl(:, :, 1), sarc_slFile,'WriteMode','overwrite','Compression','none');
imwrite(mt(:, :, 1), sarc_mtFile,'WriteMode','overwrite','Compression','none');

%append the rest.
for z=2:total_sarc_slices
   imwrite(mf(:, :, z), sarc_mfFile,'WriteMode','append','Compression','none');
   imwrite(mM(:, :, z), sarc_mMFile,'WriteMode','append','Compression','none');
   imwrite(sl(:, :, z), sarc_slFile,'WriteMode','append','Compression','none');
   imwrite(mt(:, :, z), sarc_mtFile,'WriteMode','append','Compression','none');
   
end

%% create sl+mito image stack
% combined_sl_mito = uint8(zeros(size(sl)));
% mt_px = find(mt>125);
% sl_px = find(sl>125);
% combined_sl_mito(sl_px) = 255;
% combined_sl_mito(mt_px) = 125;

%% create sl+mito+ryrgap image stack
combined_sl_mito_ryrgap = uint8(zeros(size(sl)));
mt_px = find(mt>125);
sl_px = find(sl>125);
ryrgap_px = find(mM>10);
combined_sl_mito_ryrgap(sl_px) = 255;
combined_sl_mito_ryrgap(mt_px) = 125;
combined_sl_mito_ryrgap(ryrgap_px) = 255; %can set to different colour if I want to explicitly model myofibrils; not right now though.0;
%just make sure the outside of the cell is set to zero value.
bg_px = find(sl==0);
combined_sl_mito_ryrgap(bg_px) = 0;

%% create sl wout mito image stack
sl_wo_mito = uint8(zeros(size(sl)));
sl_wo_mito(sl_px) = 255;
sl_wo_mito(mt_px) = 0;

%% generate surface meshes of sl and mt separately for tetgen to use.

% [sl_nod,sl_el,sl_reg,sl_hole] = v2s(sl,0.1,20);
% sl_nod(:,1) = sl_nod(:,1)*imres(1);
% sl_nod(:,2) = sl_nod(:,2)*imres(2);
% sl_nod(:,3) = sl_nod(:,3)*imres(3);
% plotmesh(sl_nod,sl_el)
% savestl(sl_nod,sl_el,[mesh_outDir 'sl_surface.stl']);
% bbox = ceil(size(sl).*imres);
% savesurfpoly(sl_nod,sl_el,sl_hole,sl_reg,[-5,-5,-5],[15,15,3],[mesh_outDir 'sl_surface.poly']);
% [mt_nod,mt_el,mt_reg,mt_hole] = v2s(mt,0.2,10);
% mt_nod(:,1) = mt_nod(:,1)*imres(1);
% mt_nod(:,2) = mt_nod(:,2)*imres(2);
% mt_nod(:,3) = mt_nod(:,3)*imres(3);
% figure;plotmesh(mt_nod,mt_el);
% savestl(mt_nod,mt_el,[mesh_outDir 'mt_surface.stl']);
% savesurfpoly(mt_nod,mt_el,mt_hole,mt_reg,[-5,-5,-5],[15,15,3],[mesh_outDir 'mitos_surface.poly']);

%% generate tet mesh of the combined version
% [combined_nod,combined_el,combined_fac] = v2m(combined_sl_mito,[125,255],5,5,'cgalmesh');
% combined_nod(:,1) = combined_nod(:,1)*imres(1);
% combined_nod(:,2) = combined_nod(:,2)*imres(2);
% combined_nod(:,3) = combined_nod(:,3)*imres(3);
% % savestl(combined_nod,combined_el,[mesh_outDir 'combined_mesh.stl']);
% savetetgennode(combined_nod,[mesh_outDir 'combined_tet_mesh.node']);
% savetetgenele(combined_el,[mesh_outDir 'combined_tet_mesh.ele']);
% plotmesh(combined_nod(:,1:3),combined_el);
% title('Computational FE mesh generated from segmented tomogram');
% xlabel('x-dimension (micron)');
% ylabel('y-dimension (micron)');
% zlabel('z-dimension (micron)');
% legend('Mitochondria','Sarcolemma');
% 
%% generate tet mesh of the combined version
[combined_nod,combined_el,combined_fac] = v2m(combined_sl_mito_ryrgap,[125,255],5,5,'cgalmesh');
combined_nod(:,1) = combined_nod(:,1)*imres(1);
combined_nod(:,2) = combined_nod(:,2)*imres(2);
combined_nod(:,3) = combined_nod(:,3)*imres(3);
% savestl(combined_nod,combined_el,[mesh_outDir 'combined_mesh.stl']);
savetetgennode(combined_nod,[mesh_outDir 'combined_tet_mesh_wryrgap.node']);
savetetgenele(combined_el,[mesh_outDir 'combined_tet_mesh_wryrgap.ele']);
plotmesh(combined_nod(:,1:3),combined_el);
title('Computational FE mesh generated from segmented tomogram');
xlabel('x-dimension (micron)');
ylabel('y-dimension (micron)');
zlabel('z-dimension (micron)');
legend('Mitochondria','Sarcolemma');

%% generate tet mesh with mitos as holes
% [sl_womito_nod,sl_womito_el,sl_womito_fac] = v2m(sl_wo_mito,0.1,500,500,'cgalmesh');
% sl_womito_nod(:,1) = sl_womito_nod(:,1)*imres(1);
% sl_womito_nod(:,2) = sl_womito_nod(:,2)*imres(2);
% sl_womito_nod(:,3) = sl_womito_nod(:,3)*imres(3);
% % savestl(combined_nod,combined_el,[mesh_outDir 'combined_mesh.stl']);
% savetetgennode(sl_womito_nod,[mesh_outDir 'sl_tet_mesh.node']);
% savetetgenele(sl_womito_el,[mesh_outDir 'sl_tet_mesh.ele']);
% plotmesh(sl_womito_nod(:,1:3),sl_womito_el);
