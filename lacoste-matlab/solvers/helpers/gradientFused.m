function [ g ] = gradientFused( Yd, u, i )
%GRADIENTFUSED Gradient of the objective w.r.t the block u_i

% Yd : (d,n-1)
% u : (d,n-1)
% 1 <= i <= n-1

[~, n_1] = size(Yd);

g = 2*u(:,i) - Yd(:,i);

if( i > 1)
    g = g - u(:,i-1);
end
if( i < n_1 )
    g = g - u(:,i+1);
end




end

