%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2016 Sanworks LLC, Sound Beach, New York, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
function sma = SetGlobalTimer(sma, TimerNumber, Duration)

% Example usage:
% sma = SetGlobalTimer(sma, 1, 0.025); % sets timer 1 for 25ms

if ischar(Duration)
    error('Global timer durations must be numbers, in seconds')
end
if Duration < 0
    error('When setting global timers, time (in seconds) must be positive.')
end
if Duration > 3600
    error('Global timers can not exceed 1 hour');
end
nTimers = length(sma.GlobalTimers);
if TimerNumber > nTimers
    error(['Only ' num2str(nTimers) ' global timers are available in the current revision.']);
end
sma.GlobalTimers(TimerNumber) = Duration;
sma.GlobalTimersSet(TimerNumber) = 1;