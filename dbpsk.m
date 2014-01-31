%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%Module 1%%%%%%%%%%%%%%%%%%%%
%Removing the carrier frequency difference%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rowCount = 1;
d_BETA = 0.01;
d_ALPHA = 0.1;
d_freq = 0;
d_phase = 0;
derotatedRealInput = 100 : 1; %This creates an empty array
derotatedImaginaryInput = 100 : 1; %This creates an empty array
%Open input file 
testdata = fopen('testdata', 'r');
while ~feof(testdata)
    %Read each sample
    row = fscanf(testdata, '%f %f', [2 1]);
    
    if ~isempty(row)
        %Rotate the sample about the origin
        derotatedRealInput(rowCount) = row(1,1)*cosd(d_phase) - row(2,1)*sind(d_phase);
        derotatedImaginaryInput(rowCount) = row(2,1)*cosd(d_phase) + row(1,1)*sind(d_phase);

        %Then calculate the phase error
        phase_error = -atand(derotatedImaginaryInput(rowCount)/derotatedRealInput(rowCount));

        %Finally, update d_freq and d_phase accordingly
        d_freq = d_freq + d_BETA * phase_error;
        d_phase = d_phase + d_freq + d_ALPHA * phase_error;

        %Increment counter for next iteration
        rowCount = rowCount + 1;
    end
end

%Plot graph 
xaxis = 1:1:length(derotatedRealInput);
plot(xaxis, derotatedRealInput);

%Open costasoutR for writing  
costasoutR_write = fopen('costasoutR', 'w');
fprintf(costasoutR_write,'%f \n',derotatedRealInput);
fclose(costasoutR_write);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%Module 2%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%Taking the samples%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
index = 1;
tempSamplesList = 100:1; %This creates an empty array
%Open input file 
costasoutR_read = fopen('costasoutR', 'r');
%Read each sample and store it an array
while ~feof(costasoutR_read)
   sample = fscanf(costasoutR_read, '%f', [1,1]);
   if ~isempty(sample)
       tempSamplesList(index) = sample(1,1);
       index = index + 1;
   end
end

%Read first three samples to get started
if tempSamplesList(1) > 0
   dk_minus_one = 1;
else 
   dk_minus_one = 0;
end

if tempSamplesList(2) > 0
   dk = 1;
else 
   dk = 0;
end

if tempSamplesList(3) > 0
   dk_plus_one = 1;
else 
   dk_plus_one = 0;
end

%Calculate the timing error based on the M&M algorithm
timingError = (dk_minus_one - dk_plus_one)*tempSamplesList(2) + (tempSamplesList(3) - tempSamplesList(1))*dk;
%Indicates from which position we start reading the samples
readPosition = 7;
%Samples are taken every 10 microseconds
readPosition = readPosition + 10 + timingError;

mmDecisionList = 100 : 1; %This creates an empty array
mmDecisionSamplesList = 100 : 1; %This creates an empty array
mmDecisionCounter = 1;
while(length(tempSamplesList) - readPosition > 10)
   %Check if the readPosition is a whole number first
   if(readPosition - floor(readPosition) > 0)
       x = readPosition;
       x0 = floor(x);
       x1 = floor(x) + 1;
       y0 = tempSamplesList(x0);
       y1 = tempSamplesList(x1);
       %We need to find the sample by linear interpolation
       mmDecisionSamplesList(mmDecisionCounter) = y0 + (y1 - y0) * ((x - x0)/(x1-x0));
       
       x = readPosition+(10+timingError);
       x0 = floor(x);
       x1 = floor(x) + 1;
       y0 = tempSamplesList(x0);
       y1 = tempSamplesList(x1);
       sample_plus_one = y0 + (y1 - y0) * ((x - x0)/(x1-x0));
       
       x = readPosition-(10+timingError);
       x0 = floor(x);
       x1 = floor(x) + 1;
       y0 = tempSamplesList(x0);
       y1 = tempSamplesList(x1);
       sample_minus_one = y0 + (y1 - y0) * ((x - x0)/(x1-x0));
   else 
       mmDecisionSamplesList(mmDecisionCounter) = tempSamplesList(readPosition);
       sample_plus_one = tempSamplesList(readPosition+(10+timingError));
       sample_minus_one = tempSamplesList(readPosition-(10+timingError));
   end
   
   %Make a decision on the bit value based on whether its negative or
   %positive
   if mmDecisionSamplesList(mmDecisionCounter) > 0
       mmDecisionList(mmDecisionCounter) = 1;
   else 
       mmDecisionList(mmDecisionCounter) = 0;
   end
   
   if sample_plus_one > 0
       decision_plus_one = 1;
   else
       decision_plus_one = 0;
   end
   if sample_minus_one > 0
       decision_minus_one = 1;
   else
       decision_minus_one = 0;
   end
   %Calculate the timing error based on the M&M algorithm
   timingError = (decision_minus_one - decision_plus_one)*mmDecisionSamplesList(mmDecisionCounter) + (sample_plus_one - sample_minus_one)* mmDecisionList(mmDecisionCounter);
   %Samples are taken every 10 microseconds
   readPosition = readPosition + 10 + timingError;
   mmDecisionCounter = mmDecisionCounter + 1;
end

%Plot graph 
xaxis = 1:1:length(mmDecisionSamplesList);
figure;
plot(xaxis, mmDecisionSamplesList);

%Open mmdecisions for writing  
mmdecisions_write = fopen('mmdecisions', 'w');
fprintf(mmdecisions_write,'%d',mmDecisionList);
fclose(mmdecisions_write);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%Module 3%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%Finding Data Packet%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% taking input from input file
fid = fopen('mmdecisions', 'r');
% this file stores the original data after extraction from raw bits
fid2 = fopen('output.bin.txt','w');
%this variable is used for swapping between bits
temp = fscanf(fid,'%c',1);
while ~feof(fid)
    b = fscanf(fid,'%c',1);
    chk = fid;
    if feof(fid)
        break;
    end
    if temp == b
        %if there is no change in  bit, write 0
        fprintf(fid2,'%c','0');
    else
        %if there is change in bit, write 1
        fprintf(fid2,'%c','1');
    end
    temp = b;
end
fclose(fid);
fclose(fid2);
%array to store hexa value
hexarray = hexToBinaryVector('0xA4F2');
% hexa value is compared with the content of this file to get the begining
% location
fid2=fopen('output.bin.txt');
%variable to keep track of bit location and its count
tempcount=0;
a=fscanf(fid2,'%c',1);
intialcount=1;
count=1;
while ~feof(fid2)
    tempcount=0;
    for i= 1:16
        a = str2num(a);
        if a == hexarray(i)
            tempcount=tempcount+1;
            a=fscanf(fid,'%c',1);
            if i ==16
                disp('       result');
                %this will print the intial position of packet
                disp(intialcount);
            end
        else
            tempcount=0;
            fid=fid2;
            a=fscanf(fid2,'%c',1);
            count=count+1;
            break;
        end
    end
    if tempcount == 0
       intialcount=count;
    else
        fid2=fid;
        a=fscanf(fid2,'%c',1);
        count=count+tempcount;
        intialcount=count;
    end
end
