%Open input file 
testdata = fopen('testdata_b.txt', 'r');
sampleAmplitude = 100 : 1; %This creates an empty array
rowCount = 1;
sampleSum = 0;
still_deviation = 8:1;
current_deviation = 100:1;
outputVector = 100:1;
while ~feof(testdata)
    %Read each sample
    row = fscanf(testdata, '%f %f', [2 1]);
    if ~isempty(row)
        realComponent = row(1,1);
        imaginaryComponent = row(2,1);
        %Calculate the amplitude of each sample
        sampleAmplitude(rowCount) = sqrt((realComponent^2) + (imaginaryComponent^2));
        %Get an idea of what the signal looks like when the 
        %person is still by looking at samples from T-0 to T-2000
        %We take 250 samples at a time for calculating standard 
        %deviation and then look at the difference between consecutive
        %ones to detect the spike that corresponds to movement
        if rowCount <= 2000
            if rem(rowCount,250) ~= 0
                sampleSum = sampleSum + sampleAmplitude(rowCount);
            else
                sampleSum = sampleSum + sampleAmplitude(rowCount);
                mean = sampleSum / 250;
                sampleSum = 0;
                differenceSum = 0;
                for sampleCounter = rowCount-249:rowCount
                    differenceSum = differenceSum + (sampleAmplitude(sampleCounter) - mean)^2;
                end
                still_deviation((rowCount/250)) = sqrt(differenceSum/250);
            end
        else
            if rowCount == 2001
                %Have calculated the still deviation for the first two seconds and
                %stored it, Now will try to learn from this info by looking at the
                %difference between deviations over one second at a time
                for deviationCounter = 1:length(still_deviation)
                    if deviationCounter == 1
                        lastSample = still_deviation(deviationCounter);
                    else
                        if still_deviation(deviationCounter) > lastSample
                            upper_limit = still_deviation(deviationCounter);
                            lower_limit = lastSample;
                        else
                            lower_limit = still_deviation(deviationCounter);
                            upper_limit = lastSample;
                        end
                        lastSample = still_deviation(deviationCounter);
                    end
                end
                outputVector(1) = 0;
                outputVector(2) = 0;
            end
            if rem(rowCount,250) ~= 0
                sampleSum = sampleSum + sampleAmplitude(rowCount);
            else
                sampleSum = sampleSum + sampleAmplitude(rowCount);
                mean = sampleSum / 250;
                sampleSum = 0;
                differenceSum = 0;
                for sampleCounter = rowCount-249:rowCount
                    differenceSum = differenceSum + (sampleAmplitude(sampleCounter) - mean)^2;
                end
                current_deviation(rowCount/250) = sqrt(differenceSum/250);
                %Every fourth group of 250, i need to check if there was
                %movement and mark it in the output vector accordingly
                spikeFlag = 0;
                if rem((rowCount/250),4) == 0
                    for counter = (rowCount/250)-3:(rowCount/250)
                        if current_deviation(counter) > upper_limit
                            %Makes sure we don't misinterpret spikes due to
                            %WiFi packets
                            spikeFlag = spikeFlag + 1;                            
                        end
                    end
                    if spikeFlag >= 2
                        outputVector((rowCount/250)/4) = 1;
                    elseif spikeFlag == 0
                        outputVector((rowCount/250)/4) = 0;
                    end
                end
            end
        end
        rowCount = rowCount + 1;
    end
end
x = 1:1:length(sampleAmplitude);
plot(x,sampleAmplitude);
outputVector