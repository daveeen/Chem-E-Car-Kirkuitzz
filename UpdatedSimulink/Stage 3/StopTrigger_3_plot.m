function StopTrigger_3_plot(R, pngFile)
% Stage 3 figure: speed, motor current and distance travelled, timed from STOP.
% After STOP the car is the same for both sensors, so one set of curves is drawn (phototransistor).
if nargin < 1, R = StopTrigger_3_report(); end   % no input: reuse the last results, or run the bench
if nargin < 2, pngFile = ''; end
r = R.PT; C = R.out.Car_PT;
t = C.Time - r.tStop; v = C.Data(:,1); x = C.Data(:,2); ic = C.Data(:,4);
xs = (x - r.xTrip)*1e3; xl = [-0.3 r.tStopped-r.tStop+0.3]; off = r.delay_ms/1e3;
f = figure('Name','Stage 3: car after STOP','Color','w','Position',[100 100 900 900]); try, theme(f,'light'); catch, end
tl = tiledlayout(f,3,1,'TileSpacing','compact','Padding','compact');
title(tl,{'Stage 3: car stopping distance after STOP (time measured from the moment STOP fires)','Identical for LDR and phototransistor. They only differ in when STOP fires.'});
ax = nexttile(tl); hold(ax,'on'); grid(ax,'on');
plot(ax,t,v*1e3,'b','LineWidth',1.6,'DisplayName','Car speed');
xline(ax,0,'r-','LineWidth',1.2,'DisplayName','STOP fires'); xline(ax,off,'k--','LineWidth',1.2,'DisplayName','Motors off');
xlim(ax,xl); ylim(ax,[0 230]); ylabel(ax,'Car speed [mm/s]'); title(ax,'Car speed'); legend(ax,'Location','northeast');
ax = nexttile(tl); hold(ax,'on'); grid(ax,'on');
plot(ax,t,ic*1e3,'Color',[0.85 0.33 0.1],'LineWidth',1.6,'DisplayName','Motor current');
xline(ax,0,'r-','LineWidth',1.2,'DisplayName','STOP fires'); xline(ax,off,'k--','LineWidth',1.2,'DisplayName','Motors off');
xlim(ax,xl); ylim(ax,[0 120]); ylabel(ax,'Motor current [mA]'); title(ax,'Motor current'); legend(ax,'Location','northeast');
ax = nexttile(tl); hold(ax,'on'); grid(ax,'on');
plot(ax,t,xs,'Color',[0 0.5 0.2],'LineWidth',1.6,'DisplayName','Distance travelled since STOP');
xline(ax,0,'r-','LineWidth',1.2,'DisplayName','STOP fires'); xline(ax,off,'k--','LineWidth',1.2,'DisplayName','Motors off');
yline(ax,r.dTotal*1e3,':k','LineWidth',1.3,'DisplayName',sprintf('Final: %.1f mm (%.1f relay delay + %.1f coast)',r.dTotal*1e3,r.dDelay*1e3,r.dCoast*1e3));
xlim(ax,xl); ylim(ax,[-30 90]); ylabel(ax,'Distance since STOP [mm]'); xlabel(ax,'Time from STOP [s]'); title(ax,'Distance travelled'); legend(ax,'Location','southeast');
if ~isempty(pngFile), exportgraphics(f,pngFile,'Resolution',130); end
end
