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
function sma = GenerateBlankStateMatrix
global BpodSystem

% This function returns the final state (always = state 1). All subsequent calls to "AddState" will
% append to this.
sma.nStates = 0;
sma.nStatesInManifest = 0;
sma.Manifest = cell(1,127); % State names in the order they were added by user
sma.StateNames = {'Placeholder'}; % State names in the order they were referenced
sma.InputMatrix = ones(1,40);
sma.OutputMatrix = zeros(1,17);
sma.GlobalTimerMatrix = ones(1,5);
sma.GlobalTimers = zeros(1,5);
sma.GlobalTimerSet = zeros(1,5); % Changed to 1 when the timer is given a duration with SetGlobalTimer
sma.GlobalCounterMatrix = ones(1,5);
sma.GlobalCounterEvents = ones(1,5)*254; % Default event of 254 is code for "no event attached".
sma.GlobalCounterThresholds = zeros(1,5);
sma.GlobalCounterSet = zeros(1,5); % Changed to 1 when the counter event is identified and given a threshold with SetGlobalCounter
sma.StateTimers = 0;
sma.StatesDefined = 1; % Referenced states are set to 0. Defined states are set to 1. Both occur with AddState
BpodSystem.BlankStateMatrix = sma;