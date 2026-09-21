function download_demo_data()
    disp('Checking for real sample data from PhysioNet (chb01_03.edf)...');
    
    root_dir = fileparts(fileparts(mfilename('fullpath')));
    raw_dir = fullfile(root_dir, 'data', 'raw', 'chb01');
    if ~exist(raw_dir, 'dir')
        mkdir(raw_dir);
    end
    
    edf_url = 'https://physionet.org/files/chbmit/1.0.0/chb01/chb01_03.edf';
    edf_file = fullfile(raw_dir, 'chb01_03.edf');
    
    txt_url = 'https://physionet.org/files/chbmit/1.0.0/chb01/chb01-summary.txt';
    txt_file = fullfile(raw_dir, 'chb01-summary.txt');
    
    try
        if ~exist(edf_file, 'file')
            disp(['Downloading ' edf_file ' (~32 MB)...']);
            websave(edf_file, edf_url);
            disp('Downloaded chb01_03.edf successfully.');
        else
            disp('chb01_03.edf already exists. Skipping download.');
        end
        
        if ~exist(txt_file, 'file')
            websave(txt_file, txt_url);
            disp('Downloaded chb01-summary.txt successfully.');
        else
            disp('chb01-summary.txt already exists. Skipping download.');
        end
    catch e
        error('Failed to download demo data. Error: %s', e.message);
    end
end

