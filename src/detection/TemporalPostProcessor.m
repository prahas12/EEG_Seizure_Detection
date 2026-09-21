classdef TemporalPostProcessor
    % TEMPORALPOSTPROCESSOR Applies temporal rules to predictions
    
    properties
        ConsecutiveWindows
        RefractoryPeriodSec
        WindowStepSec
    end
    
    methods
        function obj = TemporalPostProcessor(config)
            obj.ConsecutiveWindows = config.consecutive_windows;
            obj.RefractoryPeriodSec = config.refractory_period_sec;
            % step = size - overlap
            obj.WindowStepSec = config.window_size_sec * (1 - config.overlap_ratio);
        end
        
        function final_preds = process(obj, raw_preds)
            final_preds = zeros(size(raw_preds));
            consecutive_count = 0;
            refractory_steps = round(obj.RefractoryPeriodSec / obj.WindowStepSec);
            refractory_counter = 0;
            
            for i = 1:length(raw_preds)
                if refractory_counter > 0
                    refractory_counter = refractory_counter - 1;
                    continue;
                end
                
                if raw_preds(i) == 1
                    consecutive_count = consecutive_count + 1;
                    if consecutive_count >= obj.ConsecutiveWindows
                        final_preds(i) = 1;
                        % Assuming seizure continues as long as raw_pred=1
                        % If it stops, enter refractory
                    end
                else
                    if consecutive_count >= obj.ConsecutiveWindows
                        % Seizure just ended
                        refractory_counter = refractory_steps;
                    end
                    consecutive_count = 0;
                end
            end
        end
    end
end

