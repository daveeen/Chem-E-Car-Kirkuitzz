function R = StopTrigger_2_report()
% Stage 2: latch -> coil driver -> relay -> motor. Runs the bench and prints the pass checks and the trip-to-motors-off delay.
bn='StopTrigger_Bench_2'; load_system(bn);
out = sim(bn,'ReturnWorkspaceOutputs','on');
V = {'LDR','S2_LDR'; 'PT','S2_PT'}; R = struct('out',out);
for c = 1:2
  if ~isfield(out.who, 'x') && ~any(strcmp(out.who, V{c,2})), continue; end
  A = out.(V{c,1}).STOP; B = out.(V{c,2});
  tS = A.Time(find(A.Data>2.5,1));
  q = B.Q; tQ = q.Time(find(q.Data>2.5,1));
  ic = B.Icoil; tC = ic.Time(find(ic.Data>0.0593,1));
  im = B.Im; pre = im.Time>0.5 & im.Time<tS-0.02; Is = mean(im.Data(pre));
  tOff = im.Time(find(im.Time>tS & im.Data<0.05*Is,1));
  tOn = im.Time(find(im.Time>tS & im.Data<0.95*Is,1));
  nQ = sum(abs(diff(q.Data>2.5)));
  fprintf('\n== %s ==\n', V{c,1});
  fprintf('STOP asserted            %8.4f s\n', tS);
  fprintf('Latch Q high             %8.4f s  (+%.3f ms)\n', tQ, 1e3*(tQ-tS));
  fprintf('Coil current at 59.3 mA  %8.4f s  (+%.2f ms)\n', tC, 1e3*(tC-tS));
  fprintf('Motor current -5%%        %8.4f s  (+%.2f ms)\n', tOn, 1e3*(tOn-tS));
  fprintf('Motor current <5%%        %8.4f s  (+%.2f ms)  <- trip to motors off\n', tOff, 1e3*(tOff-tS));
  fprintf('Running motor current    %8.3f A\n', Is);
  fprintf('Coil current, final      %8.1f mA\n', 1e3*ic.Data(end));
  fprintf('Peak Vds                 %8.2f V   (5 V rail + flyback drop should stay near 5.7 V)\n', max(B.Vds.Data));
  fprintf('Latch Q transitions      %8d     (1 = set once, never released)\n', nQ);
  fprintf('Q at end                 %8.2f V   (still high after the 2.5 s re-arm press)\n', q.Data(end));
  R.(V{c,1}) = struct('tStop',tS,'tLatch',tQ,'tCoil',tC,'tMotorOff',tOff,'delay',tOff-tS);
end
end
