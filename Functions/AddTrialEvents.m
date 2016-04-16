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
function newTE = AddTrialEvents(TE, RawTrialEvents)
global BpodSystem

if isfield(TE, 'RawEvents')
    TrialNum = length(TE.RawEvents.Trial) + 1;
else
    TrialNum = 1;
end
TE.nTrials = TrialNum;
%% Parse and add raw events for this trial
States = RawTrialEvents.States;
nPossibleStates = length(BpodSystem.StateMatrix.StateNames);
VisitedStates = zeros(1,nPossibleStates);
% determine unique states while preserving visited order
UniqueStates = zeros(1,nPossibleStates);
nUniqueStates = 0;
UniqueStateIndexes = zeros(1,length(States));
for x = 1:length(States)
    if sum(UniqueStates == States(x)) == 0
        nUniqueStates = nUniqueStates + 1;
        UniqueStates(nUniqueStates) = States(x);
        VisitedStates(States(x)) = 1;
        UniqueStateIndexes(x) = nUniqueStates;
    else
        UniqueStateIndexes(x) = find(UniqueStates == States(x));
    end
end
UniqueStates = UniqueStates(1:nUniqueStates);
UniqueStateDataMatrices = cell(1,nUniqueStates);
% Create a 2-d matrix for each state in a cell array
for x = 1:length(States)
    UniqueStateDataMatrices{UniqueStateIndexes(x)} = [UniqueStateDataMatrices{UniqueStateIndexes(x)}; [RawTrialEvents.StateTimestamps(x) RawTrialEvents.StateTimestamps(x+1)]];
end
for x = 1:nUniqueStates
    %eval(['TE.RawEvents.Trial{' num2str(TrialNum) '}.States.' BpodSystem.StateMatrix.StateNames{UniqueStates(x)} ' = UniqueStateDataMatrices{x};'])
    TE.RawEvents.Trial{TrialNum}.States.(BpodSystem.StateMatrix.StateNames{UniqueStates(x)}) = UniqueStateDataMatrices{x};
    % Note: Modify this to handle states that recur multiple times
end
for x = 1:nPossibleStates
    if VisitedStates(x) == 0
        %eval(['TE.RawEvents.Trial{' num2str(TrialNum) '}.States.' BpodSystem.StateMatrix.StateNames{x} ' = [NaN NaN];'])
        TE.RawEvents.Trial{TrialNum}.States.(BpodSystem.StateMatrix.StateNames{x}) = [NaN NaN];
    end
end
Events = RawTrialEvents.Events;
for x = 1:length(Events)
    %eval(['TE.RawEvents.Trial{' num2str(TrialNum) '}.Events.' BpodSystem.EventNames{Events(x)} ' = [' num2str(RawTrialEvents.EventTimestamps(Events == Events(x))) '];'])
    TE.RawEvents.Trial{TrialNum}.Events.(BpodSystem.EventNames{Events(x)}) = RawTrialEvents.EventTimestamps(Events == Events(x));
end
TE.RawData.OriginalStateNamesByNumber{TrialNum} = BpodSystem.StateMatrix.StateNames;
TE.RawData.OriginalStateData{TrialNum} = RawTrialEvents.States;
TE.RawData.OriginalEventData{TrialNum} = RawTrialEvents.Events;
TE.RawData.OriginalStateTimestamps{TrialNum} = RawTrialEvents.StateTimestamps;
TE.RawData.OriginalEventTimestamps{TrialNum} = RawTrialEvents.EventTimestamps;
TE.TrialStartTimestamp(TrialNum) = RawTrialEvents.TrialStartTimestamp;
TE.Settings = BpodSystem.ProtocolSettings;
newTE = TE;
