% StopTrigger_export  Run the stop trigger bench and write the results to a CSV.
%   Usage:  StopTrigger_export            (writes StopTrigger_results.csv next to this file)
%           StopTrigger_export("out.csv")
function T = StopTrigger_export(csvFile)
    if nargin < 1, csvFile = fullfile(fileparts(mfilename("fullpath")), "StopTrigger_results.csv"); end
    bn = "StopTrigger_Bench"; load_system(bn);
    sim(bn);                                   % To Workspace blocks write Tsig, LDR, PT to the base workspace
    LDR = evalin("base","LDR"); PT = evalin("base","PT"); Tsig = evalin("base","Tsig");
    t = LDR.Vs.Time;
    T = table(t, interp1(Tsig.Time, Tsig.Data, t), LDR.Vs.Data, LDR.Va.Data, LDR.STOP.Data, ...
              PT.Vs.Data, PT.Va.Data, PT.STOP.Data, ...
              VariableNames = ["time_s","T","LDR_Vs","LDR_Va","LDR_STOP","PT_Vs","PT_Va","PT_STOP"]);
    writetable(T, csvFile);
    fprintf("Wrote %d rows to %s\n", height(T), csvFile);
end
