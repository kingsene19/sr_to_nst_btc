function Isr = ESRGAN_2xSuperResolution(Ilr)
    scale = 2;

    load('ESRGAN.mat');
    
    Ilr_s = im2single(Ilr);
    Ilr_dl = dlarray(Ilr_s, 'SSCB');
    
    [Isr_dl, stateG] = forward(dlnG, Ilr_dl);
    
    Isr = single(extractdata(Isr_dl));
    Isr = Isr * 0.5 + 0.5;    
    
    %figure;
    %imshow(Isr);
    %title('ESRGAN Super Resolution Image');
end





