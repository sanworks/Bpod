function BpodSerialWrite(ByteString, Datatype)
global BpodSystem
switch BpodSystem.ControlInterface
    case 0 % MATLAB/Java
        fwrite(BpodSystem.SerialPort, ByteString, Datatype);
    case 1% Psychtoolbox
        switch Datatype
            case 'uint8'
                IOPort('Write', BpodSystem.SerialPort, uint8(ByteString), 0);
            case 'uint16'
                IOPort('Write', BpodSystem.SerialPort, typecast(uint16(ByteString), 'uint8'), 0);
            case 'uint32'
                IOPort('Write', BpodSystem.SerialPort, typecast(uint32(ByteString), 'uint8'), 0);
        end
    case 2 % Ethernet/Serial
        
end
