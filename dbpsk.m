%Open file 
fid = fopen('testdata', 'r');
%Initialize fRead for reading lines from text
fRead = '%f %f';

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
while ~feof(fid)
    %Read each sample
    row = fscanf(fid, fRead, [2 1]);
    
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

x = 1:1:rowCount-1;
plot(x,derotatedRealInput);
figure
plot(x,derotatedImaginaryInput);
