function Kentucky2AFC_RS2
% Kentucky2AFC_RS2 task in chickenfoot maze.
%
% This is the second step in trainig mice in an audio 2AFC in the chickenfoot maze.
% RS stands for Require Sides: here the mouse has to poke firstly in the centre
% port (now wthout getting the reward) and then laterally in order to get the 5ul reward.
% After central poking, the animal has a limited amount of time to poke the
% correct lateral port: so even if he pokes wrong, ha can have enough time
% to run on the othe port and get the reward.
% Anti-bias included.
% Only the central port is illuminated, as will always be. CS is presented on poking the central port
% see also Kentucky2AFC_DP Kentucky2AFC_ID Kentucky2AFC_RC
%
%
% Nicola Solari, 2016
% Lendulet Laboratory of Systems Neuroscience (hangyalab.koki.hu)
% Institute of Experimental Medicine, Hungarian Academy of Sceinces

clc

global BpodSystem

%Structure creation
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
S = struct;
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.NumTrialTypes = 2;   % Different trial types corresponding to different cues and outcome contingencies
    S.GUI.ITI = 3 % Inter Trial Interval
    S.GUI.RewardWindow = 9; % After central poking, the seconds the animal has to go and collect the reward
    S.GUI.RewardObtained = 0; % The up-to-trial updated quantity of water received by the animal during the task
    S.GUI.SinWavekHz1 = 3; % Cue tone #1 in kHz - tone #1 signals the availability of the reward in the left arm
    S.GUI.SinWavedB1 = 65; % Cue tone #1 dB SPL
    S.GUI.SinWavekHz2 = 7; % Cue tone #2 in kHz - tone #2 signals the availability of the reward in the right arm
    S.GUI.SinWavedB2 = 65; % Cue tone #2 dB SPL
end
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

%Trials definition

rng('shuffle')   % Reset pseudorandom seed
BpodSystem.Data.TrialTypes = []; % BpodSystem.Data.TrialTypes = []
TrialTypes = [];
ITI = S.GUI.ITI;
Window = S.GUI.RewardWindow;

% % Initialize plots
% BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
% BpodSystem.GUIHandles.SideOutcomePlot = axes('Position', [.075 .3 .89 .6]);
% SideOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'init',2-TrialTypes);
BpodNotebook('init');

%Teensy & calibration data engagement
delete(instrfindall);
[Status RawString] = system('wmic path Win32_SerialPort Where "PNPDeviceID LIKE ''%1547110%''" Get DeviceID'); % Search for Teensy PnP ID (1547110) on PNPDeviceID
PortLocations = strfind(RawString, 'COM');
TeensyPorts = cell(1,100);
nPorts = length(PortLocations);
for x = 1:nPorts
    Clip = RawString(PortLocations(x):PortLocations(x)+6);
    TeensyPorts{x} = Clip(1:find(Clip == 32,1, 'first')-1);
end
TeensyPort = TeensyPorts(1:nPorts);
%TeensySoundServer('init',TeensyPort); % Opens Teensy Server at the COM port engaged by the device
FilePath = fullfile(BpodSystem.BpodPath,'Protocols','TeensyCalibration','TeensyCalData.mat');
%load(FilePath); % Load Calibration data as a reference

% Tones 1 and 2 Creation
Tg1 = S.GUI.SinWavedB1; % Wanted dB for tone 1
Tg2 = S.GUI.SinWavedB2; % Wanted dB for tone 2
Fr1 = S.GUI.SinWavekHz1;
Fr2 = S.GUI.SinWavekHz2;
%SPL1 = TeensyCalData.SPL(Fr1); % Recalls calibrated dB for the frequency of tone 1
%SPL2 = TeensyCalData.SPL(Fr2); % Recalls calibrated dB for the frequency of tone 2
%Ampl1 = TeensyCalData.Amplitude(Fr1); % Recalls calibrated amplitude for the tone 1 frequency
%Ampl2 = TeensyCalData.Amplitude(Fr2); % Recalls calibrated amplitude for the tone 2 frequency
%NewAmpl1  = AmplAdjst(SPL1,Tg1,Ampl1); % Calculates new amplitude for tone 1
%NewAmpl2  = AmplAdjst(SPL2,Tg2,Ampl2); % Calculates new amplitude for tone 2
%sinewave1  = NewAmpl1.*sin(2*pi*Fr1*1000/44100.*(0:44100*0.1)); % Creates the sinewave of tone 1
%sinewave2  = NewAmpl2.*sin(2*pi*Fr2*1000/44100.*(0:44100*0.1)); % Creates the sinewaves of tone 2
%TeensySoundServer ('loadwaveform', Fr1, sinewave1); % Uploads the sinewave for tone 1
%TeensySoundServer ('loadwaveform', Fr2, sinewave2); % Uploads the sinewave for tone 2

% Main trial loop
for currentTrial = 1:11
    TrialTypes(currentTrial) = ceil(rand(1,1)*2);
    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial))])
    
    S = BpodParameterGUI('sync', S); % Synchronize the GUI
    cTg1 = S.GUI.SinWavedB1;
    cTg2 = S.GUI.SinWavedB2;
    cFr1 = S.GUI.SinWavekHz1;
    cFr2 = S.GUI.SinWavekHz2;
    
    if ~isequal(Tg1,cTg1) || ~isequal(Fr1,cFr1) % Controls if parameters for tone 1 are changed: if so, it is modified accordingly
        %SPL1 = TeensyCalData.SPL(S.GUI.SinWavekHz1);
        %Ampl1 = TeensyCalData.Amplitude(S.GUI.SinWavekHz1);
        %NewAmpl1  = AmplAdjst(SPL1,cTg1,Ampl1);
        %sinewave1  = NewAmpl1.*sin(2*pi*cFr1*1000/44100.*(0:44100*0.1));
        %TeensySoundServer ('loadwaveform', S.GUI.SinWavekHz1, sinewave1);
        Tg1 = cTg1;
        Fr1 = cFr1;
    end
    if  ~isequal(Tg2,cTg2) || ~isequal(Fr2,cFr2) % Controls if parameters for tone 2 are changed: if so, it is modified accordingly
        %SPL2 = TeensyCalData.SPL(S.GUI.SinWavekHz2);
        %Ampl2 = TeensyCalData.Amplitude(S.GUI.SinWavekHz2);
        %NewAmpl2  = AmplAdjst(SPL2,cTg2,Ampl2);
        %sinewave2  = NewAmpl2.*sin(2*pi*cFr2*1000/44100.*(0:44100*0.1));
        %TeensySoundServer ('loadwaveform', S.GUI.SinWavekHz2, sinewave2);
        Tg2 = cTg2;
        Fr2 = cFr2;
    end
    
    % Eventual adjustment of ITI
    cITI = S.GUI.ITI;
    if ~isequal(ITI,cITI)
        ITI = cITI;
    end
    
    % Eventual adjustment of RewardWindow
    cWindow = S.GUI.RewardWindow;
    if ~isequal(Window,cWindow)
        Window = cWindow;
    end
    
    R1 = GetValveTimes(5, [1 2]); LeftValveTime = R1(1); RightValveTime = R1(2); % Calulates the proper opening time for the valve to deliver the 5ul reward amount
    
    % Defines what tone is played depending on the trial type
    if TrialTypes(currentTrial) == 1
        Audio = S.GUI.SinWavekHz1;
        LeftActionState = 'Reward'; RightActionState = 'Null';
        RewardValve = 1; ValveTime = LeftValveTime; Audio = Fr1;
        LeftPokeAction2 = 'LReward2'; RightPokeAction2 = 'Null2';
        TimeOut = 'LFail'; 
    else
        Audio = S.GUI.SinWavekHz2;
        LeftActionState = 'Null'; RightActionState = 'Reward';
        RewardValve = 2; ValveTime = RightValveTime; Audio = Fr2;
        LeftPokeAction2 = 'Null2'; RightPokeAction2 = 'RReward2';
        TimeOut = 'RFail'; 
    end
    
    % Assemble state matrix
    sma = NewStateMatrix();   % 'Serial1Code', Fr1
    sma = SetGlobalTimer(sma, 1, S.GUI.RewardWindow);
    sma = AddState(sma, 'Name', 'WaitForCentralPoking', ... % A new trial begins
        'Timer', 0,...
        'StateChangeConditions', {'Port3In', 'PlayCue' },...
        'OutputActions', {'PWM3', 255});
    sma = AddState(sma, 'Name', 'PlayCue', ... % Sound cue is played
        'Timer', 0.1,...
        'StateChangeConditions', {'Tup', 'ChoosePort'},...
        'OutputActions', {'Serial1Code', Audio, 'PWM3', 255, 'GlobalTimerTrig',1});
    sma = AddState(sma, 'Name', 'ChoosePort', ... % Mouse has to choose a port
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', LeftActionState, 'Port2In', RightActionState,'GlobalTimer1_End', TimeOut},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Reward', ... % Mouse get the major reward
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', RewardValve});
    sma = AddState(sma, 'Name', 'Null', ... % Mouse have poked wrong: nothing happens but he has time for correction (maybe)
        'Timer', .01,...
        'StateChangeConditions', {'Tup', 'Repent'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Repent', ... % Mouse must poke correctly to proceed
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', LeftPokeAction2, 'Port2In', RightPokeAction2, 'GlobalTimer1_End', TimeOut},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Null2', ... % Mouse failed, should try again
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup', 'Repent'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'LReward2', ... % Mouse gets water and future cue sound but the trial is considered as failed
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', RewardValve});
    sma = AddState(sma, 'Name', 'RReward2', ... % Mouse gets water and future cue sound but the trial is considered as failed
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', RewardValve});
    sma = AddState(sma, 'Name', 'LFail', ...
        'Timer',  0.01,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'RFail', ...
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', S.GUI.ITI,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
%         UpdateSideOutcomePlot(TrialTypes, BpodSystem.Data);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    TotalReward = UpdateWaterReward(currentTrial, TrialTypes, BpodSystem.Data);
    if currentTrial == 11
        Correction = BiasCounter(TrialTypes, BpodSystem.Data);
    else
        BiasCounter(TrialTypes, BpodSystem.Data);
    end
    HandlePauseCondition;
    if BpodSystem.BeingUsed == 0
        return
    end
end
for currentTrial = 12:300
    
    if Correction == 1
        TrialTypes(currentTrial) = 1
    elseif Correction == 2
        TrialTypes(currentTrial) = 2
    else
        TrialTypes(currentTrial) = ceil(rand(1,1)*2)
    end
    
    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial))])
    
    S = BpodParameterGUI('sync', S); % Synchronize the GUI
    cTg1 = S.GUI.SinWavedB1;
    cTg2 = S.GUI.SinWavedB2;
    cFr1 = S.GUI.SinWavekHz1;
    cFr2 = S.GUI.SinWavekHz2;
    
    if ~isequal(Tg1,cTg1) || ~isequal(Fr1,cFr1) % Controls if parameters for tone 1 are changed: if so, it is modified accordingly
        SPL1 = TeensyCalData.SPL(S.GUI.SinWavekHz1);
        Ampl1 = TeensyCalData.Amplitude(S.GUI.SinWavekHz1);
        NewAmpl1  = AmplAdjst(SPL1,cTg1,Ampl1);
        sinewave1  = NewAmpl1.*sin(2*pi*cFr1*1000/44100.*(0:44100*0.1));
        TeensySoundServer ('loadwaveform', S.GUI.SinWavekHz1, sinewave1);
        Tg1 = cTg1;
        Fr1 = cFr1;
    end
    if  ~isequal(Tg2,cTg2) || ~isequal(Fr2,cFr2) % Controls if parameters for tone 2 are changed: if so, it is modified accordingly
        SPL2 = TeensyCalData.SPL(S.GUI.SinWavekHz2);
        Ampl2 = TeensyCalData.Amplitude(S.GUI.SinWavekHz2);
        NewAmpl2  = AmplAdjst(SPL2,cTg2,Ampl2);
        sinewave2  = NewAmpl2.*sin(2*pi*cFr2*1000/44100.*(0:44100*0.1));
        TeensySoundServer ('loadwaveform', S.GUI.SinWavekHz2, sinewave2);
        Tg2 = cTg2;
        Fr2 = cFr2;
    end
    
    % Eventual adjustment of ITI
    cITI = S.GUI.ITI;
    if ~isequal(ITI,cITI)
        ITI = cITI;
    end
    
    % Eventual adjustment of RewardWindow
    cWindow = S.GUI.RewardWindow;
    if ~isequal(Window,cWindow)
        Window = cWindow;
    end
    
    R1 = GetValveTimes(5, [1 2]); LeftValveTime = R1(1); RightValveTime = R1(2); % Calulates the proper opening time for the valve to deliver the 5ul reward amount
    
    % Defines what tone is played depending on the trial type
    if TrialTypes(currentTrial) == 1
        Audio = S.GUI.SinWavekHz1;
        LeftActionState = 'Reward'; RightActionState = 'Null';
        RewardValve = 1; ValveTime = LeftValveTime; Audio = Fr1;
        LeftPokeAction2 = 'LReward2'; RightPokeAction2 = 'Null2';
        TimeOut = 'LFail';
    else
        Audio = S.GUI.SinWavekHz2;
        LeftActionState = 'Null'; RightActionState = 'Reward';
        RewardValve = 2; ValveTime = RightValveTime; Audio = Fr2;
        LeftPokeAction2 = 'Null2'; RightPokeAction2 = 'RReward2';
        TimeOut = 'RFail';
    end
    
    % Assemble state matrix
    sma = NewStateMatrix();   % 'Serial1Code', Fr1
    sma = SetGlobalTimer(sma, 1, S.GUI.RewardWindow);
    sma = AddState(sma, 'Name', 'WaitForCentralPoking', ... % A new trial begins
        'Timer', 0,...
        'StateChangeConditions', {'Port3In', 'PlayCue' },...
        'OutputActions', {'PWM3', 255});
    sma = AddState(sma, 'Name', 'PlayCue', ... % Sound cue is played
        'Timer', 0.1,...
        'StateChangeConditions', {'Tup', 'ChoosePort'},...
        'OutputActions', {'Serial1Code', Audio, 'PWM3', 255, 'GlobalTimerTrig',1});
    sma = AddState(sma, 'Name', 'ChoosePort', ... % Mouse has to choose a port
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', LeftActionState, 'Port2In', RightActionState,'GlobalTimer1_End', TimeOut},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Reward', ... % Mouse get the major reward
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', RewardValve});
    sma = AddState(sma, 'Name', 'Null', ... % Mouse have poked wrong: nothing happens but he has time for correction (maybe)
        'Timer', .01,...
        'StateChangeConditions', {'Tup', 'Repent'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Repent', ... % Mouse must poke correctly to proceed
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', LeftPokeAction2, 'Port2In', RightPokeAction2, 'GlobalTimer1_End', TimeOut},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Null2', ... % Mouse failed, should try again
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup', 'Repent'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'LReward2', ... % Mouse gets water and future cue sound but the trial is considered as failed
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', RewardValve});
    sma = AddState(sma, 'Name', 'RReward2', ... % Mouse gets water and future cue sound but the trial is considered as failed
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', RewardValve});
    sma = AddState(sma, 'Name', 'LFail', ...
        'Timer',  0.01,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'RFail', ...
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', S.GUI.ITI,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
%         UpdateSideOutcomePlot(TrialTypes, BpodSystem.Data);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    TotalReward = UpdateWaterReward(currentTrial, TrialTypes, BpodSystem.Data);
    Correction = BiasCounter(TrialTypes, BpodSystem.Data);
    HandlePauseCondition;
    if BpodSystem.BeingUsed == 0
        return
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [CalAmpl] = AmplAdjst(SPL,Tg,Ampl) % Calculate the new proper sinewave amplitude
y = SPL - Tg;
b =  20 * log10(Ampl) - y;
c = b / 20;
CalAmpl = 10 .^ c;

% function UpdateSideOutcomePlot(TrialTypes, Data)
% global BpodSystem
% Outcomes = zeros(1,Data.nTrials);
% for x = 1:Data.nTrials
%     if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1))
%         Outcomes(x) = 1; % Green dot
%     elseif ~isnan(Data.RawEvents.Trial{x}.States.Reward2(1))
%         Outcomes(x) = 2; % Green circle
%     else
%         Outcomes(x) = -1; % Red circle
%     end
% end
% SideOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'update',Data.nTrials+1,2-TrialTypes,Outcomes)

function [TotalReward] = UpdateWaterReward(currentTrial, TrialTypes, Data) % Sums up the water obtained
global BpodSystem
Outcomes = zeros(1,Data.nTrials);
for x = 1:Data.nTrials
    if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1))
        Outcomes(x) = 5;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.LReward2(1))
        Outcomes(x) = 5;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.RReward2(1))
        Outcomes(x) = 5;
    else
        Outcomes(x) = 0;
    end
    TotalReward = sum(Outcomes);
end
NumParam = BpodSystem.GUIData.ParameterGUI.nParams;
for  n = 1:NumParam;
    if strcmp(BpodSystem.GUIData.ParameterGUI.ParamNames(n), 'RewardObtained') == 1
        b = n;
    end
end
if currentTrial ~= 1
    ThisParamHandle = BpodSystem.GUIHandles.ParameterGUI.Params(b);
    set(ThisParamHandle, 'String', num2str(TotalReward));
end

% function [CleverMouse] = SuccessCounter(Start, TrialTypes, Data)   % SHOULD WE COUND BOTH ON ONLY DIRECT GUESS REWARD?
% global BpodSystem
% Outcomes = zeros(1,Data.nTrials);
% for x = Start:Data.nTrials
%     if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1))
%         Outcomes(x) = 1;
%     elseif ~isnan(Data.RawEvents.Trial{x}.States.Reward2(1))
%         Outcomes(x) = 1;
%     else
%         Outcomes(x) = 0;
%     end
%     Success = sum(Outcomes);
%     if Success == 200
%         msgbox(['Egészségére! Mouse got reward 200 times at trial ' num2str(Data.nTrials)],'Not a Title')
%     end
% end

function [Correction] = BiasCounter(TrialTypes, Data)
global BpodSystem
window = 10;
% Outcomes = zeros(1,1000);
for x = 1:Data.nTrials
    if ~isnan(Data.RawEvents.Trial{x}.States.LReward2(1)) % wrong TrialType1 trial
        Outcomes(x) = 1
    elseif ~isnan(Data.RawEvents.Trial{x}.States.LFail(1))
        Outcomes(x) = 1
    elseif ~isnan(Data.RawEvents.Trial{x}.States.RReward2(1))
        Outcomes(x) = 2
    elseif ~isnan(Data.RawEvents.Trial{x}.States.RFail(1))
        Outcomes(x) = 2
    else
        Outcomes(x) = 3 %the rewards
    end
    if x > window
        LastOutcomes = Outcomes(end-9:end);
        t = tabulate(LastOutcomes);
        if x > 10
            if  t(1,3) >50
                C = 1
            elseif  t(2,3) >50
                C = 2
            else
                C = 0
            end
        else
        end
        Correction = C;
    end
end