setup_project;
config = project_config();

disp('==================================================');
disp('   SINGLE-PATIENT DEMONSTRATION');
disp('==================================================');

download_demo_data();
prepare_dataset();

disp('Training local demonstration model...');
proc_dir = config.processed_dir;
files = dir(fullfile(proc_dir, '*_features.mat'));

if isempty(files)
    error('No processed feature files found.');
end

test_data = load(fullfile(proc_dir, files(1).name));
X = test_data.pat_features;
Y = test_data.pat_labels;

classifier = SeizureClassifier('rf');
classifier = classifier.train(X, Y);

[y_pred, scores] = classifier.predict(X);

tp = TemporalPostProcessor(config);
y_pred_final = tp.process(y_pred);

metrics = MetricsEvaluator.evaluate(Y, y_pred_final, scores);
MetricsEvaluator.print_report(metrics);

% Human understandable output
disp('==================================================');
disp('   PATIENT CONDITION SUMMARY');
disp('==================================================');
num_seizures = sum(diff([0; y_pred_final; 0]) == 1);
if num_seizures > 0
    total_duration = sum(y_pred_final) * config.window_size_sec * (1 - config.overlap_ratio);
    fprintf('The model predicted %d seizure event(s) in this recording.\n', num_seizures);
    fprintf('The total duration of seizure activity was approximately %.0f seconds.\n', total_duration);
    fprintf('The model detected the annotated seizure activity with %.1f%% sensitivity.\n', metrics.Sensitivity * 100);
else
    disp('No seizure activity was detected during this recording.');
end
disp('==================================================');

model = classifier.Model;
test_patient = strrep(files(1).name, '_features.mat', '');
train_patients = {test_patient};
model_save_name = sprintf('LOCAL_%s_%s.mat', 'RF', upper(test_patient));
save(fullfile(config.results_dir, 'models', model_save_name), 'model', 'train_patients', 'test_patient', 'metrics', 'config');

disp('Launching Dashboard...');
app = EEGSeizureAnalyzer();

