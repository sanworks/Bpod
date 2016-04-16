try
    BpodSystem.SerialPort = evalin('base', 'BpodSystem.SerialPort');
catch
    disp('Initializing Connection. . .');
    evalin ('base', 'Bpod');
    disp('Bpod Online!');
    BpodSystem.SerialPort = evalin('base', 'BpodSystem.SerialPort');
end