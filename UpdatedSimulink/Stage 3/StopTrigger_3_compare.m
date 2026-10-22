function StopTrigger_3_compare(R, pngFile)
% Stage 3: LDR vs phototransistor on one clock. Distance is measured from the ideal trip point (T = 0.5).
if nargin < 1, R = StopTrigger_3_report(); end   % no input: reuse the last results, or run the bench
if nargin < 2, pngFile = ''; end
o = R.out; mw = get_param('StopTrigger_Bench_3','ModelWorkspace');
t0 = getVariable(mw,'t0'); tau = getVariable(mw,'tau'); Ts = getVariable(mw,'Tstart'); Te = getVariable(mw,'Tend'); Tt = getVariable(mw,'Ttrip');
tI = t0 + tau*log((Ts-Te)/(Tt-Te) - 1);          % time the light crosses T = 0.5
col = {[0.85 0.33 0.1],[0 0.45 0.74]}; tg = {'LDR','PT'}; nm = {'LDR','Phototransistor'};
xl = [tI-0.2 max(R.LDR.tStopped,R.PT.tStopped)+0.2];
f = figure('Name','Stage 3: LDR vs phototransistor','Color','w','Position',[100 100 1000 900]);
try, theme(f,'light'); catch, end
T = @(t) Te + (Ts-Te)./(1+exp((t-t0)/tau));
tt = linspace(xl(1),xl(2),600);
tl = tiledlayout(f,3,1,'TileSpacing','compact','Padding','compact');
title(tl,'Stage 3: LDR vs phototransistor on the same clock (same light, same car)');
ax = nexttile(tl); hold(ax,'on'); grid(ax,'on');
plot(ax,tt,T(tt),'k','LineWidth',1.5,'DisplayName','Light T');
yline(ax,Tt,':k','DisplayName','Trip level T = 0.5'); xline(ax,tI,'k--','DisplayName','Ideal trip moment');
for k = 1:2, xline(ax,R.(tg{k}).tStop,'-','Color',col{k},'LineWidth',1.6,'DisplayName',sprintf('%s fires STOP (%.3f s)',nm{k},R.(tg{k}).tStop)); end
xlim(ax,xl); ylabel(ax,'Light T (1 = clear)'); title(ax,'Light fades. Each sensor fires STOP at a different moment'); legend(ax,'Location','northeast');
ax = nexttile(tl); hold(ax,'on'); grid(ax,'on');
for k = 1:2, C = o.(['Car_' tg{k}]); plot(ax,C.Time,C.Data(:,1)*1e3,'Color',col{k},'LineWidth',1.6,'DisplayName',nm{k}); end
xline(ax,tI,'k--','DisplayName','Ideal trip moment');
xlim(ax,xl); ylabel(ax,'Car speed [mm/s]'); legend(ax,'Location','northeast'); title(ax,'Speed: the LDR car keeps going longer because STOP fires later');
ax = nexttile(tl); hold(ax,'on'); grid(ax,'on');
for k = 1:2
  C = o.(['Car_' tg{k}]); r = R.(tg{k}); x0 = interp1(C.Time,C.Data(:,2),tI); dend = (r.xTrip + r.dTotal - x0)*1e3;
  plot(ax,C.Time,(C.Data(:,2)-x0)*1e3,'Color',col{k},'LineWidth',1.6,'DisplayName',sprintf('%s stops %.1f mm past ideal',nm{k},dend));
  yline(ax,dend,':','Color',col{k},'HandleVisibility','off');
end
xline(ax,tI,'k--','DisplayName','Ideal trip moment');
gap = (R.LDR.xTrip+R.LDR.dTotal - R.PT.xTrip-R.PT.dTotal)*1e3;
xlim(ax,xl); ylim(ax,[-40 100]); ylabel(ax,'Distance past ideal trip point [mm]'); xlabel(ax,'Time [s]');
title(ax,sprintf('Where each car stops: gap = %.1f mm',gap)); legend(ax,'Location','southeast');
if ~isempty(pngFile), exportgraphics(f,pngFile,'Resolution',150); end
end
