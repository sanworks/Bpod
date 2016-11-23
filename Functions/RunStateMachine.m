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
function RawTrialEvents = RunStateMachine
global BpodSystem
if isempty(BpodSystem.StateMatrix)
    error('Error: A state matrix must be sent prior to calling "RunStateMatrix".')
end
if BpodSystem.BonsaiSocket.Connected == 1
    BonsaiBytesAvailable = BpodSocketServer('bytesAvailable');
    if BonsaiBytesAvailable > 0
        BpodSocketServer('read', BonsaiBytesAvailable);
    end
end
RawTrialEvents = struct;
if BpodSystem.EmulatorMode == 0
    if BpodSystem.SerialPort.bytesAvailable > 0
        trash = BpodSystem.SerialPort.read(BpodSystem.SerialPort.bytesAvailable, 'uint8');
    end
    BpodSystem.SerialPort.write('R', 'uint8'); % Send the code to run the loaded matrix (character "R" for Run)
end
EventNames = BpodSystem.StateMachineInfo.EventNames;
MaxEvents = 10000;
nEvents = 0; nStates = 1;
Events = zeros(1,MaxEvents); States = zeros(1,MaxEvents);
CurrentEvent = zeros(1,10);
StateChangeIndexes = zeros(1,MaxEvents);
States(nStates) = 1;
StateNames = BpodSystem.StateMatrix.StateNames;
BpodSystem.Status.LastStateCode = 0;
BpodSystem.Status.CurrentStateCode = 1;
BpodSystem.Status.LastStateName = 'None';
BpodSystem.Status.CurrentStateName = StateNames{1};
InputMatrix = BpodSystem.StateMatrix.InputMatrix;
GlobalTimerMatrix = BpodSystem.StateMatrix.GlobalTimerMatrix;
GlobalCounterMatrix = BpodSystem.StateMatrix.GlobalCounterMatrix;
ConditionMatrix = BpodSystem.StateMatrix.ConditionMatrix;
StateTimerMatrix = BpodSystem.StateMatrix.StateTimerMatrix;
GlobalTimerOffset = BpodSystem.StateMatrix.meta.InputMatrixSize;
GlobalCounterOffset = GlobalTimerOffset+5;
ConditionOffset = GlobalCounterOffset+5;
JumpOffset = ConditionOffset+5;

nTotalStates = BpodSystem.StateMatrix.nStatesInManifest;
BpodSystem.RefreshGUI; % Reads BpodSystem.HardwareState and BpodSystem.LastEvent to commander GUI.

% Update time display
TimeElapsed = ceil((now*100000) - BpodSystem.ProtocolStartTime);
set(BpodSystem.GUIHandles.TimeDisplay, 'String', Secs2HMS(TimeElapsed));
set(BpodSystem.GUIHandles.RunButton, 'cdata', BpodSystem.GUIData.PauseButton);

BpodSystem.Status.BeingUsed = 1; BpodSystem.Status.InStateMatrix = 1;
if BpodSystem.EmulatorMode == 1
    RunBpodEmulator('init', []);
    BpodSystem.ManualOverrideFlag = 0;
end
SetBpodHardwareMirror2CurrentState(1);
BpodSystem.RefreshGUI;
BpodSystem.Status.InStateMatrix = 1;
while BpodSystem.Status.InStateMatrix
    if BpodSystem.EmulatorMode == 0
        if BpodSystem.SerialPort.bytesAvailable > 0
            NewMessage = 1;
            opCodeBytes = BpodSystem.SerialPort.read(2, 'uint8');
        else
            NewMessage = 0;
        end
    else
        if BpodSystem.BonsaiSocket.Connected == 1
            if BpodSocketServer('bytesAvailable') > 0
                Byte = ReadOscByte;
                OverrideMessage = ['VS' Byte];
                BpodSystem.VirtualManualOverrideBytes = OverrideMessage;
                BpodSystem.ManualOverrideFlag = 1;
            end
        end
        if BpodSystem.ManualOverrideFlag == 1;
            ManualOverrideEvent = VirtualManualOverride(BpodSystem.VirtualManualOverrideBytes);
            BpodSystem.ManualOverrideFlag = 0;
        else
            ManualOverrideEvent = [];
        end
        [NewMessage, opCodeBytes, VirtualCurrentEvents] = RunBpodEmulator('loop', ManualOverrideEvent);
    end
    if NewMessage
        opCode = opCodeBytes(1);
        switch opCode
            case 1 % Receive and handle events
                nCurrentEvents = double(opCodeBytes(2));
                if BpodSystem.EmulatorMode == 0
                    TempCurrentEvents = BpodSystem.SerialPort.read(nCurrentEvents, 'uint8');
                else
                    TempCurrentEvents = VirtualCurrentEvents;
                end
                CurrentEvent(1:nCurrentEvents) = TempCurrentEvents(1:nCurrentEvents) + 1; % Read and convert from c++ index at 0 to MATLAB index at 1
                TransitionEventFound = 0; i = 1;
                NewState = BpodSystem.Status.CurrentStateCode;
                while (TransitionEventFound == 0) && (i <= nCurrentEvents)
                    if CurrentEvent(i) == 255
                        BpodSystem.Status.InStateMatrix = 0;
                        break
                    elseif CurrentEvent(i) < GlobalTimerOffset
                        NewState = InputMatrix(BpodSystem.Status.CurrentStateCode, CurrentEvent(i));
                    elseif CurrentEvent(i) < GlobalCounterOffset
                        NewState = GlobalTimerMatrix(BpodSystem.Status.CurrentStateCode, CurrentEvent(i)-(GlobalTimerOffset-1));
                    elseif CurrentEvent(i) < ConditionOffset
                        NewState = GlobalCounterMatrix(BpodSystem.Status.CurrentStateCode, CurrentEvent(i)-(GlobalCounterOffset-1));
                    elseif CurrentEvent(i) < JumpOffset
                        NewState = ConditionMatrix(BpodSystem.Status.CurrentStateCode, CurrentEvent(i)-(ConditionOffset-1));
                    elseif CurrentEvent(i) == BpodSystem.HW.StateTimerPosition
                        NewState = StateTimerMatrix(BpodSystem.Status.CurrentStateCode);
                    else
                        error(['Error: Unknown event code returned: ' num2str(CurrentEvent(i))]);
                    end
                    if NewState ~= BpodSystem.Status.CurrentStateCode
                        TransitionEventFound = 1;
                    end
                    i = i + 1;
                end
                SetBpodHardwareMirror2ReflectEvent(CurrentEvent);
                if NewState ~= BpodSystem.Status.CurrentStateCode
                    if  NewState <= nTotalStates
                        StateChangeIndexes(nStates) = nEvents+1;
                        nStates = nStates + 1;
                        States(nStates) = NewState;
                        BpodSystem.Status.LastStateCode = BpodSystem.Status.CurrentStateCode;
                        BpodSystem.Status.CurrentStateCode = NewState;
                        BpodSystem.Status.CurrentStateName = StateNames{NewState};
                        BpodSystem.Status.LastStateName = StateNames{BpodSystem.Status.LastStateCode};
                        SetBpodHardwareMirror2CurrentState(NewState);
                        if BpodSystem.EmulatorMode == 1
                            BpodSystem.Emulator.CurrentState = NewState;
                            BpodSystem.Emulator.StateStartTime = BpodSystem.Emulator.CurrentTime;
                            % Set global timer end-time
                            ThisGlobalTimer = BpodSystem.StateMatrix.OutputMatrix(NewState,BpodSystem.HW.Pos.GlobalTimerTrig);
                            if ThisGlobalTimer ~= 0
                                BpodSystem.Emulator.GlobalTimerEnd(ThisGlobalTimer) = BpodSystem.Emulator.CurrentTime + BpodSystem.StateMatrix.GlobalTimers(ThisGlobalTimer);
                                BpodSystem.Emulator.GlobalTimersActive(ThisGlobalTimer) = 1;
                            end
                            % Cancel global timers
                            ThisGlobalTimer = BpodSystem.StateMatrix.OutputMatrix(NewState,BpodSystem.HW.Pos.GlobalTimerCancel);
                            if ThisGlobalTimer ~= 0
                                BpodSystem.Emulator.GlobalTimersActive(ThisGlobalTimer) = 0;
                            end
                            % Reset global counter counts
                            ThisGlobalCounter = BpodSystem.StateMatrix.OutputMatrix(NewState,BpodSystem.HW.Pos.GlobalCounterReset);
                            if ThisGlobalCounter ~= 0
                                BpodSystem.Emulator.GlobalCounterCounts(ThisGlobalCounter) = 0;
                            end
                            % Update soft code
                            BpodSystem.Emulator.SoftCode = BpodSystem.StateMatrix.OutputMatrix(NewState,BpodSystem.HW.Pos.Output_USB);
                        end
                    else
                        if BpodSystem.EmulatorMode == 1
                            StateChangeIndexes(nStates) = nEvents+1;
                            Events(nEvents+1:(nEvents+nCurrentEvents)) = CurrentEvent(1:nCurrentEvents);
                            nEvents = nEvents + nCurrentEvents;
                            break
                        end
                    end
                end
                if BpodSystem.Status.InStateMatrix == 1
                    BpodSystem.RefreshGUI;
                    Events(nEvents+1:(nEvents+nCurrentEvents)) = CurrentEvent(1:nCurrentEvents);
                    BpodSystem.Status.LastEvent = CurrentEvent(1);
                    CurrentEvent(1:nCurrentEvents) = 0;
                    set(BpodSystem.GUIHandles.LastEventDisplay, 'string', EventNames{BpodSystem.Status.LastEvent});
                    nEvents = nEvents + uint16(nCurrentEvents);
                end
            case 2 % Soft-code
                SoftCode = opCodeBytes(2);
                HandleSoftCode(SoftCode);
            otherwise
                disp('Error: Invalid op code received')
        end
    else
        if BpodSystem.EmulatorMode == 0
            if BpodSystem.BonsaiSocket.Connected == 1
                if BpodSocketServer('bytesAvailable') > 0
                    Byte = ReadOscByte;
                    OverrideMessage = ['VS' Byte];
                    BpodSystem.SerialPort.write(OverrideMessage, 'uint8');
                end
            end
        end
        %pause(0.0001);
        drawnow;
    end
end

if BpodSystem.Status.BeingUsed == 1
    Events = Events(1:nEvents);
    States = States(1:nStates);
    % Accept Timestamps
    if BpodSystem.EmulatorMode == 0
        TrialStartTimestamp =  double(BpodSystem.SerialPort.read(1, 'uint32'))/1000; % Start-time of the trial in milliseconds (immune to 32-bit clock rollover)
        TrialStartMicroseconds = double(BpodSystem.SerialPort.read(1, 'uint32')); % Time the trial started (in microseconds)
        TrialStartMilliseconds = TrialStartMicroseconds/1000;
        nTimeStamps = double(BpodSystem.SerialPort.read(1, 'uint16'));
        TimeStamps = double(BpodSystem.SerialPort.read(nTimeStamps, 'uint32'));
        TimeScaleFactor = (BpodSystem.HW.CyclePeriod/1000);
        TimeStamps = TimeStamps*TimeScaleFactor;
    else
        TrialStartTimestamp = BpodSystem.Emulator.MatrixStartTime-(BpodSystem.Status.BpodStartTime*100000);
        TrialStartMilliseconds = TrialStartTimestamp*1000;
        TimeStamps = (BpodSystem.Emulator.Timestamps(1:BpodSystem.Emulator.nEvents)*1000) + TrialStartMilliseconds;
    end
    StateChangeIndexes = StateChangeIndexes(1:nStates-1);
    EventTimeStamps = TimeStamps;
    StateTimeStamps = zeros(1,nStates);
    StateTimeStamps(2:nStates) = TimeStamps(StateChangeIndexes); % Figure out StateChangeIndexes has a "change" event for sma start (longer than nEvents)
    StateTimeStamps(1) = TrialStartMilliseconds;
    RawTrialEvents.States = States;
    RawTrialEvents.Events = Events;
    RawTrialEvents.StateTimestamps = Round2Millis(StateTimeStamps-TrialStartMilliseconds)/1000; % Convert to seconds
    RawTrialEvents.EventTimestamps = Round2Millis(EventTimeStamps-TrialStartMilliseconds)/1000;
    RawTrialEvents.TrialStartTimestamp = Round2Millis(TrialStartTimestamp);
    RawTrialEvents.StateTimestamps(end+1) = RawTrialEvents.EventTimestamps(end);
end
SetBpodHardwareMirror2CurrentState(0);
BpodSystem.Status.InStateMatrix = 0;

function MilliOutput = Round2Millis(DecimalInput)
MilliOutput = round(DecimalInput*(1000))/(1000);

function SetBpodHardwareMirror2CurrentState(CurrentState)
global BpodSystem
if CurrentState > 0
    BpodSystem.HardwareState.OutputState = BpodSystem.StateMatrix.OutputMatrix(CurrentState,:);
else
    BpodSystem.HardwareState.InputState(1:end) = 0;
    BpodSystem.HardwareState.OutputState(1:end) = 0;
    BpodSystem.RefreshGUI;
end

function SetBpodHardwareMirror2ReflectEvent(Events)
global BpodSystem
nEvents = sum(Events ~= 0);
for i = 1:nEvents
    thisEvent = Events(i);
    if thisEvent ~= 255
        if BpodSystem.HW.EventTypes(thisEvent) == 'I'
            p = ((thisEvent-BpodSystem.HW.IOEventStartposition)/2)+BpodSystem.HW.n.SerialChannels+1;
            thisChannel = floor(p);
            isOdd = rem(p,1);
            if isOdd == 0
                BpodSystem.HardwareState.InputState(thisChannel) = 1;
            else
                BpodSystem.HardwareState.InputState(thisChannel) = 0;
            end
        end
    end
end

function TimeString = Secs2HMS(Seconds)
H = floor(Seconds/3600); 
Seconds = Seconds-(H*3600);
M = floor(Seconds/60); 
S = Seconds - (M*60);
if M < 10
    MPad = '0';
else 
    MPad = '';
end
if S < 10
    SPad = '0';
else 
    SPad = '';
end
TimeString = [num2str(H) ':' MPad num2str(M) ':' SPad num2str(S)];

function HandleSoftCode(SoftCode)
global BpodSystem
eval([BpodSystem.SoftCodeHandlerFunction '(' num2str(SoftCode) ')'])

function ManualOverrideEvent = VirtualManualOverride(OverrideMessage)
% Converts the byte code transmission formatted for the state machine into event codes
global BpodSystem
OpCode = OverrideMessage(1);
if OpCode == 'V'
    InputChannel = OverrideMessage(2)+1;
    EventType = BpodSystem.HardwareState.InputType(InputChannel);
    if ~strcmp(EventType, {'U','X'})
        NewChannelState = BpodSystem.HardwareState.InputState(InputChannel);
        ManualOverrideEvent = BpodSystem.HW.Pos.Event_BNC-1 + 2*(InputChannel-BpodSystem.HW.Pos.Output_USB)-1 + (1-NewChannelState);
    else
        switch EventType
            case 'U'
                ManualOverrideEvent = [];
            case 'X'
                ManualOverrideEvent = [];
        end
    end
elseif OpCode == 'S'
    HandleSoftCode(uint8(OverrideMessage(2)));
    ManualOverrideEvent = [];
else
    ManualOverrideEvent = [];
end