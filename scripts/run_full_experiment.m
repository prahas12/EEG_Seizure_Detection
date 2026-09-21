setup_project;
config = project_config();

disp('==================================================');
disp('   EEG SEIZURE DETECTION - FULL EXPERIMENT');
disp('==================================================');

patients = dir(config.data_dir);
patients = patients([patients.isdir] & ~startsWith({patients.name}, '.'));

if length(patients) < 2
    disp('Full multi-patient evaluation not executed locally because the complete CHB-MIT dataset is not installed.');
    disp('Please download the dataset from PhysioNet or run run_demo.m instead.');
    return;
end

prepare_dataset;

models = {'rf', 'knn', 'svm'};
all_results = struct();

for m = 1:length(models)
    metrics = PatientIndependentValidator.run_lopo(config, config.data_dir, models{m});
    all_results.(models{m}) = metrics;
end

disp('==================================================');
disp('   FINAL COMPARISON');
disp('==================================================');
for m = 1:length(models)
    disp(['Model: ' upper(models{m})]);
    mets = all_results.(models{m});
    if isempty(mets), continue; end
    avg_sens = mean(cellfun(@(x) x.Sensitivity, mets));
    avg_spec = mean(cellfun(@(x) x.Specificity, mets));
    avg_f1 = mean(cellfun(@(x) x.F1, mets));
    avg_fah = mean(cellfun(@(x) x.FAH, mets));
    fprintf('Avg Sens: %.2f%% | Avg Spec: %.2f%% | Avg F1: %.2f%% | Avg FA/h: %.2f\n', avg_sens*100, avg_spec*100, avg_f1*100, avg_fah);
end

