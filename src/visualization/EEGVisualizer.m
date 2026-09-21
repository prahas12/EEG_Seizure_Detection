classdef EEGVisualizer
    % EEGVISUALIZER Helper for generating publication-quality figures
    
    methods(Static)
        function plot_spectrogram(signal, fs)
            figure('Name', 'Spectrogram');
            [s, f, t] = spectrogram(signal, round(fs*2), round(fs*1), 256, fs);
            imagesc(t, f, 10*log10(abs(s)+1e-6));
            axis xy;
            ylim([0 70]);
            xlabel('Time (s)');
            ylabel('Frequency (Hz)');
            title('EEG Spectrogram');
            colorbar;
        end
        
        function plot_wavelet_scalogram(signal, fs)
            % Requires Wavelet Toolbox (cwt)
            try
                figure('Name', 'Wavelet Scalogram');
                cwt(signal, fs);
                title('Continuous Wavelet Transform');
            catch
                disp('Wavelet toolbox missing or error in CWT.');
            end
        end
        
        function plot_multichannel(data, fs, channels, offset)
            if nargin < 4, offset = 100; end
            num_channels = min(10, size(data, 1));
            t = (0:size(data,2)-1)/fs;
            figure('Name', 'Multi-channel EEG');
            hold on;
            for i = 1:num_channels
                plot(t, data(i,:) + (num_channels-i)*offset, 'k');
            end
            yticks((0:num_channels-1)*offset);
            yticklabels(flip(channels(1:num_channels)));
            xlabel('Time (s)');
            title('Multi-channel EEG');
            hold off;
        end
    end
end

