function BpodSplashScreen(Stage)
global BpodSystem
if Stage == 1
        ha = axes('units','normalized', 'position',[0 0 1 1]);
        uistack(ha,'bottom');
end    
Img = BpodSystem.SplashData.BG;
Img(201:240,1:485) = BpodSystem.SplashData.Messages(:,:,Stage); 
Img(270:274, 43:442) = ones(5,400)*128;
StartPos = 43;
EndPos = 44;

switch Stage
    case 1
        StepSize = 3;
        while EndPos < 123
            EndPos = EndPos + StepSize;
            Img(270:274, StartPos:EndPos) = ones(5,(EndPos-(StartPos-1)))*20;
            imagesc(Img); colormap('gray'); set(gcf,'name','Bpod','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); axis off; drawnow;
        end
    case 2
        StepSize = 5;
        EndPos = 123;
        while EndPos < 203
            EndPos = EndPos + StepSize;
            Img(270:274, StartPos:EndPos) = ones(5,(EndPos-(StartPos-1)))*20;
            imagesc(Img); colormap('gray'); set(gcf,'name','Bpod','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); axis off; drawnow;
        end
    case 3
        StepSize = 5;
        EndPos = 203;
        while EndPos < 283
            EndPos = EndPos + StepSize;
            Img(270:274, StartPos:EndPos) = ones(5,(EndPos-(StartPos-1)))*20;
            imagesc(Img); colormap('gray'); set(gcf,'name','Bpod','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); axis off; drawnow;
        end
    case 4
        StepSize = 5;
        EndPos = 283;
        while EndPos < 363
            EndPos = EndPos + StepSize;
            Img(270:274, StartPos:EndPos) = ones(5,(EndPos-(StartPos-1)))*20;
            imagesc(Img); colormap('gray'); set(gcf,'name','Bpod','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); axis off; drawnow;
        end
    case 5
        StepSize = 5;
        EndPos = 363;
        while EndPos < 442
            EndPos = EndPos + StepSize;
            Img(270:274, StartPos:EndPos) = ones(5,(EndPos-(StartPos-1)))*20;
            imagesc(Img); colormap('gray'); set(gcf,'name','Bpod','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); axis off; drawnow;
        end
        pause(.5);
end



