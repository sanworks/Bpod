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
function BpodPortConfig
global BpodSystem
BpodSystem.GUIHandles.PortConfigFig = figure('Position',[300 300 400 250],'name','Port config.','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
ha = axes('units','normalized', 'position',[0 0 1 1]);
uistack(ha,'bottom');
BG = imread('InputChannelConfig.bmp');
image(BG); axis off;
BpodSystem.GUIHandles.PortConfigPort1 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [35 142 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 1 input');
BpodSystem.GUIHandles.PortConfigPort2 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [80 142 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 2 input');
BpodSystem.GUIHandles.PortConfigPort3 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [125 142 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 3 input');
BpodSystem.GUIHandles.PortConfigPort4 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [170 142 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 4 input');
BpodSystem.GUIHandles.PortConfigPort5 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [215 142 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 5 input');
BpodSystem.GUIHandles.PortConfigPort6 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [260 142 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 6 input');
BpodSystem.GUIHandles.PortConfigPort7 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [305 142 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 7 input');
BpodSystem.GUIHandles.PortConfigPort8 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [350 142 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 8 input');

BpodSystem.GUIHandles.WireConfigPort1 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [35 59 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable wire 1 input');
BpodSystem.GUIHandles.WireConfigPort2 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [80 59 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable wire 2 input');
BpodSystem.GUIHandles.WireConfigPort3 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [125 59 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable wire 3 input');
BpodSystem.GUIHandles.WireConfigPort4 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [170 59 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable wire 4 input');

% Populate checkboxes
for x = 1:8
    if BpodSystem.InputsEnabled.PortsEnabled(x) == 1
        eval(['set(BpodSystem.GUIHandles.PortConfigPort' num2str(x) ', ''Value'', 1);']) 
    else
        eval(['set(BpodSystem.GUIHandles.PortConfigPort' num2str(x) ', ''Value'', 0);']) 
    end
end
for x = 1:4
    if BpodSystem.InputsEnabled.WiresEnabled(x) == 1
        eval(['set(BpodSystem.GUIHandles.WireConfigPort' num2str(x) ', ''Value'', 1);']) 
    else
        eval(['set(BpodSystem.GUIHandles.WireConfigPort' num2str(x) ', ''Value'', 0);']) 
    end
end


function UpdatePortConfig(hObject,event)
global BpodSystem
for x = 1:8
    eval(['BpodSystem.InputsEnabled.PortsEnabled(' num2str(x) ') = get(BpodSystem.GUIHandles.PortConfigPort' num2str(x) ', ''Value'');'])
end
for x = 1:4
    eval(['BpodSystem.InputsEnabled.WiresEnabled(' num2str(x) ') = get(BpodSystem.GUIHandles.WireConfigPort' num2str(x) ', ''Value'');'])
end
BpodInputConfig = BpodSystem.InputsEnabled;
save (BpodSystem.InputConfigPath, 'BpodInputConfig');