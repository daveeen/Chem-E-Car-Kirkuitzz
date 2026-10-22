function StopTrigger_2_flyback_test()
% Coil turn-off test: switches the relay coil on at 10 ms and off at 100 ms, with and without the flyback diode.
% 'No diode' is done by setting the diode's forward voltage to 1000 V, so the reported peak is a lower bound.
C='StopTrigger_Bench_2/LDR stage 2/Coil driver and relay'; load_system('StopTrigger_Bench_2');
for variant = ['with diode';'no diode  ']'
  tm='tmp_coil_off'; if bdIsLoaded(tm), close_system(tm,0); end
  new_system(tm); load_system(tm); add_block(C,[tm '/C']);
  if strncmp(variant','no',2), set_param([tm '/C/Flyback diode'],'Vf','1000'); end
  add_block('simulink/Sources/Step',[tm '/on'],'Time','0.01','Before','0','After','5','SampleTime','0');
  add_block('simulink/Sources/Step',[tm '/off'],'Time','0.1','Before','0','After','-5','SampleTime','0');
  add_block('simulink/Math Operations/Sum',[tm '/sum'],'Inputs','++');
  nm={'i','e','v'}; for k=1:3, add_block('simulink/Sinks/To Workspace',[tm '/' nm{k}],'VariableName',['tc_' nm{k}],'SaveFormat','Timeseries'); end
  add_line(tm,'on/1','sum/1'); add_line(tm,'off/1','sum/2'); add_line(tm,'sum/1','C/1');
  add_line(tm,'C/1','e/1'); add_line(tm,'C/2','i/1'); add_line(tm,'C/3','v/1');
  set_param(tm,'Solver','ode23t','MaxStep','2e-5','StopTime','0.12');
  out=sim(tm,'ReturnWorkspaceOutputs','on'); V=out.tc_v; I=out.tc_i;
  ton=V.Time>=0.01 & V.Time<0.0102; toff=V.Time>=0.1;
  k=find(I.Time>0.1 & I.Data<0.05*0.079,1); tdec=NaN; if ~isempty(k), tdec=1e3*(I.Time(k)-0.1); end
  fprintf('%s | turn-on Vds peak %.2f V | turn-off Vds peak %.1f V | coil current below 5%% after %.1f ms\n', variant', max(V.Data(ton)), max(V.Data(toff)), tdec);
  close_system(tm,0);
end
end
