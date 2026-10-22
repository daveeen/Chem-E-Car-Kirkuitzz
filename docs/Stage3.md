# Stop trigger simulation: stage 3

Stage 3 adds a model of the car to the stop-trigger simulation. It answers the main project question: how far does the car travel after `STOP` fires?

Status (22 Oct 2026): built and passing for both sensors. Stages 1, 1b and 2 are unchanged.

> [!warning] Placeholder car
> The audit and the 2026 rules do not specify the car's mass, wheel size, gear ratio, motor constants, or friction. Every car value marked **Assumed** below is a placeholder, not a measured value. The stopping distances will only represent the real car after these values are measured (see **Next**).

Related notes: [[Stop Trigger Simulation]] (stage 1), [[Stop Trigger Simulation - Stage 1b]], [[Stop Trigger Simulation - Stage 2]], [[Propulsion Electrical Design]], [[Workshop - Battery to Motor]].

## The short version

- With the placeholder car values (2 kg and 0.19 m/s), the simulated car travels **about 68 mm** from when `STOP` fires until it stops.
- About **2 mm** of that distance is travelled during the relay delay (10.4 ms at 0.19 m/s). The remaining **66 mm** is travelled while coasting.
- The LDR and phototransistor stopping points differ by **10.5 mm** in this run. The LDR triggers 54.7 ms later because of its response delay, so the car travels further before stopping.
- Coasting distance depends on the car, not just the circuit. It is affected by speed squared, car mass, motor rotor inertia, and friction.
- The rules prohibit mechanical brakes (12.11), so the car relies on coasting to stop. Consistent stopping distance is more important than simply having a short distance.

## What the plot shows

![[stoptrigger_3_stopping.png]]

Time starts when `STOP` fires (red line). The dashed line marks when the motors are off. From that point onward, the car model is the same for both sensors, so the figure shows one set of curves.

1. **Car speed:** The car travels at a steady 191 mm/s until the motors switch off. Its speed then falls in a straight line to zero over 0.69 s because the model uses a constant friction force.
2. **Motor current:** The motor draws 92 mA while running. Current falls to zero when the relay contact opens.
3. **Distance since `STOP`:** The car travels 2 mm before the motors switch off, then coasts another 66 mm.

This figure focuses on the car, not the sensors. Time starts at `STOP`, and the car behaves the same for both sensors after that point. The next figure shows how the sensor choice changes when `STOP` occurs.

![[stoptrigger_3_compare.png]]

This figure compares both sensors on the same timeline. Distance is measured from the ideal trip point, when $T = 0.5$ (dashed line).

1. **Light level at the trigger:** The phototransistor triggers at $T = 0.50$ (blue). The LDR triggers 54.7 ms later at about $T = 0.45$ (orange) because of its response delay.
2. **Car speed:** Each car starts slowing down when its own `STOP` signal fires. The LDR car therefore continues at full speed for longer.
3. **Stopping point:** The phototransistor car stops 67.8 mm past the ideal point; the LDR car stops 78.2 mm past it. The 10.5 mm difference is a fixed offset caused by sensor timing, so a $V_{ref}$ trim can compensate for it. A trim cannot remove the unit-to-unit variation seen in Stage 1b.

## Results

After `STOP` fires, both sensor versions give the same result to within 0.02 mm.

| | Both sensors |
|---|---|
| `STOP` to motors off | 10.3 to 10.4 ms |
| Running speed | 190.8 mm/s |
| Running motor current | 92.0 mA |
| Distance during relay delay | 2.0 mm |
| Coast distance | 65.9 mm |
| **Total, `STOP` to standstill** | **67.9 mm** |
| Standstill | 0.69 s after `STOP` |

The sensor versions differ only in when `STOP` fires:

| | LDR | Phototransistor |
|---|---|---|
| `STOP` fires | 2.1097 s | 2.0550 s |
| Where the car stops, past the ideal trip point | 78.2 mm | 67.8 mm |
| Gap | 10.5 mm further | |

The hand calculation below gives a running current of 92.0 mA, speed of 190.8 mm/s, and coasting distance of 65.95 mm. The simulation matches these values to the reported precision.

### How the "distance past ideal" is calculated

The second figure measures each car's distance from the ideal trip point: the moment the light transmission crosses $T = 0.5$.

$$t_I = t_0 + \tau \ln\!\left(\frac{T_{start} - T_{end}}{T_{trip} - T_{end}} - 1\right) = 2 + 0.25\ln(1.25) = 2.0558\ \text{s}$$

To calculate distance past the ideal point, subtract the car's distance at $t_I$ from its distance at the time the sensor triggers. For a trigger time of $t_{STOP}$:

$$d = v\,(t_{STOP} - t_I) + d_{after\ STOP}$$

| | $t_{STOP}$ | Before STOP | After STOP | Past ideal |
|---|---|---|---|---|
| Phototransistor | 2.0550 s | $-0.15$ mm (0.8 ms early) | 67.90 mm | 67.8 mm |
| LDR | 2.1097 s | $+10.3$ mm (about 54 ms late at 0.19 m/s) | 67.92 mm | 78.2 mm |

After `STOP` both cars behave the same, so the gap is the extra time the LDR takes to fire: $0.0547\ \text{s} \times 0.1908\ \text{m/s} \approx 10.4$ mm.

### What matters most for distance

| Source | Size at 0.19 m/s | Comment |
|---|---|---|
| Relay delay (assumed 8 ms contact travel) | 2 mm | Small. Measuring the relay changes this very little. |
| LDR vs phototransistor lag | 10.5 mm | Fixed offset, trimmed out with Vref. |
| Trip scatter from stage 1b (std of $T$ at trip: 0.113 phototransistor, 0.127 LDR) | 24 mm and 27 mm | Needs the fade speed. See the note below. |
| Coast distance | 66 mm | Repeatable if friction and speed are repeatable. |

The scatter row estimates distance by converting the Stage 1b variation in light level to a time difference, then multiplying by speed. It uses the Stage 1b fade ($\tau = 0.25$ s, with a slope of about 0.89 per second at $T = 0.5$). This is only an estimate: if the real light fades more slowly, the same variation in $T$ will mean a larger timing and distance error. Since the target is judged in millimetres, variation in the sensor trip point is a bigger concern than relay delay.

## How it works

The circuit is unchanged from Stage 2 up to the relay contact. Stage 3 adds a motor back-EMF source and a mechanical model of the car.

- **Motor:** The motor model uses the same 4.5 Ω resistance and 2 mH inductance as Stage 2, plus a controlled voltage source that opposes the current: $V_{emf} = K_e\,\omega$. Because the motor now has back-EMF, its running current is much lower than Stage 2's 0.48 A.
- **Where to find the car model:** The top-level layout is unchanged from Stage 2. Inside each Stage 2 block, open `Motor circuit` to find the `Back-EMF` source, `Shaft acceleration` (described by the equation below), `Motor speed omega`, `Car speed v`, `Distance x`, and `Car log` blocks. The `Back-EMF` source applies voltage to the motor; the gain block labelled "Back-EMF = Ke x omega" calculates that voltage. If the source is removed, the motor circuit is open and no current flows.
- **Noise:** The car model does not receive the light signal or noise directly. The 1% light noise (`sigN`, using a fixed random seed) and the 50 ms LDR response delay from Stage 1b affect the sensors and therefore change when `STOP` fires. That trigger timing is how they affect the car.
- **Motor torque:** The motor produces torque $K_t I$. Motor friction and rolling resistance oppose it, so the motor shaft's angular acceleration follows:

$$J_{eq}\,\dot\omega = K_t I - T_f \tanh(\omega/2)$$

  - **Equivalent inertia:** $J_{eq} = J_m + m\,r_w^2/N^2$ combines the motor rotor and the car's mass as seen from the motor shaft. The $\tanh$ function keeps the friction model smooth as the motor slows through zero speed.
  - **Friction:** $T_f = T_0 + C_{rr}\,m\,g\,r_w/N$ combines motor no-load friction and rolling resistance, expressed as torque at the motor shaft.
  - **Speed and distance:** Car speed is $v = \omega\,r_w/N$. Distance is calculated by integrating speed over time.
  - **Gearbox:** Gearbox friction and efficiency are included in $T_0$ and $C_{rr}$ rather than modelled separately.

At steady speed, $\dot\omega = 0$, which gives:

$$I = \frac{T_f}{K_e}, \qquad v = \frac{V - I R}{K_e}\,\frac{r_w}{N}$$

After the motors switch off, the motor circuit is open, so there is no electrical braking. The model calculates coasting distance as:

$$d_{coast} = \frac{\tfrac12 M_{eq}\,v^2}{F_{drag}}, \quad M_{eq} = m + \frac{J_m N^2}{r_w^2}, \quad F_{drag} = \frac{T_0 N}{r_w} + C_{rr}\,m\,g$$

With the placeholder values, $M_{eq} = 3.11$ kg. The motor rotor contributes an equivalent 1.11 kg because the gearing multiplies its inertia. The drag force is $F_{drag} = 0.86$ N: 0.47 N from motor friction and 0.39 N from rolling resistance.

Since $d_{coast} \propto v^2$, a 10% change in speed causes about a 20% change in coasting distance. Battery voltage sag changes the speed, and therefore also changes the stopping distance.

## Parameters

| Item | Value | Source |
|---|---|---|
| Battery | 2.2 V, constant | Audit (loaded pack voltage). No internal resistance or sag modelled. |
| Motor resistance, inductance | 4.5 Ω, 2 mH | Audit (Tamiya 70203) |
| Motors | One | Audit option A |
| Car mass $m$ | 2.0 kg | **Assumed.** The rules set no mass limit. They do limit the car to a 40 × 30 × 20 cm box (13.1). |
| Wheel radius $r_w$ | 0.03 m | **Assumed.** 60 mm wheel. |
| Gear ratio $N$ | 100 | **Assumed.** Chosen to give about 0.19 m/s. |
| Motor constant $K_e = K_t$ | 2.8 mV·s/rad | **Assumed.** Gives about 7500 rpm no-load at 2.2 V. Not from a datasheet. |
| Rotor inertia $J_m$ | $1\times10^{-7}$ kg·m² | **Assumed.** |
| Motor no-load friction $T_0$ | $1.4\times10^{-4}$ N·m | **Assumed.** About 50 mA of no-load current. |
| Rolling resistance $C_{rr}$ | 0.02 | **Assumed.** |
| Relay, MOSFET, latch | As in stage 2 | See [[Stop Trigger Simulation - Stage 2]] |

The rules set a target distance of 15 to 30 m (6.2) and a 2-minute time limit. That corresponds to an average speed of about 0.13 to 0.25 m/s. The placeholder car runs at 0.19 m/s, which is enough to cover about 21 m in 110 s. To cover 30 m within 2 minutes, the car needs to reach at least 0.25 m/s, so a longer target may require a different gear ratio.

## Plug in the mech team's numbers

All car parameters are in `StopTrigger_3_params.m`. The file uses values the mech team can provide, such as car mass, wheel diameter, gear ratio, and motor data. It currently contains the placeholder values above. When measured values are available:

1. Open `StopTrigger_3_params.m` and replace the values in the first section. The units are shown on each line.
2. Run `R = StopTrigger_3_run();` in the MATLAB command window.

The script applies the values to the model, runs the simulation, prints the results and a hand calculation for comparison, and draws both figures. It first estimates running speed, coasting distance, and time to cover the target distance. It also warns if the car may be too slow. The script calculates the motor constants from the datasheet values, so you do not need to convert them by hand.

### What to ask the mech team

| Value | File name | Preset | How to get it |
|---|---|---|---|
| Car mass, ready to run | `P.m_car` | 2.0 kg | Weigh the car with battery and payload. |
| Driven wheel diameter | `P.wheel_dia` | 60 mm | Measure. |
| Gear ratio | `P.gear_ratio` | 100 | Motor turns per wheel turn, from the gearbox. |
| Rolling resistance | `P.Crr` | 0.02 | Roll-down test: push the car with the motor disconnected and measure the coast distance from a known speed. |
| Target distance | `P.Dtarget` | 20 m | Announced one hour before the run (15 to 30 m). |
| Motor no-load speed, current and test voltage | `P.rpm_nl`, `P.I_nl`, `P.V_nl` | 6736 rpm, 50 mA, 2.2 V | Motor datasheet, or measure on the bench. Measure the current with the gearbox fitted, so gearbox friction is included. |
| Winding resistance | `P.R_motor` | 4.5 Ω | Datasheet, or measure with the rotor held still. |
| Rotor inertia | `P.J_rotor` | 1 g·cm² | Motor datasheet. |
| Loaded pack voltage | `P.V_pack` | 2.2 V | Battery team, measured under the running load. |

Two inputs have the greatest effect on the result: speed strongly affects coasting distance because distance scales with $v^2$, and no-load current helps determine friction, which accounts for about half the drag in this model. Ask for those values first.

## Running it

- `StopTrigger_Bench_3.slx` is the simulation bench. Select **Run** to simulate a few seconds; this takes about one or two minutes.
- `StopTrigger_3_params.m` contains the car values. Edit this file when measured values are available.
- `StopTrigger_3_run.m` applies the values, runs the simulation, reports the results, and draws both figures.
- `StopTrigger_3_report.m` prints the results table and hand calculation.
- `StopTrigger_3_plot.m` draws the first figure, timed from `STOP`.
- `StopTrigger_3_compare.m` draws the second figure, with both sensors on one timeline.

```matlab
cd <your-directory>
R = StopTrigger_3_run();        % everything: values, simulation, table, both figures
```

The model uses workspace variables (`mcar`, `rw`, `Ng`, `Ke`, `Jm`, `T0m`, `Crr`, `Vpack`, `Rm`) internally. Edit the parameter file rather than these variables, because the next `StopTrigger_3_run` will overwrite them. Results are stored in `Car_LDR` and `Car_PT`, each containing speed (m/s), distance (m), shaft speed (rad/s), and motor current (A).

If you run a plot script without giving it input, it reuses results already in the workspace. Those results may be from older car values. Run `StopTrigger_3_run` after changing any parameter.

Compared with Stage 2, the light fade now starts at 2 s so the car can reach steady speed first, the simulation runs for 7 s, and the motor circuit includes back-EMF and car mechanics. The latch, coil driver, and relay are unchanged.

## Pass criteria and result

| Check | Result |
|---|---|
| Running speed and current match the hand calculation | Pass, 190.8 mm/s and 92.0 mA |
| Coast distance matches the hand calculation | Pass, 65.94 mm against 65.95 mm |
| Motors off within about 11 ms of `STOP` | Pass, 10.4 and 10.3 ms |
| Car stops and stays stopped | Pass, standstill 0.69 s after `STOP` |
| Distance logged for both sensors | Pass |

## Limits of this model

- All car values are placeholders. The distances are examples, not predictions of the real car.
- The battery is modelled as a constant 2.2 V supply. In reality, its voltage sags under load and falls during a run, changing the car's speed and coasting distance.
- The model assumes no wheel slip or gearbox backlash, and only simulates straight-line motion.
- Motor and gearbox friction are modelled as a constant torque. Real friction changes with speed and temperature.
- The simulation uses nominal component values and does not include Stage 1b's component variation. The 10.5 mm gap comes from one fixed noise sequence, not from an average across many simulated cars.
- As in Stage 2, the relay's 8 ms contact travel time is an assumption.

## Next

- Measure the car's mass, wheel diameter, gear ratio, and motor no-load current and speed using the real battery pack.
- Disconnect the motor and roll the car to a stop. Compare its coasting distance with the simulation to calibrate $T_0$ and $C_{rr}$.
- Combine the Stage 1b component variation with this model to calculate stopping-distance spread directly.
- Add a battery-pack model that includes voltage sag, so the simulated speed and coasting distance change with battery conditions.
