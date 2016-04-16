%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

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

% BpodPath
% AGV Feb 14, 2012
% This script 
% a) returns the value of BpodPath 
% b) doublechecks that BpodPath/Data and BpodPath/CalibrationFiles exist, and makes them if not.


%% Set BpodPath

FullBpodPath = which('Bpod');
BpodPath = FullBpodPath(1:strfind(FullBpodPath, 'Bpod System Files')-1);

%% Check that /Data and /CalibrationFiles exist, and make them if not.

%Check for Data
dir_data = dir( fullfile(BpodPath,'Data') );
if length(dir_data) == 0, %then Data didn't exist.
    mkdir([BpodPath,'/' 'Data']);
end

%Check for CalibrationFiles
dir_calfiles = dir( fullfile(BpodPath,'Calibration Files') );
if length(dir_calfiles) == 0, %then Data didn't exist.
    mkdir([BpodPath,'/' 'Calibration Files']);
end
clear dir_data dir_calfiles FullBpodPath

