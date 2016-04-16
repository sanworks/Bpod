function [HighByte LowByte] = ConvertWordToBytes(Word)

BinaryWord = dec2bin(Word);
nSpaces = 16-length(BinaryWord);
Pad = '';
MaxPad = '0000000000000000';
if nSpaces < 16
    Pad = [Pad MaxPad(1:nSpaces)];
    BinaryWord = [Pad BinaryWord];
end

HighBinary = BinaryWord(1:8);
LowBinary = BinaryWord(9:16);
HighByte = uint8(bin2dec(HighBinary));
LowByte = uint8(bin2dec(LowBinary));