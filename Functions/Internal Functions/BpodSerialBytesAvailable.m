function BytesAvailable = BpodSerialBytesAvailable
global BpodSystem
switch BpodSystem.UsesPsychToolbox
    case 0
        BytesAvailable = BpodSystem.SerialPort.BytesAvailable;
    case 1
        BytesAvailable = IOPort('BytesAvailable', BpodSystem.SerialPort);
end