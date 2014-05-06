

s = RandStream.create('mt19937ar','seed',5494);
RandStream.setGlobalStream(s);

options = [];
options.lambda = 1e-2;
options.gap_threshold = 0.1; % duality gap stopping criterion
options.num_passes = 100; % max number of passes through data
options.do_line_search = 0; % TODO
options.debug = 0; % for displaying more info (makes code about 3x slower)
options.do_weighted_averaging =0;

% Script to run Frank-Wolfe simulation on a fused lasso problem

lambda = 1;
n = 100;
d = 10;
partsize = 5; % The signal Y stays almost put for this many time points at a stretch
nparts = n/partsize;

Y = zeros(d,n);
for i = 1:nparts
    Y(:,(i-1)*partsize+1:i*partsize) = repmat(rand(d,1), 1, partsize) + normrnd(0,0.02, d, partsize); 
end

options.num_passes = 1000000; % max number of passes through data

%taus = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377];
%taus = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89];
taus = [1, 70];
%taus = 1;
times = zeros(size(taus));
epochs = zeros(size(taus));
for i=1:numel(taus)
    options.tau = taus(i)/n;
    options.debug_iter = n/taus(i);
    
    [stats] = solverFWFused( Y, lambda, options );
    
    times(i) = stats.time;
    epochs(i) = stats.k;
    
end

%%
figure
plot(taus(1:end), epochs(1:end),'LineWidth', 2)
xlabel('\tau','FontSize', 16);
ylabel('\tau Epochs', 'FontSize', 16);
title('Variation of number of epochs with \tau','FontSize', 16);

figure
speedups = epochs(1) ./ epochs;
plot(1:1:taus(end), 1:1:taus(end), 'r', taus(1:end), speedups(1:end),'LineWidth', 2)
xlabel('\tau','FontSize', 16);
ylabel(' Speedup', 'FontSize', 16);
title('Speedup with distribution','FontSize', 16);
legend('y=x line', 'speedup')

