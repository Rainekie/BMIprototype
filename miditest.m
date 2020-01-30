clear all

% 
% 
% 

%% get start sig from Max (mes: 144,60,1)

send = mididevice('to Max 1');
receive = mididevice('from Max 1');

% if Max send the midi message of '144,60,1', this scpript continue the
% next section.
while 1
       receivedMessages = midireceive(receive);
       if isempty(receivedMessages) == 1
           disp('wait on start sig section')
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

%% EEG connection
% instantiate the library
disp('Pass EEG section');


%% Send the ready sig to Max
msg = midimsg('ProgramChange',1,1); %mes: (192,1) = ready sig
midisend(send,msg)

%% PARAMETERS

%get the parameters from maxmsp. if Max get the ready sig above, it
%suddenly send the parameter sig.

% parameter sig = (145,trial,device)

clear receivedMessages

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

disp(fprintf('trial number is; %i',trial))
disp(fprintf('device number is; %i',device))
disp('pass parameter section')

%% start Game

nt = trial; % Number of trials per block. get the amount from Maxmsp.
na = 2; %number of averages

for it = 1:nt

    for ii = 1:na
        
        % get a soundplay message from Maxmsp
        res = waitMidi(receive,146,1);
        if res ~= 1
            error('get the worng sound play message.')
        end
        
        if ii ~= na
            % send a replaySound trigger to Maxmsp
            msg = midimsg('ProgramChange',1,3); %mes: (192,3) = replay sig
            midisend(send,msg)
        end
        
    end
    
    result = 0;
    
    % send the result to Maxmsp
    if result == 0
        % send a replaySound trigger to Maxmsp
        msg = midimsg('ProgramChange',1,4); %mes: (192,4) = res sig:Left
        midisend(send,msg)
    elseif result == 1
        msg = midimsg('ProgramChange',1,5); %mes: (192,5) = res sig:right
        midisend(send,msg)
    end
    
    disp(fprintf('pass game section: %i',it))
end


%%
msg = midimsg('ProgramChange',1,6); %mes: (192,6) = game end sig
midisend(send,msg)

disp('pass all senction')
