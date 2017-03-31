function ModuleWrite(ModuleName, ByteString)
global BpodSystem
ModuleNumber = find(strcmp(ModuleName, BpodSystem.Modules.Name));
if isempty(ModuleNumber)
    error(['Error: ' ModuleName ' is not connected. See valid modules by running BpodSystem.Modules.']);
end
nBytes = length(ByteString);
BpodSystem.SerialPort.write(['T' ModuleNumber], 'uint8', nBytes, 'uint32', ByteString, 'uint8');