function StopTrigger_plot(pngFile)
% Stage 1 figure: light, sensor voltage with clear/trip/dark levels and margins, and the comparator STOP output.
if nargin < 1, pngFile = ''; end
bn = 'StopTrigger_Bench'; load_system(bn);
o = sim(bn,'ReturnWorkspaceOutputs','on');            % fresh run, never stale workspace data
LDR = o.LDR; PT = o.PT; Tsig = o.Tsig; tend = Tsig.Time(end);
tF = Tsig.Time(find(Tsig.Data < 0.9*Tsig.Data(1),1));  % moment the fade has clearly started
f = figure('Name','Stop trigger: LDR vs phototransistor','Color','w','Position',[100 80 1100 850]); try, theme(f,'light'); end
tl = tiledlayout(f,3,2,'TileSpacing','compact','Padding','compact');
title(tl,'Stage 1: optical stop trigger, sensor voltage, margins and STOP');
S = {LDR,'LDR','falls when dark','northeast','southeast'; PT,'Phototransistor','rises when dark','southeast','southeast'};
ax0 = nexttile(tl,1,[1 2]); hold(ax0,'on'); grid(ax0,'on');
plot(ax0,Tsig.Time,Tsig.Data,'k','LineWidth',1.5,'DisplayName','Light reaching the sensor, T');
yline(ax0,0.5,'--r','DisplayName','Trip level, T = 0.5');
xlim(ax0,[0 tend]); ylabel(ax0,'Light T (1 = clear)'); xlabel(ax0,'Time [s]');
title(ax0,'Light fades as the reaction finishes'); legend(ax0,'Location','northeast');
for c = 1:2
  D = S{c,1}; nm = S{c,2}; dr = S{c,3};
  t = D.Vs.Time; vs = D.Vs.Data; stp = D.STOP.Data;
  k = find(stp > 0.5,1); ttrip = t(k); vtrip = vs(k);
  vclear = mean(vs(t >= 0.5*tF & t <= 0.9*tF)); vdark = mean(vs(t >= 0.9*tend));
  m1 = abs(vtrip-vclear); m2 = abs(vdark-vtrip);
  ax = nexttile(tl,2+c); hold(ax,'on'); grid(ax,'on');
  plot(ax,t,vs,'b','LineWidth',1.5,'DisplayName','Sensor voltage Vs');
  yline(ax,vclear,':k','LineWidth',1.3,'DisplayName',sprintf('Clear level %.2f V',vclear));
  yline(ax,vdark,'-.k','LineWidth',1.3,'DisplayName',sprintf('Dark level %.2f V',vdark));
  yline(ax,vtrip,'--r','LineWidth',1.3,'DisplayName',sprintf('Vs at trip %.2f V',vtrip));
  xline(ax,ttrip,'--r','HandleVisibility','off');
  ylim(ax,[0 5]); xlim(ax,[0 tend]); xlabel(ax,'Time [s]'); ylabel(ax,'Sensor node Vs [V]');
  title(ax,sprintf('%s: Vs %s\nmargin: clear to trip %.2f V, trip to dark %.2f V',nm,dr,m1,m2));
  legend(ax,'Location',S{c,4});
  ax2 = nexttile(tl,4+c); hold(ax2,'on'); grid(ax2,'on');
  plot(ax2,t,stp,'r','LineWidth',1.5,'DisplayName','Comparator output STOP');
  xline(ax2,ttrip,'--k','LineWidth',1.2,'DisplayName',sprintf('STOP fires at %.3f s',ttrip));
  ylim(ax2,[-0.5 5.5]); xlim(ax2,[0 tend]); xlabel(ax2,'Time [s]'); ylabel(ax2,'STOP [V]  (5 V = stop car)');
  title(ax2,[nm ': comparator output']); legend(ax2,'Location',S{c,5});
end
if ~isempty(pngFile), exportgraphics(f,pngFile,'Resolution',150); end
end
