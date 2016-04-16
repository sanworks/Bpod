function BpodSerialWrite(ByteString, Datatype)
global BpodSystem
switch BpodSystem.UsesPsychToolbox
    case 0
        fwrite(BpodSystem.SerialPort, ByteString, Datatype);
    case 1
        switch Datatype
            case 'uint8'
                IOPort('Write', BpodSystem.SerialPort, uint8(ByteString), 1);
            case 'uint16'
                IOPort('Write', BpodSystem.SerialPort, typecast(uint16(ByteString), 'uint8'), 1);
            case 'uint32'
                IOPort('Write', BpodSystem.SerialPort, typecast(uint32(ByteString), 'uint8'), 1);
        end
end
