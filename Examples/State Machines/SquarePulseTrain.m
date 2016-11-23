% Example state matrix: Runs through 8 states of 1ms each.
% Sends a pulse train on BNC trigger channel 1, where alternating states
% are high and low.
% Useful for bench-testing SYNC line.

sma = NewStateMatrix();
i = 1;
for x = 1:8
    eval(['sma = AddState(sma, ''Name'', ''State ' num2str(x) ''', ''Timer'', .001, ''StateChangeConditions'', {''Tup'', ''State ' num2str(x+1) '''}, ''OutputActions'', {''BNCState'',' num2str(i) '});']);
    i = 1-i;
end
sma = AddState(sma, 'Name', ['State ' num2str(x+1)], 'Timer', .001, 'StateChangeConditions', {'Tup', 'exit'}, 'OutputActions', {});