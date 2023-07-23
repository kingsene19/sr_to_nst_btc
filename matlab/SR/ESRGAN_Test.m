clear;
clc;
clearvars;
close all;

n = 2.0;

exts = {'.jpg','.png'};
fileNames = {'sherlock.jpg', ...
    'indiancorn.jpg','sevilla.jpg',...
    'peacock.jpg',};

filePath = [fullfile(matlabroot,'toolbox','images','imdata') filesep];
filePathNames = strcat(filePath,fileNames);
testImages = imageDatastore(filePathNames,'FileExtensions',exts);

IrefCropList = [];
ILanczosCropList = [];
IsisrCropList = [];


for indx=1:numel(fileNames)
    fprintf('%d / %d\n', indx, numel(fileNames));
    
    roi = [320 30 479 399];
    
    roiS = roi / 2;
    
    Ireference = readimage(testImages,indx);    
    Ireference = im2single(Ireference);
    IrefC = imcrop(Ireference, roi);
    
    IrefCropList = cat(1, IrefCropList, IrefC);
    
    IlowresC = imresize(IrefC, 1.0/n, 'lanczos3');

    ILanczos3C = imresize(IlowresC, n, 'lanczos3');

    ILanczosCropList = cat(1, ILanczosCropList, ILanczos3C);

    IsisrC = ESRGAN_2xSuperResolution(IlowresC);

    IsisrCropList = cat(1, IsisrCropList, IsisrC);

end


%figure;
%imshow(Ilanczos3)
%title('High-Resolution Image Obtained Using lanczos3 Interpolation')

combinedImg = cat(2, ILanczosCropList, IrefCropList, IsisrCropList);

imwrite(combinedImg, 'Lanczos3_Reference_ESRGAN.png');

figure;
imshow(combinedImg);
title('Lanczos3, Reference, ESRGAN');


