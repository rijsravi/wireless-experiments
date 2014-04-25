%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%Viterbi Decoder%%%%%%%%%%%%%%%%%%%
%%Change the INDICATOR to hard/soft as required%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function decoder
    %Open input file 
    testdata = fopen('ccode_samples1.txt', 'r');
    %This creates an empty array
    sampleBlock = 100:1;
    partialStringTable = cell(4,64);
    costTable = 100:1;
    sampleCounter = 1;
    INDICATOR = 'soft';
    while ~feof(testdata)
        %Read each sample
        row = fscanf(testdata, '%f', [1 1]);
        if ~isempty(row) 
            %Make blocks of 3 samples. Each block represents one bit
            if rem(sampleCounter,3) == 0        
                sampleBlock(3) = row;
                %For the first three samples, we assume an initial state of 00
                if sampleCounter/3 == 1
                    possibleState1 = getPossibleState(0,0);
                    possibleState2 = getPossibleState(0,1);             
                    for rowCounter = 1:4
                        if rowCounter == getLastTwoBits(possibleState1) + 1
                            partialStringTable{rowCounter, 1} =  '0';
                            costTable(rowCounter, 1) = findDistance(possibleState1,sampleBlock,INDICATOR);
                        elseif rowCounter == getLastTwoBits(possibleState2) + 1
                            partialStringTable{rowCounter, 1} = '1';
                            costTable(rowCounter, 1) = findDistance(possibleState2,sampleBlock,INDICATOR);
                        else
                            %For states from which we don't branch, we fill
                            %the rows with 2
                            partialStringTable{rowCounter, 1} = '2';
                            costTable(rowCounter, 1) = 0;
                        end
                    end
                else
                    %We fill each row initially with 2s and then proceed to
                    %push the partial strings into it as applicable
                    for rowCounter = 1:4
                        partialStringTable{rowCounter, sampleCounter/3} = '2';
                    end
                    for rowCounter = 1:4
                        if strcmp(partialStringTable(rowCounter,(sampleCounter/3)-1),'2') == 0
                            
                            prevCost = costTable(rowCounter,(sampleCounter/3)-1);
                            prevString = partialStringTable(rowCounter,(sampleCounter/3)-1);
                            
                            possibleState1 = getPossibleState(rowCounter-1, 0);
                            possibleState1LastTwo = getLastTwoBits(possibleState1);
                            possibleState2 = getPossibleState(rowCounter-1, 1);
                            possibleState2LastTwo = getLastTwoBits(possibleState2);
                            distance1 = prevCost + findDistance(possibleState1,sampleBlock,INDICATOR);
                            distance2 = prevCost + findDistance(possibleState2,sampleBlock,INDICATOR);
                            
                            %The branching from the first two states are
                            %pushed directly, the subsequent branches need
                            %to be checked if they are smaller than the one
                            %already filled
                            if strcmp(partialStringTable(possibleState1LastTwo + 1, sampleCounter/3),'2') == 1
                                partialStringTable(possibleState1LastTwo + 1, sampleCounter/3) = strcat(prevString,'0');
                                costTable(possibleState1LastTwo + 1, sampleCounter/3) = distance1;
                            else
                                distance3 = costTable(possibleState1LastTwo + 1, sampleCounter/3);
                                if distance1 < distance3
                                    partialStringTable(possibleState1LastTwo + 1, sampleCounter/3) = strcat(prevString,'0');
                                    costTable(possibleState1LastTwo + 1, sampleCounter/3) = distance1;
                                end
                            end
                            
                            if strcmp(partialStringTable(possibleState2LastTwo + 1, sampleCounter/3),'2') == 1 
                                partialStringTable(possibleState2LastTwo + 1, sampleCounter/3) = strcat(prevString,'1');
                                costTable(possibleState2LastTwo + 1, sampleCounter/3) = distance2;
                            else
                                distance4 = costTable(possibleState2LastTwo + 1, sampleCounter/3);
                                if distance2 < distance4
                                    partialStringTable(possibleState2LastTwo + 1, sampleCounter/3) = strcat(prevString,'1');
                                    costTable(possibleState2LastTwo + 1, sampleCounter/3) = distance2;
                                end
                            end
                        end
                    end
                end
            else
                sampleBlock(rem(sampleCounter,3)) = row;
            end
            sampleCounter = sampleCounter + 1;
        end
    end
    
    %Since we know that the last two bits are 00, the string present at
    %state 00 at the end would be the correct one
    finalString = strtok(char(partialStringTable(1,64)));
    output_write = fopen('output', 'w');
    fprintf(output_write,'%c\n',finalString);
end

function distance = findDistance(possibleState, sampleBlock, INDICATOR)
    possibleStateBin = dec2bin(possibleState,3);
    tokens = strtok(possibleStateBin);
    %Given the bits, we need to find what it would've been encoded to
    x0 = rem(bin2dec(tokens(1)) + bin2dec(tokens(2)) + bin2dec(tokens(3)),2);
    x1 = rem(bin2dec(tokens(1)) + bin2dec(tokens(3)),2);
    x2 = rem(bin2dec(tokens(2)) + bin2dec(tokens(3)),2);
    %The final signal was sent as pulses of -1 & +1, so we map 0 to -1
    if x0 == 0
        x0 = -1;
    end
    if x1 == 0
        x1 = -1;
    end
    if x2 == 0
        x2 = -1;
    end
    if strcmp(INDICATOR,'soft') == 1
        distance = (x0 - sampleBlock(1))^2 + (x1 - sampleBlock(2))^2 + (x2 - sampleBlock(3))^2;
    elseif strcmp(INDICATOR,'hard') == 1
        distance = (x0 - quantize(sampleBlock(1)))^2 + (x1 - quantize(sampleBlock(2)))^2 + (x2 - quantize(sampleBlock(3)))^2;
    end
end

function val = quantize(sample)
    if sample < 0
        val = -1;
    else 
        val = 1;
    end
end

function output = getPossibleState(currentState, inputBin)
    currentStateBin = dec2bin(currentState,2);
    token = strtok(currentStateBin);
    b0 = token(1);
    b1 = token(2);
    b2 = dec2bin(inputBin);
    output = bin2dec([b0,b1,b2]);
end

function output = getLastTwoBits(input)
    tokens = strtok(dec2bin(input,3));
    bin = [tokens(2),tokens(3)];
    output = bin2dec(bin);
end