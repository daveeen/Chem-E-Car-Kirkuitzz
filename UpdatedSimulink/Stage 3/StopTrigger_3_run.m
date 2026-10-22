function R = StopTrigger_3_run()
% One call: apply the car values in StopTrigger_3_params.m, simulate, report, plot.
run('StopTrigger_3_params.m');
out = sim('StopTrigger_Bench_3','ReturnWorkspaceOutputs','on');
R = StopTrigger_3_report(out);
StopTrigger_3_plot(R);
StopTrigger_3_compare(R);
end
