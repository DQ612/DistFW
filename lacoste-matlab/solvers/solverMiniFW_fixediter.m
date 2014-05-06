function [model, progress, stats] = solverBCFW(param, options)
% [model, progress] = solverBCFW(param, options)
%
% Solves the structured support vector machine (SVM) using the block-coordinate
% Frank-Wolfe algorithm, see (Lacoste-Julien, Jaggi, Schmidt, Pletscher; ICML
% 2013) for more details.
% This is Algorithm 4 in the paper, and the code here follows a similar
% notation. Each step of the method calls the decoding oracle (i.e. the 
% loss-augmented predicion) only for a single point.
%
% The structured SVM has the form
% min_{w} 0.5*\lambda*||w||^2+ 1/n*\sum_{i=1}^n H_i(w) [see (3) in paper]
%   where H_i(w) is the structured hinge loss on the i^th example:
%         H_i(w) = max_{y in Y} L(y_i,y) - <w, \psi_i(y)> [(2) in paper]
%
% We use a calling interface very similar to version 1.1 of svm-struct-matlab 
% developped by Andrea Vedaldi (see vedaldi/code/svm-struct-matlab.html).
% svm-struct-matlab is a Matlab wrapper interface to the widely used
% SVM^struct code by Thorsten Joachims (http://svmlight.joachims.org/svm_struct.html) 
% which implements a cutting plane algorithm. See our ICML 2013 paper for
% experiments showing that the convergence per oracle call is much slower
% for SVM^struct than BCFW.
% 
% If your code was using:
%    model = svm_struct_learn(command_args,param)
%
% You can replace it with:
%    model = solverBCFW(param, options)
% 
% with the same param structure and letting options.lambda = 1/C
% to solve the *same* optimization problem. [Make sure your code only 
% uses model.w as we currently don't return the dual variables, etc. in the
% model structure unlike svm-struct-learn].
% 
% Inputs:
%   param: a structure describing the problem with the following fields:
%
%     patterns  -- patterns (x_i)
%         A cell array of patterns (x_i). The entries can have any
%         nature (they can just be indexes of the actual data for
%         example).
%     
%     labels    -- labels (y_i)
%         A cell array of labels (y_i). The entries can have any nature.
%
%     lossFn    -- loss function callback
%         A handle to the loss function L(ytruth, ypredict) defined for 
%         your problem. This function should have a signature of the form:
%           scalar_output = loss(param, ytruth, ypredict) 
%         It will be given an input ytruth, a ground truth label;
%         ypredict, a prediction label; and param, the same structure 
%         passed to solverBCFW.
% 
%     oracleFn  -- loss-augmented decoding callback
%         [Can also be called constraintFn for backward compatibility with
%          code using svm_struct_learn.]
%         A handle to the 'maximization oracle' (equation (2) in paper) 
%         which solves the loss-augmented decoding problem. This function
%         should have a signature of the form:
%           ypredict = decode(param, model, x, y)
%         where x is an input pattern, y is its ground truth label,
%         param is the input param structure to solverBCFW and model is the
%         current model structure (the main field is model.w which contains
%         the parameter vector).
%
%     featureFn  feature map callback
%         A handle to the feature map function \phi(x,y). This function
%         should have a signature of the form:
%           phi_vector = feature(param, x, y)
%         where x is an input pattern, y is an input label, and param 
%         is the usual input param structure. The output should be a vector 
%         of *fixed* dimension d which is the same
%         across all calls to the function. The parameter vector w will
%         have the same dimension as this feature map. In our current
%         implementation, w is sparse if phi_vector is sparse.
% 
%  options:    (an optional) structure with some of the following fields to
%              customize the behavior of the optimization algorithm:
% 
%   lambda      The regularization constant (default: 1/n).
%
%   gap_threshold **STOPPING CRITERION**
%               Stop the algorithm once the duality gap falls below this
%               threshold. Use gap_check to control how often the gap is
%               checked. Note that the default of 0.1 is equivalent
%               to the criterion used in svm_struct_learn Matlab wrapper.
%               (default: 0.1).
%               
%   gap_check   Gives the number of passes through data between each check of the 
%               duality gap (put 0 to turn it off). 
%               I.e. every gap_check passes through the data,
%               the algorithm do a batch pass through the data to compute
%               the duality gap. [A feature to implement in the future is
%               to do a batch FW step if the gap_threshold hasn't been met 
%               yet to avoid wasting this computation.] This slows down the
%               code roughly by a factor of (100/gap_check) %.
%               (default: 10)
%
%   num_passes  Maximum number of passes through the data before the 
%               algorithm stops (default: 200)
%
%   debug       Boolean flag whether to track the primal objective, dual
%               objective, and training error (makes the code about 3x
%               slower given the extra two passes through data).
%               (default: 0)
%   do_linesearch
%               Boolean flag whether to use line-search. (default: 1)
%   do_weighted_averaging
%               Boolean flag whether to use weighted averaging of the iterates.
%               *Recommended -- it made a big difference in test error in
%               our experiments.*
%               (default: 1)
%   time_budget Number of minutes after which the algorithm should terminate.
%               Useful if the solver is run on a cluster with some runtime
%               limits. (default: inf)
%   rand_seed   Optional seed value for the random number generator.
%               (default: 1)
%   sample      Sampling strategy for example index, either a random permutation
%               ('perm') or uniform sampling ('uniform').
%               [Note that our convergence rate proof only holds for uniform
%               sampling, not for a random permutation.]
%               (default: 'uniform')
%   debug_multiplier
%               If set to 0, the algorithm computes the objective after each full
%               pass trough the data. If in (0,100) logging happens at a
%               geometrically increasing sequence of iterates, thus allowing for
%               within-iteration logging. The smaller the number, the more
%               costly the computations will be!
%               (default: 0)
%   test_data   Struct with two fields: patterns and labels, which are cell
%               arrays of the same form as the training data. If provided the
%               logging will also evaluate the test error.
%               (default: [])
%   tau         
%
% Outputs:
%   model       model.w contains the parameters;
%               model.ell contains b'*alpha which is useful to compute
%               duality gap, etc.
%   progress    Primal objective, duality gap etc as the algorithm progresses,
%               can be used to visualize the convergence.
%
% Authors: Simon Lacoste-Julien, Martin Jaggi, Mark Schmidt, Patrick Pletscher
% Web: https://github.com/ppletscher/BCFWstruct
%
% Relevant Publication:
%       S. Lacoste-Julien, M. Jaggi, M. Schmidt, P. Pletscher,
%       Block-Coordinate Frank-Wolfe Optimization for Structural SVMs,
%       International Conference on Machine Learning, 2013.

% == getting the problem description:
phi = param.featureFn; % for \phi(x,y) feature mapping
loss = param.lossFn; % for L(ytruth, ypred) loss function
if isfield(param, 'constraintFn')
    % for backward compatibility with svm-struct-learn
    maxOracle = param.constraintFn;
else
    maxOracle = param.oracleFn; % loss-augmented decoding function
end

patterns = param.patterns; % {x_i} cell array
labels = param.labels; % {y_i} cell array
n = length(patterns); % number of training examples

% == parse the options
options_default = defaultOptions(n);
if (nargin >= 2)
    options = processOptions(options, options_default);
else
    options = options_default;
end

% general initializations
lambda = options.lambda;
phi1 = phi(param, patterns{1}, labels{1}); % use first example to determine dimension
d = length(phi1); % dimension of feature mapping
using_sparse_features = issparse(phi1);
progress = [];

% === Initialization ===
% set w to zero vector
% (corresponds to setting all the mass of each dual variable block \alpha_(i)
% on the true label y_i coordinate [i.e. \alpha_i(y) =
% Kronecker-delta(y,y_i)] using notation from Appendix E of paper).

% w: d x 1: store the current parameter iterate
% wMat: d x n matrix, wMat(:,i) is storing w_i (in Alg. 4 notation) for example i.
%    Using implicit dual variable notation, we would have w_i = A \alpha_[i]
%    -- see section 5, "application to the Structural SVM"
if using_sparse_features
    model.w = sparse(d,1);
    wMat = sparse(d,n); 
else
    model.w = zeros(d,1);
    wMat = zeros(d,n); 
end

ell = 0; % this is \ell in the paper. Here it is assumed that at the true label, the loss is zero
         % Implicitly, we have ell = b' \alpha
ellMat = zeros(n,1); % ellMat(i) is \ell_i in the paper (implicitly, ell_i = b' \alpha_[i])

if (options.do_weighted_averaging)
    wAvg = model.w; % called \bar w in the paper -- contains weighted average of iterates
    lAvg = 0;
end

% logging
if (options.debug_multiplier == 0)
    debug_iter = n;
    options.debug_multiplier = 100;
else
    debug_iter = 1;
end
progress.primal = [];
progress.dual = [];
progress.eff_pass = [];
progress.train_error = [];
if (isstruct(options.test_data) && isfield(options.test_data, 'patterns'))
    progress.test_error = [];
end

fprintf('running BCFW on %d examples. The options are as follows:\n', length(patterns));
options

rand('state',options.rand_seed);
randn('state',options.rand_seed);
tic();


% === Main loop ====
tau=min(max(1, floor(options.tau * n)),n);
k=0; % same k as in paper
gap_check_counter = 1; % keeps track of how many passes through the data since last duality gap check...
for p=1:options.num_passes

    perm = randperm(n);
    S = perm(1:tau);
    sumw = 0;
    sumell = 0;
    
    w_tilde = model.w; % reference iterate
    model_tilde.w = w_tilde;    
    
    for dummy = 1:tau
        % (each numbered comment correspond to a line in algorithm 4)
        % 1) Picking random example:
        i = S(dummy);
    
        % 2) solve the loss-augmented inference for point i
        % the workers have the reference w only
        ystar_i = maxOracle(param, model_tilde, patterns{i}, labels{i});
                
        % 3) define the update quantities:
        % [note that lambda*w_s is subgradient of 1/n*H_i(w) ]
        % psi_i(y) := phi(x_i,y_i) - phi(x_i, y)
        psi_i =   phi(param, patterns{i}, labels{i}) ...
                - phi(param, patterns{i}, ystar_i);
        w_s = 1/(n*lambda) * psi_i;
        loss_i = loss(param, labels{i}, ystar_i);
        ell_s = 1/n*loss_i;

        % sanity check, if this assertion fails, probably there is a bug in the
        % maxOracle or in the featuremap
        assert((loss_i - w_tilde'*psi_i) >= -1e-12);  
    
        % 4) get the step-size gamma:        
        gamma = 2*n*tau/(k*tau^2 +2*n);
        
        % 5-6-7-8) finally update the weights and ell variables
        % workers send w_s, ell_s to server and server computes
        % w^{k+1}_i and l^{k+1}_i and finally w^{k+1} as follows
        model.w = model.w - wMat(:,i); % this is w^(k)-w_i^(k)
        wMat(:,i) = (1-gamma)*wMat(:,i) + gamma*w_s;
        model.w = model.w + wMat(:,i); % this is w^(k+1) = w^(k)-w_i^(k)+w_i^(k+1)
        
        ell = ell - ellMat(i); % this is ell^(k)-ell_i^(k)
        ellMat(i) = (1-gamma)*ellMat(i) + gamma*ell_s;
        ell = ell + ellMat(i); % this is ell^(k+1) = ell^(k)-ell_i^(k)+ell_i^(k+1)

    end     
    
    % 9) Optionally, update the weighted average:
    if (options.do_weighted_averaging)
        rho = 2/(k+2); % results in each iterate w^(k) weighted proportional to k
        wAvg = (1-rho)*wAvg + rho*model.w;
        lAvg = (1-rho)*lAvg + rho*ell; % this is required to compute statistics on wAvg -- such as the dual objective
    end

    k=k+1;

    % debug: compute objective and duality gap. do not use this flag for
    % timing the optimization, since it is very costly!
    % (makes the code about 3x slower given the additional 2 passes
    % through the data).
    %if (options.debug &&  mod(k*tau, n) == 0)
    if (options.debug && k >= debug_iter/tau)
        if (options.do_weighted_averaging)
            model_debug.w = wAvg;
            model_debug.ell = lAvg;
        else
            model_debug.w = model.w;
            model_debug.ell = ell;
        end
        f = -objective_function(model_debug.w, model_debug.ell, lambda); % dual value -equation (4)
        gap = duality_gap(param, maxOracle, model_debug, lambda);
        primal = f+gap; % a cheaper alternative to get the primal value
        train_error = average_loss(param, maxOracle, model_debug);
        fprintf('pass %d (iteration %d), SVM primal = %f, SVM dual = %f, duality gap = %f, train_error = %f \n', ...
                         p, k, primal, f, gap, train_error);

        progress.primal = [progress.primal; primal];
        progress.dual = [progress.dual; f];
        progress.eff_pass = [progress.eff_pass; k*tau/n];
        progress.train_error = [progress.train_error; train_error];
        if (isstruct(options.test_data) && isfield(options.test_data, 'patterns'))
            param_debug = param;
            param_debug.patterns = options.test_data.patterns;
            param_debug.labels = options.test_data.labels;
            test_error = average_loss(param_debug, maxOracle, model_debug);
            progress.test_error = [progress.test_error; test_error];
        end

        debug_iter = min(debug_iter+n,ceil(debug_iter*(1+options.debug_multiplier/100))); 
    end

    % time-budget exceeded?
    t_elapsed = toc();
    if (t_elapsed/60 > options.time_budget)
        fprintf('time budget exceeded.\n');
        if (options.do_weighted_averaging)
            model.w = wAvg; % return the averaged version
            model.ell = lAvg;
        else
            model.ell = ell;
        end
        return
    end
    
    % checking duality gap stopping criterion if required:


    if (options.gap_check && gap_check_counter >= options.gap_check)
        gap_check_counter = 0;
        
        % we use the wAvg parameter to compute gap
        if (options.do_weighted_averaging)
            model_debug.w = wAvg;
            model_debug.ell = lAvg;
        else
            model_debug.w = model.w;
            model_debug.ell = ell;
        end
        
        % compute gap:
        gap = duality_gap(param, maxOracle, model_debug, lambda);
        % for later: [gap, w_s, ell_s] = duality_gap(param, maxOracle, model, lambda);

        %%%%%%%%%%%%
        %% Commenting the following out for now --- replace back in later
        %% (in order to do experiments for a fixed number of iterations instead of until-convergence)
        %%%%%%%%%%%%
        %if gap <= options.gap_threshold
            %fprintf('Duality gap below threshold -- stopping!\n')
            %fprintf('current gap: %g, gap_threshold: %g\n', gap, options.gap_threshold)
            %fprintf('Reached after pass: %d (iteration %d).\n', p, k)
            %break % exit loop!
        %else
            %% to implement later: do a batch FW step with w_s & ell_s above
            %fprintf('Duality gap check: gap = %g at pass %d (iteration %d)\n', gap, p, k)
        %end
        %%%%%%%%%%%
        %%% And adding the following line (remove later)
        %%%%%%%%%%%
        fprintf('Duality gap check: gap = %g at pass %d (iteration %d)\n', gap, p, k)

    end % end of gap_check section
    gap_check_counter = gap_check_counter+1;
    
end % end of main loop

if (options.do_weighted_averaging)
    model.w = wAvg; % return the averaged version
    model.ell = lAvg;
else
    model.ell = ell;
end

stats.k = k;
stats.time = toc();


%%%%%%%%%%%%%%%%%%%%%%%
%%%% returning duality gap
if (options.do_weighted_averaging)
    model_debug.w = wAvg;
    model_debug.ell = lAvg;
else
    model_debug.w = model.w;
    model_debug.ell = ell;
end
stats.gap = duality_gap(param, maxOracle, model_debug, lambda)
%%%%%%%%%%%%%%%%%%%%%%%


end % solverBCFW


function options = defaultOptions(n)

options = [];
options.num_passes = 200;
options.do_line_search = 1;
options.do_weighted_averaging = 1;
options.time_budget = inf;
options.debug = 0;
options.rand_seed = 1;
options.sample = 'uniform'; % sampling strategy in {'uniform', 'perm'}
options.debug_multiplier = 0; % 0 corresponds to logging after each full pass
options.lambda = 1/n;
options.test_data = [];
options.gap_threshold = 0.1;
options.gap_check = 10; % this makes the code about 10% slower than if use gap_check = 0
options.tau = 3000;

end % defaultOptions
