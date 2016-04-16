% Example state matrix: Runs through 128 states of 1ms each. 
% Useful for bench-testing SYNC lines.

sma = NewStateMatrix();

for x = 1:7
eval(['sma = AddState(sma, ''Name'', ''State ' num2str(x) ''', ''Timer'', .001, ''StateChangeConditions'', {''Tup'', ''State ' num2str(x+1) '''}, ''OutputActions'', {});']);
end
sma = AddState(sma, 'Name', 'State 8', 'Timer', .001, 'StateChangeConditions', {'Tup', 'exit'}, 'OutputActions', {});