function SaveBpodSystemSettings
global BpodSystem
BpodSystemSettings = BpodSystem.SystemSettings;
save(fullfile(BpodSystem.BpodPath, 'Settings Files', 'BpodSystemSettings.mat'), 'BpodSystemSettings');