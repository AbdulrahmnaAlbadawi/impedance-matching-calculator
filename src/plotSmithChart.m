function fig = plotSmithChart(varargin)
% PLOTSMITHCHART  Draw a normalised Smith chart with optional overlays.
%
%   fig = plotSmithChart()
%       Draws a blank Smith chart (Z0 = 50 Ω, unit circle).
%
%   fig = plotSmithChart('Z0', 75)
%       Same but with a 75 Ω reference impedance.
%
%   fig = plotSmithChart('Points', Z_list)
%       Plots complex impedance values Z_list (unnormalised, in ohms).
%       Z_list can be a scalar or a vector (e.g. a frequency sweep).
%
%   fig = plotSmithChart('Points', Z_list, 'Labels', {'ZL', 'Z_match'})
%       Adds text labels next to each plotted point.
%
%   fig = plotSmithChart('Points', Z_list, 'ConnectDots', true)
%       Draws a line connecting the points (useful for frequency sweeps).
%
%   EXAMPLES
%       See examples/ex_basic.m, ex_matching.m, ex_sweep.m
%
%   THEORY
%       A point on the Smith chart represents a normalised impedance
%           z = Z / Z0 = r + jx
%       mapped to the complex reflection coefficient
%           Γ = (z − 1) / (z + 1)
%       whose real and imaginary parts give the Cartesian position on the
%       chart. Constant-r circles and constant-x arcs form the grid.

% ── parse inputs ────────────────────────────────────────────────────────
p = inputParser;
addParameter(p, 'Z0',          50,    @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'Points',      [],    @isnumeric);
addParameter(p, 'Labels',      {},    @iscell);
addParameter(p, 'ConnectDots', false, @islogical);
addParameter(p, 'PointColor',  [0.85 0.1 0.1], @(x) isnumeric(x) && numel(x)==3);
addParameter(p, 'LineColor',   [0.2  0.4 0.9], @(x) isnumeric(x) && numel(x)==3);
parse(p, varargin{:});
Z0          = p.Results.Z0;
Z_points    = p.Results.Points(:);          % ensure column vector
labels      = p.Results.Labels;
connectDots = p.Results.ConnectDots;
ptColor     = p.Results.PointColor;
lnColor     = p.Results.LineColor;

% ── figure / axes ───────────────────────────────────────────────────────
fig = figure('Color','w','Name','Smith Chart','NumberTitle','off');
ax  = axes(fig);
hold(ax,'on');
axis(ax,'equal');
axis(ax,'off');
ax.XLim = [-1.15 1.15];
ax.YLim = [-1.15 1.15];

% ── colour palette ──────────────────────────────────────────────────────
cGrid  = [0.55 0.55 0.55];   % light grey grid
cEdge  = [0.15 0.15 0.15];   % dark outer circle

% ── outer unit circle ───────────────────────────────────────────────────
theta = linspace(0, 2*pi, 360);
plot(ax, cos(theta), sin(theta), 'Color', cEdge, 'LineWidth', 1.4);

% ── constant-resistance circles  r = const  ─────────────────────────────
% Each circle: centre = (r/(1+r), 0), radius = 1/(1+r)
r_values = [0, 0.2, 0.5, 1, 2, 5];
for r = r_values
    cx = r / (1 + r);
    cr = 1 / (1 + r);
    t  = linspace(0, 2*pi, 400);
    xc = cx + cr * cos(t);
    yc =       cr * sin(t);
    % clip to unit disk
    inside = (xc.^2 + yc.^2) <= 1.0001;
    xc(~inside) = NaN;  yc(~inside) = NaN;
    plot(ax, xc, yc, 'Color', cGrid, 'LineWidth', 0.7);
    % label on the real axis
    labelX = cx + cr;          % rightmost point of circle = (2r/(1+r), 0)
    if labelX <= 1
        text(ax, labelX, 0.03, num2str(r), ...
            'FontSize', 7, 'Color', cGrid, ...
            'HorizontalAlignment', 'center');
    end
end

% ── constant-reactance arcs  x = const  ─────────────────────────────────
% Each arc: centre = (1, 1/x), radius = 1/|x|
x_values = [0.2, 0.5, 1, 2, 5];
for x = [x_values, -x_values]
    cx = 1;
    cy = 1 / x;
    cr = abs(1 / x);
    t  = linspace(0, 2*pi, 800);
    xc = cx + cr * cos(t);
    yc = cy + cr * sin(t);
    inside = (xc.^2 + yc.^2) <= 1.0001;
    xc(~inside) = NaN;  yc(~inside) = NaN;
    plot(ax, xc, yc, 'Color', cGrid, 'LineWidth', 0.7);
    % small label near rim
    [~, idx] = min(abs(xc - 0.95));
    if ~isnan(xc(idx))
        text(ax, xc(idx), yc(idx), sprintf('%+.1f j', x), ...
            'FontSize', 6, 'Color', cGrid, ...
            'HorizontalAlignment', 'center');
    end
end

% real axis (x = 0 arc is the whole real line inside circle)
plot(ax, [-1 1], [0 0], 'Color', cGrid, 'LineWidth', 0.7);

% ── axis labels ─────────────────────────────────────────────────────────
text(ax,  1.05,  0,    '∞', 'FontSize', 9,  'Color', cEdge, 'FontWeight','bold');
text(ax, -1.12,  0,   '0',  'FontSize', 9,  'Color', cEdge, 'FontWeight','bold');
text(ax,  0,     1.10,'Smith Chart', ...
    'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2], ...
    'HorizontalAlignment', 'center');
text(ax,  0,     1.03, sprintf('Z_0 = %g Ω', Z0), ...
    'FontSize', 8, 'Color', [0.4 0.4 0.4], 'HorizontalAlignment','center');

% ── reference points ────────────────────────────────────────────────────
plot(ax, 0, 0, 'k+', 'MarkerSize', 8, 'LineWidth', 1.2);   % centre (Z = Z0)
text(ax, 0.03, 0.06, 'Z_0', 'FontSize', 7, 'Color', [0.3 0.3 0.3]);

% ── optional user data ───────────────────────────────────────────────────
if ~isempty(Z_points)
    Gamma = (Z_points/Z0 - 1) ./ (Z_points/Z0 + 1);  % reflection coeff
    Gx    = real(Gamma);
    Gy    = imag(Gamma);

    if connectDots
        plot(ax, Gx, Gy, '-', 'Color', lnColor, 'LineWidth', 1.4);
    end
    plot(ax, Gx, Gy, 'o', ...
        'MarkerFaceColor', ptColor, 'MarkerEdgeColor', ptColor*0.6, ...
        'MarkerSize', 7, 'LineWidth', 1);

    for k = 1:numel(Z_points)
        lbl = '';
        if k <= numel(labels); lbl = labels{k}; end
        if isempty(lbl)
            lbl = sprintf('Z_%d', k);
        end
        text(ax, Gx(k)+0.04, Gy(k)+0.05, lbl, ...
            'FontSize', 8, 'Color', ptColor*0.7, 'FontWeight','bold');
    end
end

hold(ax,'off');
end
