%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2016 Sanworks LLC, Sound Beach, New York, USA

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
function Bpod(varargin)

BpodPath = fileparts(which('Bpod'));
addpath(genpath(fullfile(BpodPath, 'Functions')));
addpath(genpath(fullfile(BpodPath, 'Media')));
try
    evalin('base', 'BpodSystem;');
    BpodErrorSound;
    disp('Bpod is already open.');
catch
    warning off
    global BpodSystem
    if exist('rng','file') == 2
        rng('shuffle', 'twister'); % Seed the random number generator by CPU clock
    else
        rand('twister', sum(100*fliplr(clock))); % For older versions of MATLAB
    end
    BpodSystem = BpodObject(BpodPath);
    BpodSplashScreen(1);
        
    % Try to find hardware. If none, prompt to run emulation mode.
    try
        if nargin > 0
            if strcmp(varargin{1}, 'EMU')
                EmulatorDialog;
            else
                BpodSystem.InitializeHardware(varargin{1});
                SetupBpod;
            end
        else
            BpodSystem.InitializeHardware('AUTO');
            SetupBpod;
        end
    catch
        EmulatorDialog;
    end
    
end

function SetupBpod(hObject,event)
global BpodSystem
if BpodSystem.EmulatorMode == 1
    close(BpodSystem.GUIHandles.LaunchEmuFig);
    disp('Connection aborted. Bpod started in Emulator mode.')
end
BpodSplashScreen(2);
BpodSplashScreen(3);
if isfield(BpodSystem.SystemSettings, 'BonsaiAutoConnect')
    if BpodSystem.SystemSettings.BonsaiAutoConnect == 1
        try
            disp('Attempting to connect to Bonsai. Timeout in 10 seconds...')
            BpodSocketServer('connect', 11235);
            BpodSystem.BonsaiSocket.Connected = 1;
            disp('Connected to Bonsai on port: 11235')
        catch
            BpodErrorSound;
            disp('Warning: Auto-connect to Bonsai failed. Please connect manually.')
        end
    end
end
BpodSplashScreen(4);
BpodSplashScreen(5);
close(BpodSystem.GUIHandles.SplashFig);
BpodSystem.InitializeGUI();
evalin('base', 'global BpodSystem')

function CloseBpodHWNotFound(hObject,event)
global BpodSystem
lasterr
close(BpodSystem.GUIHandles.LaunchEmuFig);
close(BpodSystem.GUIHandles.SplashFig);
delete(BpodSystem)
disp('Error: Bpod device not found.')

function EmulatorDialog
global BpodSystem
BpodErrorSound;
BpodSystem.GUIHandles.LaunchEmuFig = figure('Position',[500 350 300 125],'name','ERROR','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
ha = axes('units','normalized', 'position',[0 0 1 1]);
uistack(ha,'bottom'); BG = imread('DeviceNotFound.bmp'); image(BG); axis off;
BpodSystem.Graphics.CloseBpodButton = imread('CloseBpod.bmp');
BpodSystem.Graphics.LaunchEMUButton = imread('StartInEmuMode.bmp');
BpodSystem.GUIHandles.LaunchEmuModeButton = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [15 55 277 32], 'Callback', @SetupBpod, 'CData', BpodSystem.Graphics.LaunchEMUButton, 'TooltipString', 'Start Bpod in emulation mode');
BpodSystem.GUIHandles.CloseBpodButton = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [15 15 277 32], 'Callback', @CloseBpodHWNotFound, 'CData', BpodSystem.Graphics.CloseBpodButton,'TooltipString', 'Close Bpod');
BpodSystem.EmulatorMode = 1;