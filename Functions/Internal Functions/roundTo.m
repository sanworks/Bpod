function roundedNumber = roundTo(number,nPlaces)
%ROUNDTO rounds a number to n places
% SYNOPSIS: roundedNumber = roundTo(number,nPlaces)
% IN: number : the number to be rounded. Can also be an array
% nPlaces: How many places to round to. E.g. 3 will round the number to the 3rd place
% OUT: roundedNumber: number rounded to nth place
%%%%%%%%%%%%%%%%%%%%%%%%%%

% check input
if nargin < 2 || isempty(nPlaces)
error('please supply two nonempty input arguments')
end

% make multiplier
mult = 10^nPlaces;

% round
roundedNumber = round(number*mult)./mult;