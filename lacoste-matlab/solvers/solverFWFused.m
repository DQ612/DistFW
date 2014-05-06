function [ stats, u ] = solverFWFused( Y, lambda, options )
%SOLVERFUSED Solves the dual problem of fused lasso using Frank-Wolfe

% Server broadcasts u, waits for \tau updates
% Workers have Y and u

[d, n] = size(Y);
tau=min(max(1, floor(options.tau * (n-1))),n-1);

Yd = zeros(d,n-1);
for i=1:n-1
    Yd(:,i) = Y(:,i) - Y(:,i+1);
end
u = zeros(d,n-1);
tic
for k=1:options.num_passes
    % do tau passes
    perm = randperm(n-1);
    S = perm(1:tau);
    
    gamma = 2*(n-1)*tau/(k*tau^2 +2*(n-1));
    
    uref = u;   % workers see only uref, u is updated on the server
    for dummy=1:tau
        i = S(dummy);
        
        gradient_i = gradientFused(Yd,uref,i);
        
        normg = norm(gradient_i);
        s = 0;
        if( normg > 0 )
            s = gradient_i * ( -lambda / normg );
        end
        u(:,i) = (1-gamma) * uref(:,i) + gamma * s;
    end
    
    if (mod(k, options.debug_iter) == 0)
        gap = 0;
        for i=1:n-1
            gradient = gradientFused(Yd,u,i);
            gap = gap + u(:,i)' * gradient + lambda * norm(gradient);
        end
        if gap <= options.gap_threshold
            fprintf('Duality gap below threshold -- stopping!\n')
            fprintf('current gap: %g, gap_threshold: %g\n', gap, options.gap_threshold)
            fprintf('Reached after pass: %d \n', k)
            break % exit loop!
        else
            % to implement later: do a batch FW step with w_s & ell_s above
            fprintf('Duality gap check: gap = %g at pass %d \n', gap, k)
        end
    end
end

stats.k = k;
stats.time = toc;


end

