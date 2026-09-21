classdef ArtifactRemover
    % ARTIFACTREMOVER Detects and clips extreme amplitudes in EEG signals
    
    properties
        ThresholdZ
    end
    
    methods
        function obj = ArtifactRemover(threshold_z)
            if nargin < 1
                threshold_z = 5; % Default clip beyond 5 standard deviations
            end
            obj.ThresholdZ = threshold_z;
        end
        
        function clean_data = process(obj, data)
            clean_data = data;
            [num_channels, ~] = size(data);
            
            for c = 1:num_channels
                sig = data(c, :);
                mu = mean(sig);
                sigma = std(sig);
                
                upper_bound = mu + obj.ThresholdZ * sigma;
                lower_bound = mu - obj.ThresholdZ * sigma;
                
                sig(sig > upper_bound) = upper_bound;
                sig(sig < lower_bound) = lower_bound;
                
                clean_data(c, :) = sig;
            end
        end
    end
end

