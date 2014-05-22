% Applies the structured SVM to the OCR dataset by Ben Taskar. The structured
% model considered here is the standard chain graph, with the pixel values of
% the digit as unary features and a transition matrix of size num_states^2 as
% a pairwise potential. Additionally, we include a unary bias term for the first
% and last symbol in the sequence.
speedups_gap1 = speedups;
clear
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
options.lambda = 1;
options.gap_threshold = 2; % duality gap stopping criterion
options.num_passes = 100; % max number of passes through data
options.do_line_search = 1; % TODO
options.debug = 0; % for displaying more info (makes code about 3x slower)
options.do_weighted_averaging =0;
%% run the solver
%[model, progress] = solverBCFW(param, options);

%%

if (strcmp(data_name, 'ocr'))
    n = 626;
else
    n = 6251;
end

options.num_passes = n*1000; % max number of passes through data

%taus = [1,100,200,300,400];
%taus = [1,2,3,5,8,13,21,34,55,89];%,144,233];
taus = [1,10,50,100, 150, 200, 300, 800, 1600, 3126, n];
for i=1:numel(taus)
    fprintf('tau=%d\n', taus(i))
    options.tau = taus(i)/n;
    options.gap_check = 5*n/taus(i);
    [model, progress, stats] = solverMiniFW(param, options);
    times(i) = stats.time;
    epochs(i) = stats.k;
end
%[model, progress] = solverSSG(param, options);

%%

% figure
% plot(taus, epochs)
% xlabel('\tau','FontSize', 16);
% ylabel('\tau Epochs', 'FontSize', 16);
% title('Variation of number of epochs with \tau','FontSize', 16);
% 
% figure
% datapasses = epochs .* taus/n;
% plot(taus,datapasses);
% xlabel('\tau','FontSize', 16);
% ylabel('Data Passes', 'FontSize', 16);
% title('Variation of # data passes with \tau','FontSize', 16);

% speed-up plot
% figure
speedups = epochs(1) ./ epochs;
plot(taus,taus,taus,speedups);
xlabel('\tau','FontSize', 16);
ylabel('Speedup', 'FontSize', 16);
title('Speedup with distribution','FontSize', 16);



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
% plot(progress.eff_pass, progress.primal, 'r-'); % primal
% hold on;
% plot(progress.eff_pass, progress.dual, 'b--'); % dual
% hold off;
% xlabel('effective passes');
