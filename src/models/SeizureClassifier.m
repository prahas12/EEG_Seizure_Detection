classdef SeizureClassifier
    % SEIZURECLASSIFIER Wrapper for training and predicting seizures
    
    properties
        Model
        ModelType
    end
    
    methods
        function obj = SeizureClassifier(model_type)
            if nargin < 1, model_type = 'rf'; end
            obj.ModelType = lower(model_type);
        end
        
        function obj = train(obj, X, Y)
            disp(['Training ' obj.ModelType '...']);
            
            % Handle class imbalance by undersampling majority class (0)
            idx_pos = find(Y == 1);
            idx_neg = find(Y == 0);
            
            if isempty(idx_pos)
                warning('No positive samples found in training data.');
                obj.Model = [];
                return;
            end
            
            % Balance the dataset 1:3 ratio
            num_neg_to_keep = min(length(idx_neg), length(idx_pos) * 3);
            idx_neg_sampled = randsample(idx_neg, num_neg_to_keep);
            
            X_bal = [X(idx_pos, :); X(idx_neg_sampled, :)];
            Y_bal = [Y(idx_pos); Y(idx_neg_sampled)];
            
            switch obj.ModelType
                case 'svm'
                    obj.Model = fitcsvm(X_bal, Y_bal, 'Standardize', true, 'KernelFunction', 'rbf');
                case 'rf'
                    obj.Model = TreeBagger(50, X_bal, Y_bal, 'Method', 'classification');
                case 'knn'
                    obj.Model = fitcknn(X_bal, Y_bal, 'NumNeighbors', 5, 'Standardize', true);
                otherwise
                    error('Unknown model type');
            end
        end
        
        function [predictions, scores] = predict(obj, X)
            if isempty(obj.Model)
                predictions = zeros(size(X, 1), 1);
                scores = zeros(size(X, 1), 1);
                return;
            end
            
            switch obj.ModelType
                case 'svm'
                    [predictions, score_mat] = predict(obj.Model, X);
                    scores = score_mat(:, 2);
                case 'rf'
                    [pred_str, score_mat] = predict(obj.Model, X);
                    predictions = str2double(pred_str);
                    scores = score_mat(:, 2);
                case 'knn'
                    [predictions, score_mat] = predict(obj.Model, X);
                    scores = score_mat(:, 2);
            end
        end
    end
end

