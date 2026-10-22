% StopTrigger_3_params.m  --  EDIT THE VALUES BELOW, save, then run:  R = StopTrigger_3_run();
% Every value is a PLACEHOLDER until the mech team confirms it. Right-hand column says what it is.
P = struct();
%% Car (mech team)
P.m_car      = 2.0;    % [kg]       car mass, ready to run (chassis + battery + payload)
P.wheel_dia  = 60;     % [mm]       driven wheel diameter
P.gear_ratio = 100;    % [-]        motor turns per wheel turn (100 means 100:1)
P.Crr        = 0.02;   % [-]        rolling resistance coefficient (roll-down test with motor disconnected)
P.Dtarget    = 20;     % [m]        target distance (rules: 15 to 30 m, announced 1 h before)
%% Motor (datasheet or bench test)
P.V_nl       = 2.2;    % [V]        voltage the three no-load numbers below were measured at
P.rpm_nl     = 6736;   % [rpm]      no-load speed at V_nl
P.I_nl       = 0.050;  % [A]        no-load current at V_nl (measure with the gearbox fitted if you can)
P.R_motor    = 4.5;    % [ohm]      winding resistance (audit: Tamiya 70203, 0.67 A stall at 3 V)
P.J_rotor    = 1.0;    % [g cm^2]   rotor inertia (motor datasheet)
%% Battery (circuits / battery team)
P.V_pack     = 2.2;    % [V]        loaded pack voltage while running (audit: 1.8 to 2.7 V)
%% ---- Derived values and model update (do not edit below) ----
bn = 'StopTrigger_Bench_3'; if ~bdIsLoaded(bn), load_system(bn); end
mw = get_param(bn,'ModelWorkspace');
g = 9.81; rw = P.wheel_dia/2/1000; Ng = P.gear_ratio;
w0 = P.rpm_nl*2*pi/60;                         % no-load shaft speed [rad/s]
Ke = (P.V_nl - P.I_nl*P.R_motor)/w0;           % back-EMF constant = torque constant [V s/rad]
T0 = Ke*P.I_nl;                                % no-load friction torque [N m]
Jm = P.J_rotor*1e-7;                           % [kg m^2]
Fd = T0*Ng/rw + P.Crr*P.m_car*g;               % drag force at the wheel [N]
Meq = P.m_car + Jm*Ng^2/rw^2;                  % car mass plus rotor inertia seen at the wheel [kg]
Itop = (T0 + P.Crr*P.m_car*g*rw/Ng)/Ke;        % running current [A]
v = (P.V_pack - Itop*(P.R_motor+0.05))/Ke*rw/Ng;   % running speed [m/s]
dco = 0.5*Meq*v^2/Fd;                          % coast distance [m]
tmech = (Jm + P.m_car*rw^2/Ng^2)*(P.R_motor+0.05)/Ke^2;   % speed-up time constant [s]
tcoast = v*Meq/Fd;                             % time to coast to rest [s]
t0 = max(2, 0.5 + 6*tmech);                    % light fade starts after the car is up to speed
vals = {'mcar',P.m_car; 'rw',rw; 'Ng',Ng; 'Ke',Ke; 'Jm',Jm; 'T0m',T0; 'Crr',P.Crr; 'g',g; 'Vpack',P.V_pack; 'Rm',P.R_motor; 't0',t0};
for i = 1:size(vals,1), assignin(mw, vals{i,1}, vals{i,2}); end
set_param(bn,'StopTime',num2str(ceil(t0 + 1.5*tcoast + 1.5)));
fprintf('\nCar values applied. Quick estimate (no simulation):\n');
fprintf('  running speed  %.1f mm/s,  running current %.1f mA\n', v*1e3, Itop*1e3);
fprintf('  coast distance %.1f mm,  coast time %.2f s\n', dco*1e3, tcoast);
fprintf('  %.0f m takes %.0f s at this speed (limit 120 s)\n', P.Dtarget, P.Dtarget/v);
if P.Dtarget/v > 110, fprintf('  WARNING: too slow for the target distance. Raise speed (lower gear ratio) or cut the distance.\n'); end
if v*1e3 < 20, fprintf('  WARNING: car barely moves. Check gear ratio, mass and motor numbers.\n'); end
