function StopTrigger_2_plot(R, pngFile)
% Stage 2 timeline: comparator STOP -> latch -> coil -> relay -> motor current, zoomed on the trip.
% Everything after the comparator is identical for LDR and phototransistor, so one chain is drawn (phototransistor).
if nargin<1, R = StopTrigger_2_report(); end
if nargin<2, pngFile=''; end
out = R.out; A = out.PT.STOP; B = out.S2_PT;
tS = A.Time(find(A.Data>2.5,1)); ms = @(ts) (ts.Time-tS)*1e3; tOff = R.PT.tMotorOff; xr = [-2 20];
f = figure('Name','Stage 2: STOP to motors off','Color','w','Position',[100 60 900 950]); try, theme(f,'light'); end
tl = tiledlayout(f,4,1,'TileSpacing','compact','Padding','compact');
title(tl,{'Stage 2: from STOP to motors off (time measured from the moment STOP fires)','Identical for LDR and phototransistor (they differ by under 0.1 ms)'});
ax = nexttile(tl); hold(ax,'on'); grid(ax,'on');
plot(ax,ms(A),A.Data,'r','LineWidth',1.5,'DisplayName','Comparator STOP'); plot(ax,ms(B.Q),B.Q.Data,'b--','LineWidth',1.5,'DisplayName','Latch Q');
xlim(ax,xr); ylim(ax,[-0.5 5.5]); ylabel(ax,'Voltage [V]'); title(ax,'Comparator STOP and latch Q'); legend(ax,'Location','east');
ax = nexttile(tl); hold(ax,'on'); grid(ax,'on');
plot(ax,ms(B.Icoil),1e3*B.Icoil.Data,'b','LineWidth',1.5,'DisplayName','Relay coil current');
yline(ax,59.3,'--k','LineWidth',1.2,'DisplayName','Relay pulls in (59.3 mA)');
xlim(ax,xr); ylabel(ax,'Coil current [mA]'); title(ax,'Relay coil current'); legend(ax,'Location','southeast');
ax = nexttile(tl); hold(ax,'on'); grid(ax,'on');
plot(ax,ms(B.Vds),B.Vds.Data,'Color',[0.85 0.33 0.1],'LineWidth',1.5,'DisplayName','Drain voltage');
xlim(ax,xr); ylabel(ax,'Drain voltage [V]'); title(ax,'Driver MOSFET drain (5 V off, about 0 V on)'); legend(ax,'Location','east');
ax = nexttile(tl); hold(ax,'on'); grid(ax,'on');
plot(ax,ms(B.Im),B.Im.Data,'Color',[0 0.5 0],'LineWidth',1.5,'DisplayName','Motor current');
xline(ax,(tOff-tS)*1e3,'--k','LineWidth',1.2,'DisplayName',sprintf('Motors off, +%.1f ms',(tOff-tS)*1e3));
xlim(ax,xr); ylabel(ax,'Motor current [A]'); xlabel(ax,'Time after STOP [ms]'); title(ax,'Motor current through the relay contact'); legend(ax,'Location','east');
if ~isempty(pngFile), exportgraphics(f,pngFile,'Resolution',130); end
end
