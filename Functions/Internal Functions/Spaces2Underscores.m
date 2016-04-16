function OutputString = Spaces2Underscores(InputString)
SpaceIndexes = find(InputString == ' ');
InputString(SpaceIndexes) = '_';
OutputString = InputString;