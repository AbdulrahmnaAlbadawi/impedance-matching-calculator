function result = rfMetrics(Z, Z0)
% RFMETRICS  Compute common RF figures-of-merit for an impedance.
%
%   result = rfMetrics(Z, Z0)
%
%   INPUTS
%       Z   – Complex impedance (scalar or vector, ohms)
%       Z0  – Reference impedance (scalar, default 50 Ω)
%
%   OUTPUT struct fields
%       Z           – Input impedance(s)
%       Gamma       – Reflection coefficient (complex)
%       Gamma_mag   – |Γ|
%       Gamma_ang   – ∠Γ (degrees)
%       VSWR        – Voltage Standing Wave Ratio
%       ReturnLoss  – Return loss (dB, positive number)
%       MismatchLoss– Mismatch / insertion loss (dB, positive number)
%
%   THEORY
%       Γ = (Z – Z0) / (Z + Z0)
%       VSWR = (1 + |Γ|) / (1 – |Γ|)
%       RL   = –20·log10(|Γ|)   [dB]
%       ML   = –10·log10(1 – |Γ|²)   [dB]

if nargin < 2; Z0 = 50; end

Gamma       = (Z - Z0) ./ (Z + Z0);
Gamma_mag   = abs(Gamma);
Gamma_ang   = angle(Gamma) * 180/pi;
VSWR        = (1 + Gamma_mag) ./ max(1 - Gamma_mag, 1e-12);
ReturnLoss  = -20*log10(Gamma_mag + 1e-15);
MismatchLoss= -10*log10(1 - Gamma_mag.^2 + 1e-15);

result.Z            = Z;
result.Z0           = Z0;
result.Gamma        = Gamma;
result.Gamma_mag    = Gamma_mag;
result.Gamma_ang    = Gamma_ang;
result.VSWR         = VSWR;
result.ReturnLoss   = ReturnLoss;
result.MismatchLoss = MismatchLoss;

% ── print table ──────────────────────────────────────────────────────────
fprintf('\n  Z0 = %.0f Ω\n', Z0);
fprintf('  %-22s  %-18s  %-8s  %-8s  %-8s  %-8s\n', ...
        'Z (Ω)', 'Γ', 'VSWR', 'RL (dB)', 'ML (dB)', '|Γ|');
fprintf('  %s\n', repmat('─',1,85));
for k = 1:numel(Z)
    fprintf('  %-22s  %-18s  %-8.3f  %-8.2f  %-8.3f  %-8.4f\n', ...
        sprintf('%.3f%+.3fj', real(Z(k)), imag(Z(k))), ...
        sprintf('%.4f∠%.1f°', Gamma_mag(k), Gamma_ang(k)), ...
        VSWR(k), ReturnLoss(k), MismatchLoss(k), Gamma_mag(k));
end
fprintf('\n');
end
