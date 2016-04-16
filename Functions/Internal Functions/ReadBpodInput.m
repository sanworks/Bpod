function InputStatus = ReadBpodInput(Target, Channel)
% Target = 'BNC', 'Wire', 'Port'
global BpodSystem
Message = 'I';
switch Target
    case 'BNC'
        Message = [Message 'B'];
    case 'Wire'
        Message = [Message 'W'];
    case 'Port'
        Message = [Message 'P'];
    otherwise
        error('Target must be equal to ''BNC'', ''Wire'', or ''Port''');
end
if BpodSystem.EmulatorMode == 0
    Message = [Message Channel];
    BpodSerialWrite(Message, 'uint8');
    InputStatus = fread(BpodSystem.SerialPort, 1);
else
    error('The IR port sensors, wire terminals and BNC connector lines cannot be directly read while in emulator mode');
end