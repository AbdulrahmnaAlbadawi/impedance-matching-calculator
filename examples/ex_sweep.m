% ex_sweep.m — Example 3: Frequency sweep trace on Smith chart
%
% Simulates how the impedance of a series RLC circuit (antenna model)
% varies with frequency, producing the characteristic spiral trace
% you'd see on a VNA screen.
%
% Run from project root:
%   addpath('src'); run('examples/ex_sweep.m')

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% RLC antenna model
R0   = 50;           % radiation resistance (Ω)
L_a  = 10e-9;        % antenna inductance (H)
C_a  = 0.44e-12;     % antenna capacitance (F) → resonance ≈ 2.4 GHz
Z0   = 50;

%% Frequency sweep 1 – 4 GHz
f    = linspace(1e9, 4e9, 400);
omega = 2*pi*f;
ZL   = R0 + 1j*omega*L_a + 1./(1j*omega*C_a);

%% Resonant frequency (where Im{Z} = 0)
f_res = 1 / (2*pi*sqrt(L_a*C_a));
omega_res = 2*pi*f_res;
Z_res = R0 + 1j*omega_res*L_a + 1/(1j*omega_res*C_a);

fprintf('\nAntenna RLC model:\n');
fprintf('  L  = %.2f nH\n', L_a*1e9);
fprintf('  C  = %.3f pF\n', C_a*1e12);
fprintf('  R  = %.0f Ω\n', R0);
fprintf('  f_resonance ≈ %.4f GHz  (Z_res = %.2f%+.4fj Ω)\n\n', ...
    f_res/1e9, real(Z_res), imag(Z_res));

%% Plot Smith chart with sweep trace
fig = plotSmithChart('Z0', Z0, ...
                     'Points', ZL, ...
                     'Labels', {}, ...
                     'ConnectDots', true, ...
                     'LineColor', [0.2 0.4 0.9], ...
                     'PointColor', [0.2 0.4 0.9]);

% Highlight resonant frequency
hold on;
Z_res_actual = R0;   % at resonance Im{Z}=0 for series RLC
Gamma_res = (Z_res_actual/Z0 - 1) / (Z_res_actual/Z0 + 1);
plot(real(Gamma_res), imag(Gamma_res), 'r*', 'MarkerSize', 12, 'LineWidth', 2);
text(real(Gamma_res)+0.05, 0.08, ...
    sprintf('f_{res} = %.2f GHz', f_res/1e9), ...
    'Color','r','FontSize',9,'FontWeight','bold');

% Mark 1 GHz and 4 GHz endpoints
Gamma_end = (ZL([1,end])/Z0 - 1) ./ (ZL([1,end])/Z0 + 1);
plot(real(Gamma_end(1)), imag(Gamma_end(1)), 'gs','MarkerSize',9,'MarkerFaceColor','g');
plot(real(Gamma_end(2)), imag(Gamma_end(2)), 'ms','MarkerSize',9,'MarkerFaceColor','m');
text(real(Gamma_end(1))-0.1, imag(Gamma_end(1))+0.08,'1 GHz','Color','g','FontSize',8);
text(real(Gamma_end(2))-0.1, imag(Gamma_end(2))-0.08,'4 GHz','Color','m','FontSize',8);
hold off;

title('Example 3 — Frequency Sweep (1–4 GHz, series-RLC antenna model)');

%% Also plot VSWR vs frequency
figure('Color','w','Name','VSWR vs Frequency');
m = rfMetrics(ZL, Z0);
subplot(2,1,1);
plot(f/1e9, m.VSWR, 'b-', 'LineWidth', 1.4);
xline(f_res/1e9, 'r--', sprintf('%.2f GHz', f_res/1e9));
yline(2, 'k:', 'VSWR = 2');
ylabel('VSWR'); xlabel('Frequency (GHz)');
title('VSWR vs Frequency'); grid on; ylim([1 20]);

subplot(2,1,2);
plot(f/1e9, m.ReturnLoss, 'b-', 'LineWidth', 1.4);
xline(f_res/1e9, 'r--', sprintf('%.2f GHz', f_res/1e9));
yline(10, 'k:', '10 dB');
ylabel('Return Loss (dB)'); xlabel('Frequency (GHz)');
title('Return Loss vs Frequency'); grid on;
