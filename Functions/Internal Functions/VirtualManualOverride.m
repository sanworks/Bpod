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
function ManualOverrideEvent = VirtualManualOverride(OverrideMessage)
% Converts the byte code transmission formatted for the state machine into event codes
global BpodSystem
OpCode = OverrideMessage(1);
if OpCode == 'V'
    EventType = OverrideMessage(2);
    ChannelCode = OverrideMessage(3)+1;
    switch EventType
        case 'P'
            if BpodSystem.HardwareState.PortSensors(ChannelCode) == 1
                ManualOverrideEvent = (ChannelCode*2)-1;
            else
                ManualOverrideEvent = (ChannelCode*2);
            end
        case 'B'
            if BpodSystem.HardwareState.BNCInputs(ChannelCode) == 1
                ManualOverrideEvent = 16+(ChannelCode*2)-1;
            else
                ManualOverrideEvent = 16+(ChannelCode*2);
            end
        case 'W'
            if BpodSystem.HardwareState.WireInputs(ChannelCode) == 1
                ManualOverrideEvent = 20+(ChannelCode*2)-1;
            else
                ManualOverrideEvent = 20+(ChannelCode*2);
            end
        case 'S'
            ManualOverrideEvent = 27+ChannelCode;
        case 'X'
            ManualOverrideEvent = 256;
    end
else
    ManualOverrideEvent = [];
end