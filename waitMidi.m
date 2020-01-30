function output = waitMidi(receive,target1,target2)

    while 1
           receivedMessages = midireceive(receive);
           if isempty(receivedMessages) == 1
               continue
           end
           
           [m, n] = size(receivedMessages);
           if m ~= 1
               error('Midi receive error; got 2 more midi data.')
               
           elseif receivedMessages.MsgBytes(1) ~= target1
               error('Midi receive error; got miss midi data.')
               
           else
               if receivedMessages.MsgBytes(2) == target2
                   output = receivedMessages.MsgBytes(3);
                   break 
               else 
                    error('Midi receive error; it does not mat the target.')
               end
            end
    end
end

