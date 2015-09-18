function [fin,stats] = WatershedsegmCytoplasm(I2,I,se)
% USE THE WATERSHED OF THE NUCLEAR CHANNEL(OBTAINED FROM THE WATERSHED.M
% FUNCTION) AS THE FOREGROUND OBJECT OF THE CYTOPLASMIC CHANNEL. FIRST NEED
% TO CONVERT THE LABEL MATRIX OF THE WATERSHEDTO THE LOGICAL IMAGE

% I2 = imread('SingleCellSignalingAN_t0000_f0019_z0003_w0001.tif');% gfp channel (gfp-smad4 cells)
% I = imread('SingleCellSignalingAN_t0000_f0019_z0003_w0000.tif');% nuc chan
%----------------
% need to obtain the bw image of the watershed of the nuclear channel (
% convert the label matrix obtained from watershed function into the bw
% need to then subtract this from the cytoplasmic channel and this will
% give the foreground object image
[Lnuc,statsnuc] = Watershedsegm(I,se);

 bw = Lnuc ;%> 1;
  
 nuc = I2;
% nuc_o = nuc;
% preprocess
global userParam;
userParam.gaussRadius = 10;
userParam.gaussSigma = 3;
userParam.small_rad = 3;
userParam.presubNucBackground = 1;
userParam.backdiskrad = 300;

nuc = imopen(nuc,strel('disk',userParam.small_rad)); % remove small bright stuff
nuc = smoothImage(nuc,userParam.gaussRadius,userParam.gaussSigma); %smooth
nuc =presubBackground_self(nuc);
%  Normalize image
diskrad = 100;
low_thresh = 500;
    
nuc(nuc < low_thresh)=0;
norm = imdilate(nuc,strel('disk',diskrad));
normed_img = im2double(nuc)./im2double(norm);
normed_img(isnan(normed_img))=0;
figure,imshow(normed_img);


% threshold and find objects
thresh = 0.04; %arealo = 1000;%0.04

 nthresh = normed_img > thresh;
 imshow(nthresh);
 t = bw+nthresh;
 t = im2bw(t);
%  t2 = im2bw(t-bw);
%  imshow(t2,[]);
%  fgm = imregionalmax(t2);%t2
%  
%  figure,imshow(fgm);title('foreground markers');
 fgm = imregionalmax(t);

h = fspecial('sobel');
Ix  = imfilter((bw+nthresh),h,'replicate'); %double(normed_img) %f3 if the other algothithm is used
Iy  = imfilter((bw+nthresh),h','replicate');
gradmag = sqrt(Ix.^2 + Iy.^2);% this is the image where the dark regions are objects to be segmented (?) doublecheck
%figure, imshow(gradmag);

%now marking the background objects( in the normed_img the dark pixels belong to the background)
%bw = im2bw(normed_img, graythresh(normed_img));

%bw1 = im2bw(normed_img,graythresh(normed_img));%f3
% figure,imshow(bw1);
%-----------
%D = bwdist(t2);%
D = bwdist(t);%
figure,imshow(D);title('distance transform');
DL = watershed(D);
bgm =  DL == 0; %watershed ridge lines (background markers, bgm)
%calculate the watershed transform of the segmentation function
figure,imshow(bgm);title('background markers');
gradmag2 = imimposemin(gradmag,bgm|fgm);     % modify the image so that it only has ...
...regional minima at desired locations(here the reg. min need to occur only ...
...at foreground and background locations
Lall = watershed(gradmag2); % final watershed segmentation
%L == 0; % this is where object boundaries are located
Lrgb = label2rgb(Lall, 'jet', 'k', 'shuffle');
figure,imshow(I2,[]);hold on
% h = imshow(Lrgb);
% h.AlphaData = 0.3;  % overlap the segmentation with the original image using transparency option of the image object 
% get the purely cytoplasmic mask by subtracting the nuclear watershed from
% the watershed of the nuc+cyto;
lrgball = label2rgb(Lall);
 lrgbgrall = rgb2gray(lrgball);
% imshow(lrgbgr,[]);
 lblall = im2bw(lrgbgrall,graythresh(lrgbgrall));
 % bw was obtained from converting the L, returned by the Watershed() to
 % logcal image
 S = bw + lblall;
 S = im2bw(S);
 fin = S-bw;
 figure, imshow(fin);
 
 figure,imshow(I2,[]);hold on
%  h = imshow(fin);
%  h.AlphaData = 0.3;
 
 
 
end

