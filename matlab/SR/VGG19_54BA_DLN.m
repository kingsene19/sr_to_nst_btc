function dln = VGG19_54BA_DLN()
    v = vgg19;
    vL = v.Layers(:);
      
    inL = imageInputLayer([224 224 3], 'Normalization', 'none', 'Name', 'in_wo_normalize');
    
    scL = AddMulRGBLayer('scale_to_PM128', [0, 0, 0], [128.0, 128.0, 128.0]);
    
    dln = dlnetwork([inL scL vL(2:36)']);
end
