%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2017 Sanworks LLC, Sound Beach, New York, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
classdef PsychToolboxMovieServer < handle
    properties
        Window % PsychToolbox Window object
        Movies % Cell array containing movies loaded with obj.loadMovie()
        TextStrings % Cell array containing text strings
        StimulusType % Vector of 0 = movie, 1 = frame with centred text
        ViewportBorder = 1; % Draw gray border around viewport
        UseTimer = 0; % Use MATLAB timer object to trigger frame flips (default = code loop)
    end
    properties (Access = private)
        WindowDimensions % window dimensions
        ViewPortDimensions % [Width, Height]
        ViewPortOffset = [0 0]; % Width, Height from Movie Window top-left corner
        MaxMovies = 100;
        SyncPatchSizeX = 30; % Size of sync patch in X dimension, in pixels
        SyncPatchSizeY = 30; % Size of sync patch in Y dimension, in pixels
        SyncPatchYOffset % Sync patch offset from window bottom on Y axis (in pixels)
        SyncPatchDimensions = [0 0 0 0];
        BlankScreen; % Texture of blanks screen
        Timer % Timer object that controls playback
        CurrentFrame = 1; % Current frame
        StimulusIndex = 1; % Current stimulus
        TextStringFontSize
        TextStringStartPos
    end
    methods
        function obj = PsychToolboxMovieServer(MovieWindowSize, MovieWindowYoffset, ViewPortSize, ViewPortOffset, SyncPatchSize, SyncPatchYOffset)
            obj.Movies = cell(1,obj.MaxMovies);
            obj.TextStrings = cell(1,obj.MaxMovies);
            obj.TextStringStartPos = cell(1,obj.MaxMovies);
            obj.TextStringFontSize = ones(1,obj.MaxMovies)*36;
            obj.StimulusType = zeros(1,obj.MaxMovies);
            obj.ViewPortDimensions = ViewPortSize;
            obj.ViewPortOffset = ViewPortOffset;
            obj.SyncPatchSizeX = SyncPatchSize(1);
            obj.SyncPatchSizeY = SyncPatchSize(2);
            obj.SyncPatchYOffset = SyncPatchYOffset;
            SystemVars = get(0); MonitorSize = SystemVars.ScreenSize;
            obj.WindowDimensions = [MonitorSize(3)-MovieWindowSize(1) (MonitorSize(4)-MovieWindowYoffset)-MovieWindowSize(2)... 
                MonitorSize(3) (MonitorSize(4)-MovieWindowYoffset)];
            yEnd = MovieWindowSize(2);
            xEnd = MovieWindowSize(1);
            patchStartY = yEnd-obj.SyncPatchSizeY - SyncPatchYOffset;
            patchStartX = xEnd-obj.SyncPatchSizeX;
            obj.SyncPatchDimensions = [patchStartY patchStartY+obj.SyncPatchSizeY patchStartX xEnd];
            Screen('Preference','SkipSyncTests', 0);
            %Screen('Preference', 'VBLTimestampingMode', -1);
            obj.Window = Screen('OpenWindow', max(Screen('Screens')), 0, obj.WindowDimensions);
            Frame = zeros(MovieWindowSize(2), MovieWindowSize(1));
            if obj.ViewportBorder
                Frame = obj.addViewPortBorder(Frame);
            end
            obj.BlankScreen = Screen('MakeTexture', obj.Window, Frame);
            Screen('DrawTexture', obj.Window, obj.BlankScreen);
            Screen('Flip', obj.Window);
        end
        function set.ViewportBorder(obj, Value)
            if Value == 1
                obj.ViewportBorder = 1;
            else
                obj.ViewportBorder = 0;
            end
            Frame = zeros(obj.WindowDimensions(4)-obj.WindowDimensions(2), obj.WindowDimensions(3)-obj.WindowDimensions(1)); % Use actual window width
            if obj.ViewportBorder
                Frame = obj.addViewPortBorder(Frame);
            end
            obj.BlankScreen = Screen('MakeTexture', obj.Window, Frame);
            Screen('DrawTexture', obj.Window, obj.BlankScreen);
            Screen('Flip', obj.Window);
            disp('Viewport border set. You must now manually re-load any stimuli you had previously loaded with loadMovie(), because the border is hard-coded in the video frames.')
        end
        function loadMovie(obj, MovieIndex, MovieMatrix)
            if ~isempty(obj.Movies{MovieIndex})
                Screen('Close', obj.Movies{MovieIndex}.Data);
            end
            obj.Movies{MovieIndex} = struct;
            MatrixSize = size(MovieMatrix);
            VPdim = obj.ViewPortDimensions;
            DimensionError = 0;
            if (MatrixSize(1) == VPdim(2)) && (MatrixSize(2) == VPdim(1))
                
            else
                 DimensionError = 1;
            end
            if length(MatrixSize) == 4
                if MatrixSize(3) == 3
                    MatrixType = 2; % Stack of RGB Frames
                    nFrames = MatrixSize(4);
                else
                    DimensionError = 1;
                end
            elseif length(MatrixSize) == 3
                if MatrixSize(3) == 3
                     MatrixType = 2; % Single RGB Frame
                     nFrames = 1;
                else
                     MatrixType = 1; % Stack of B&W Frames
                     nFrames = MatrixSize(3);
                end
            elseif length(MatrixSize) == 2
                MatrixType = 1; % Single B&W Frame
                nFrames = 1;
            else
                error('Error: Movie data must be a stack of 2-D images.')
            end
            if DimensionError
                error(['Error loading movie: The movie dimensions must match the viewport dimensions: ' num2str(VPdim(1)) ' X ' num2str(VPdim(2))]);
            end
            obj.Movies{MovieIndex}.nFrames = nFrames+1; % +1 to account for blank frame at the end
            obj.Movies{MovieIndex}.Data = zeros(1,nFrames);
            SignalOn = 1;
            for i = 1:nFrames
                switch MatrixType
                    case 1
                        frame = zeros(obj.WindowDimensions(4)-obj.WindowDimensions(2), obj.WindowDimensions(3)-obj.WindowDimensions(1)); % Use actual window width
                        frame(1+obj.ViewPortOffset(1):obj.ViewPortDimensions(2)+obj.ViewPortOffset(1), 1+obj.ViewPortOffset(2):obj.ViewPortDimensions(1)+obj.ViewPortOffset(2)) = MovieMatrix(:,:,i);
                        frame(obj.SyncPatchDimensions(1):obj.SyncPatchDimensions(2),obj.SyncPatchDimensions(3):obj.SyncPatchDimensions(4)) = SignalOn*255;
                    case 2
                        frame = zeros(obj.WindowDimensions(4)-obj.WindowDimensions(2), obj.WindowDimensions(3)-obj.WindowDimensions(1), 3); % Use actual window width
                        frame(1+obj.ViewPortOffset(1):obj.ViewPortDimensions(2)+obj.ViewPortOffset(1), 1+obj.ViewPortOffset(2):obj.ViewPortDimensions(1)+obj.ViewPortOffset(2), :) = MovieMatrix(:,:,:,i);
                        frame(obj.SyncPatchDimensions(1):obj.SyncPatchDimensions(2),obj.SyncPatchDimensions(3):obj.SyncPatchDimensions(4),:) = SignalOn*255;
                end
                if obj.ViewportBorder
                    frame = obj.addViewPortBorder(frame);
                end
                obj.Movies{MovieIndex}.Data(i) = Screen('MakeTexture', obj.Window, frame);
                if SignalOn == 1
                    SignalOn = 0;
                else
                    SignalOn = 1;
                end
            end
            % Add final blank frame
            frame = zeros(obj.WindowDimensions(4)-obj.WindowDimensions(2), obj.WindowDimensions(3)-obj.WindowDimensions(1)); % Use actual window width
            if obj.ViewportBorder
                    frame = obj.addViewPortBorder(frame);
            end
            obj.Movies{MovieIndex}.Data(i+1) = Screen('MakeTexture', obj.Window, frame);
            obj.StimulusType(MovieIndex) = 0;
        end
        function loadText(obj, TextIndex, TextString, varargin)
            obj.TextStrings{TextIndex} = cell(1,1);
            obj.TextStrings{TextIndex}{1} = TextString;
            obj.TextStringStartPos{TextIndex} = [150 150];
            if nargin > 3
                obj.TextStrings{TextIndex}{2} = varargin{1};
            end
            if nargin > 4
                obj.TextStringFontSize(TextIndex) = varargin{2};
            end
            if nargin > 5
                obj.TextStringStartPos{TextIndex} = varargin{3};
            end
            obj.StimulusType(TextIndex) = 1;
        end
        function play(obj, StimulusIndex)
            if StimulusIndex == 0
                Screen('AsyncFlipEnd', obj.Window);
                Screen('DrawTexture', obj.Window, obj.BlankScreen);
                Screen('Flip', obj.Window);
            else
                switch obj.StimulusType(StimulusIndex)
                    case 0 % Play movie
                        if obj.Movies{StimulusIndex}.nFrames == 1
                            if ~isempty(obj.Timer)
                                stop(obj.Timer);
                                delete(obj.Timer);
                                obj.Timer = [];
                            end
                            Screen('AsyncFlipEnd', obj.Window);
                            Screen('DrawTexture', obj.Window, obj.Movies{StimulusIndex}.Data(1));
                            Screen('Flip', obj.Window);
                        else
                            obj.CurrentFrame = 1;
                            obj.StimulusIndex = StimulusIndex;
                            if obj.UseTimer == 1
                                if isempty(obj.Timer)
                                    obj.Timer = timer('TimerFcn',@(x,y)obj.playNextFrame(), 'Period', 0.02,  ...
                                        'ExecutionMode', 'fixedRate');
                                    start(obj.Timer);
                                end
                            else
                                Screen('AsyncFlipEnd', obj.Window);
                                for iFrame = 1:obj.Movies{StimulusIndex}.nFrames
                                    Screen('DrawTexture', obj.Window, obj.Movies{obj.StimulusIndex}.Data(iFrame));
                                    [VBLts, SonsetTime, FlipTimestamp, Missed, BeamPos] = Screen('Flip', obj.Window);
                                end
                            end
                        end
                    case 1 % Display text
                        if ~isempty(obj.Timer)
                            stop(obj.Timer);
                            delete(obj.Timer);
                            obj.Timer = [];
                        end
                        Strings = obj.TextStrings{StimulusIndex};
                        nStrings = length(Strings);
                        Screen('TextFont',obj.Window, 'Arial');
                        Screen('TextSize',obj.Window, obj.TextStringFontSize(StimulusIndex));
                        Screen('TextStyle', obj.Window, 1);
                        Y = obj.TextStringStartPos{StimulusIndex};
                        X = 220-(50*(nStrings-1));
                        Screen('AsyncFlipEnd', obj.Window);
                        Screen('DrawTexture', obj.Window, obj.BlankScreen);
                        for i = 1:nStrings
                            Screen('DrawText', obj.Window, Strings{i}, Y(i), X, [255, 255, 255, 255]); X=X+50;
                        end
                        Screen('AsyncFlipBegin',obj.Window);
                end
            end
        end
        function stop(obj)
            if ~isempty(obj.Timer)
                stop(obj.Timer);
                delete(obj.Timer);
                obj.Timer = [];
            end
            Screen('AsyncFlipEnd', obj.Window);
            Screen('DrawTexture', obj.Window, obj.BlankScreen);
            Screen('Flip', obj.Window);
        end
        function frame = addViewPortBorder(obj, frame)
            frame(1+obj.ViewPortOffset(1):obj.ViewPortOffset(1)+obj.ViewPortDimensions(2), 1+obj.ViewPortOffset(2),:) = 64; % Left
            frame(1+obj.ViewPortOffset(1):obj.ViewPortDimensions(2)+obj.ViewPortOffset(1), obj.ViewPortDimensions(1)+obj.ViewPortOffset(2),:) = 64; % Right
            frame(obj.ViewPortDimensions(2)+obj.ViewPortOffset(1), 1+obj.ViewPortOffset(2):obj.ViewPortDimensions(1)+obj.ViewPortOffset(2),:) = 64; % Bottom
            frame(1+obj.ViewPortOffset(1), 1+obj.ViewPortOffset(2):obj.ViewPortDimensions(1)+obj.ViewPortOffset(2),:) = 64; % Top
        end
        function delete(obj)
            for i = 1:obj.MaxMovies
                if ~isempty(obj.Movies{i})
                    Screen('Close', obj.Movies{i}.Data);
                end
            end
            Screen('CloseAll');
        end
        function playNextFrame(obj, e)
            thisFrame = obj.CurrentFrame;
            Screen('AsyncFlipEnd', obj.Window);
            Screen('DrawTexture', obj.Window, obj.Movies{obj.StimulusIndex}.Data(thisFrame));
            Screen('AsyncFlipBegin', obj.Window);
            nextFrame = thisFrame+1;
            if nextFrame > obj.Movies{obj.StimulusIndex}.nFrames
                stop(obj.Timer);
                delete(obj.Timer);
                obj.Timer = [];
            end
            obj.CurrentFrame = nextFrame;
        end
    end
end