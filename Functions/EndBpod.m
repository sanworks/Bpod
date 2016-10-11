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
global BpodSystem
if BpodSystem.EmulatorMode == 0
    if BpodSerialBytesAvailable > 0
        BpodSerialRead(BpodSerialBytesAvailable, 'uint8')
    end
end
try
    close(BpodSystem.GUIHandles.LiveDispFig)
catch
end
if BpodSystem.BeingUsed == 0
    if BpodSystem.EmulatorMode == 0
        BpodSerialWrite('Z', 'uint8');
    end
    pause(.1);
    delete(BpodSystem.GUIHandles.MainFig);
    if BpodSystem.EmulatorMode == 0
        switch BpodSystem.ControlInterface
        case 0 % Java
            fclose(BpodSystem.SerialPort);
            delete(BpodSystem.SerialPort);
        case 1 % Psychtoolbox
            IOPort('Close', BpodSystem.SerialPort);
        end
    
        BpodSystem.SerialPort = [];
        if isfield(BpodSystem.PluginSerialPorts, 'TeensySoundServer')
            TeensySoundServer('end');
        end
    end
    if BpodSystem.EmulatorMode == 0
        disp('Bpod successfully disconnected.')
    else
        disp('Bpod emulator successfully closed.')
    end
    BpodSocketServer('close');
    try 
       close(BpodSystem.GUIHandles.ConfigureBonsaiFig)
    catch
    end
else
    msgbox('There is a running protocol. Please stop it first.')
    BpodErrorSound;
end
clear BpodSystem