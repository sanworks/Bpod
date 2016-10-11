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
function ConfigureSync(junk, morejunk)
global BpodSystem
close(BpodSystem.GUIHandles.SettingsMenuFig)
if BpodSystem.FirmwareBuild < 8 % Bpod 0.5
    error('Bpod 0.5 has a fixed sync port. No configuration required.')
else
    BpodSystem.GUIHandles.PortConfigFig = figure('Position',[600 400 400 150],'name','Sync config.','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
end
ha = axes('units','normalized', 'position',[0 0 1 1]);
uistack(ha,'bottom');
BG = imread('InputChannelConfig2.bmp');
image(BG); axis off;


%BpodSystem.GUIHandles.PortConfigPort1 = uicontrol('Style', 'checkbox', 'String', '', 'Position', [35 yPos 15 15], 'Callback', @UpdatePortConfig,'TooltipString', 'Enable port 1 input');
text(80, 25, 'Sync channel config', 'FontName', 'OCRAStd', 'FontSize', 14, 'Color', [0.8 0.8 0.8]);
text(50, 65, 'Channel', 'FontName', 'OCRAStd', 'FontSize', 14, 'Color', [0.8 0.8 0.8]);
text(210, 65, 'Signal type', 'FontName', 'OCRAStd', 'FontSize', 14, 'Color', [0.8 0.8 0.8]);
BpodSystem.GUIHandles.SyncConfigChannel = uicontrol('Position', [55 35 80 20], 'Style', 'popupmenu', 'String', {'None', 'BNC2', 'Port8LED', 'Wire3'}, 'Callback', @UpdateSyncConfig, 'FontSize', 12);
BpodSystem.GUIHandles.SyncConfigType = uicontrol('Position', [220 35 120 20], 'Style', 'popupmenu', 'String', {'Each_Trial', 'Each_State'}, 'Callback', @UpdateSyncConfig, 'FontSize', 12);

% Populate menus
set(BpodSystem.GUIHandles.SyncConfigChannel, 'value', BpodSystem.SyncConfig.Channel+1);
set(BpodSystem.GUIHandles.SyncConfigType, 'value', BpodSystem.SyncConfig.SignalType+1);

function UpdateSyncConfig(hObject,event)
global BpodSystem
Ch = get(BpodSystem.GUIHandles.SyncConfigChannel, 'Value') - 1;
Type = get(BpodSystem.GUIHandles.SyncConfigType, 'Value') - 1;
BpodSerialWrite(['K' Ch Type], 'uint8');
BpodSystem.SyncConfig.Channel = Ch;
BpodSystem.SyncConfig.SignalType = Type;
BpodSyncConfig = BpodSystem.SyncConfig;
save (BpodSystem.SyncConfigPath, 'BpodSyncConfig');