send = mididevice('to Max 1');
receive = mididevice('from Max 1');

msg = midimsg('ProgramChange',1,2);
receivedMessages = midireceive(receive)

midisend(send,msg)

%% wait until entering something

while 1
       receivedMessages = midireceive(receive);
       if isempty(receivedMessages) == 1
           continue
       elseif receivedMessages.MsgBytes(2) == 1
           disp('OK')
           break 
       else 
           disp(receivedMessages.MsgBytes(2))
           disp('other')
           break
       end
end
