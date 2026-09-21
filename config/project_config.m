function config = project_config()
    % PROJECT_CONFIG Returns a struct with all configurable project parameters
    
    config = struct();
    root_dir = fileparts(fileparts(mfilename('fullpath')));
    
    % --- Dataset Configuration ---
    config.fs = 256; % Sampling frequency in Hz
    config.data_dir = fullfile(root_dir, 'data', 'raw');
    config.processed_dir = fullfile(root_dir, 'data', 'processed');
    config.results_dir = fullfile(root_dir, 'results');
    
    % --- Preprocessing ---
    config.filter_low = 0.5;   % Hz
    config.filter_high = 70;   % Hz
    config.notch_freq = 60;    % Hz
    config.filter_order = 4;
    
    % --- Feature Extraction ---
    config.window_size_sec = 4;
    config.overlap_ratio = 0.5; % 50% overlap
    config.seizure_overlap_threshold = 0.5; % 50% temporal overlap required
    config.bands = struct('delta', [0.5 4], 'theta', [4 8], 'alpha', [8 13], 'beta', [13 30], 'gamma', [30 70]);
    config.wavelet_name = 'db4';
    config.wavelet_level = 4;
    
    % --- Detection (Post-processing) ---
    config.consecutive_windows = 3; 
    config.refractory_period_sec = 30; 
    
    config.standard_channels = {'FP1-F7', 'F7-T7', 'T7-P7', 'P7-O1', 'FP1-F3', 'F3-C3', 'C3-P3', 'P3-O1', ...
                                'FP2-F4', 'F4-C4', 'C4-P4', 'P4-O2', 'FP2-F8', 'F8-T8', 'T8-P8', 'P8-O2', ...
                                'FZ-CZ', 'CZ-PZ'};
end

