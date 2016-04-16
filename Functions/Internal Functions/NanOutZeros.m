function Output = NanOutZeros(Input)
Siz = size(Input);
Output = Input;
for x = 1:Siz(1)
    for y = 1:Siz(2);
        if Input(x,y) == 0
            Output(x,y) = NaN;
        end
    end
end