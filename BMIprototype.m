clear all

% 
% 
% 

%% 1. get start sig from Max (mes: 144,60,1)

send = mididevice('to Max 1');
receive = mididevice('from Max 1');

% if Max send the midi message of '144,60,1', this scpript continue the
% next section.
while 1
       receivedMessages = midireceive(receive);
       if isempty(receivedMessages) == 1
           continue
       else
           res = waitMidi(receive, 144, 60);
           if res == 1
               disp('receive the game start sig from Max')
               break
           else 
               continue
           end
       end
end

%% 2. EEG connection
% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG');
end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

[chunk,stamps] = inlet.pull_chunk();

%% 3. Send the ready sig to Max
msg = midimsg('ProgramChange',1,1); %mes: (192,1) = ready sig
midisend(send,msg)

%% 5. PARAMETERS

%get the parameters from maxmsp. if Max get the ready sig above, it
%suddenly send the parameter sig.

% parameter sig = (145,trial,device)

while 1
       receivedMessages = midireceive(receive);
       if isempty(receivedMessages) == 1
           disp('wait on parameter section')
           continue
       else
           if receivedMessages.MsgBytes(1) == 145
               trial = receivedMessages.MsgBytes(2);
               device = receivedMessages.MsgBytes(3);
               break
           else
               disp('wait on parameter section')
               continue
           end
       end
end

%Subject Details
subj = 'test'; %get subjectname from Maxmsp
timestamp = datestr(now,'yyyymmddTHHMMSS');
filename = ['Subj_' subj '_' timestamp '_'];
mkdir(filename);

numSpk = 2; % Number of loudspeakers. 3 is standard (L/C/R).
isSelAtt = 1;
giveFeedback = 1;
nt = trial; % Number of trials per block. get the amount from Maxmsp.
na = 2; %number of averages

if device == 0
    fseeg = 2048;
elseif device == 1
    fseeg = 128;
else 
    error('Device setting error; you can only set the number 0 or 1.')
end

load templateUpDn256

chois = [3:5,7:9];
choisBack = 14:16;

choisTemplate = [40, 38, 5, 13, 48, 50];
choisBackTemplate = [27, 29, 64];

tUpHG = mean(templateUp256(:,choisTemplate),2) - mean(templateUp256(:,choisBackTemplate),2);
tDnHG = mean(templateDn256(:,choisTemplate),2) - mean(templateDn256(:,choisBackTemplate),2);
cf1 = 2; cf2 = 9;
tUpHG = BPFtd(tUpHG,256,256,cf1,cf2);
tDnHG = BPFtd(tDnHG,256,256,cf1,cf2);

startP = 533;
endP = 811;
maxlag = 3;

% Normalize peak sizes
tUpHG(585:669) = tUpHG(585:669) / max(abs(tUpHG(615:640)));
tUpHG(746:830) = tUpHG(746:830) / max(abs(tUpHG(779:802)));
tDnHG(510:592) = tDnHG(510:592) / max(abs(tDnHG(538:564)));
tDnHG(707:786) = tDnHG(707:786) / max(abs(tDnHG(733:756)));

%% 6. send a finish message to Maxmsp
msg = midimsg('ProgramChange',1,2); %mes: (192,2) = finish sig
midisend(send,msg)

%% start Game

[chunk,stamps] = inlet.pull_chunk();
tcount = 0;

for it = 1:nt
    
    % get a Start/Next message from Maxmsp
    res = waitMidi(receive,146,1);
    if res ~= 1
        error('get the worng sound play message.')
    end

    for ii = 1:na
        
        % get a soundplay message from Maxmsp
        res = waitMidi(receive,147,1);
        if res ~= 1
            error('get the worng sound play message.')
        end

        % get a message that finish playing the sound
        [chunk,stamps] = inlet.pull_chunk();
        
        % processing the trigger
        if device == 0
            tg = diff(chunk(1,:));
            tg(tg<0) = 0;
            onset = find(tg==1);
            onset = onset(end); % in case more than one trigger pulses are found
        elseif device == 1
            
        else 
            error('Device setting error; you can only set the number 0 or 1.')
        end
        
        % processing EEG sig
        eegNow = chunk(:,onset-fseeg+1:onset+3*fseeg);
        save([filename '/' sprintf('epoch%03i.mat',tcount)], 'eegNow');
        
        temp = mean(chunk(1+chois,onset-fseeg+1:onset+3*fseeg))' - ...
            mean(chunk(1+choisBack,onset-fseeg+1:onset+3*fseeg))';
        
        temp = BPFtd(temp, fseeg, round(fseeg/2), cf1, cf2);
        baseline = mean(temp(round(fseeg*0.5)+1:fseeg));
        eegtemp(:,ii) = temp - baseline;
        pause(1);
        
        if ii ~= na
            % send a replaySound trigger to Maxmsp
            msg = midimsg('ProgramChange',1,3); %mes: (192,3) = replay sig
            midisend(send,msg)
        end
        
    end

    eeg(:,it) = BPFtd(resample(mean(eegtemp,2),256,2048),256,256,cf1,cf2);

    xcs = xcorr(tUpHG(startP:endP),eeg(startP+128:endP+128,it),maxlag,'normalized');
    simUp(it) = max(xcs);
    xcs = xcorr(tDnHG(startP:endP),eeg(startP+128:endP+128,it),maxlag,'normalized');
    simDn(it) = max(xcs);

    if simUp(it) > simDn(it)
        result = 0; % attending to Left
    else
        result = 1; % attending to Right
    end
    
    % send the result to Maxmsp
    if result == 0
        % send a replaySound trigger to Maxmsp
        msg = midimsg('ProgramChange',1,4); %mes: (192,4) = res sig:Left
        midisend(send,msg)
    elseif result == 1
        msg = midimsg('ProgramChange',1,5); %mes: (192,5) = res sig:right
        midisend(send,msg)
    end
    
    msg = midimsg('ProgramChange',1,6); %mes: (192,6) = gameready sig
    midisend(send,msg)
    
end


%%
msg = midimsg('ProgramChange',1,6); %mes: (192,6) = game end sig
midisend(send,msg)
close all
