# Stop trigger simulation

This note introduces the Simulink model for our optical stop trigger. It explains what the model includes, the sensor and circuit basics, why we made our design choices, and what still needs to be measured. Use it as a guide while exploring the model.

## What we are building

As the reaction in the jar finishes, the solution darkens and less light reaches the sensor. The circuit detects this change and produces a `STOP` signal to switch off the motors.

light → sensor → gain stage → comparator → (stage 2) latch → coil driver → relay → motors off

We compare two sensor options—an LDR and a phototransistor—using the same light input. First, we check that each circuit switches once without false or repeated triggers. Then we compare when each one switches.

The model is built in stages. Stage 1 covers the light input through the comparator. Stage 2 adds a latch, a MOSFET relay-coil driver, and a relay after the sensor trip point has been checked.

## Requirements

- MATLAB R2025b with Simulink, Simscape and Simscape Electrical.


## Running it and getting the results

1. Open `StopTrigger_Bench.slx` and select **Run**. The simulation takes a few seconds.
2. Open either sensor's scope to view the sensor voltage (`Vs`), amplifier output (`Va`), and `STOP` signal.
3. After the run, the MATLAB workspace contains `Tsig` (the light signal) and `LDR` and `PT` (the sensor results). Each sensor result contains `Vs`, `Va`, and `STOP` time series. For example, `LDR.Vs.Data` contains voltage samples and `LDR.Vs.Time` contains their times.
4. To create a spreadsheet, run `StopTrigger_export` in the MATLAB command window. The script runs the bench and creates `StopTrigger_results.csv` with columns `time_s, T, LDR_Vs, LDR_Va, LDR_STOP, PT_Vs, PT_Va, PT_STOP`.

To change the light fade, resistor values, or gains, edit the variables in the model workspace (**Model Explorer** > **Model Workspace**). The phototransistor circuit starts from zero initial conditions and takes about 1 ms to settle, so ignore its first few samples.

The model is laid out from left to right: light input, sensor, gain stage, comparator, and measurement probes. Each part is a subsystem; double-click one to inspect its circuit.

## Physics

**Light input.** Transmission $T(t)$ changes from clear to dark. The model assumes that illuminance $E$ is proportional to $T$:

$$T(t) = T_{end} + \frac{T_{start} - T_{end}}{1 + e^{(t - t_0)/\tau}}$$

**LDR.** An LDR's resistance falls as the light level rises:

$$R_{LDR} \approx A\,E^{-\gamma}, \quad \gamma \approx 0.8$$

The LDR and a fixed resistor form a voltage divider. As the jar darkens, the sensor output voltage falls:

$$V_{sensor} = V_+ \frac{R_{fixed}}{R_{LDR} + R_{fixed}}$$

The divider is most sensitive near the trip point when $R_{fixed} = R_{LDR}$, so we chose $A$ to make those resistances equal there. LDR response times are typically 10 to 100 ms. LDRs also contain cadmium.

**Phototransistor.** The model assumes that photocurrent increases in proportion to light, and that the transistor amplifies this current:

$$I_B = S\,E, \quad I_C = \beta\,I_B, \quad V_{sensor} \approx V_+ - I_C R_{fixed}$$

In this circuit, the sensor output rises as the jar darkens—the opposite direction from the LDR output. The transistor must not saturate when the jar is clear. Phototransistors respond in microseconds.

**Gain stage.** A non-inverting op-amp increases the sensor voltage without significantly loading the sensor:

$$V_{out} = V_{sensor}\left(1 + \frac{R_2}{R_1}\right)$$

**Hysteresis.** Hysteresis gives the comparator separate switch-on and switch-off thresholds. Feeding some of the comparator output back through $R_b$, while connecting the reference through $R_a$, creates a voltage band of

$$\Delta V = (V_{OH} - V_{OL})\frac{R_a}{R_a + R_b}$$

For a 5 V output swing, a 100 mV band needs $R_a/(R_a + R_b) = 0.02$. The bench uses 1 kΩ and 47 kΩ for this. The final band should be chosen using noise measured on the real circuit.

This arrangement is used for the LDR: its signal falls as the jar darkens, so it connects to the inverting input and the comparator drives `STOP` high at the trip point. The phototransistor signal rises in the dark, so its comparator uses the opposite input arrangement. Its signal connects through $R_{in}$ to the non-inverting input, with feedback through $R_b$ and the reference on the inverting input. This gives a hysteresis band of $(V_{OH} - V_{OL})R_{in}/R_b$ and a trip voltage of $V_{ref}(1 + R_{in}/R_b)$.

## Design choices

| Question | Choice | Reason |
|---|---|---|
| What should we simulate first? | The stop trigger | It is the smallest well-defined part and is central to the circuits team's work. |
| Which sensor should we test? | Both, using the same input | This lets us directly test the audit's preference for the phototransistor. |
| How much of the circuit should we include? | Build in stages: sensor to comparator first, then latch and relay | We can check the trip point before adding latch behavior and relay delay. |
| What light input should we use? | An adjustable sigmoid fade with settable start, end, $t_0$, and $\tau$ | It resembles an iodine clock reaction and can later be replaced with measured data. A sudden step would hide chatter. |
| Where should the model go? | In a new file beside the base model | This keeps the original model unchanged. |
| What trip level should we target? | $T = 0.5$ | This gives equal margin to the clear and dark end states. |
| How should the comparator be wired? | Use the polarity needed by each sensor | LDR output falls in the dark; phototransistor output rises. |

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

The base model has three stop-trigger subsystems. Each uses the same layout: sensor, op-amp gain stage, and ideal switch.

- `Stopping Mech` uses a photodiode.
- `Stopping Mech_LDR` uses a potentiometer standing in for the LDR.
- `Stopping Mech_Phototransistor` uses a current source driving an NPN.

None has the comparator with hysteresis, the latch, the coil driver or the relay.

Running the base model currently fails during compilation. The physical network in `Motor System` (`PS Constant1` and `Vehicle Body`) is missing a Solver Configuration block. The bench model avoids this problem by giving each sensor variant its own solver configuration.

## Pass criteria

For both variants:

1. STOP asserts once and stays asserted.
2. It trips at $T = 0.5 \pm 0.05$.
3. Every node stays between 0 and 5 V.
4. Trip time and the voltage margin to each end state are logged for LDR and phototransistor.

## Stage 1 results

Both sensor versions pass all four checks.

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

The LDR results match the hand calculation above. The two versions trip within 10 ms of each other because the light fades over several seconds and this stage does not yet model the LDR's response delay. The main difference is the voltage margin around the trip point. The phototransistor responds linearly, giving it nearly equal margins on both sides. The LDR follows a power law, leaving less margin on the clear side. For both sensors, the margins are much larger than the 0.1 V hysteresis band.

There is a wiring difference from some earlier notes. The audit connects the phototransistor with a collector pull-up, so its output rises as the jar darkens. The Simulation Research write-up and the base model use an emitter pull-down, where the output falls instead. This bench follows the audit's collector pull-up arrangement.

## What we still need

This model makes several simplifications. Stage 1 does not include the LDR's 10 to 100 ms response time, the op-amp and comparator are ideal, and the sigmoid is only an approximation of the real reaction.

Before relying on the model, measure:
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
