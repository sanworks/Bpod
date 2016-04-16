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
% Update gui reads BpodSystem.HardwareState and updates the commander GUI
% to reflect it.
function UpdateBpodCommanderGUI
global BpodSystem

if ~isempty(BpodSystem.StateMatrix)
    EventNames = BpodSystem.EventNames;
    set(BpodSystem.GUIHandles.PreviousStateDisplay, 'String', BpodSystem.LastStateName);
    set(BpodSystem.GUIHandles.CurrentStateDisplay, 'String', BpodSystem.CurrentStateName);
    if ~isempty(BpodSystem.LastEvent)
        if BpodSystem.LastEvent <= length(EventNames)
            set(BpodSystem.GUIHandles.LastEventDisplay, 'String', EventNames{BpodSystem.LastEvent});
        end
    end
end

% Set GUI valve state indicators
ChangedValves = find((BpodSystem.HardwareState.Valves ~= BpodSystem.LastHardwareState.Valves));
for x = ChangedValves
    if BpodSystem.HardwareState.Valves(x) == 1
        set(BpodSystem.GUIHandles.PortValveButton(x), 'CData', BpodSystem.Graphics.OnButton);
    else
        set(BpodSystem.GUIHandles.PortValveButton(x), 'CData', BpodSystem.Graphics.OffButton);
    end
end

% Set GUI PWM/LED-on indicators
ChangedPWM = find((BpodSystem.HardwareState.PWMLines ~= BpodSystem.LastHardwareState.PWMLines));
for x = ChangedPWM
    if BpodSystem.HardwareState.PWMLines(x) > 0
        set(BpodSystem.GUIHandles.PortLEDButton(x), 'CData', BpodSystem.Graphics.OnButton);
    else
        set(BpodSystem.GUIHandles.PortLEDButton(x), 'CData', BpodSystem.Graphics.OffButton);
    end
end

% Set virtual event indicators
ChangedV = find((BpodSystem.HardwareState.PortSensors ~= BpodSystem.LastHardwareState.PortSensors));
for x = ChangedV
    if BpodSystem.HardwareState.PortSensors(x) == 1
        set(BpodSystem.GUIHandles.PortvPokeButton(x), 'CData', BpodSystem.Graphics.OnButton);
    else
        set(BpodSystem.GUIHandles.PortvPokeButton(x), 'CData', BpodSystem.Graphics.OffButton);
    end
end

% Set GUI BNC state indicators
ChangedBNCIn = find((BpodSystem.HardwareState.BNCInputs ~= BpodSystem.LastHardwareState.BNCInputs));
for x = ChangedBNCIn
    if BpodSystem.HardwareState.BNCInputs(x) == 1
        set(BpodSystem.GUIHandles.BNCInputButton(x), 'CData', BpodSystem.Graphics.OnButton);
    else
        set(BpodSystem.GUIHandles.BNCInputButton(x), 'CData', BpodSystem.Graphics.OffButton);
    end
end
ChangedBNCOut = find((BpodSystem.HardwareState.BNCOutputs ~= BpodSystem.LastHardwareState.BNCOutputs));
for x = ChangedBNCOut
    if BpodSystem.HardwareState.BNCOutputs(x) == 1
        set(BpodSystem.GUIHandles.BNCOutputButton(x), 'CData', BpodSystem.Graphics.OnButton);
    else
        set(BpodSystem.GUIHandles.BNCOutputButton(x), 'CData', BpodSystem.Graphics.OffButton);
    end
end

% Set GUI Wire state indicators
ChangedWireIn = find((BpodSystem.HardwareState.WireInputs ~= BpodSystem.LastHardwareState.WireInputs));
for x = ChangedWireIn
    if BpodSystem.HardwareState.WireInputs(x) == 1
        set(BpodSystem.GUIHandles.InputWireButton(x), 'CData', BpodSystem.Graphics.OnButton);
    else
        set(BpodSystem.GUIHandles.InputWireButton(x), 'CData', BpodSystem.Graphics.OffButton);
    end
end
ChangedWireOut = find((BpodSystem.HardwareState.WireOutputs ~= BpodSystem.LastHardwareState.WireOutputs));
for x = ChangedWireOut
    if BpodSystem.HardwareState.WireOutputs(x) == 1
        set(BpodSystem.GUIHandles.OutputWireButton(x), 'CData', BpodSystem.Graphics.OnButton);
    else
        set(BpodSystem.GUIHandles.OutputWireButton(x), 'CData', BpodSystem.Graphics.OffButton);
    end
end

% Set Serial and soft code windows
if BpodSystem.HardwareState.Serial1Code ~= BpodSystem.LastHardwareState.Serial1Code
    set(BpodSystem.GUIHandles.HWSerialCodeSelector1, 'String', num2str(BpodSystem.HardwareState.Serial1Code));
end
if BpodSystem.HardwareState.Serial2Code ~= BpodSystem.LastHardwareState.Serial2Code
    set(BpodSystem.GUIHandles.HWSerialCodeSelector2, 'String', num2str(BpodSystem.HardwareState.Serial2Code));
end
if BpodSystem.HardwareState.SoftCode ~= BpodSystem.LastHardwareState.SoftCode
    set(BpodSystem.GUIHandles.SoftCodeSelector, 'String', num2str(BpodSystem.HardwareState.SoftCode));
end

BpodSystem.LastHardwareState = BpodSystem.HardwareState;
