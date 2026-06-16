% ex_stub.m — Example 4: Single shunt-stub matching
%
% Matches Z_L = 25 + j30 Ω → Z0 = 50 Ω @ 2.4 GHz using a shunt stub.
% A shunt stub is a short section of transmission line (open or short)
% placed in parallel with the main line at a specific distance from the load.
% This topology is easy to implement in microstrip.
%
% Run from project root:
%   addpath('src'); run('examples/ex_stub.m')

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% Parameters
Z0   = 50;
ZL   = 25 + 30j;
freq = 2.4e9;

%% Solve
result = matchImpedance(ZL, Z0, freq, 'Topology', 'stub');

%% Smith chart
fig = plotSmithChart('Z0', Z0, 'Points', ZL, 'Labels', {'Z_L=25+j30'});
title('Example 4 — Shunt-Stub Matching @ 2.4 GHz');

%% Microstrip length hint (εr = 4.4, h = 1.6 mm, W ≈ 3 mm → Z0 ≈ 50 Ω)
lambda = 3e8 / (freq * sqrt(3.5));   % effective εr ≈ 3.5 for FR4
fprintf('Physical stub lengths (FR4 εr_eff ≈ 3.5, λ = %.2f mm):\n\n', lambda*1e3);
for k = 1:numel(result.solutions)
    sol = result.solutions(k);
    if isfield(sol.elements, 'd_over_lambda')
        d_mm = sol.elements.d_over_lambda * lambda * 1e3;
        l_mm = sol.elements.l_over_lambda * lambda * 1e3;
        fprintf('  Solution %d (%s stub):\n', k, sol.elements.stub_type);
        fprintf('    d = %.3f mm  (distance from load)\n', d_mm);
        fprintf('    l = %.3f mm  (stub length)\n\n', l_mm);
    end
end
