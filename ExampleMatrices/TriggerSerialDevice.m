% Example state matrix: Writes a byte to serial devices 1 and 2. 

ByteForSerial1 = 65;
ByteForSerial2 = 66;
ByteForSerial3 = 67;

sma = NewStateMatrix();

sma = AddState(sma, 'Name', 'SendSerial1', 'Timer', 0, ... 
                    'StateChangeConditions', {'Tup', 'exit'}, ... 
                    'OutputActions', {'Serial1Write', ByteForSerial1, 'Serial2Write', ByteForSerial2, 'Serial3Write', ByteForSerial3});