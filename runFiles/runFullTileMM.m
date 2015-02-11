function runFullTileMM(direc,outfile,paramfile,step)
%runFullTile(direc,outfile,maxims,step)
%---------------------
%For a set of tiled images, runs segmentCells (uses parfor for this), runs
%alignment program for images, outputs in matfile -- peaks -- cell by cells
%list by image, colonies -- colonies data structure
%direc -- image directory
%outfile -- matfile for output
%step = step to begin at. See code. allows for skipping finding cells etc.

if ~exist('step','var')
    step=1;
end

if ~exist('paramfile','var')
    paramfile='setUserParamSC20xIFEDS';
end

ff=readMMdirectory(direc);
dims = [ max(ff.pos_x) max(ff.pos_y)];
wavenames=ff.chan;

maxims= dims(1)*dims(2);
nloop=4;
imgsperprocessor=ceil(maxims/nloop);

%generate background image for each channel
if step < 2
    for ii=1:length(wavenames)
        [minI, meanI]=mkBackgroundImageMM(ff,ii,min(500,maxims));
        bIms{ii}=uint16(2^16*minI);
        normIm=(meanI-minI);
        normIm=normIm.^-1;
        normIm=normIm/min(min(normIm));
        nIms{ii}=normIm;
    end
    save([direc filesep outfile],'bIms','nIms','dims');
end
%runTileLoop--runs segmentCells in parfor loop,
%send imgsperprocessor to each, nloop = total number necessary
%Assemble Mat Files--puts together matfiles, all data stored as peaks in
%outfile
if step < 3
    load([direc filesep outfile],'bIms','nIms');
    runTileLoopMM(ff,imgsperprocessor,nloop,maxims,bIms,nIms,paramfile);
end

%performs a series of pairwise alignments,
%each img is aligned img on top and to the left, pixel overlap
%stored in accords, can also return fully aligned image, but not
%recommended for large numbers of files.
if step < 4
    acoords=alignManyPanelsMM(ff,1:200,maxims);
    save([direc filesep outfile],'acoords','-append');
end

if step < 5
     assembleMatFiles(direc,imgsperprocessor,nloop,outfile);
end
%peaksToColonies generates the colony structure from peaks and accords
%computes alpha volume and then finds all connected components.
if step < 6
    load([direc filesep outfile],'bIms','nIms');
    [colonies, peaks]=peaksToColonies([direc filesep outfile]);
    plate1=plate(colonies,dims,direc,chans,bIms,nIms);
    save([direc filesep outfile],'plate1','peaks','-append');  
end



