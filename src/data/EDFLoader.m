classdef EDFLoader
    % EDFLOADER Handles loading of EEG data and parsing annotations
    
    properties
        DataDir
    end
    
    methods
        function obj = EDFLoader(data_dir)
            obj.DataDir = data_dir;
        end
        
        function [eeg_data, fs, channels] = load_eeg(~, filepath)
            % LOAD_EEG Loads EEG data from EDF or MAT files
            [~, ~, ext] = fileparts(filepath);
            
            if strcmpi(ext, '.edf')
                try
                    % requires edfread from modern MATLAB
                    warning('off', 'signal:edfread:SignalLabelsNotUnique');
                    info = edfinfo(filepath);
                    tt = edfread(filepath);
                    warning('on', 'signal:edfread:SignalLabelsNotUnique');
                    vars = tt.Variables;
                    if iscell(vars)
                        num_records = size(vars, 1);
                        num_channels = size(vars, 2);
                        samples_per_record = numel(vars{1,1});
                        eeg_data = zeros(num_channels, num_records * samples_per_record);
                        for c = 1:num_channels
                            ch_data = cell2mat(vars(:, c));
                            eeg_data(c, :) = ch_data';
                        end
                    else
                        eeg_data = vars';
                    end
                    channels = info.SignalLabels;
                    fs = info.NumSamples(1) / seconds(info.DataRecordDuration);
                catch e
                    error('Failed to load EDF. Ensure MATLAB is newer than R2020a and Signal Processing Toolbox is installed. Error: %s', e.message);
                end
            elseif strcmpi(ext, '.mat')
                data = load(filepath);
                eeg_data = data.eeg_data;
                fs = data.fs;
                channels = data.channels;
            else
                error('Unsupported file format: %s', ext);
            end
        end
        
        function [seizures] = parse_annotations(~, summary_file, target_filename)
            % PARSE_ANNOTATIONS Parses CHB-MIT summary txt for seizure times
            seizures = [];
            if ~exist(summary_file, 'file')
                return;
            end
            
            fid = fopen(summary_file, 'r');
            file_found = false;
            
            while ~feof(fid)
                line = fgetl(fid);
                if contains(line, 'File Name:') && contains(line, target_filename)
                    file_found = true;
                elseif file_found && contains(line, 'File Name:')
                    % Reached next file
                    break;
                end
                
                if file_found
                    if contains(line, 'Number of Seizures')
                        parts = split(line, ':');
                        num_seizures = str2double(strtrim(parts{2}));
                        if num_seizures == 0
                            break;
                        end
                    end
                    
                    if contains(line, 'Seizure Start Time') || contains(line, 'Seizure') && contains(line, 'Start Time')
                        parts = split(line, ':');
                        time_str = strrep(strtrim(parts{2}), 'seconds', '');
                        start_time = str2double(time_str);
                        
                        % Read next line for end time
                        line2 = fgetl(fid);
                        parts2 = split(line2, ':');
                        time_str2 = strrep(strtrim(parts2{2}), 'seconds', '');
                        end_time = str2double(time_str2);
                        
                        seizures = [seizures; start_time, end_time];
                    end
                end
            end
            fclose(fid);
        end
    end
end

