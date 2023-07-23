classdef PixelShuffleLayer < nnet.layer.Layer

    properties (Learnable)
    end
    
    methods
        function layer = PixelShuffleLayer(name) 
            layer.NumInputs = 1;
            layer.Name = name;

            layer.Description = "PixelShuffle";
        end
                
        function Z = predict(layer, X1)
            sz = size(X1);
            
            nX = sz(1); % 48
            nY = sz(2); % 48
            nF = sz(3); % 256
            
            if numel(sz) == 3
                Z = zeros( nX*2, nY*2, fix(nF / 4), 'like', X1 );

                Z(1:2:nX*2, 1:2:nY*2, 1:fix(nF/4)) = X1(1:nX, 1:nY, 1:4:nF);
                Z(2:2:nX*2, 1:2:nY*2, 1:fix(nF/4)) = X1(1:nX, 1:nY, 2:4:nF);
                Z(1:2:nX*2, 2:2:nY*2, 1:fix(nF/4)) = X1(1:nX, 1:nY, 3:4:nF);
                Z(2:2:nX*2, 2:2:nY*2, 1:fix(nF/4)) = X1(1:nX, 1:nY, 4:4:nF);
                
            elseif numel(sz) == 4
                nB = sz(4);
                Z = zeros( nX*2, nY*2, fix(nF / 4), nB, 'like', X1 );

                Z(1:2:nX*2, 1:2:nY*2, 1:fix(nF/4),:) = X1(1:nX, 1:nY, 1:4:nF,:);
                Z(2:2:nX*2, 1:2:nY*2, 1:fix(nF/4),:) = X1(1:nX, 1:nY, 2:4:nF,:);
                Z(1:2:nX*2, 2:2:nY*2, 1:fix(nF/4),:) = X1(1:nX, 1:nY, 3:4:nF,:);
                Z(2:2:nX*2, 2:2:nY*2, 1:fix(nF/4),:) = X1(1:nX, 1:nY, 4:4:nF,:);
            end
        end
                
        function Z = forward(layer, X1)
            Z = predict(layer,X1);
        end

    end
end

