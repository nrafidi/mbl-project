function [ labels, label_times] = prepareLabels()
%prepareLabels unrolls the character annotation matrix for each cut and
%assigns it a time that corresponds to TRs

frameRate = 23.98;%fps

load ../../Data/Home_Alone_2_character_annotations.mat

emptyResponses = cellfun(@isempty, responses);
responses = responses(~emptyResponses);
numResp = length(responses) - 1;

labels = [];
label_times = [];
for r = 1:numResp
    startTime = ceil(responses{r}.init_frame/frameRate);
    endTime = ceil(responses{r}.finit_frame/frameRate);
%     if mod(startTime, 2) ~= 0
%         startTime = startTime - 1;
%     end
    charLabels = reshape(responses{r}.char_checkbox', 1, []);
    for timeToAdd = startTime:2:endTime
        if ~any(label_times == timeToAdd)
            labels = cat(1, labels, charLabels);
            label_times = cat(1, label_times, timeToAdd);
        end
    end
end

save ../../Data/labelsAndTimes_notEven.mat labels label_times

end

