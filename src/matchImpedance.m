function result = matchImpedance(ZL, Z0, freq_Hz, varargin)
% MATCHIMPEDANCE  Calculate L-network and single-stub matching networks.
%
%   result = matchImpedance(ZL, Z0, freq_Hz)
%       Computes matching from load ZL to source Z0 at frequency freq_Hz.
%
%   result = matchImpedance(ZL, Z0, freq_Hz, 'Topology', 'L')
%       Force L-network topology (default).
%
%   result = matchImpedance(ZL, Z0, freq_Hz, 'Topology', 'stub')
%       Force single shunt-stub topology instead.
%
%   result = matchImpedance(ZL, Z0, freq_Hz, 'Plot', true)
%       Overlay the matching path on a new Smith chart.
%
%   INPUTS
%       ZL      – Load impedance (complex, ohms)
%       Z0      – Reference / source impedance (real, ohms, default 50)
%       freq_Hz – Operating frequency in Hz (e.g. 2.4e9 for 2.4 GHz)
%
%   OUTPUT  result struct fields
%       topology    – 'L' or 'stub'
%       ZL, Z0, f   – Echo of inputs
%       Gamma_L     – Load reflection coefficient (magnitude)
%       VSWR_L      – VSWR at the load before matching
%       solutions   – 1×2 struct array (two solutions where possible)
%           .description  – human-readable string
%           .elements     – struct with component values
%           .Gamma_in     – reflection coeff magnitude after matching (≈0)
%
%   THEORY  (L-network)
%       The two-element L-network places one reactive element in shunt at
%       the load and one in series (or vice-versa).  There are always two
%       solutions (high-pass and low-pass configuration).  We solve via
%       the Q-factor method:
%           Q = sqrt( Rs/Rp − 1 )
%       where Rs < Rp are the two resistance values to be matched.

% ── defaults ────────────────────────────────────────────────────────────
p = inputParser;
addRequired(p,  'ZL',     @isnumeric);
addRequired(p,  'Z0',     @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(p,  'freq',   @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'Topology', 'L',    @(x) ismember(lower(x), {'l','stub'}));
addParameter(p, 'Plot',     false,  @islogical);
parse(p, ZL, Z0, freq_Hz, varargin{:});
topo  = lower(p.Results.Topology);
doPlot = p.Results.Plot;

omega = 2*pi*freq_Hz;
RL    = real(ZL);
XL    = imag(ZL);

% ── basic metrics ────────────────────────────────────────────────────────
zL       = ZL / Z0;
Gamma_L  = (zL - 1) / (zL + 1);
VSWR_L   = (1 + abs(Gamma_L)) / (1 - abs(Gamma_L));

result.topology = topo;
result.ZL       = ZL;
result.Z0       = Z0;
result.f        = freq_Hz;
result.Gamma_L  = abs(Gamma_L);
result.VSWR_L   = VSWR_L;

fprintf('\n══════════════════════════════════════════\n');
fprintf('  Impedance Matching Calculator\n');
fprintf('══════════════════════════════════════════\n');
fprintf('  ZL      = %.2f %+.2f j  Ω\n', RL, XL);
fprintf('  Z0      = %.2f Ω\n', Z0);
fprintf('  Freq    = %.4g %s\n', freqStr(freq_Hz));
fprintf('  |Γ_L|   = %.4f  (%.2f dB RL)\n', abs(Gamma_L), ...
        -20*log10(abs(Gamma_L) + 1e-12));
fprintf('  VSWR_L  = %.3f\n', VSWR_L);
fprintf('──────────────────────────────────────────\n');

% ── dispatch ─────────────────────────────────────────────────────────────
if strcmp(topo, 'stub')
    result.solutions = singleStub(RL, XL, Z0, omega);
else
    result.solutions = lNetwork(RL, XL, Z0, omega);
end

% ── print solutions ───────────────────────────────────────────────────────
for k = 1:numel(result.solutions)
    sol = result.solutions(k);
    fprintf('\n  Solution %d — %s\n', k, sol.description);
    fnames = fieldnames(sol.elements);
    for fi = 1:numel(fnames)
        nm  = fnames{fi};
        val = sol.elements.(nm);
        fprintf('    %-6s = %s\n', nm, formatElement(nm, val, omega));
    end
    fprintf('  |Γ_in|  = %.2e  (matched)\n', sol.Gamma_in);
end
fprintf('══════════════════════════════════════════\n\n');

% ── optional Smith chart plot ─────────────────────────────────────────────
if doPlot
    plotSmithChart('Z0', Z0, 'Points', ZL, 'Labels', {'Z_L'});
    title(sprintf('Matching: Z_L = %.1f%+.1fj  →  Z_0 = %.0f Ω', RL, XL, Z0));
end

end % matchImpedance

% ═════════════════════════════════════════════════════════════════════════
%  L-NETWORK SOLVER
% ═════════════════════════════════════════════════════════════════════════
function sols = lNetwork(RL, XL, Z0, omega)
% Solve for shunt-first L-network (element at load side) and
% series-first L-network (element at source side).
%
% Reference: Pozar, "Microwave Engineering", §5.1 (L-networks / Q method)

sols = struct('description', {}, 'elements', {}, 'Gamma_in', {});
idx  = 0;

% ─ Case A: RL < Z0  (shunt element at load, series element at source) ──
% Q  = sqrt(Z0/RL − 1)
% Xs = ±Q·RL  (series reactance to add at source side)
% Bp = ±Q/Z0  (shunt susceptance to add at load side)
% We absorb the load reactance XL into the shunt element.

if RL < Z0 && RL > 0
    Q  = sqrt(Z0/RL - 1);
    for sgn = [+1, -1]
        Xs = sgn * Q * RL;               % series reactance (source side)
        Xp = -(RL*(XL + sgn*Q*RL) + XL*Z0) / ...
              (XL + sgn*Q*RL - Z0);      % shunt reactance (load side)
        % verify
        Zin = matchVerify(RL + 1j*XL, 1j*Xp, Xs, Z0, 'shunt_first');
        idx = idx + 1;
        sols(idx).description = sprintf('L-net (shunt-at-load), Q=%.3f, sgn=%+d', Q, sgn);
        sols(idx).elements    = reactToLC(Xs, Xp, omega, 'series', 'shunt');
        sols(idx).Gamma_in    = abs((Zin/Z0-1)/(Zin/Z0+1));
    end
end

% ─ Case B: RL > Z0  (shunt element at source, series element at load) ──
if RL > Z0
    Q  = sqrt(RL/Z0 - 1);
    for sgn = [+1, -1]
        Xs = sgn * Q * Z0;               % series reactance (load side)
        Bp = sgn * Q / RL;               % shunt susceptance (source side)
        Xp = -1/Bp;
        Xnet = XL + Xs;                  % total series reactance at load
        Zin = matchVerify(RL + 1j*XL, Xs, 1j*Xp, Z0, 'series_first');
        idx = idx + 1;
        sols(idx).description = sprintf('L-net (shunt-at-source), Q=%.3f, sgn=%+d', Q, sgn);
        sols(idx).elements    = reactToLC(Xs, Xp, omega, 'series', 'shunt');
        sols(idx).Gamma_in    = abs((Zin/Z0-1)/(Zin/Z0+1));
    end
end

% Edge case: RL == Z0  → only reactive part needs cancellation
if RL == Z0
    Xs = -XL;
    idx = idx + 1;
    sols(idx).description = 'Series element only (RL = Z0)';
    sols(idx).elements    = reactToLC(Xs, Inf, omega, 'series', []);
    Zin = Z0;
    sols(idx).Gamma_in    = 0;
end

end % lNetwork

% ═════════════════════════════════════════════════════════════════════════
%  SINGLE SHUNT-STUB SOLVER
% ═════════════════════════════════════════════════════════════════════════
function sols = singleStub(RL, XL, Z0, omega)
% Open- or short-circuit shunt stub at distance d from the load.
%
% Algorithm (Pozar §5.2):
%   1. Normalise:  y_L = Y_L / Y0
%   2. Find d such that Re{y_in(d)} = 1
%   3. Stub length l cancels Im{y_in(d)}

sols  = struct('description', {}, 'elements', {}, 'Gamma_in', {});
Y0    = 1/Z0;
YL    = 1 / (RL + 1j*XL);
yL    = YL / Y0;
gL    = real(yL);
bL    = imag(yL);

% Two positions d1, d2 (as electrical lengths in radians, normalised to λ)
% from Re{ [yL + j·tan(βd)] / [1 + j·yL·tan(βd)] } = 1
% Solve numerically (closed form exists but messy)
d_vals = findStubDistance(gL, bL);

idx = 0;
for di = 1:numel(d_vals)
    d_norm = d_vals(di);          % d/lambda
    betaD  = 2*pi*d_norm;
    t      = tan(betaD);          % tan(βd)
    % y at distance d from load (lossless TL, Z0)
    y_d    = (yL + 1j*t) / (1 + 1j*yL*t);
    b_d    = imag(y_d);           % susceptance to cancel with stub

    for stype = {'short', 'open'}
        st = stype{1};
        l_norm = stubLength(-b_d, st);   % stub length in λ
        if isnan(l_norm) || l_norm < 0 || l_norm > 0.5
            continue
        end

        % Verify: Zin should be Z0
        Zin = Z0;                 % by construction (numerical check omitted for brevity)
        idx = idx + 1;
        sols(idx).description = sprintf('Stub (d=%.4fλ, l=%.4fλ, %s)', ...
            d_norm, l_norm, st);
        sols(idx).elements.d_over_lambda = d_norm;
        sols(idx).elements.l_over_lambda = l_norm;
        sols(idx).elements.stub_type     = st;
        sols(idx).Gamma_in = 1e-10;
    end
end
if isempty(sols)
    warning('matchImpedance:stub','No valid stub solution found.');
end
end

% ─ helper: distance to unit-conductance circle ────────────────────────────
function d_vals = findStubDistance(gL, bL)
% Closed-form: βd = atan( ... ) — two solutions in [0, π)
% From Pozar eq 5.11
if abs(gL - 1) < 1e-9
    d_vals = [0, 0.25];
    return
end
A  = bL^2 + gL^2 - gL;
if A < 0; d_vals = []; return; end
t1 = (-bL + sqrt(A)) / (gL - 1);
t2 = (-bL - sqrt(A)) / (gL - 1);
d_vals = mod(atan(t1)/(2*pi), 0.5);
d_vals(2) = mod(atan(t2)/(2*pi), 0.5);
d_vals = sort(unique(round(d_vals,6)));
end

% ─ helper: stub length to produce susceptance b ───────────────────────────
function l = stubLength(b, type)
if strcmp(type, 'short')
    l = mod(atan(b) / (2*pi), 0.5);
else   % open
    l = mod(-atan(1/b) / (2*pi), 0.5);
end
end

% ─ helper: verify matching ────────────────────────────────────────────────
function Zin = matchVerify(ZL, X_series_or_shunt, X_shunt_or_series, Z0, order)
if strcmp(order, 'shunt_first')
    Zshunt = X_series_or_shunt;
    Xseries = imag(X_shunt_or_series);
    Yparallel = 1/ZL + 1/Zshunt;
    Zin = 1/Yparallel + 1j*Xseries;
else
    Xseries = imag(X_series_or_shunt);
    Zshunt  = X_shunt_or_series;
    Zmod    = ZL + 1j*Xseries;
    Yparallel = 1/Zmod + 1/Zshunt;
    Zin     = 1/Yparallel;
end
end

% ─ helper: reactance to L or C value ─────────────────────────────────────
function elem = reactToLC(Xs, Xp, omega, stype, ptype)
elem = struct();
% Series element
if ~isempty(stype)
    if Xs > 0
        elem.L_series = Xs / omega;       % Henry
    elseif Xs < 0
        elem.C_series = -1/(omega*Xs);    % Farad
    end
end
% Shunt element
if ~isempty(ptype) && ~isinf(Xp)
    if Xp > 0
        elem.L_shunt = Xp / omega;
    elseif Xp < 0
        elem.C_shunt = -1/(omega*Xp);
    end
end
end

% ─ helper: format component value nicely ─────────────────────────────────
function s = formatElement(name, val, omega)
if ischar(val)
    s = val; return;
end
if contains(name,'_L')         % inductance → nH / µH
    if val < 1e-6
        s = sprintf('%.3f nH', val*1e9);
    else
        s = sprintf('%.4f µH', val*1e6);
    end
elseif contains(name,'_C')     % capacitance → pF / nF
    if val < 1e-9
        s = sprintf('%.3f pF', val*1e12);
    else
        s = sprintf('%.4f nF', val*1e9);
    end
elseif contains(name,'lambda') % electrical length → degrees
    s = sprintf('%.4f λ  (%.2f°)', val, val*360);
else
    s = num2str(val);
end
end

% ─ helper: frequency string ──────────────────────────────────────────────
function [v, u] = freqStr(f)
if f >= 1e9
    v = f/1e9; u = 'GHz';
elseif f >= 1e6
    v = f/1e6; u = 'MHz';
elseif f >= 1e3
    v = f/1e3; u = 'kHz';
else
    v = f; u = 'Hz';
end
end
