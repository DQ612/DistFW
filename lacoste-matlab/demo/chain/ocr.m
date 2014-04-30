% Applies the structured SVM to the OCR dataset by Ben Taskar. The structured
% model considered here is the standard chain graph, with the pixel values of
% the digit as unary features and a transition matrix of size num_states^2 as
% a pairwise potential. Additionally, we include a unary bias term for the first
% and last symbol in the sequence.

addpath(genpath('../../solvers/'));
addpath('helpers');

% We support two different settings for the dataset (ocr: only one fold in
% training set, ocr2: all but one fold in training set
% -- ocr2 is the one that we have used in our experiments in the 
% ICML 2013 paper)
data_name = 'ocr2';
[patterns_train, labels_train, patterns_test, labels_test] = loadOCRData(data_name, '../../data/');

%% == run one of the solvers on the problem

% create problem structure:
param = [];
param.patterns = patterns_train;
param.labels = labels_train;
param.lossFn = @chain_loss;
param.oracleFn = @chain_oracle;
param.featureFn = @chain_featuremap;

% options structure:
options = [];
options.lambda = 1e-2;
options.gap_threshold = 0.1; % duality gap stopping criterion
options.num_passes = 100; % max number of passes through data
options.do_line_search = 0; % TODO
options.debug = 0; % for displaying more info (makes code about 3x slower)
options.do_weighted_averaging =0;
%% run the solver
%[model, progress] = solverBCFW(param, options);

%%
options.num_passes = 1000000; % max number of passes through data
options.tau = 1/626;
%n = 626;
n = 6251;
tau = max(1,n*options.tau);
options.gap_check = 10*n/tau;
taus = [1 5 10 20 40 80 160];

for i=1:numel(taus)
    options.tau = taus(i)/n;    
    options.gap_check = 10*/taus(i);
    [model, progress, stats] = solverMiniFW(param, options);
    times(i) = stats.time;
    epochs(i) = stats.k;    
end
%[model, progress] = solverSSG(param, options);

%%

figure
plot(taus(1:5), epochs(1:5))
xlabel('\tau','FontSize', 16);
ylabel('\tau Epochs', 'FontSize', 16);
title('Variation of number of epochs with \tau','FontSize', 16);

figure
datapasses = epochs .* taus/n;
plot(taus(1:5),datapasses(1:5));
xlabel('\tau','FontSize', 16);
ylabel('Data Passes', 'FontSize', 16);
title('Variation of # data passes with \tau','FontSize', 16);


%% loss on train set
avg_loss = 0;
for i=1:numel(patterns_train)
    ypredict = chain_oracle(param, model, patterns_train{i}); % standard prediction as don't give label as input
    avg_loss = avg_loss + chain_loss(param, labels_train{i}, ypredict);
end
avg_loss = avg_loss / numel(patterns_train);
fprintf('average loss on the training set: %f.\n', avg_loss);

% loss on test set
avg_loss = 0;
for i=1:numel(patterns_test)
    ypredict = chain_oracle(param, model, patterns_test{i});
    avg_loss = avg_loss + chain_loss(param, labels_test{i}, ypredict);
end
avg_loss = avg_loss / numel(patterns_test);
fprintf('average loss on the test set: %f.\n', avg_loss);

% plot the progress of the solver
plot(progress.eff_pass, progress.primal, 'r-'); % primal
hold on;
plot(progress.eff_pass, progress.dual, 'b--'); % dual
hold off;
xlabel('effective passes');
