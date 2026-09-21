function test_detection()
    disp('Testing Temporal Post Processor...');
    cfg = project_config();
    cfg.consecutive_windows = 3;
    cfg.refractory_period_sec = 6;
    cfg.window_size_sec = 4;
    cfg.overlap_ratio = 0.5; % 2s step
    
    tp = TemporalPostProcessor(cfg);
    
    % Raw predictions
    raw = [0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0]';
    final = tp.process(raw);
    
    % The single 1 at index 2 should be 0.
    % The 1,1,1 at indices 4,5,6 should become 1 at index 6.
    % The 1,1,1 at indices 8,9,10 should fall in refractory (6s = 3 steps) after index 6 ends at 7.
    
    assert(final(2) == 0, 'Failed to suppress isolated prediction');
    assert(final(6) == 1, 'Failed to trigger on consecutive');
    
    disp('Temporal Post Processor test passed.');
end

