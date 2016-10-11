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
if BpodSystem.FirmwareBuild < 8 % Bpod 0.5
    BpodSystem.GUIHandles.PortConfigFig = figure('Position',[600 400 400 250],'name','Port config.','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
    yPos = 142;
else
    BpodSystem.GUIHandles.PortConfigFig = figure('Position',[600 400 400 150],'name','Port config.','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
    yPos = 50;
end
ha = axes('units','normalized', 'position',[0 0 1 1]);
uistack(ha,'bottom');
if BpodSystem.FirmwareBuild < 8 % Bpod 0.5
    BG = imread('InputChannelConfig.bmp');
else
    BG = imread('InputChannelConfig2.bmp');
end
image(BG); axis off;
BpodSystem.GUIHandles.PortConfigPort1 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [35 yPos 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 1 input');
BpodSystem.GUIHandles.PortConfigPort2 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [80 yPos 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 2 input');
BpodSystem.GUIHandles.PortConfigPort3 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [125 yPos 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 3 input');
BpodSystem.GUIHandles.PortConfigPort4 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [170 yPos 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 4 input');
BpodSystem.GUIHandles.PortConfigPort5 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [215 yPos 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 5 input');
BpodSystem.GUIHandles.PortConfigPort6 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [260 yPos 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 6 input');
BpodSystem.GUIHandles.PortConfigPort7 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [305 yPos 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 7 input');
BpodSystem.GUIHandles.PortConfigPort8 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [350 yPos 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 8 input');
if BpodSystem.FirmwareBuild < 8 % Bpod 0.5
    BpodSystem.GUIHandles.WireConfigPort1 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [35 59 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable wire 1 input');
    BpodSystem.GUIHandles.WireConfigPort2 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [80 59 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable wire 2 input');
    BpodSystem.GUIHandles.WireConfigPort3 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [125 59 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable wire 3 input');
    BpodSystem.GUIHandles.WireConfigPort4 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [170 59 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable wire 4 input');
else
    text(90, 25, 'Port input enable', 'FontName', 'OCRAStd', 'FontSize', 14, 'Color', [0.8 0.8 0.8]);
    Pos = 36;
    for x = 1:8
        text(Pos, 65,num2str(x), 'FontName', 'OCRAStd', 'FontSize', 12, 'Color', [0.8 0.8 0.8]);
        Pos = Pos + 45;
    end
end
% Populate checkboxes
for x = 1:8
    if BpodSystem.InputsEnabled.PortsEnabled(x) == 1
        eval(['set(BpodSystem.GUIHandles.PortConfigPort' num2str(x) ', ''Value'', 1);'])
    else
        eval(['set(BpodSystem.GUIHandles.PortConfigPort' num2str(x) ', ''Value'', 0);'])
    end
end
if BpodSystem.FirmwareBuild < 8
    for x = 1:4
        if BpodSystem.InputsEnabled.WiresEnabled(x) == 1
            eval(['set(BpodSystem.GUIHandles.WireConfigPort' num2str(x) ', ''Value'', 1);'])
        else
            eval(['set(BpodSystem.GUIHandles.WireConfigPort' num2str(x) ', ''Value'', 0);'])
        end
    end
end

function UpdatePortConfig(hObject,event)
global BpodSystem
for x = 1:8
    eval(['BpodSystem.InputsEnabled.PortsEnabled(' num2str(x) ') = get(BpodSystem.GUIHandles.PortConfigPort' num2str(x) ', ''Value'');'])
end
if BpodSystem.FirmwareBuild < 8
    for x = 1:4
        eval(['BpodSystem.InputsEnabled.WiresEnabled(' num2str(x) ') = get(BpodSystem.GUIHandles.WireConfigPort' num2str(x) ', ''Value'');'])
    end
end
BpodInputConfig = BpodSystem.InputsEnabled;
save (BpodSystem.InputConfigPath, 'BpodInputConfig');