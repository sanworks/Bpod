%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

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
function [NewMessage OpCodeBytes VirtualCurrentEvents] = RunBpodEmulator(Op, ManualOverrideEvent)
global BpodSystem
VirtualCurrentEvents = zeros(1,10);
switch Op
    case 'init'
        BpodSystem.Emulator.nEvents = 0;
        BpodSystem.Emulator.CurrentState = 1;
        BpodSystem.Emulator.GlobalTimerEnd = zeros(1,5);
        BpodSystem.Emulator.GlobalTimersActive = zeros(1,5);
        BpodSystem.Emulator.GlobalCounterCounts = zeros(1,5);
        BpodSystem.Emulator.Timestamps = zeros(1,10000);
        BpodSystem.Emulator.MeaningfulTimer = (BpodSystem.StateMatrix.InputMatrix(:,40)' ~= 1:length(BpodSystem.StateMatrix.StatesDefined));
        BpodSystem.Emulator.CurrentTime = now*100000;
        BpodSystem.Emulator.MatrixStartTime = BpodSystem.Emulator.CurrentTime;
        BpodSystem.Emulator.StateStartTime = BpodSystem.Emulator.CurrentTime;
        BpodSystem.Emulator.SoftCode = BpodSystem.StateMatrix.OutputMatrix(1,6);
        % Set global timer end-time (if triggered in first state)
        ThisGlobalTimer = BpodSystem.StateMatrix.OutputMatrix(BpodSystem.Emulator.CurrentState,7);
        if ThisGlobalTimer ~= 0
            BpodSystem.Emulator.GlobalTimerEnd(ThisGlobalTimer) = BpodSystem.Emulator.CurrentTime + BpodSystem.StateMatrix.GlobalTimers(ThisGlobalTimer);
            BpodSystem.Emulator.GlobalTimersActive(ThisGlobalTimer) = 1;
        end
    case 'loop'
        if BpodSystem.Emulator.SoftCode == 0
            BpodSystem.Emulator.CurrentTime = now*100000;
            BpodSystem.Emulator.nCurrentEvents = 0;
            % Add manual overrides to current events
            if ~isempty(ManualOverrideEvent)
                BpodSystem.Emulator.nCurrentEvents = BpodSystem.Emulator.nCurrentEvents + 1;
                VirtualCurrentEvents(BpodSystem.Emulator.nCurrentEvents) = ManualOverrideEvent;
            end
            % Evaluate global timer transitions
            for x = 1:5
                if BpodSystem.Emulator.GlobalTimersActive(x) == 1
                    if BpodSystem.Emulator.CurrentTime > BpodSystem.Emulator.GlobalTimerEnd(x)
                        BpodSystem.Emulator.nCurrentEvents = BpodSystem.Emulator.nCurrentEvents + 1;
                        VirtualCurrentEvents(BpodSystem.Emulator.nCurrentEvents) = 40+x;
                        BpodSystem.Emulator.GlobalTimersActive(x) = 0;
                    end
                end
            end
            % Evaluate global counter transitions
            for x = 1:5
                if BpodSystem.StateMatrix.GlobalCounterEvents(x) ~= 254
                    if BpodSystem.Emulator.GlobalCounterCounts(x) == BpodSystem.StateMatrix.GlobalCounterThresholds(x)
                        BpodSystem.Emulator.nCurrentEvents = BpodSystem.Emulator.nCurrentEvents + 1;
                        VirtualCurrentEvents(BpodSystem.Emulator.nCurrentEvents) = 45+x;
                    end
                    if VirtualCurrentEvents(1) == BpodSystem.StateMatrix.GlobalCounterEvents(x)
                        BpodSystem.Emulator.GlobalCounterCounts(x) = BpodSystem.Emulator.GlobalCounterCounts(x) + 1;
                    end
                end
            end
            % Evaluate state timer transitions
            TimeInState = BpodSystem.Emulator.CurrentTime - BpodSystem.Emulator.StateStartTime;
            StateTimer = BpodSystem.StateMatrix.StateTimers(BpodSystem.Emulator.CurrentState);
            if (TimeInState > StateTimer) && (BpodSystem.Emulator.MeaningfulTimer(BpodSystem.Emulator.CurrentState) == 1)
                BpodSystem.Emulator.nCurrentEvents = BpodSystem.Emulator.nCurrentEvents + 1;
                VirtualCurrentEvents(BpodSystem.Emulator.nCurrentEvents) = 40;
            end
            DominantEvent = VirtualCurrentEvents(1);
            if DominantEvent > 0
                NewMessage = 1;
                OpCodeBytes = [1 BpodSystem.Emulator.nCurrentEvents];
                VirtualCurrentEvents = VirtualCurrentEvents - 1; % Set to c++ index by 0
                BpodSystem.Emulator.Timestamps(BpodSystem.Emulator.nEvents+1:BpodSystem.Emulator.nEvents+BpodSystem.Emulator.nCurrentEvents) = BpodSystem.Emulator.CurrentTime - BpodSystem.Emulator.MatrixStartTime;
                BpodSystem.Emulator.nEvents = BpodSystem.Emulator.nEvents + BpodSystem.Emulator.nCurrentEvents;
            else
                NewMessage = 0;
                OpCodeBytes = [];
                VirtualCurrentEvents = [];
            end
            drawnow;
        else
            NewMessage = 1;
            OpCodeBytes = [2 BpodSystem.Emulator.SoftCode];
            VirtualCurrentEvents = [];
            BpodSystem.Emulator.SoftCode = 0;
        end
end

