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

%Open costasoutR for writing  
costasoutR_write = fopen('costasoutR', 'w');
fprintf(costasoutR_write,'%f \n',derotatedRealInput);
fclose(costasoutR_write);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%Module 2%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%Taking the samples%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
timingError = 0;
decision_plus_one = 0;
decision_minus_one = 0;
sample_plus_one = 0;
sample_minus_one = 0;
counter = 0;
readPosition = 10;
sampleList = 100 : 1; %This creates an empty array
sampleListActual = 100 : 1; %This creates an empty array
sampleCounter = 1;
%Open input file 
costasoutR_read = fopen('costasoutR', 'r');
while ~feof(costasoutR_read)
   %Read each sample
   sample = fscanf(costasoutR_read, '%f', [1,1]);
   %Read first three samples to get started
   if(counter < 3)
       if(counter == 0)
           sample_minus_one = sample(1,1);
           if sample_minus_one > 0
               decision_minus_one = 1;
           else 
               decision_minus_one = 0;
           end
           sampleList(sampleCounter) = decision_minus_one;
       elseif(counter == 1)
           if sample(1,1) > 0
               decision = 1;
           else 
               decision = 0;
           end
           sampleList(sampleCounter) = decision;
       elseif(counter == 2)
           sample_plus_one = sample(1,1);
           if sample_plus_one > 0
               decision_plus_one = 1;
           else 
               decision_plus_one = 0;
           end
           sampleList(sampleCounter) = decision_plus_one;
           %Calculate the timing error based on the M&M algorithm
           timingError = floor((decision_minus_one - decision_plus_one)*sample + (sample_plus_one - sample_minus_one)*decision);
           %Samples are taken every 10 microseconds
           readPosition = readPosition + 10 + timingError;
       end
       sampleCounter = sampleCounter + 1;
   end
   %Now continue with the rest of the samples
   if(counter == readPosition)
       %Make a decision on the bit value based on whether its negative or
       %positive
       if sample(1,1) > 0
           decision = 1;
       else 
           decision = 0;
       end
       sampleList(sampleCounter) = decision;
       sampleCounter = sampleCounter + 1;
       %Calculate the timing error based on the M&M algorithm
       timingError = floor((decision_minus_one - decision_plus_one)*sample(1,1) + (sample_plus_one - sample_minus_one)*decision);
       %Samples are taken every 10 microseconds
       readPosition = readPosition + 10 + timingError;
   end
   counter = counter + 1;
end

%Open mmdecisions for writing  
mmdecisions_write = fopen('mmdecisions', 'w');
fprintf(mmdecisions_write,'%d',sampleList);
fclose(mmdecisions_write);
