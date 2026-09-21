classdef FeatureExtractor
    % FEATUREEXTRACTOR Extracts time, frequency, and wavelet features from EEG windows
    
    properties
        FS
        WindowSizeSamples
        OverlapSamples
        Bands
        WaveletName
        WaveletLevel
        Config
    end
    
    methods
        function obj = FeatureExtractor(config)
            obj.FS = config.fs;
            obj.WindowSizeSamples = round(config.window_size_sec * obj.FS);
            obj.OverlapSamples = round(obj.WindowSizeSamples * config.overlap_ratio);
            obj.Bands = config.bands;
            obj.WaveletName = config.wavelet_name;
            obj.WaveletLevel = config.wavelet_level;
            obj.Config = config;
        end
        
        function [features, timestamps] = extract(obj, eeg_data)
            [num_channels, num_samples] = size(eeg_data);
            step_size = obj.WindowSizeSamples - obj.OverlapSamples;
            num_windows = floor((num_samples - obj.WindowSizeSamples) / step_size) + 1;
            
            % Each channel will have ~12 features. Total = num_channels * 12
            num_features_per_channel = 5 + 5 + 2; % 5 time, 5 freq, 2 wavelet
            features = zeros(num_windows, num_channels * num_features_per_channel);
            timestamps = zeros(num_windows, 2); % start and end time
            
            for w = 1:num_windows
                if mod(w, 100) == 0
                    fprintf('Extracting features: Window %d / %d...\n', w, num_windows);
                end
                start_idx = (w-1)*step_size + 1;
                end_idx = start_idx + obj.WindowSizeSamples - 1;
                
                start_time = (start_idx - 1) / obj.FS;
                end_time = end_idx / obj.FS;
                timestamps(w, 1) = start_time;
                timestamps(w, 2) = end_time;
                
                window_data = eeg_data(:, start_idx:end_idx);
                window_features = zeros(1, num_channels * num_features_per_channel);
                
                for c = 1:num_channels
                    sig = window_data(c, :);
                    
                    % 1. Time Domain (5 features)
                    feat_var = var(sig);
                    feat_rms = rms(sig);
                    feat_skew = skewness(sig);
                    feat_kurt = kurtosis(sig);
                    feat_line = sum(abs(diff(sig)));
                    
                    % 2. Frequency Domain (Relative Band Power)
                    [pxx, f] = pwelch(sig, [], [], [], obj.FS);
                    total_power = trapz(f, pxx);
                    if total_power == 0, total_power = 1e-6; end
                    
                    idx_delta = f >= obj.Bands.delta(1) & f <= obj.Bands.delta(2);
                    rp_delta = trapz(f(idx_delta), pxx(idx_delta)) / total_power;
                    
                    idx_theta = f >= obj.Bands.theta(1) & f <= obj.Bands.theta(2);
                    rp_theta = trapz(f(idx_theta), pxx(idx_theta)) / total_power;
                    
                    idx_alpha = f >= obj.Bands.alpha(1) & f <= obj.Bands.alpha(2);
                    rp_alpha = trapz(f(idx_alpha), pxx(idx_alpha)) / total_power;
                    
                    idx_beta = f >= obj.Bands.beta(1) & f <= obj.Bands.beta(2);
                    rp_beta = trapz(f(idx_beta), pxx(idx_beta)) / total_power;
                    
                    idx_gamma = f >= obj.Bands.gamma(1) & f <= obj.Bands.gamma(2);
                    rp_gamma = trapz(f(idx_gamma), pxx(idx_gamma)) / total_power;
                    
                    % 3. Wavelet Domain (Energy & Entropy of approx/detail coeffs)
                    try
                        [C, ~] = wavedec(sig, obj.WaveletLevel, obj.WaveletName);
                        energy = sum(C.^2);
                        prob = (C.^2) / energy;
                        prob(prob == 0) = 1e-10;
                        entropy = -sum(prob .* log2(prob));
                    catch
                        energy = 0; entropy = 0;
                    end
                    
                    % Concatenate
                    ch_feats = [feat_var, feat_rms, feat_skew, feat_kurt, feat_line, ...
                                rp_delta, rp_theta, rp_alpha, rp_beta, rp_gamma, ...
                                energy, entropy];
                    
                    start_feat = (c-1)*num_features_per_channel + 1;
                    end_feat = c*num_features_per_channel;
                    window_features(start_feat:end_feat) = ch_feats;
                end
                
                features(w, :) = window_features;
            end
        end
        
        function labels = create_labels(obj, timestamps, seizures)
            num_windows = size(timestamps, 1);
            labels = zeros(num_windows, 1);
            threshold = obj.Config.seizure_overlap_threshold;
            
            for w = 1:num_windows
                w_start = timestamps(w, 1);
                w_end = timestamps(w, 2);
                w_dur = w_end - w_start;
                
                overlap_dur = 0;
                for i = 1:size(seizures, 1)
                    s_start = seizures(i, 1);
                    s_end = seizures(i, 2);
                    
                    % Calculate intersection
                    o_start = max(w_start, s_start);
                    o_end = min(w_end, s_end);
                    if o_end > o_start
                        overlap_dur = overlap_dur + (o_end - o_start);
                    end
                end
                
                if (overlap_dur / w_dur) >= threshold
                    labels(w) = 1;
                end
            end
        end
    end
end

