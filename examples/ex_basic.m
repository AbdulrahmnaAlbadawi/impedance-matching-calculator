% ex_basic.m — Example 1: Plot several impedances on a Smith chart
%
% Run this from the project root after adding /src to the path:
%   addpath('src')
%   run('examples/ex_basic.m')

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% Impedances to plot (Z0 = 50 Ω)
Z0 = 50;
Z_points = [
    50 + 0j;       % 1. matched (centre of chart)
    100 + 0j;      % 2. purely resistive, r = 2 (right half)
    25 + 0j;       % 3. purely resistive, r = 0.5 (left half)
    50 + 50j;      % 4. inductive
    50 - 50j;      % 5. capacitive
    0 + 50j;       % 6. purely reactive (rim)
    200 + 100j;    % 7. high-impedance mismatch
];

labels = {'50Ω','100Ω','25Ω','50+50j','50-50j','j50','200+100j'};

fig = plotSmithChart('Z0', Z0, ...
                     'Points', Z_points, ...
                     'Labels', labels);

title('Example 1 — Basic Smith Chart (7 impedance points)');

%% Also print RF metrics for each point
fprintf('=== RF Metrics for each impedance (Z0 = %g Ω) ===\n', Z0);
rfMetrics(Z_points, Z0);
