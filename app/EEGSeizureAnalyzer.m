classdef EEGSeizureAnalyzer < handle
    properties
        UIFigure
        EEGData
        FS
        Channels
        CurrentChannel = 1
        TimeVector
        PredictedSeizures
        TrueSeizures
        Seizures
        SignalAxes
        SpecAxes
        BandAxes
        StatusLabel
        PerfTextArea
        PatientDropdown
        RecordingDropdown
        LoadBtn
        RunBtn
        ChannelDropdown
        ModelDropdown
        EvalModeDropdown
        Config
    end
    
    methods
        function obj = EEGSeizureAnalyzer()
            obj.Config = project_config();
            obj.create_ui();
            obj.populate_patients();
        end
        
        function create_ui(obj)
            obj.UIFigure = uifigure('Name', 'EEG Seizure Analysis System', 'Position', [100, 100, 1200, 750]);
            g = uigridlayout(obj.UIFigure, [4, 3]);
            g.RowHeight = {'1x', '1x', '1x', '0.5x'};
            g.ColumnWidth = {'1x', '1x', '0.5x'};
            
            obj.SignalAxes = uiaxes(g);
            obj.SignalAxes.Layout.Row = 1;
            obj.SignalAxes.Layout.Column = [1 2];
            title(obj.SignalAxes, 'EEG Signal View');
            
            obj.SpecAxes = uiaxes(g);
            obj.SpecAxes.Layout.Row = 2;
            obj.SpecAxes.Layout.Column = [1 2];
            title(obj.SpecAxes, 'Spectral Analysis');
            
            obj.BandAxes = uiaxes(g);
            obj.BandAxes.Layout.Row = 3;
            obj.BandAxes.Layout.Column = [1 2];
            title(obj.BandAxes, 'Relative EEG Band Power');
            
            ctrl_pnl = uipanel(g, 'Title', 'Controls');
            ctrl_pnl.Layout.Row = [1 2];
            ctrl_pnl.Layout.Column = 3;
            
            cg = uigridlayout(ctrl_pnl, [12, 1]);
            
            uilabel(cg, 'Text', 'Patient:');
            obj.PatientDropdown = uidropdown(cg, 'Items', {'Select'}, 'ValueChangedFcn', @(dd, event) obj.populate_recordings());
            
            uilabel(cg, 'Text', 'Recording:');
            obj.RecordingDropdown = uidropdown(cg, 'Items', {'Select'});
            
            obj.LoadBtn = uibutton(cg, 'Text', 'Load EDF', 'ButtonPushedFcn', @(btn, event) obj.load_data());
            
            uilabel(cg, 'Text', 'Channel:');
            obj.ChannelDropdown = uidropdown(cg, 'Items', {'Select Data First'}, 'ValueChangedFcn', @(dd, event) obj.change_channel());
            
            uilabel(cg, 'Text', 'Eval Mode:');
            obj.EvalModeDropdown = uidropdown(cg, 'Items', {'Single-patient demonstration', 'Patient-independent evaluation'});
            
            uilabel(cg, 'Text', 'Model:');
            obj.ModelDropdown = uidropdown(cg, 'Items', {'RF', 'SVM', 'KNN'});
            
            obj.RunBtn = uibutton(cg, 'Text', 'Run Analysis', 'ButtonPushedFcn', @(btn, event) obj.run_analysis());
            obj.RunBtn.Enable = 'off';
            
            obj.StatusLabel = uilabel(cg, 'Text', 'Status: Idle');
            
            perf_pnl = uipanel(g, 'Title', 'Performance');
            perf_pnl.Layout.Row = 3;
            perf_pnl.Layout.Column = 3;
            
            obj.PerfTextArea = uitextarea(perf_pnl, 'Position', [10 10 180 120]);
            obj.PerfTextArea.Value = {'Run analysis...'};
        end
        
        function populate_patients(obj)
            patients = dir(obj.Config.data_dir);
            patients = patients([patients.isdir] & ~startsWith({patients.name}, '.'));
            
            if ~isempty(patients)
                obj.PatientDropdown.Items = {patients.name};
                obj.populate_recordings();
                
                if length(patients) < 2
                    obj.EvalModeDropdown.Value = 'Single-patient demonstration';
                    obj.EvalModeDropdown.Enable = 'off';
                else
                    obj.EvalModeDropdown.Enable = 'on';
                end
            else
                obj.PatientDropdown.Items = {'No data found'};
            end
        end
        
        function populate_recordings(obj)
            pat = obj.PatientDropdown.Value;
            if strcmp(pat, 'No data found'), return; end
            
            recs = dir(fullfile(obj.Config.data_dir, pat, '*.edf'));
            if ~isempty(recs)
                obj.RecordingDropdown.Items = {recs.name};
            else
                obj.RecordingDropdown.Items = {'No EDFs found'};
            end
        end
        
        function load_data(obj)
            obj.StatusLabel.Text = 'Status: Loading EDF...'; drawnow;
            try
                pat = obj.PatientDropdown.Value;
                rec = obj.RecordingDropdown.Value;
                
                edf_path = fullfile(obj.Config.data_dir, pat, rec);
                sum_path = fullfile(obj.Config.data_dir, pat, [pat '-summary.txt']);
                
                if ~exist(edf_path, 'file')
                    error('EDF file not found.');
                end
                
                loader = EDFLoader('');
                [obj.EEGData, obj.FS, obj.Channels] = loader.load_eeg(edf_path);
                
                max_len = 3600 * obj.FS;
                if size(obj.EEGData, 2) > max_len
                    obj.EEGData = obj.EEGData(:, 1:max_len);
                end
                
                obj.TimeVector = (0:size(obj.EEGData,2)-1)/obj.FS;
                
                seizures = loader.parse_annotations(sum_path, rec);
                obj.Seizures = seizures;
                obj.TrueSeizures = zeros(1, length(obj.TimeVector));
                for i=1:size(seizures, 1)
                    idx = obj.TimeVector >= seizures(i, 1) & obj.TimeVector <= seizures(i, 2);
                    obj.TrueSeizures(idx) = 1;
                end
                
                obj.ChannelDropdown.Items = obj.Channels;
                obj.CurrentChannel = 1;
                obj.RunBtn.Enable = 'on';
                obj.StatusLabel.Text = 'Status: Data Loaded';
                obj.plot_signal();
            catch e
                uialert(obj.UIFigure, e.message, 'Error');
                obj.StatusLabel.Text = 'Status: Error loading';
            end
        end
        
        function plot_signal(obj)
            plot(obj.SignalAxes, obj.TimeVector, obj.EEGData(obj.CurrentChannel, :));
            hold(obj.SignalAxes, 'on');
            if any(obj.TrueSeizures)
                idx = find(obj.TrueSeizures);
                plot(obj.SignalAxes, obj.TimeVector(idx), obj.EEGData(obj.CurrentChannel, idx), 'r.');
            end
            if ~isempty(obj.PredictedSeizures)
                yl = ylim(obj.SignalAxes);
                idx_p = find(obj.PredictedSeizures);
                plot(obj.SignalAxes, obj.TimeVector(idx_p), repmat(yl(1), 1, length(idx_p)), 'k*', 'MarkerSize', 2);
            end
            hold(obj.SignalAxes, 'off');
        end
        
        function run_analysis(obj)
            obj.StatusLabel.Text = 'Status: Preprocessing...'; drawnow;
            try
                prep = EEGPreprocessor(obj.Config);
                art = ArtifactRemover();
                feat = FeatureExtractor(obj.Config);
                
                valid_data = zeros(length(obj.Config.standard_channels), size(obj.EEGData, 2));
                for i = 1:length(obj.Config.standard_channels)
                    target = obj.Config.standard_channels{i};
                    idx = find(startsWith(obj.Channels, target, 'IgnoreCase', true), 1);
                    if ~isempty(idx)
                        valid_data(i, :) = obj.EEGData(idx(1), :);
                    end
                end
                
                clean = prep.process(valid_data);
                clean = art.process(clean);
                
                obj.StatusLabel.Text = 'Status: Extracting features...'; drawnow;
                [f_mat, t_stamps] = feat.extract(clean);
                
                model_type = upper(obj.ModelDropdown.Value);
                pat = obj.PatientDropdown.Value;
                eval_mode = obj.EvalModeDropdown.Value;
                
                if strcmp(eval_mode, 'Single-patient demonstration')
                    model_file = fullfile(obj.Config.results_dir, 'models', sprintf('LOCAL_%s_%s.mat', model_type, upper(pat)));
                else
                    model_file = fullfile(obj.Config.results_dir, 'models', sprintf('LOPO_%s_TEST_%s.mat', model_type, upper(pat)));
                end
                
                if ~exist(model_file, 'file')
                    obj.StatusLabel.Text = 'MODEL NOT TRAINED';
                    uialert(obj.UIFigure, ['Model not trained for this patient in ' eval_mode '. Please run the corresponding experiment first.'], 'MODEL NOT TRAINED');
                    return;
                end
                
                obj.StatusLabel.Text = 'Status: Predicting...'; drawnow;
                mod_data = load(model_file);
                
                if strcmp(eval_mode, 'Patient-independent evaluation')
                    if ~strcmpi(mod_data.test_patient, pat) || any(strcmpi(mod_data.train_patients, pat))
                        obj.StatusLabel.Text = 'INVALID LOPO MODEL';
                        uialert(obj.UIFigure, 'Invalid patient-independent model. The model was trained with the test patient included.', 'INVALID MODEL');
                        return;
                    end
                end
                
                [pred_str, scores] = predict(mod_data.model, f_mat);
                
                if iscell(pred_str)
                    preds = str2double(pred_str);
                else
                    preds = pred_str;
                end
                
                tp = TemporalPostProcessor(obj.Config);
                f_preds = tp.process(preds);
                
                obj.PredictedSeizures = interp1(t_stamps(:, 2), f_preds, obj.TimeVector, 'nearest', 0);
                obj.plot_signal();
                
                [s,f,t] = spectrogram(clean(obj.CurrentChannel,:), round(obj.Config.fs*2), round(obj.Config.fs*1), 256, obj.Config.fs);
                imagesc(obj.SpecAxes, t, f, 10*log10(abs(s)+1e-6));
                obj.SpecAxes.YDir = 'normal';
                ylim(obj.SpecAxes, [0 70]);
                
                num_features_per_channel = 12;
                offset = (obj.CurrentChannel - 1) * num_features_per_channel;
                bands_idx = offset + [6, 7, 8, 9, 10];
                
                plot(obj.BandAxes, t_stamps(:, 2), f_mat(:, bands_idx)); 
                title(obj.BandAxes, 'Relative EEG Band Power');
                xlabel(obj.BandAxes, 'Time (s)');
                ylabel(obj.BandAxes, 'Relative Power');
                legend(obj.BandAxes, {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'}, 'Location', 'best');
                
                obj.StatusLabel.Text = 'Status: Analysis Complete';
                
                true_win_labels = feat.create_labels(t_stamps, obj.Seizures);
                
                % Use actual scores for GUI eval
                % RF returns [Nx2] directly from MATLAB's predict if mod_data.model is the raw TreeBagger
                if size(scores, 2) > 1
                    eval_scores = scores(:, 2);
                else
                    eval_scores = scores;
                end
                
                mets = MetricsEvaluator.evaluate(true_win_labels, f_preds, eval_scores);
                
                train_str = strjoin(mod_data.train_patients, ', ');
                
                obj.PerfTextArea.Value = {
                    sprintf('Evaluation mode:'),
                    sprintf('%s', eval_mode),
                    '',
                    sprintf('Patient: %s', upper(pat)),
                    sprintf('Training: %s', upper(train_str)),
                    sprintf('Testing: %s', upper(pat)),
                    '',
                    sprintf('Sens: %.1f%%', mets.Sensitivity*100),
                    sprintf('Spec: %.1f%%', mets.Specificity*100),
                    sprintf('F1: %.1f%%', mets.F1*100),
                    sprintf('FA/h: %.2f', mets.FAH)
                };
            catch e
                 uialert(obj.UIFigure, e.message, 'Error');
                 obj.StatusLabel.Text = 'Status: Error';
            end
        end
        
        function change_channel(obj)
            idx = find(strcmp(obj.Channels, obj.ChannelDropdown.Value));
            if ~isempty(idx)
                obj.CurrentChannel = idx;
                obj.plot_signal();
            end
        end
    end
end

