function AvailablePorts = ListAvailableSerialPorts;
AvailablePorts = cell(1);
nPorts = 0;



if ispc,
    
    for x = 1:50
        try
            TestSer = serial(['COM' num2str(x)], 'BaudRate', 115200, 'DataBits', 8, 'StopBits', 1, 'Timeout', 1);
            fopen(TestSer);
            fclose(TestSer);
            nPorts = nPorts + 1;
            AvailablePorts{nPorts} = ['COM' num2str(x)];
        catch
        end
    end
    
elseif ismac,
    
    testPorts = {...
        '/dev/tty.usbmodemfd121',...
        '/dev/tty.usbmodemfd131',...
        '/dev/tty.usbmodemfa121',...
        '/dev/tty.usbmodemfa131',...
        '/dev/tty.SerialPort-1',...
        '/dev/tty.Agave-SerialServer'};
    
    for i = 1:length(testPorts)
        
        try
            TestSer = serial(testPorts{i}, 'BaudRate', 115200,...
                'DataBits', 8, 'StopBits', 1, 'Timeout', 1,'InputBuffer',512);
            
            fopen(TestSer);
            if strcmp(TestSer.Status,'open')
                nPorts = nPorts + 1;
                AvailablePorts{nPorts} = testPorts{i};
            end
            fclose(TestSer);
            
        catch
        end
        
    end
    
    
    
elseif isunix,
    error('Not supported on Unix.');
    
end