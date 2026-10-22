# Stop trigger simulation

This note explains the Simulink model of our optical stopping circuit: what it covers, the physics behind it, the choices we made, and what is still unknown. Read it before opening the model.

## What we are building

When the reaction in the jar finishes, the solution goes from clear to dark and less light reaches the sensor. The circuit turns that into a STOP signal that cuts power to the motors.

light → sensor → gain stage → comparator → (stage 2) latch → coil driver → relay → motors off

The goal is to show that an LDR version and a phototransistor version each trip once, cleanly, on the same light input, and to compare when they trip.

We are building it in two stages. Stage 1 runs from the light input to the comparator. Stage 2 adds the latch, MOSFET coil driver and relay, once the trip point is right.

## Requirements

- MATLAB R2025b with Simulink, Simscape and Simscape Electrical.


## Running it and getting the results

1. Open `StopTrigger_Bench.slx` and press Run. It takes a few seconds.
2. Each variant has a scope that plots sensor voltage (`Vs`), amplifier output (`Va`) and `STOP`. Open the scope after the run.
3. The workspace gets three variables: `Tsig` (the light signal) and `LDR` and `PT`, each holding timeseries called `Vs`, `Va` and `STOP`. For example, `LDR.Vs.Data` and `LDR.Vs.Time`.
4. To get a spreadsheet, run `StopTrigger_export` in the MATLAB command window from `C:\Users\davin\Documents`. It runs the bench and writes `StopTrigger_results.csv` with columns `time_s, T, LDR_Vs, LDR_Va, LDR_STOP, PT_Vs, PT_Va, PT_STOP`.

Change the light fade, resistor values or gains by editing the variables in the model workspace (Model Explorer, then Model Workspace). In the first millisecond the phototransistor circuit settles from zero initial conditions, so ignore the first few samples of `PT`.

Each stage is its own subsystem, laid out left to right: light to sensor, gain stage, comparator, probes. Double-click a stage to see the circuit.

## Physics

Light input. Transmission $T(t)$ fades from clear to dark, and illuminance $E$ is proportional to $T$:

$$T(t) = T_{end} + \frac{T_{start} - T_{end}}{1 + e^{(t - t_0)/\tau}}$$

LDR. Resistance falls as light rises:

$$R_{LDR} \approx A\,E^{-\gamma}, \quad \gamma \approx 0.8$$

It sits in a divider with a fixed resistor to ground, so the output falls as the jar darkens:

$$V_{sensor} = V_+ \frac{R_{fixed}}{R_{LDR} + R_{fixed}}$$

Sensitivity is highest when $R_{fixed} = R_{LDR}$ at the trip point, so we set $A$ to make that true. Response time is 10 to 100 ms, and it contains cadmium.

Phototransistor. Photocurrent is linear in light and the transistor multiplies it:

$$I_B = S\,E, \quad I_C = \beta\,I_B, \quad V_{sensor} \approx V_+ - I_C R_{fixed}$$

This output rises as the jar darkens, the opposite of the LDR. The clear state must stay out of saturation. Response time is microseconds.

Gain stage. A non-inverting op-amp, so it does not load the sensor node:

$$V_{out} = V_{sensor}\left(1 + \frac{R_2}{R_1}\right)$$

Hysteresis. Feeding the comparator output back through $R_b$, with the reference through $R_a$, gives a band of

$$\Delta V = (V_{OH} - V_{OL})\frac{R_a}{R_a + R_b}$$

A 100 mV band on a 5 V swing needs $R_a/(R_a + R_b) = 0.02$, for example 1 kΩ and 47 kΩ, which the bench uses. The band should end up sized from measured noise.

That form suits the LDR, whose signal falls in the dark, so the signal goes to the inverting input and STOP is output high. The phototransistor signal rises, so its comparator is wired the other way: signal through $R_{in}$ to the non-inverting input, feedback $R_b$ from the output, reference on the inverting input. Its band is $(V_{OH} - V_{OL})R_{in}/R_b$, and the trip happens at $V_{ref}(1 + R_{in}/R_b)$.

## Design choices

| Question | Choice | Why |
|---|---|---|
| What to simulate first | Stop trigger | Smallest piece, fully specified, core of the circuits team's work. |
| Which sensor | Both, on the same input | Tests the audit's preference for the phototransistor directly. |
| How much of the chain | Staged: sensors to comparator, then latch and relay | Fix the trip point before adding delay and latch behaviour. |
| Light input | Sigmoid fade with settable start, end, $t_0$, $\tau$ | Looks like an iodine clock reaction and is easy to replace with measured data. A step hides chatter. |
| Where to build | New file beside the base model | Keeps the original intact. |
| Trip level | $T = 0.5$ | Equal margin to both end states. |
| Comparator polarity | Set per variant | LDR output falls in the dark, phototransistor output rises. |

## Starting values

Supply 5 V (the separate instrumentation rail), $R_{fixed} = 10\,\text{k}\Omega$, $T_{start} = 1.0$, $T_{end} = 0.1$, $t_0 = 10$ s, $\tau = 1$ s, 20 s run.

LDR (hand calculation, $\gamma = 0.8$):

| State | $T$ | $R_{LDR}$ | $V_{sensor}$ |
|---|---|---|---|
| Clear | 1.0 | 5.74 kΩ | 3.18 V |
| Trip | 0.5 | 10 kΩ | 2.50 V |
| Dark | 0.1 | 36.2 kΩ | 1.08 V |

Phototransistor (a stand-in, not TEPT4400 data): a photocurrent source $I_{pk} T$ drives the base of an NPN with $\beta = 100$, collector pull-up $R_{fixed}$. The simulated transistor behaves like $\beta \approx 92$, so $I_{pk} = 4.37\,\mu\text{A}$ puts the trip at $V_{sensor} = 3.0$ V when $T = 0.5$.

| State | $T$ | $V_{sensor}$ |
|---|---|---|
| Clear | 1.0 | 1.39 V |
| Trip | 0.5 | 3.00 V |
| Dark | 0.1 | 4.57 V |

Replace these with TEPT4400 curve data once the LED and jar are measured.

Comparator references that set the trip at $T = 0.5$: $V_{ref} = 3.83$ V (LDR, after the 1.5 gain) and 2.94 V (phototransistor, gain 1). On the real circuit each comes from a trim pot on the 5 V rail.

## Hardware from the circuit audit (Rev 3, 15 Sep 2026)

- Instrumentation runs on a regulated 5 V rail (S7V8F5, four AA NiMH cells), separate from the propulsion battery. Only the control ground is shared.
- Detector: Vishay TEPT4400, emitter to ground, collector through about 10 kΩ to 5 V.
- LEDs to trial: red (660 nm), yellow, green (515 nm), and an RGB part. Start near 5 mA with $R = (5 - V_F)/I$.
- Optical path: 80 mm through the jar.
- Stage 2 parts: MCP6541 comparator, 74HC00 SR latch, IRLZ44N coil driver with a 1N4007 flyback diode, Omron G5LE-1 DC5 relay (about 79 mA coil).
- A 10 kΩ and 10 µF filter has $RC = 100$ ms, so it reaches 90% only after 230 ms. Try 1 to 10 ms of filtering first.
- Hysteresis does not remember a trip. The latch does.
- Check relay and instrumentation power against the event's official rules. The audit could not fetch the AIChE 2026 rules PDF (403).

## State of the base model

The three stop-trigger subsystems share one layout: sensor, op-amp gain stage, ideal switch.

- `Stopping Mech` uses a photodiode.
- `Stopping Mech_LDR` uses a potentiometer standing in for the LDR.
- `Stopping Mech_Phototransistor` uses a current source driving an NPN.

None has the comparator with hysteresis, the latch, the coil driver or the relay.

Pressing Run fails at compile because the physical network in `Motor System` (`PS Constant1` and `Vehicle Body`) has no Solver Configuration block. The bench avoids this by giving each variant its own.

## Pass criteria

For both variants:

1. STOP asserts once and stays asserted.
2. It trips at $T = 0.5 \pm 0.05$.
3. Every node stays between 0 and 5 V.
4. Trip time and the voltage margin to each end state are logged for LDR and phototransistor.

## Stage 1 results

All four checks pass for both variants.

| | LDR | Phototransistor |
|---|---|---|
| Sensor voltage, clear (T = 1) | 3.17 V | 1.39 V |
| Sensor voltage at trip | 2.50 V | 3.00 V |
| Sensor voltage, dark (T = 0.1) | 1.08 V | 4.57 V |
| Trip time | 10.231 s | 10.224 s |
| Transmission at trip | 0.498 | 0.500 |
| Output transitions | 1 | 1 |
| Margin, clear to trip | 0.67 V | 1.62 V |
| Margin, trip to dark | 1.42 V | 1.56 V |
| Amplifier output range | 1.62 to 4.76 V | 1.39 to 4.57 V |

The LDR numbers match the hand calculation above. The two variants trip within 10 ms of each other because the fade takes seconds and the LDR's own response time is not modelled yet. The real difference is the margin. The phototransistor's response is linear, so its margin is nearly the same on both sides of the trip point. The LDR's power-law response leaves less room on the clear side. Both margins are far larger than the 0.1 V hysteresis band.

Differences from the earlier notes: the audit wires the phototransistor with a collector pull-up, so its output rises in the dark. The Simulation Research write-up and the base model use an emitter pull-down, where the output falls. The bench follows the audit.

## What we still need

Simplifications in the sim: the LDR's 10 to 100 ms response is not modelled in stage 1, op-amp and comparator are ideal, and the sigmoid stands in for the real reaction.

To measure:
- Sensor voltage in the clear and endpoint states over several reactions, with motors running.
- The LED current at which the detector saturates.
- Real light transmission through the 80 mm jar.
- Noise near the threshold, to size the hysteresis.
- Relay opening delay and coast distance (stage 2).
- LED-off and blocked-beam faults. Both should trigger STOP.

## Sources

- Chem-E-Car circuit budget audit, Rev 3, 15 September 2026
- Simulation Research notes (battery mechanisms, LDR and phototransistor trigger write-ups)
- [Battery Builder, MathWorks](https://au.mathworks.com/help/simscape-battery/ug/get-started-battery-builder.html)
- [SPST relay block, MathWorks R2025b](https://au.mathworks.com/help/releases/R2025b/sps/ref/spstrelay.html)
