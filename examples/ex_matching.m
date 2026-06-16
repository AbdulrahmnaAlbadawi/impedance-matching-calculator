% ex_matching.m — Example 2: L-network impedance matching at 2.4 GHz
%
% Task: match a 100 - j30 Ω antenna to a 50 Ω source at 2.4 GHz.
% This is a very common scenario (e.g. an ESP32 PCB trace antenna).
%
% Run from project root:
%   addpath('src'); run('examples/ex_matching.m')

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% Parameters
Z0   = 50;                  % source / system impedance (Ω)
ZL   = 100 - 30j;          % antenna / load impedance (Ω)
freq = 2.4e9;               % 2.4 GHz

%% Step 1 — RF metrics BEFORE matching
fprintf('\n=== BEFORE MATCHING ===\n');
rfMetrics(ZL, Z0);

%% Step 2 — Compute L-network solutions
result = matchImpedance(ZL, Z0, freq, 'Topology', 'L');

%% Step 3 — Visualise on Smith chart
fig = plotSmithChart('Z0', Z0, ...
                     'Points', ZL, ...
                     'Labels', {'Z_L = 100−j30'});

title(sprintf('Matching Z_L = %g%+gj → Z_0 = %g Ω  @ %.1f GHz', ...
    real(ZL), imag(ZL), Z0, freq/1e9));

%% Notes printed to command window  (matchImpedance already printed them)
fprintf('Pick Solution 1 (low-pass L-net) for best harmonic suppression.\n');
fprintf('Pick Solution 2 (high-pass L-net) if you need to pass DC.\n\n');
