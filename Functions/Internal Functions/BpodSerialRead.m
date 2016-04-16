function Data = BpodSerialRead(nIntegers, Datatype)
global BpodSystem
switch BpodSystem.UsesPsychToolbox
    case 0
        Data = fread(BpodSystem.SerialPort, nIntegers, Datatype);
    case 1
        % Psych toolbox way
        nIntegers = double(nIntegers);
        switch Datatype
            case 'uint8'
                Data = IOPort('Read', BpodSystem.SerialPort, 1, nIntegers);
            case 'uint16'
                Data = IOPort('Read', BpodSystem.SerialPort, 1, nIntegers*2);
                Data = uint8(Data);
                Data = double(typecast(Data, 'uint16'));
            case 'uint32'
                Data = IOPort('Read', BpodSystem.SerialPort, 1, nIntegers*4);
                Data = uint8(Data);
                Data = double(typecast(Data, 'uint32'));
        end
end