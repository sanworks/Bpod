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
function Confirmed = SendStateMatrix(sma)
global BpodSystem
nStates = length(sma.StateNames);
%% Check to make sure the Placeholder state was replaced
if strcmp(sma.StateNames{1},'Placeholder')
    error('Error: could not send an empty matrix. You must define at least one state first.')
end

%% Check to make sure the State Matrix doesn't have undefined states
if sum(sma.StatesDefined == 0) > 0
    disp('Error: The state matrix contains references to the following undefined states: ');
    UndefinedStates = find(sma.StatesDefined == 0);
    nUndefinedStates = length(UndefinedStates);
    for x = 1:nUndefinedStates
        disp(sma.StateNames{UndefinedStates(x)});
    end
    error('Please define these states using the AddState function before sending.')
end

%% Check to make sure the state matrix does not exceed the maximum number of states
if nStates > BpodSystem.MaxStates
    error(['Error: the state matrix can have a maximum of ' num2str(BpodSystem.MaxStates) ' states.'])
end

%% Rearrange states to reflect order they were added (not referenced)
sma.Manifest = sma.Manifest(1:sma.nStatesInManifest);
StateOrder = zeros(1,sma.nStatesInManifest);
OriginalInputMatrix = sma.InputMatrix;
OriginalTimerMatrix = sma.GlobalTimerMatrix;
OriginalCounterMatrix = sma.GlobalCounterMatrix;
if BpodSystem.FirmwareBuild > 7
    OriginalConditionMatrix = sma.ConditionMatrix;
end
for i = 1:sma.nStatesInManifest
    StateOrder(i) = find(strcmp(sma.StateNames, sma.Manifest{i}));
    sma.InputMatrix(OriginalInputMatrix==StateOrder(i)) = i;
    sma.GlobalTimerMatrix(OriginalTimerMatrix==StateOrder(i)) = i;
    sma.GlobalCounterMatrix(OriginalCounterMatrix==StateOrder(i)) = i;
end
if BpodSystem.FirmwareBuild > 7
    for i = 1:sma.nStatesInManifest
        sma.ConditionMatrix(OriginalConditionMatrix==StateOrder(i)) = i;
    end
end
sma.InputMatrix = sma.InputMatrix(StateOrder,:);
sma.OutputMatrix = sma.OutputMatrix(StateOrder,:);
sma.GlobalTimerMatrix = sma.GlobalTimerMatrix(StateOrder,:);
sma.GlobalCounterMatrix = sma.GlobalCounterMatrix(StateOrder,:);
if BpodSystem.FirmwareBuild > 7
    sma.ConditionMatrix = sma.ConditionMatrix(StateOrder,:);
end
sma.StateNames = sma.StateNames(StateOrder);
sma.StateTimers = sma.StateTimers(StateOrder);

%% Add exit state codes to transition matrices
sma.InputMatrix(isnan(sma.InputMatrix)) = nStates+1;
sma.GlobalTimerMatrix(isnan(sma.GlobalTimerMatrix)) = nStates+1;
sma.GlobalCounterMatrix(isnan(sma.GlobalCounterMatrix)) = nStates+1;
if BpodSystem.FirmwareBuild > 7
    sma.ConditionMatrix(isnan(sma.ConditionMatrix)) = nStates+1;
end
%% Format input, output and wave matrices into linear byte vectors for transfer
DefaultInputMatrix = repmat((1:nStates)', 1, 69);
DefaultExtensionMatrix = DefaultInputMatrix(1:nStates, 1:5);
DifferenceMatrix = (sma.InputMatrix ~= DefaultInputMatrix)';
nDifferences = sum(DifferenceMatrix);
msgLength = sum(nDifferences>0)*2 + nStates;
InputMatrix = zeros(1,msgLength); Pos = 1;
for i = 1:nStates
    ThisState = DifferenceMatrix(:,i)';
    InputMatrix(Pos) = nDifferences(i); Pos = Pos + 1;
    if nDifferences(i) > 0
        Positions = find(ThisState)-1;
        Values = sma.InputMatrix(i,ThisState)-1;
        PosVal = [Positions; Values];
        PosVal = PosVal(1:end);
        InputMatrix(Pos:Pos+(nDifferences(i)*2)-1) = PosVal;
        Pos = Pos + nDifferences(i)*2;
    end
end
InputMatrix = uint8(InputMatrix);

DifferenceMatrix = (sma.OutputMatrix ~= 0)';
nDifferences = sum(DifferenceMatrix);
msgLength = sum(nDifferences>0)*2 + nStates;
OutputMatrix = zeros(1,msgLength); Pos = 1;
for i = 1:nStates
    ThisState = DifferenceMatrix(:,i)';
    OutputMatrix(Pos) = nDifferences(i); Pos = Pos + 1;
    if nDifferences(i) > 0
        Positions = find(ThisState)-1;
        Values = sma.OutputMatrix(i,ThisState);
        PosVal = [Positions; Values];
        PosVal = PosVal(1:end);
        OutputMatrix(Pos:Pos+(nDifferences(i)*2)-1) = PosVal;
        Pos = Pos + nDifferences(i)*2;
    end
end
OutputMatrix = uint8(OutputMatrix);

DifferenceMatrix = (sma.GlobalTimerMatrix ~= DefaultExtensionMatrix)';
nDifferences = sum(DifferenceMatrix);
msgLength = sum(nDifferences>0)*2 + nStates;
GlobalTimerMatrix = zeros(1,msgLength); Pos = 1;
for i = 1:nStates
    ThisState = DifferenceMatrix(:,i)';
    GlobalTimerMatrix(Pos) = nDifferences(i); Pos = Pos + 1;
    if nDifferences(i) > 0
        Positions = find(ThisState)-1;
        Values = sma.GlobalTimerMatrix(i,ThisState)-1;
        PosVal = [Positions; Values];
        PosVal = PosVal(1:end);
        GlobalTimerMatrix(Pos:Pos+(nDifferences(i)*2)-1) = PosVal;
        Pos = Pos + nDifferences(i)*2;
    end
end
GlobalTimerMatrix = uint8(GlobalTimerMatrix);

DifferenceMatrix = (sma.GlobalCounterMatrix ~= DefaultExtensionMatrix)';
nDifferences = sum(DifferenceMatrix);
msgLength = sum(nDifferences>0)*2 + nStates;
GlobalCounterMatrix = zeros(1,msgLength); Pos = 1;
for i = 1:nStates
    ThisState = DifferenceMatrix(:,i)';
    GlobalCounterMatrix(Pos) = nDifferences(i); Pos = Pos + 1;
    if nDifferences(i) > 0
        Positions = find(ThisState)-1;
        Values = sma.GlobalCounterMatrix(i,ThisState)-1;
        PosVal = [Positions; Values];
        PosVal = PosVal(1:end);
        GlobalCounterMatrix(Pos:Pos+(nDifferences(i)*2)-1) = PosVal;
        Pos = Pos + nDifferences(i)*2;
    end
end
GlobalCounterMatrix = uint8(GlobalCounterMatrix);

if BpodSystem.FirmwareBuild > 7
    DifferenceMatrix = (sma.ConditionMatrix ~= DefaultExtensionMatrix)';
    nDifferences = sum(DifferenceMatrix);
    msgLength = sum(nDifferences>0)*2 + nStates;
    ConditionMatrix = zeros(1,msgLength); Pos = 1;
    for i = 1:nStates
        ThisState = DifferenceMatrix(:,i)';
        ConditionMatrix(Pos) = nDifferences(i); Pos = Pos + 1;
        if nDifferences(i) > 0
            Positions = find(ThisState)-1;
            Values = sma.ConditionMatrix(i,ThisState)-1;
            PosVal = [Positions; Values];
            PosVal = PosVal(1:end);
            ConditionMatrix(Pos:Pos+(nDifferences(i)*2)-1) = PosVal;
            Pos = Pos + nDifferences(i)*2;
        end
    end
    ConditionMatrix = uint8(ConditionMatrix);
end

if BpodSystem.FirmwareBuild > 7
    ConditionChannels = uint8(sma.ConditionChannels-1);
    ConditionValues = uint8(sma.ConditionValues);
end
GlobalCounterAttachedEvents = uint8(sma.GlobalCounterEvents-1);
GlobalCounterThresholds = uint32(sma.GlobalCounterThresholds);


%% Format timers (doubles in seconds) into 32 bit int vectors in milliseconds
if BpodSystem.FirmwareBuild < 6
    TimeScaleFactor = 1000000;
else
    TimeScaleFactor = 10000;
end
StateTimers = uint32(sma.StateTimers*TimeScaleFactor);
GlobalTimers = uint32(sma.GlobalTimers*TimeScaleFactor);

%% Add input channel configuration
if BpodSystem.FirmwareBuild > 7
    InputChannelConfig = [BpodSystem.InputsEnabled.PortsEnabled];
else
    InputChannelConfig = [BpodSystem.InputsEnabled.PortsEnabled BpodSystem.InputsEnabled.WiresEnabled(1:4)];
end
%% Create vectors of 8-bit and 32-bit data
if BpodSystem.FirmwareBuild > 7
    EightBitMatrix = ['C' nStates InputMatrix OutputMatrix GlobalTimerMatrix GlobalCounterMatrix ConditionMatrix GlobalCounterAttachedEvents ConditionChannels ConditionValues InputChannelConfig];
else
    EightBitMatrix = ['C' nStates InputMatrix OutputMatrix GlobalTimerMatrix GlobalCounterMatrix GlobalCounterAttachedEvents InputChannelConfig];
end
ThirtyTwoBitMatrix = [StateTimers GlobalTimers GlobalCounterThresholds];

if BpodSystem.EmulatorMode == 0
    %% Send state matrix to Bpod device
    ByteString = [EightBitMatrix typecast(ThirtyTwoBitMatrix, 'uint8')];
    BpodSerialWrite(ByteString, 'uint8');
    
    %% Recieve Acknowledgement
    Confirmed = BpodSerialRead(1, 'uint8'); % Confirm that it has been received
    if isempty(Confirmed)
        Confirmed = 0;
    end
else
    Confirmed = 1;
end
%% Update State Machine Object
BpodSystem.StateMatrix = sma;
set(BpodSystem.GUIHandles.CxnDisplay, 'String', 'Idle');