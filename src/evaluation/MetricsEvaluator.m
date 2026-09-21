classdef MetricsEvaluator
    % METRICSEVALUATOR Calculates clinical and ML performance metrics
    
    methods(Static)
        function metrics = evaluate(y_true, y_pred, scores, duration_hours)
            tp = sum((y_true == 1) & (y_pred == 1));
            tn = sum((y_true == 0) & (y_pred == 0));
            fp = sum((y_true == 0) & (y_pred == 1));
            fn = sum((y_true == 1) & (y_pred == 0));
            
            sensitivity = tp / (tp + fn + 1e-10);
            specificity = tn / (tn + fp + 1e-10);
            precision = tp / (tp + fp + 1e-10);
            f1 = 2 * (precision * sensitivity) / (precision + sensitivity + 1e-10);
            balanced_acc = (sensitivity + specificity) / 2;
            
            % False alarm rate (alarms per hour).
            % We estimate alarms by finding rising edges in y_pred outside of true seizure
            false_alarms = 0;
            in_fa = false;
            for i = 1:length(y_pred)
                if y_pred(i) == 1 && y_true(i) == 0
                    if ~in_fa
                        false_alarms = false_alarms + 1;
                        in_fa = true;
                    end
                else
                    in_fa = false;
                end
            end
            
            if nargin < 4, duration_hours = length(y_pred) * 2 / 3600; end % rough approx if step is 2s
            
            fah = false_alarms / duration_hours;
            
            % AUC (Requires ML toolbox)
            try
                [~,~,~,auc] = perfcurve(y_true, scores, 1);
            catch
                auc = NaN;
            end
            
            metrics = struct('Sensitivity', sensitivity, 'Specificity', specificity, ...
                             'Precision', precision, 'F1', f1, ...
                             'BalancedAcc', balanced_acc, 'FAH', fah, 'AUC', auc, ...
                             'Confusion', [tn, fp; fn, tp]);
        end
        
        function print_report(metrics)
            fprintf('\n--- Performance Report ---\n');
            fprintf('Sensitivity: %.2f%%\n', metrics.Sensitivity * 100);
            fprintf('Specificity: %.2f%%\n', metrics.Specificity * 100);
            fprintf('Precision: %.2f%%\n', metrics.Precision * 100);
            fprintf('F1-Score: %.2f%%\n', metrics.F1 * 100);
            fprintf('AUC: %.2f\n', metrics.AUC);
            fprintf('False Alarms / Hour: %.2f\n', metrics.FAH);
            fprintf('--------------------------\n\n');
        end
    end
end

