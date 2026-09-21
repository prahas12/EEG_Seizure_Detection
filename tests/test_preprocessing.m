function test_preprocessing()
    disp('Testing EEG Preprocessor...');
    cfg = project_config();
    prep = EEGPreprocessor(cfg);
    
    fs = cfg.fs;
    t = 0:1/fs:1-1/fs;
    
    % Signal with 10Hz, 60Hz noise, and DC drift
    raw_sig = 5 * sin(2*pi*10*t) + 10 * sin(2*pi*60*t) + 20 * t;
    
    clean_sig = prep.process(raw_sig);
    
    % 60Hz should be gone, DC should be gone.
    [pxx, f] = pwelch(clean_sig, [], [], [], fs);
    power_60 = bandpower(pxx, f, [59 61], 'psd');
    
    assert(power_60 < 1, 'Notch filter failed');
    disp('Preprocessing test passed.');
end

