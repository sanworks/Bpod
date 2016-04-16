function GrayImage = GrayscaleThis(ColorImage)
[row col byt]=size(ColorImage);
R=ColorImage(:,:,1);              % red plane
G=ColorImage(:,:,2);              % green plane
B=ColorImage(:,:,3);              % blue plane
R=double(R);
G=double(G);
B=double(B);
GrayImage = zeros(row, col);
for x=1:1:row
    for y=1:1:col
        GrayImage(x,y)=0.3.*R(x,y)+0.59.*G(x,y)+0.11.*B(x,y); % method2
    end
end
GrayImage = uint8(GrayImage);