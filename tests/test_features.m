function test_features()
    disp('Testing Feature Extractor...');
    cfg = project_config();
    feat = FeatureExtractor(cfg);
    
    fs = cfg.fs;
    data = randn(2, fs * 10); % 2 channels, 10 seconds
    
    [f_mat, t_stamps] = feat.extract(data);
    
    % Windows: 10s total, 4s window, 2s step -> windows at [0,4], [2,6], [4,8], [6,10] = 4 windows
    assert(size(f_mat, 1) == 4, 'Incorrect number of windows');
    % Features: 2 channels * 12 features = 24 features
    assert(size(f_mat, 2) == 24, 'Incorrect number of features');
    
    assert(size(t_stamps, 2) == 2, 'Timestamps should be Nx2');
    
    % Test labeling logic
    % Windows:
    % 1: 0 - 4
    % 2: 2 - 6
    % 3: 4 - 8
    % 4: 6 - 10
    
    % Seizure from 3.5 to 5.5 (duration 2s)
    seizures = [3.5 5.5];
    labels = feat.create_labels(t_stamps, seizures);
    
    % w1: 0-4. Overlap is 3.5-4 (0.5s). 0.5/4 = 0.125 < 0.5 -> 0
    % w2: 2-6. Overlap is 3.5-5.5 (2.0s). 2.0/4 = 0.5 >= 0.5 -> 1
    % w3: 4-8. Overlap is 4-5.5 (1.5s). 1.5/4 = 0.375 < 0.5 -> 0
    % w4: 6-10. Overlap is 0s -> 0
    
    assert(labels(1) == 0, 'Label 1 failed');
    assert(labels(2) == 1, 'Label 2 failed');
    assert(labels(3) == 0, 'Label 3 failed');
    assert(labels(4) == 0, 'Label 4 failed');
    
    disp('Feature extraction and overlap labeling tests passed.');
end

