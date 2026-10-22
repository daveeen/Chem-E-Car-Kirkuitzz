function R = StopTrigger_1b_mc(N, sigN, pngFile)
% Stage 1b Monte Carlo: spread of the trip point (transmission T at STOP) for LDR vs phototransistor.
% Untrimmed units: part spread (LDR A, gamma; phototransistor gain; Rfix; Vref setting), LDR lag, light noise.
if nargin<1, N=100; end
if nargin<2, sigN=0.01; end
if nargin<3, pngFile=''; end
bn='StopTrigger_Bench_1b'; load_system(bn);
mw=get_param(bn,'ModelWorkspace');
A0=mw.getVariable('Ald'); g0=mw.getVariable('gam'); I0=mw.getVariable('Ipk'); R0=mw.getVariable('Rfix');
VL0=mw.getVariable('VrefL'); VP0=mw.getVariable('VrefP');
rng(1);
p.Ald=A0*exp(0.20*randn(N,1)); p.gam=g0+0.05*randn(N,1); p.Ipk=I0*exp(0.25*randn(N,1));
p.Rfix=R0*(1+0.005*randn(N,1)); p.VrefL=VL0+0.010*randn(N,1); p.VrefP=VP0+0.010*randn(N,1);
fn=fieldnames(p);
for i=1:N
  si=Simulink.SimulationInput(bn); si=si.setModelParameter('FastRestart','on');
  for k=1:numel(fn), si=si.setVariable(fn{k},p.(fn{k})(i),'Workspace',bn); end
  si=si.setVariable('sigN',sigN,'Workspace',bn); si=si.setVariable('seedN',i,'Workspace',bn);
  in(i)=si; %#ok<AGROW>
end
out=sim(in,'ShowProgress','off');
nm={'LDR','PT'}; tripT=nan(N,2); nTr=zeros(N,2); early=false(N,2);
for i=1:N
  if ~isempty(out(i).ErrorMessage), warning('run %d: %s',i,out(i).ErrorMessage); continue; end
  Tc=out(i).Tsig; [tu,iu]=unique(Tc.Time);
  for c=1:2
    s=out(i).(nm{c}).STOP; hi=s.Data>2.5; k=find(hi,1);
    nTr(i,c)=sum(abs(diff(hi)));
    if ~isempty(k), tripT(i,c)=interp1(tu,Tc.Data(iu),s.Time(k)); end
  end
end
early=tripT>0.8;
R=table((1:N)','VariableNames',{'run'}); R.Ald=p.Ald; R.gam=p.gam; R.Ipk=p.Ipk; R.Rfix=p.Rfix;
R.tripT_LDR=tripT(:,1); R.tripT_PT=tripT(:,2); R.transitions_LDR=nTr(:,1); R.transitions_PT=nTr(:,2);
writetable(R,fullfile(fileparts(which(bn)),'StopTrigger_1b_results.csv'));
fprintf('\n N=%d, light noise sigma=%.3f of T\n',N,sigN);
fprintf('%-16s %7s %7s %7s %7s %6s %8s %6s\n','sensor','mean','std','min','max','nofire','chatter','early');
lab={'LDR','Phototransistor'};
for c=1:2
  x=tripT(:,c);
  fprintf('%-16s %7.3f %7.3f %7.3f %7.3f %6d %8d %6d\n',lab{c},mean(x,'omitnan'),std(x,'omitnan'),min(x),max(x),sum(isnan(x)),sum(nTr(:,c)>1),sum(early(:,c)));
end
f=figure('Name','Stage 1b: trip-point spread','Color','w','Position',[100 100 900 520]); try, theme(f,'light'); end
ax=axes(f); hold(ax,'on'); grid(ax,'on'); ed=0.15:0.01:0.85;
histogram(ax,tripT(:,1),ed,'FaceColor',[0.85 0.33 0.1],'FaceAlpha',0.6,'DisplayName',sprintf('LDR: mean %.3f, std %.3f',mean(tripT(:,1),'omitnan'),std(tripT(:,1),'omitnan')));
histogram(ax,tripT(:,2),ed,'FaceColor',[0 0.45 0.74],'FaceAlpha',0.6,'DisplayName',sprintf('Phototransistor: mean %.3f, std %.3f',mean(tripT(:,2),'omitnan'),std(tripT(:,2),'omitnan')));
xline(ax,0.5,'--k','LineWidth',1.5,'DisplayName','Target T = 0.5'); xline(ax,0.45,':k','LineWidth',1.6,'DisplayName','Target +/- 0.05'); xline(ax,0.55,':k','LineWidth',1.6,'HandleVisibility','off');
xlabel(ax,'Transmission T at the moment STOP fires  (left = fired late, right = fired early)'); ylabel(ax,'Number of units');
title(ax,sprintf('Trip-point spread over %d simulated units (tighter = fewer false/late stops)',N));
legend(ax,'Location','northwest');
if ~isempty(pngFile), exportgraphics(f,pngFile,'Resolution',110); end
end
