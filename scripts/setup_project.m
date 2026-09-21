function setup_project()
    % SETUP_PROJECT Initializes the MATLAB environment for the project
    
    disp('Initializing EEG Seizure Detection Project...');
    
    % Add project paths
    root_dir = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root_dir, 'src', 'data'));
    addpath(fullfile(root_dir, 'src', 'preprocessing'));
    addpath(fullfile(root_dir, 'src', 'features'));
    addpath(fullfile(root_dir, 'src', 'models'));
    addpath(fullfile(root_dir, 'src', 'detection'));
    addpath(fullfile(root_dir, 'src', 'evaluation'));
    addpath(fullfile(root_dir, 'src', 'visualization'));
    addpath(fullfile(root_dir, 'config'));
    addpath(fullfile(root_dir, 'scripts'));
    addpath(fullfile(root_dir, 'app'));
    
    % Check required toolboxes
    v = ver;
    installed_toolboxes = {v.Name};
    required_toolboxes = {'Signal Processing Toolbox', 'Statistics and Machine Learning Toolbox', 'Wavelet Toolbox'};
    
    all_passed = true;
    for i = 1:length(required_toolboxes)
        if ~ismember(required_toolboxes{i}, installed_toolboxes)
            warning('Missing Toolbox: %s', required_toolboxes{i});
            all_passed = false;
        end
    end
    
    if all_passed
        disp('All required toolboxes are installed.');
    else
        disp('Warning: Some toolboxes are missing. Certain features may not work.');
    end
    
    disp('Setup complete.');
end

