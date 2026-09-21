classdef EEGPreprocessor
    % EEGPREPROCESSOR Handles signal filtering and normalization
    
    properties
        FS
        FilterLow
        FilterHigh
        NotchFreq
        FilterOrder
    end
    
    methods
        function obj = EEGPreprocessor(config)
            obj.FS = config.fs;
            obj.FilterLow = config.filter_low;
            obj.FilterHigh = config.filter_high;
            obj.NotchFreq = config.notch_freq;
            obj.FilterOrder = config.filter_order;
        end
        
        function filtered_data = process(obj, raw_data)
            % Applies bandpass and notch filters
            [num_channels, num_samples] = size(raw_data);
            filtered_data = zeros(size(raw_data));
            
            % Design bandpass filter
            [b, a] = butter(obj.FilterOrder, [obj.FilterLow, obj.FilterHigh] / (obj.FS / 2), 'bandpass');
            
            % Design notch filter
            wo = obj.NotchFreq / (obj.FS / 2);
            bw = wo / 35;
            [bn, an] = iirnotch(wo, bw);
            
            for c = 1:num_channels
                signal = raw_data(c, :);
                % Apply notch
                signal = filtfilt(bn, an, signal);
                % Apply bandpass
                signal = filtfilt(b, a, signal);
                filtered_data(c, :) = signal;
            end
        end
    end
end

