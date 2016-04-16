function varargout = LEDMatrix8X8(op, varargin)
global LEDMatrix
switch op
    case 'init'
        ComPort = varargin{1};
        LEDMatrix.SerialPort = serial(ComPort, 'BaudRate', 9600, 'Timeout', 1, 'DataTerminalReady', 'off');
        fopen(LEDMatrix.SerialPort);
    case 'program'
        Matrix = varargin{1};
        Duration = varargin{2};
        Bytestring = ['P' uint8(bin2dec(num2str(Matrix))') typecast(uint32(Duration*1000000), 'uint8')];
        fwrite(LEDMatrix.SerialPort, Bytestring, 'uint8');
    case 'trigger'
        fwrite(LEDMatrix.SerialPort, 'T');
    case 'clear'
        fwrite(LEDMatrix.SerialPort, 'C');
    case 'end'
        fclose(LEDMatrix.SerialPort);
        delete(LEDMatrix.SerialPort);
        clear global LEDMatrix
end
