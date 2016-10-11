function BytesAvailable = BpodSerialBytesAvailable
global BpodSystem
switch BpodSystem.ControlInterface
    case 0 % MATLAB/Java
        BytesAvailable = BpodSystem.SerialPort.BytesAvailable;
    case 1 % Psychtoolbox
        BytesAvailable = IOPort('BytesAvailable', BpodSystem.SerialPort);
    case 2 % Ethernet/Serial
        
end