function prepare_dataset()
    % PREPARE_DATASET Extracts features from all available real EDF files
    
    config = project_config();
    raw_dir = config.data_dir;
    proc_dir = config.processed_dir;
    
    % Find all patients
    patients = dir(raw_dir);
    patients = patients([patients.isdir] & ~startsWith({patients.name}, '.'));
    
    if isempty(patients)
        disp('ERROR: No patient data found in data/raw/');
        disp('Please run download_demo_data() to fetch a sample, or download the full CHB-MIT dataset.');
        return;
    end
    
    loader = EDFLoader(raw_dir);
    prep = EEGPreprocessor(config);
    art = ArtifactRemover();
    extractor = FeatureExtractor(config);
    
    disp('Starting real feature extraction across available dataset...');
    
    for p = 1:length(patients)
        pat_id = patients(p).name;
        pat_dir = fullfile(raw_dir, pat_id);
        
        edfs = dir(fullfile(pat_dir, '*.edf'));
        summary_file = fullfile(pat_dir, [pat_id '-summary.txt']);
        
        if isempty(edfs)
            continue;
        end
        
        disp(['Processing patient: ' pat_id]);
        
        % We will accumulate all features for this patient
        pat_features = [];
        pat_labels = [];
        pat_metadata = struct('pat_id', {}, 'file_id', {}, 'window_start', {}, 'window_end', {}, 'label', {});
        
        for e = 1:length(edfs)
            edf_name = edfs(e).name;
            edf_path = fullfile(pat_dir, edf_name);
            
            disp(['  -> ' edf_name]);
            
            try
                [eeg_data, fs, channels] = loader.load_eeg(edf_path);
                
                % Standardize channels
                [valid_data, valid_channels] = standardize_channels(eeg_data, channels, config.standard_channels);
                
                % Parse annotations
                seizures = loader.parse_annotations(summary_file, edf_name);
                
                % Preprocess
                clean_data = prep.process(valid_data);
                clean_data = art.process(clean_data);
                
                % Extract Features
                [f_mat, t_stamps] = extractor.extract(clean_data);
                labels = extractor.create_labels(t_stamps, seizures);
                
                pat_features = [pat_features; f_mat];
                pat_labels = [pat_labels; labels];
                
                % Build metadata
                for w = 1:size(t_stamps, 1)
                    w_start = t_stamps(w, 1);
                    w_end = t_stamps(w, 2);
                    pat_metadata(end+1) = struct('pat_id', pat_id, 'file_id', edf_name, ...
                                                 'window_start', w_start, 'window_end', w_end, 'label', labels(w));
                end
                
            catch ex
                warning('Failed to process %s: %s', edf_name, ex.message);
            end
        end
        
        % Save patient-level processed data
        if ~isempty(pat_features)
            save(fullfile(proc_dir, [pat_id '_features.mat']), 'pat_features', 'pat_labels', 'pat_metadata', 'valid_channels', '-v7.3');
        end
    end
    
    disp('Feature extraction complete. Data saved to data/processed/');
end

function [valid_data, valid_channels] = standardize_channels(eeg_data, channels, std_channels)
    % Extracts the common standard channels, handling CHB-MIT naming quirks
    valid_data = zeros(length(std_channels), size(eeg_data, 2));
    valid_channels = std_channels;
    
    for i = 1:length(std_channels)
        target = std_channels{i};
        idx = find(strcmpi(channels, target));
        if isempty(idx)
            idx = find(startsWith(channels, target, 'IgnoreCase', true), 1);
        end
        
        if ~isempty(idx)
            valid_data(i, :) = eeg_data(idx(1), :);
        else
            warning('Channel %s not found. Padding with zeros.', target);
        end
    end
end

