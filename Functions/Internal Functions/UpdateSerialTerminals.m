function UpdateSerialTerminals
global BpodSystem
nAvailable = BpodSystem.SerialPort.bytesAvailable;
if nAvailable > 0
    Message = BpodSystem.SerialPort.read(nAvailable, 'uint8');
    if BpodSystem.GUIData.CurrentPanel > 0
        CurrentString = get(BpodSystem.GUIHandles.SerialTerminalOutput(BpodSystem.GUIData.CurrentPanel-1), 'String');
        if length(CurrentString) > 256
            CurrentString = '';
        end
        NewString = [CurrentString Message];
        set(BpodSystem.GUIHandles.SerialTerminalOutput(BpodSystem.GUIData.CurrentPanel-1), 'String', NewString);
        drawnow;
    end
end
