t = tcpip('0.0.0.0', 54000, 'NetworkRole', 'server');
t.InputBufferSize = 134217727;
% %Open a connection. This will not return until a connection is received.
%
fopen(t);
% %Read the waveform and confirm it visually by plotting it.
BytesAvailable = 0;
while BytesAvailable == 0 || BytesAvailable ~= t.BytesAvailable
    BytesAvailable = t.BytesAvailable;
    pause(1)
end

data = fread(t, t.BytesAvailable, 'uint8');
mat = hlp_deserialize(data)
%data = fscanf(t);

fclose(t);
delete(t);
clear t;
clear BytesAvailable
clear data
