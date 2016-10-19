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
    % Check for font
    F = listfonts;
    if (sum(strcmp(F, 'OCRAStd')) == 0) && (sum(strcmp(F, 'OCR A Std')) == 0)
        disp('ALERT! Bpod needs to install a system font in order to continue.')
        input('Press enter to install the font...');
        try
            system(fullfile(BpodPath, 'Media', 'Fonts', 'OCRASTD.otf'));
            error('After installing the font, please restart Bpod.')
        catch
            error('Bpod was unable to install the font. Please install it manually from /Bpod/Media/Fonts/OCRASTD')
        end
    end
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
    BpodSystem.FirmwareBuild = 8;
end
if BpodSystem.FirmwareBuild < 8 % Bpod 0.5
    BpodSystem.MaxStates = 128;
    BpodSystem.EventNames = {'Port1In', 'Port1Out', 'Port2In', 'Port2Out', 'Port3In', 'Port3Out', 'Port4In', 'Port4Out', 'Port5In', 'Port5Out', ...
        'Port6In', 'Port6Out', 'Port7In', 'Port7Out', 'Port8In', 'Port8Out', 'BNC1High', 'BNC1Low', 'BNC2High', 'BNC2Low', ...
        'Wire1High', 'Wire1Low', 'Wire2High', 'Wire2Low', 'Wire3High', 'Wire3Low', 'Wire4High', 'Wire4Low', ...
        'SoftCode1', 'SoftCode2', 'SoftCode3', 'SoftCode4', 'SoftCode5', 'SoftCode6', 'SoftCode7', 'SoftCode8', 'SoftCode9', 'SoftCode10', ...
        'Unused', 'Tup', 'GlobalTimer1_End', 'GlobalTimer2_End', 'GlobalTimer3_End', 'GlobalTimer4_End', 'GlobalTimer5_End', ...
        'GlobalCounter1_End', 'GlobalCounter2_End', 'GlobalCounter3_End', 'GlobalCounter4_End', 'GlobalCounter5_End'};
    BpodSystem.OutputActionNames = {'ValveState', 'BNCState', 'WireState', 'Serial1Write', 'Serial2Write', 'SoftCode', ...
        'GlobalTimerTrig', 'GlobalTimerCancel', 'GlobalCounterReset', 'PWM1', 'PWM2', 'PWM3', 'PWM4', 'PWM5', 'PWM6', 'PWM7', 'PWM8'};
    BpodSystem.OutputPos.SoftCode = 6;
    BpodSystem.OutputPos.GlobalTimerTrig = 7;
    BpodSystem.OutputPos.GlobalTimerCancel = 8;
    BpodSystem.OutputPos.GlobalCounterReset = 9;
    BpodSystem.OutputPos.PWM = 10;
else % Bpod 0.7
    if BpodSystem.EmulatorMode == 0
        BpodSerialWrite(['K' BpodSystem.SyncConfig.Channel BpodSystem.SyncConfig.SignalType], 'uint8');
    end
    BpodSystem.MaxStates = 256;
    BpodSystem.EventNames = {'Port1In', 'Port1Out', 'Port2In', 'Port2Out', 'Port3In', 'Port3Out', 'Port4In', 'Port4Out', 'Port5In', 'Port5Out', ...
        'Port6In', 'Port6Out', 'Port7In', 'Port7Out', 'Port8In', 'Port8Out',...
        'BNC1High', 'BNC1Low', 'BNC2High', 'BNC2Low', ...
        'Wire1High', 'Wire1Low', 'Wire2High', 'Wire2Low', ...
        'SoftJump', 'Serial1Jump', 'Serial2Jump', 'Serial3Jump', 'Tup', ...
        'SoftCode1', 'SoftCode2', 'SoftCode3', 'SoftCode4', 'SoftCode5', 'SoftCode6', 'SoftCode7', 'SoftCode8', 'SoftCode9', 'SoftCode10' ...
        'Serial1_1', 'Serial1_2', 'Serial1_3', 'Serial1_4', 'Serial1_5', 'Serial1_6', 'Serial1_7', 'Serial1_8', 'Serial1_9', 'Serial1_10' ...
        'Serial2_1', 'Serial2_2', 'Serial2_3', 'Serial2_4', 'Serial2_5', 'Serial2_6', 'Serial2_7', 'Serial2_8', 'Serial2_9', 'Serial2_10' ...
        'Serial3_1', 'Serial3_2', 'Serial3_3', 'Serial3_4', 'Serial3_5', 'Serial3_6', 'Serial3_7', 'Serial3_8', 'Serial3_9', 'Serial3_10' ...
        'GlobalTimer1_End', 'GlobalTimer2_End', 'GlobalTimer3_End', 'GlobalTimer4_End', 'GlobalTimer5_End', ...
        'GlobalCounter1_End', 'GlobalCounter2_End', 'GlobalCounter3_End', 'GlobalCounter4_End', 'GlobalCounter5_End'...
        'Condition1', 'Condition2', 'Condition3', 'Condition4', 'Condition5', ...
        };
    BpodSystem.OutputPos.SoftCode = 7;
    BpodSystem.OutputPos.GlobalTimerTrig = 8;
    BpodSystem.OutputPos.GlobalTimerCancel = 9;
    BpodSystem.OutputPos.GlobalCounterReset = 10;
    BpodSystem.OutputPos.PWM = 11;
    BpodSystem.ChannelNames = {'Port1', 'Port2', 'Port3', 'Port4', 'Port5', 'Port6', 'Port7', 'Port8',...
        'BNC1', 'BNC2', 'Wire1', 'Wire2'};
    BpodSystem.OutputActionNames = {'ValveState', 'BNCState', 'WireState', 'Serial1Write', 'Serial2Write', 'Serial3Write', 'SoftCode', ...
        'GlobalTimerTrig', 'GlobalTimerCancel', 'GlobalCounterReset', 'PWM1', 'PWM2', 'PWM3', 'PWM4', 'PWM5', 'PWM6', 'PWM7', 'PWM8'};
end
BpodSystem.nEvents = length(BpodSystem.EventNames);
BpodSystem.nOutputActions = length(BpodSystem.OutputActionNames);
sma.nStates = 0;
sma.nStatesInManifest = 0;
sma.Manifest = cell(1,BpodSystem.MaxStates); % State names in the order they were added by user
sma.StateNames = {'Placeholder'}; % State names in the order they were referenced
if BpodSystem.FirmwareBuild < 8 % Bpod 0.5
    sma.InputMatrix = ones(1,BpodSystem.nEvents-10);
    sma.OutputMatrix = zeros(1,BpodSystem.nOutputActions);
else
    sma.InputMatrix = ones(1,BpodSystem.nEvents-15);
    sma.OutputMatrix = zeros(1,BpodSystem.nOutputActions);
    sma.ConditionMatrix = zeros(1,5);
    sma.ConditionChannels = zeros(1,5);
    sma.ConditionValues = zeros(1,5);
    sma.ConditionSet = zeros(1,5);
end
sma.GlobalTimerMatrix = ones(1,5);
sma.GlobalTimers = zeros(1,5);
sma.GlobalTimerSet = zeros(1,5); % Changed to 1 when the timer is given a duration with SetGlobalTimer
sma.GlobalCounterMatrix = ones(1,5);
sma.GlobalCounterEvents = ones(1,5)*255; % Default event of 255 is code for "no event attached".
sma.GlobalCounterThresholds = zeros(1,5);
sma.GlobalCounterSet = zeros(1,5); % Changed to 1 when the counter event is identified and given a threshold with SetGlobalCounter
sma.StateTimers = 0;
sma.StatesDefined = 1; % Referenced states are set to 0. Defined states are set to 1. Both occur with AddState
BpodSystem.BlankStateMatrix = sma;
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