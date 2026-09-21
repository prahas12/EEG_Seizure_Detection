classdef PatientIndependentValidator
    methods(Static)
        function [all_metrics] = run_lopo(config, data_dir, model_type)
            if nargin < 3, model_type = 'rf'; end
            
            proc_dir = config.processed_dir;
            files = dir(fullfile(proc_dir, '*_features.mat'));
            
            if isempty(files)
                error('No processed feature files found. Run prepare_dataset first.');
            end
            
            if length(files) < 2
                error('Patient-independent evaluation requires at least two independent patients. Run the local single-patient demonstration or add more CHB-MIT patients.');
            end
            
            disp(['Starting Patient-Independent LOPO Validation for ' upper(model_type)]);
            all_metrics = cell(length(files), 1);
            
            for test_idx = 1:length(files)
                test_pat_file = files(test_idx).name;
                test_patient = strrep(test_pat_file, '_features.mat', '');
                disp(['Fold ' num2str(test_idx) '/' num2str(length(files)) ': Test Patient ' test_patient]);
                
                test_data = load(fullfile(proc_dir, test_pat_file));
                X_test = test_data.pat_features;
                Y_test = test_data.pat_labels;
                
                X_train = [];
                Y_train = [];
                train_patients = {};
                
                for train_idx = 1:length(files)
                    if train_idx == test_idx, continue; end
                    t_data = load(fullfile(proc_dir, files(train_idx).name));
                    X_train = [X_train; t_data.pat_features];
                    Y_train = [Y_train; t_data.pat_labels];
                    train_patients{end+1} = strrep(files(train_idx).name, '_features.mat', '');
                end
                
                classifier = SeizureClassifier(model_type);
                classifier = classifier.train(X_train, Y_train);
                
                [y_pred, scores] = classifier.predict(X_test);
                
                tp = TemporalPostProcessor(config);
                y_pred_final = tp.process(y_pred);
                
                metrics = MetricsEvaluator.evaluate(Y_test, y_pred_final, scores);
                metrics.TestPatient = test_patient;
                all_metrics{test_idx} = metrics;
                
                MetricsEvaluator.print_report(metrics);
                
                model_save_name = sprintf('LOPO_%s_TEST_%s.mat', upper(model_type), upper(test_patient));
                model = classifier.Model;
                save(fullfile(config.results_dir, 'models', model_save_name), 'model', 'train_patients', 'test_patient', 'metrics', 'config');
            end
            
            save(fullfile(config.results_dir, 'metrics', [upper(model_type) '_LOPO_results.mat']), 'all_metrics');
        end
    end
end

