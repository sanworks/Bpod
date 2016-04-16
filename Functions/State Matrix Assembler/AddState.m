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
function sma_out = AddState(sma, namestr, StateName, timerstr, StateTimer, conditionstr, StateChangeConditions, outputstr, OutputActions)
% Adds a state to an existing state matrix.
%
% Example:
%
%  sma = AddState(sma, ...
%  'Name', 'Deliver_Stimulus', ...
%  'Timer', .001,...
%  'StateChangeConditions', {'Port2Out', 'WaitForResponse', 'Tup', 'ITI'},...
%  'OutputActions', {'LEDState', 1, 'WireState', 3, 'SerialCode', 3});

global BpodSystem
% Sanity check state name
if strcmpi(StateName, 'exit')
    error('Error: The exit state is added automatically when sending a matrix. Do not add it explicitly.')
end

%% Check whether the new state has already been referenced. Add new blank state to matrix
nStates = length(sma.StatesDefined);
nStatesInManifest = sma.nStatesInManifest;
StateNumber = find(strcmp(StateName, sma.StateNames));
CurrentStateInManifest = nStatesInManifest + 1;
if sum(sma.StatesDefined) == 128
    error('Error: the state matrix can have a maximum of 128 states.')
end
if strcmp(sma.StateNames{1},'Placeholder')
    CurrentState = 1;
else
    if isempty(StateNumber) % This state has not been referenced previously
        CurrentState = nStates+1;
    else % This state was already referenced
        if sma.StatesDefined(StateNumber) == 0
            CurrentState = StateNumber;
        else
            error(['The state "' StateName '" has already been defined. Edit existing states with the EditState function.'])
        end
    end
end
sma.StateNames{CurrentState} = StateName;
sma.Manifest{CurrentStateInManifest} = StateName;
sma.nStatesInManifest = sma.nStatesInManifest + 1;
sma.InputMatrix(CurrentState,:) = ones(1,40)*CurrentState; % Hard-coded matrix sizes (for efficiency) should be adjusted if changing state matrix composition
sma.OutputMatrix(CurrentState,:) = zeros(1,17);
sma.GlobalTimerMatrix(CurrentState,:) = ones(1,5)*CurrentState;
sma.GlobalCounterMatrix(CurrentState,:) = ones(1,5)*CurrentState;
sma.StateTimers(CurrentState) = StateTimer;
sma.StatesDefined(CurrentState) = 1;

%% Make sure all the states in "StateChangeConditions" exist, and if not, create them as undefined states.
for x = 2:2:length(StateChangeConditions)
    ThisStateName = StateChangeConditions{x};
    if ~strcmpi(ThisStateName,'exit')
        isThere = sum(strcmp(ThisStateName, sma.StateNames)) > 0;
        if isThere == 0
            NewStateNumber = length(sma.StateNames)+1;
            sma.StateNames(NewStateNumber) = StateChangeConditions(x);
            sma.StatesDefined(NewStateNumber) = 0;
        end
    end
end
%% Add state transitions
EventNames = BpodSystem.EventNames;
for x = 1:2:length(StateChangeConditions)
    CandidateEventCode = find(strcmp(StateChangeConditions{x},EventNames));
    TargetState = StateChangeConditions{x+1};
    if ~strcmpi(TargetState, 'exit')
        TargetStateNumber = find(strcmp(StateChangeConditions{x+1},sma.StateNames));
    else
        TargetStateNumber = NaN;
    end
    if ~isempty(CandidateEventCode)
    if CandidateEventCode > 40
        CandidateEventName = StateChangeConditions{x};
        if length(CandidateEventName) > 4
            if sum(lower(CandidateEventName(length(CandidateEventName)-3:length(CandidateEventName))) == '_end') == 4
                if CandidateEventCode < 46
                    % This is a transition for a global timer. Add to global timer matrix.
                    GlobalTimerNumber = str2double(CandidateEventName(length(CandidateEventName) - 4));
                    if ~isnan(GlobalTimerNumber)
                        sma.GlobalTimerMatrix(CurrentState, GlobalTimerNumber) = TargetStateNumber;
                    else
                        EventSpellingErrorMessage(ThisStateName);
                    end
                else
                    % This is a transition for a global counter. Add to global counter matrix.
                    GlobalCounterNumber = str2double(CandidateEventName(length(CandidateEventName) - 4));
                    if ~isnan(GlobalCounterNumber)
                        sma.GlobalCounterMatrix(CurrentState, GlobalCounterNumber) = TargetStateNumber;
                    else
                        EventSpellingErrorMessage(ThisStateName);
                    end
                end
            else
                EventSpellingErrorMessage(ThisStateName);
            end
        else
            EventSpellingErrorMessage(ThisStateName);
        end
    else
        sma.InputMatrix(CurrentState,CandidateEventCode) = TargetStateNumber;
    end
    else
         EventSpellingErrorMessage(ThisStateName);
    end
end

%% Add output actions
OutputActionNames = BpodSystem.OutputActionNames;
MetaActions = {'Valve', 'LED', 'LEDState'}; % Valve is an alternate syntax for "ValveState", specifying one valve to open (1-8)
                                % LED is an alternate syntax for PWM1-8,specifying one LED to set to max brightness (1-8)
                                % LEDState is an alternate syntax for PWM1-8. A byte coding for binary sets which LEDs are at max brightness
for x = 1:2:length(OutputActions)
    MetaAction = find(strcmp(OutputActions{x}, MetaActions));
    if ~isempty(MetaAction)
        Value = OutputActions{x+1};
        switch MetaAction
            case 1
                Value = 2^(Value-1);
                sma.OutputMatrix(CurrentState,1) = Value;
            case 2
                sma.OutputMatrix(CurrentState,9+Value) = 255;
            case 3
                
        end
    else
        TargetEventCode = find(strcmp(OutputActions{x}, OutputActionNames));
        if ~isempty(TargetEventCode)
            Value = OutputActions{x+1};
            sma.OutputMatrix(CurrentState,TargetEventCode) = Value;
        else
            error(['Check spelling of your output actions for state: ' StateName '.']);
        end
    end
    
end

%% Add self timer
sma.StateTimers(CurrentState) = StateTimer;

%% Return state matrix
sma_out = sma;

%%%%%%%%%%%%%% End Main Code. Functions below. %%%%%%%%%%%%%%
    
function EventSpellingErrorMessage(ThisStateName)
        error(['Check spelling of your state transition events for state: ' ThisStateName '. Valid events (% is an index): Port%In Port%Out BNC%High BNC%Low Wire%High Wire%Low SoftCode% GlobalTimer%End Tup'])