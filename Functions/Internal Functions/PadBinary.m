function Output = PadBinary(BinaryNumber, TotalSize)

PadLength = TotalSize - length(BinaryNumber);
Pad = '';
if PadLength > 0
    for x = 1:PadLength
        Pad = [Pad '0'];
    end
    Output = [Pad BinaryNumber];
else
    Output = BinaryNumber;
end