clear;
clc;
clearvars;
close all;
rng('default');
rng(42);

startTick = tic;

if ~isfolder('trained')
    mkdir('trained');
end


trainName = 'RGB_Flickr2K_VGG54';

versionStr = '100';
imgScale = 2;
patchSize = [112 112]; 
miniBatchSz     = 12;
patchesPerImage = 2;
preTrainEpochs  = 10;
preTrainLR = 0.0002;
preTrainDiscEpochs = 5;
ganTrainEpochs  = 300; 
loadEpochPre = 0;
loadEpochGAN = 0;


f = figure;
xywh=get(0,'ScreenSize');
plotSz=xywh(3)/4;
f.Position = [ 1 500 plotSz*4 plotSz ];

setappdata(gcf, 'SubplotDefaultAxesLocation', [0, 0, 1, 1]);
scoreAx = subplot(1,4,1);

xlabel("Iteration")
ylabel("Loss")

lineBlack = animatedline(scoreAx, 'LineStyle', 'none', 'Marker', 'o', 'MarkerSize', 4, 'MaximumNumPoints', 100, 'Color', 'black');
lineBlue  = animatedline(scoreAx, 'LineStyle', 'none', 'Marker', 'x', 'MarkerSize', 4, 'MaximumNumPoints', 100, 'Color', 'b');
lineRed   = animatedline(scoreAx, 'LineStyle', 'none', 'Marker', '+', 'MarkerSize', 4, 'MaximumNumPoints', 100, 'Color', 'r');

hleg = legend('PreTrainGenerator', '-', '-', 'Location', 'southwest');

title('Reading train files...')

imgLRAx = subplot(1,4,2);
imgSRAx = subplot(1,4,3);
imgHRAx = subplot(1,4,4);

drawnow

dlnG = ESRGAN_Generator();
dlnD = SRGAN_Discriminator();

dlnVGG = VGG19_54BA_DLN();

trailAvgG = [];
trailAvgSqG = [];
trailAvgD = [];
trailAvgSqD = [];

trainLRImgs = imageDatastore(['Flickr2kAll_RGB_MatlabF2' filesep 'train_' num2str(imgScale) 'x_small_mat'], 'FileExtensions','.mat','ReadFcn',@matRead);
trainHRImgs = imageDatastore(['Flickr2kAll_RGB_MatlabF2' filesep 'train_' num2str(imgScale) 'x_gt_mat'],    'FileExtensions','.mat','ReadFcn',@matRead);
nTrainImgs = numel(trainHRImgs.Files);

nItePerEpoch = fix(nTrainImgs * patchesPerImage / miniBatchSz);

dsTrain = randomPatchSmallLargePairDataStore(trainLRImgs, trainHRImgs, patchSize, imgScale, ...
     'DataAugmentation', 'none', 'PatchesPerImage', patchesPerImage);
 
mbqT = minibatchqueue(dsTrain, ...
    'MiniBatchSize', miniBatchSz, ...
    'MiniBatchFormat','SSCB',...
    'PartialMiniBatch', 'discard');

%% Pre-train。

if 0 < loadEpochPre
    fname = sprintf('trained/ESRGAN%s_preTrainG_%s_%dx_epoch%d.mat', versionStr, trainName, imgScale, loadEpochPre);
    load(fname);
end

if loadEpochPre < preTrainEpochs
    startEpoch = loadEpochPre + 1;
    dlnG = PreTrainNetwork(preTrainLR, trainName, imgScale, dlnG, ...
            imgLRAx, imgSRAx, imgHRAx, lineBlack, preTrainEpochs, trailAvgG, trailAvgSqG, startTick, startEpoch, nItePerEpoch, ...
            mbqT, versionStr);
end

if 0 < loadEpochGAN
    fname = sprintf('trained/ESRGAN%s_GANTrain_%s_%dx_epoch%d.mat', versionStr, trainName, imgScale, loadEpochGAN);
    load(fname);
end


clearpoints(lineBlack);

hleg.String = {'DiscHRImg', 'DiscSRImg', 'Discriminator'};

startEpochGAN = loadEpochGAN + 1;
dlnG = GANTrainNetwork(trainName, imgScale, dlnG, dlnD, dlnVGG, miniBatchSz, ...
        imgLRAx, imgSRAx, imgHRAx, lineBlack, lineBlue, lineRed, ganTrainEpochs, trailAvgG, ...
        trailAvgSqG, trailAvgD, trailAvgSqD, startTick, startEpochGAN, nItePerEpoch, preTrainDiscEpochs, ...
        mbqT, versionStr);

function dlnG = PreTrainNetwork(preTrainLR, trainName, imgScale, dlnG, ...
        imgLRAx, imgSRAx, imgHRAx, lineBlack, preTrainEpochs, trailAvgG, trailAvgSqG, startTick, loadEpochPre, nItePerEpoch, ...
        mbqT, versionStr)
    for epoch = loadEpochPre : preTrainEpochs
        fprintf('PreTrainNetwork Epoch %d\n', epoch)

        shuffle(mbqT);
        clearpoints(lineBlack);

        ite = 0;
        while hasdata(mbqT)
            ite = ite + 1;
            
            [imgLR, imgHR] = next(mbqT);
            [gradG, lossG, imgSR] = dlfeval(@preTrainGen, dlnG, imgLR, imgHR);
            
            [dlnG,trailAvgG,trailAvgSqG] = adamupdate(dlnG, gradG, ...
                trailAvgG, trailAvgSqG, ite, preTrainLR);

            % Update the scores plot.
            lossValue = double(gather(extractdata(lossG)));
            subplot(1,4,1);
            addpoints(lineBlack, ite, lossValue);
            % Update the title with training progress information.
            D = duration(0,0,toc(startTick),'Format','hh:mm:ss');
            title(...
                "Pre-train Generator Epoch " + epoch + ...
                ", Ite " + ite + " / " + nItePerEpoch + ...
                ", " + string(D))

            if mod(ite, 10) == 0 || ite == 1
                showImg(imgLR, imgSR, imgHR, imgLRAx, imgSRAx, imgHRAx);
            end
            
            drawnow
        end
        
        fname = sprintf('trained/ESRGAN%s_preTrainG_%s_%dx_epoch%d.mat', versionStr, trainName, imgScale, epoch);
        save(fname ,'dlnG', 'trailAvgG', 'trailAvgSqG');
    end
end

function dlnG = GANTrainNetwork(trainName, imgScale, dlnG, dlnD, dlnVGG, miniBatchSz, ...
        imgLRAx, imgSRAx, imgHRAx, lineBlack, lineBlue, lineRed, ganTrainEpochs, trailAvgG, ...
        trailAvgSqG, trailAvgD, trailAvgSqD, startTick, startEpochGAN, nItePerEpoch, preTrainDiscEpochs, ...
        mbqT, versionStr)
    lrG = 0.0002;
    lrD = 0.00015;

    lrDecayPeriod = 100;    
    
    trainGenDisc = 0;

    subplot(1,4,1)
    ylim([0 1])
    xlabel("Iteration")
    ylabel("Score")

    for epoch = 1 : ganTrainEpochs
        if rem(epoch, lrDecayPeriod) == 0
            lrD = lrD / 2;
            lrG = lrG / 2;
        end        
        
        if epoch < startEpochGAN
        else
            fprintf('GANTrainNetwork Epoch=%d lrG=%f lrD=%f\n', epoch, lrG, lrD)

            if epoch <= preTrainDiscEpochs
                mode = "Train Gen / Disc separately";
            else
                mode = "Train Gen-Disc connected";
                trainGenDisc = 1;
            end

            shuffle(mbqT);
            clearpoints(lineBlack);
            clearpoints(lineBlue);
            clearpoints(lineRed);

            ite = 0;
            while hasdata(mbqT)
                ite = ite + 1;

                [imgLR, imgHR] = next(mbqT);
                [gradG, gradD, imgSR, scoreRR, scoreFR, scoreDisc] ...
                    = dlfeval(@ganTrainGenDisc, dlnG, dlnD, dlnVGG, imgLR, imgHR, miniBatchSz, trainGenDisc);

                [dlnG,trailAvgG,trailAvgSqG] = adamupdate(dlnG, gradG, ...
                    trailAvgG, trailAvgSqG, ite, lrG);

                [dlnD, trailAvgD, trailAvgSqD] = adamupdate(dlnD, gradD, ...
                    trailAvgD, trailAvgSqD, ite, lrD);

                subplot(1,4,1)
                scoreRR2 = double(gather(extractdata(scoreRR)));
                addpoints(lineBlack, ite, scoreRR2);

                scoreFR2 = double(gather(extractdata(scoreFR)));
                addpoints(lineBlue, ite, scoreFR2);

                scoreDisc2 = double(gather(extractdata(scoreDisc)));
                addpoints(lineRed, ite, scoreDisc2);

                subplot(1,4,1);
                D = duration(0,0,toc(startTick),'Format','hh:mm:ss');
                title(...
                    mode + " Ep " + epoch + ...
                    ", Ite " + ite + " / " + nItePerEpoch + ...
                    ", " + string(D))

                if mod(ite, 10) == 0 || ite == 1
                    showImg(imgLR, imgSR, imgHR, imgLRAx, imgSRAx, imgHRAx);
                end

                drawnow
            end

            fname = sprintf('trained/ESRGAN%s_GANTrain_%s_%dx_epoch%d.mat', versionStr, trainName, imgScale, epoch);
            save(fname ,'dlnG', 'dlnD',  'trailAvgG', 'trailAvgSqG', 'trailAvgD', 'trailAvgSqD');

            fname = sprintf('trained/ESRGAN%s_%s_%dx_Generator_params_epoch%d.mat', versionStr, trainName, imgScale, epoch);
            save(fname ,'dlnG');
        end
    end
end

function [gradG, lossG, imgSR] = preTrainGen(dlnG, imgLR, imgHR)
    [imgSR, ~] = forward(dlnG, imgLR);

    lossG = mse(sigmoid(imgHR), sigmoid(imgSR));

    gradG = dlgradient(lossG, dlnG.Learnables, 'EnableHigherDerivatives', false);
end

function [gradG, gradD, imgSR, scoreRR, scoreFR, scoreD] = ...
ganTrainGenDisc(dlnG, dlnD, dlnVGG, imgLR, imgHR, miniBatchSz, trainGenDisc)
    [imgSR, ~] = forward(dlnG, imgLR);

    cXr = forward(dlnD, imgHR);
    
    cXf = forward(dlnD, imgSR);
    
    dXr = sigmoid(cXr);

    dXf = sigmoid(cXf);
    
    scoreD = (mean(dXr) + mean(1- dXf)) * 0.5;

    scoreRR = mean(dXr);
    
    scoreFR = mean(dXf);

    % ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    % discriminator loss is binary cross-entropy loss, 
    % on Matlab, cross-entropy loss for multi-label classification is crossentropy('TargetCategories', 'independent')
    % ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    tgt_1 = dlarray( ones(1, 1, 1, miniBatchSz, 'single'), 'SSCB');
    tgt_0 = dlarray(zeros(1, 1, 1, miniBatchSz, 'single'), 'SSCB');

    dXrf = sigmoid(cXr - mean(cXf));
    dXfr = sigmoid(cXf - mean(cXr));

    lossRF1 = crossentropy(dXrf, tgt_1, 'TargetCategories', 'independent');
    lossFR0 = crossentropy(dXfr, tgt_0, 'TargetCategories', 'independent');
    lossD = (lossFR0 + lossRF1) * 0.5;

    lossGenMSE = mse(sigmoid(imgHR), sigmoid(imgSR));

    if trainGenDisc == 0
        lossG = lossGenMSE;
        fprintf('lG=%f lD=%f\n', lossG, lossD);
    else
        % Generator loss from Discriminator
        lossRF0 = crossentropy(dXrf, tgt_0, 'TargetCategories', 'independent');
        lossFR1 = crossentropy(dXfr, tgt_1, 'TargetCategories', 'independent');
        lossGenFromDisc = (lossFR1 + lossRF0) * 0.5;

        featGT  = runVGG19_54BA(dlnVGG, imgHR);
        featGen = runVGG19_54BA(dlnVGG, imgSR);
        lossGenContent = mse(sigmoid(featGT), sigmoid(featGen));
        lossG =                                (3.0/7.0) * lossGenMSE + (3.0/5.0) * lossGenFromDisc + (3.0/1.0e3) * lossGenContent;
        fprintf('lMSE=%f lGAN=%f lVGG54=%f\n', (3.0/7.0) * lossGenMSE,  (3.0/5.0) * lossGenFromDisc,  (3.0/1.0e3) * lossGenContent);
    end

    gradG = dlgradient(lossG, dlnG.Learnables, 'EnableHigherDerivatives', false);
    gradD = dlgradient(lossD, dlnD.Learnables, 'EnableHigherDerivatives', false);
end

function feat54 = runVGG19_54BA(dlnVGG, dlImg)
    feat54 = forward(dlnVGG, dlImg);
end

function I = convDLNtoImg(dln, isLR)
    I = extractdata(dln);    
    I = I(:,:,:, 1);
    
    if isLR == 1
    else
        I = I * 0.5 + 0.5;
    end

    szI = size(I);
    if numel(szI) == 3
        I = imresize(I, 3, 'nearest');
    else
        I = imtile(I);
    end
    
end

function showImg(imgLR, imgSR, imgHR, imgLRAx, imgSRAx, imgHRAx)
    subplot(1,4,2)
    I = convDLNtoImg(imgLR, 1);
    image(imgLRAx,I);
    axis(imgLRAx, 'image');
    set(gca,'xtick',[],'ytick',[]);
    title("Input Low Res img (2x downsampled from High Res)");

    subplot(1,4,3)
    I = convDLNtoImg(imgSR, 0);
    image(imgSRAx,I);
    axis(imgSRAx, 'image');
    set(gca,'xtick',[],'ytick',[]);
    title("ESRGAN Super Res Output img");

    subplot(1,4,4)
    I = convDLNtoImg(imgHR, 0);
    image(imgHRAx,I);
    axis(imgHRAx, 'image');
    set(gca,'xtick',[],'ytick',[]);
    title("Original High Res img");
end

