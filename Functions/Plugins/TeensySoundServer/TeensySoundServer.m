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
function TeensySoundServer(varargin)
global BpodSystem
Message = lower(varargin{1});
switch Message
    case 'init'
        % Syntax: TeensySoundServer('init', SerialPort); % example SerialPort = 'COM3' 
        SerialPort = varargin{1};
        BpodSystem.PluginSerialPorts.TeensySoundServer = serial(SerialPort, 'BaudRate', 115200, 'Timeout', 1, 'DataTerminalReady', 'on', 'OutputBufferSize', 50000000);
        fopen(BpodSystem.PluginSerialPorts.TeensySoundServer);
    case 'loadwaveform'
        % Syntax: TeensySoundServer('loadwaveform', index, data);
        Index = varargin{2};
        WaveData = varargin{3};
        FilePath = fullfile(BpodSystem.BpodPath, 'Bpod System Files', 'Plugins', 'TeensySoundServer', 'temp.wav');
        audiowrite(FilePath, WaveData, 44100,'BitsPerSample', 16);
        F = fopen(FilePath);
        FileData = fread(F);
        fclose(F);
        fwrite(BpodSystem.PluginSerialPorts.TeensySoundServer, 'F');
        fwrite(BpodSystem.PluginSerialPorts.TeensySoundServer, Index, 'uint8');
        fwrite(BpodSystem.PluginSerialPorts.TeensySoundServer, length(FileData), 'uint32');
        fwrite(BpodSystem.PluginSerialPorts.TeensySoundServer, FileData, 'uint8');
    case 'loadfile'
        % Syntax: TeensySoundServer('sendfile', index, filepath);
        Index = varargin{2};
        FilePath = varargin{3};
        F = fopen(FilePath);
        FileData = fread(F);
        fclose(F);
        fwrite(BpodSystem.PluginSerialPorts.TeensySoundServer, 'F');
        fwrite(BpodSystem.PluginSerialPorts.TeensySoundServer, Index, 'uint8');
        fwrite(BpodSystem.PluginSerialPorts.TeensySoundServer, length(FileData), 'uint32');
        fwrite(BpodSystem.PluginSerialPorts.TeensySoundServer, FileData, 'uint8');
    case 'play'
        % Syntax: TeensySoundServer('play', index);
        Index = varargin{2};
        fwrite(BpodSystem.PluginSerialPorts.TeensySoundServer, ['S' Index]);
    case 'end'
        % Syntax: TeensySoundServer('end');
        fclose(BpodSystem.PluginSerialPorts.TeensySoundServer);
        delete(BpodSystem.PluginSerialPorts.TeensySoundServer);
        BpodSystem.PluginSerialPorts = rmfield(BpodSystem.PluginSerialPorts, 'TeensySoundServer');
end