%Open file 
fid = fopen('testdata', 'r');
%Initialize fRead for reading lines from text
fRead = '%f %f';
%Get the values from the testdata file
analogRealInput = 100 : 1; %This creates an empty array
analogImaginaryInput = 100 : 1; %This creates an empty array
rowCount = 0;
while rowCount < 2000
      rowCount = rowCount + 1;
      row = fscanf(fid, fRead, [2 1]);
      %Concatenate the different rows into one matrix
      analogRealInput = [analogRealInput;row(1,1)];
      analogImaginaryInput = [analogImaginaryInput;row(2,1)];
end

x = 1:1:rowCount;
y1 = analogRealInput;
y2 = analogImaginaryInput;
plot(x,y1);
figure
plot(x,y2);
