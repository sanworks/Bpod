
function TuningCurves
% This protocol is used to estimate tuning curves in auditory areas
% Written by F.Carnevale, 4/2015.

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with settings default
    % Sound settings
    S.GUI.LowFreq = 500;
    S.GUI.HighFreq = 5000;
    S.GUI.nFreq = 20;
    S.GUI.VolumeMin = 30;
    S.GUI.VolumeMax = 90;
    S.GUI.nVolumes = 20;
    S.GUI.RampDuration = 0.005;
    S.GUIPanels.SoundSettings = {'LowFreq', 'HighFreq', 'nFreq', 'VolumeMin', 'VolumeMax', 'nVolumes', 'RampDuration'};
    % Timing settings
    S.GUI.SoundIntervalMin = 0.5;
    S.GUI.SoundIntervalMax = 1.5;
    S.GUI.SoundDuration = 0.2;
    S.GUI.nSoundRepetitions = 5;
    S.GUIPanels.TimingSettings = {'SoundIntervalMin', 'SoundIntervalMax', 'SoundDuration', 'nSoundRepetitions'};
    % Recording site coodinates
    S.GUI.ElectrodeAP = 0;
    S.GUI.ElectrodeDM = 0;
    S.GUI.ElectrodeDepth = 0;
    S.GUIPanels.RecordingSite = {'ElectrodeAP', 'ElectrodeDM', 'ElectrodeDepth'};
    % Stimulation Parameters
    S.GUI.UseStimulation = 0;
    S.GUIMeta.UseStimulation.Style = 'checkbox';
    S.GUI.TrainDelay = 0.008;
    S.GUI.PulseWidth = 0.001;
    S.GUI.PulseInterval = 0.1;
    S.GUI.PulseTrainDuration = 0.1;
    S.GUI.StimProbability = 1;
    S.GUIPanels.Stimulation = {'UseStimulation', 'TrainDelay', 'PulseWidth', 'PulseInterval', 'PulseTrainDuration', 'StimProbability'};
    % Current sound display
    S.GUI.CurrentFrequency = 0;
    S.GUIMeta.CurrentFrequency.Style = 'text';
    S.GUI.CurrentVolume = 0;
    S.GUIMeta.CurrentVolume.Style = 'text';
    S.GUI.TrialNumber = 0;
    S.GUIMeta.TrialNumber.Style = 'text';
    S.GUIPanels.CurrentTrial = {'CurrentFrequency', 'CurrentVolume', 'TrialNumber'};
    % Other Stimulus settings (not in the GUI)
    SamplingRate = 192000; % Sound card sampling rate; 
end

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);

BpodSystem.Data.TrialFreq = []; % The trial frequency of each trial completed will be added here.

% Program sound server
PsychToolboxSoundServer('init')

% Set soft code handler to trigger sounds
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

BpodSystem.ProtocolFigures.InitialMsg = msgbox({'', ' Edit your settings and click OK when you are ready to start!     ', ''},'Tuning Curves Protocol...');
uiwait(BpodSystem.ProtocolFigures.InitialMsg);

S = BpodParameterGUI('sync', S); % Sync parameters with EnhancedBpodParameterGUI plugin
% InitializePulsePal
UsingStimulation = 0;
if S.GUI.UseStimulation
    PulsePal;
    load TuningCurve_PulsePalProgram;
    ProgramPulsePal(ParameterMatrix);
    S.InitialPulsePalParameters = ParameterMatrix;
    UsingStimulation = 1;
end
%% Define trials
PossibleFreqs = logspace(log10(S.GUI.LowFreq),log10(S.GUI.HighFreq),S.GUI.nFreq);
PossibleVolumes = linspace(S.GUI.VolumeMin,S.GUI.VolumeMax,S.GUI.nVolumes);
MaxTrials = size(PossibleFreqs,2)*size(PossibleVolumes,2)*S.GUI.nSoundRepetitions;
TrialFrequencies = PossibleFreqs(randi(size(PossibleFreqs,2),1,MaxTrials));
TrialVolumes = PossibleVolumes(randi(size(PossibleVolumes,2),1,MaxTrials));
% Set display fields for first trial
S.GUI.CurrentFrequency = round(TrialFrequencies(1)); % Sound Freq
S.GUI.CurrentVolume = round(TrialVolumes(1)); % Sound Freq
S.GUI.TrialNumber = [num2str(1) '/' num2str(MaxTrials)]; % Number of current trial

%% Main trial loop
for currentTrial = 1:MaxTrials
    S = BpodParameterGUI('sync', S); % Sync parameters with EnhancedBpodParameterGUI plugin
    SoundInterval = S.GUI.SoundIntervalMin + rand*S.GUI.SoundIntervalMax;
    Sound = CalibratedPureTone(TrialFrequencies(currentTrial),S.GUI.SoundDuration,TrialVolumes(currentTrial), 0, ...
    S.GUI.RampDuration, SamplingRate, BpodSystem.CalibrationTables.SoundCal);
    PsychToolboxSoundServer('Load', 1, Sound);
    
    ThisTrialBNC = rand < S.GUI.StimProbability;
    
    sma = NewStateMatrix(); % Assemble state matrix
    sma = AddState(sma, 'Name', 'DeliverStimulus', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'Stimulate'},...
        'OutputActions', {'SoftCode', 1});
    sma = AddState(sma, 'Name', 'Stimulate', ...
        'Timer', S.GUI.PulseTrainDuration,...
        'StateChangeConditions', {'Tup', 'SoundInterval'},...
        'OutputActions', {'BNCState', ThisTrialBNC});
    sma = AddState(sma, 'Name', 'SoundInterval', ...
        'Timer', SoundInterval,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialFrequency(currentTrial) = TrialFrequencies(currentTrial);
        BpodSystem.Data.TrialVolume(currentTrial) = TrialVolumes(currentTrial);
        BpodSystem.Data.SoundDuration(currentTrial) = S.GUI.SoundDuration;
        BpodSystem.Data.SoundInterval(currentTrial) = SoundInterval;
        BpodSystem.Data.StimulationTrial(currentTrial) = ThisTrialBNC;
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        if currentTrial<MaxTrials
            % display next trial info
            S.GUI.CurrentFrequency = round(TrialFrequencies(currentTrial+1)); % Sound Frequency
            S.GUI.CurrentVolume = round(TrialVolumes(currentTrial+1)); % Sound Volume
            S.GUI.TrialNumber = [num2str(currentTrial+1) '/' num2str(MaxTrials)]; % Number of current trial
        end
    end
    
    if BpodSystem.BeingUsed == 0
        return
    end
    
end
