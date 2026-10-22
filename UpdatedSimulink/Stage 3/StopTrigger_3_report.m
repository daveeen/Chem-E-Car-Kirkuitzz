function R = StopTrigger_3_report(out)
% Stage 3: stopping distance after STOP. Runs the bench unless a sim output is passed in.
if nargin < 1
  if evalin('base','exist(''Car_LDR'',''var'') && exist(''S2_LDR'',''var'')')   % use the results of the last bench Run
    out = struct('Car_LDR',evalin('base','Car_LDR'),'Car_PT',evalin('base','Car_PT'),'S2_LDR',evalin('base','S2_LDR'),'S2_PT',evalin('base','S2_PT'));
  else
    out = sim('StopTrigger_Bench_3','ReturnWorkspaceOutputs','on');
  end
end
tg = {'LDR','PT'}; nm = {'LDR','Phototransistor'};
R.out = out;
for k = 1:2
  C = out.(['Car_' tg{k}]); S = out.(['S2_' tg{k}]);
  t = C.Time; v = C.Data(:,1); x = C.Data(:,2); w = C.Data(:,3);
  tS = S.Q.Time(find(S.Q.Data > 2.5, 1));            % STOP fires (latch Q high)
  ts = S.Im.Time; im = S.Im.Data;
  Is = mean(im(ts >= tS-0.3 & ts <= tS-0.02));       % running motor current
  tOff = ts(find(ts > tS & im < 0.05*Is, 1));         % motor current below 5%
  iS = find(t >= tS, 1); iO = find(t >= tOff, 1);
  r.name = nm{k}; r.tStop = tS; r.tOff = tOff; r.delay_ms = (tOff-tS)*1e3;
  r.vRun = mean(v(t >= tS-0.3 & t <= tS-0.02)); r.iRun = Is;
  r.wRun = mean(w(t >= tS-0.3 & t <= tS-0.02));
  r.xTrip = x(iS); r.xOff = x(iO);
  r.dDelay = x(iO)-x(iS); r.dCoast = x(end)-x(iO); r.dTotal = x(end)-x(iS);
  r.tStopped = t(find(t > tOff & v < 0.002, 1));
  R.(tg{k}) = r;
end
% Hand check (same numbers as the model workspace)
mw = get_param('StopTrigger_Bench_3','ModelWorkspace');
m = getVariable(mw,'mcar'); rw = getVariable(mw,'rw'); Ng = getVariable(mw,'Ng'); Ke = getVariable(mw,'Ke');
Jm = getVariable(mw,'Jm'); T0 = getVariable(mw,'T0m'); Crr = getVariable(mw,'Crr'); g = getVariable(mw,'g');
Tf = T0 + Crr*m*g*rw/Ng;                 % friction torque at the motor shaft [N m]
Vp = getVariable(mw,'Vpack'); Rm = getVariable(mw,'Rm');
Ih = Tf/Ke; vh = (Vp - Ih*(Rm+0.05))/Ke*rw/Ng;      % pack voltage, motor resistance, 0.05 ohm contact
Meq = m + Jm*Ng^2/rw^2;                  % car mass plus rotor inertia seen at the wheel
Fd = T0*Ng/rw + Crr*m*g;                 % drag force at the wheel [N]
dh = 0.5*Meq*vh^2/Fd;
R.hand = struct('iRun',Ih,'vRun',vh,'Meq',Meq,'Fdrag',Fd,'dCoast',dh);
fprintf('\n%-18s %12s %12s\n','','LDR','Phototransistor');
row = @(lab,a,b,f) fprintf('%-18s %12s %12s\n',lab,sprintf(f,a),sprintf(f,b));
row('STOP fires [s]', R.LDR.tStop, R.PT.tStop, '%.4f');
row('Motors off [ms]', R.LDR.delay_ms, R.PT.delay_ms, '%.2f');
row('Run speed [mm/s]', R.LDR.vRun*1e3, R.PT.vRun*1e3, '%.1f');
row('Run current [mA]', R.LDR.iRun*1e3, R.PT.iRun*1e3, '%.1f');
row('Relay delay [mm]', R.LDR.dDelay*1e3, R.PT.dDelay*1e3, '%.2f');
row('Coast [mm]', R.LDR.dCoast*1e3, R.PT.dCoast*1e3, '%.2f');
row('TOTAL after STOP [mm]', R.LDR.dTotal*1e3, R.PT.dTotal*1e3, '%.2f');
row('Standstill [s]', R.LDR.tStopped, R.PT.tStopped, '%.3f');
fprintf('Hand check: run current %.1f mA, speed %.1f mm/s, coast %.2f mm\n', Ih*1e3, vh*1e3, dh*1e3);
end
