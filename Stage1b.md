# Stop trigger simulation: stage 1b

Stage 1 showed both sensors trip once on a clean, ideal input. Stage 1b asks the harder question: with real-world scatter, which sensor trips closer to where we want it?

Status: built and run, 100 simulated units. Stage 2 (latch, coil driver, relay) is not started.


## The short version

- Neither sensor trips on target without per-car trim. Only 28 of 100 LDR units and 42 of 100 phototransistor units trip within $\pm 0.05$ of the target.
- The phototransistor is closer to target on average, but 6 in 100 units chatter on 1% light noise and 2 fire far too early.
- The LDR never chatters, because its slow response filters the noise, but its trip point is more scattered.
- Both need the Vref trim pot. The phototransistor also needs more hysteresis or a small filter.

## What the plot shows

![[stoptrigger_1b_spread.png]]

Each unit is one simulated car with its own random part values. The x-axis is the light level $T$ at the moment `STOP` fired (1 = clear jar, 0.1 = dark jar). The dashed line is the target, $T = 0.5$, and the dotted lines are $\pm 0.05$.

- Right of the target (higher $T$): fired early, jar still fairly clear.
- Left of the target (lower $T$): fired late, jar darker than intended.
- A narrow, centred pile is good. A wide one means unreliable stops.

## Results (100 units, 1% light noise)

| | LDR | Phototransistor |
|---|---|---|
| Mean trip $T$ | 0.466 | 0.503 |
| Std of trip $T$ | 0.127 | 0.113 |
| Within $\pm 0.05$ of 0.5 | 28 | 42 |
| Within $\pm 0.10$ of 0.5 | 49 | 71 |
| Fired late ($T < 0.3$) | 7 | 2 |
| Fired early ($T > 0.7$) | 8 | 7 |
| Units that chattered (STOP toggled more than once) | 0 | 6 |
| Units that never fired | 0 | 0 |

What drives the scatter:

- **Phototransistor gain.** The six chattering units all had gain 28% to 93% above nominal. The two worst early firings had about half or two thirds of nominal gain. One of them fired at $t = 0$: its clear-state sensor voltage already sat above the trip level.
- **LDR spread.** Its $A$ and $\gamma$ scatter moves the trip point in both directions.
- **LDR lag.** The 50 ms lag pulls its mean down: even a nominal LDR trips at $T = 0.454$, not 0.5.

## What this means for the build

1. Fit a trim pot on Vref for each car and set it with the real jar. The assumed spread is too wide to leave untrimmed on either sensor.
2. If we choose the phototransistor, add hysteresis or a 1 to 10 ms input filter before relying on it. Stage 1 used a 0.104 V band. At the trip point the phototransistor changes about 4 V per unit of $T$, so 1% noise is about 40 mV rms and a band that size is not enough.
3. The stage 1 margin advantage (see [[Stop Trigger Simulation]]) shows up here as a tighter spread, but it is not a free win. The phototransistor's high sensitivity is also what lets noise and gain scatter through.

## What changed from stage 1

| Item | Stage 1 | Stage 1b |
|---|---|---|
| Light fade | $\tau = 1$ s, $t_0 = 10$ s, 20 s run | $\tau = 0.25$ s, $t_0 = 5$ s, 10 s run |
| LDR response | none | 50 ms first-order lag (`tauL`) before the LDR model |
| Light noise | none | band-limited white noise, 1% rms of $T$, 5 ms sample time, shared by both sensors |
| Part values | one nominal set | random per unit (table below) |
| Output | scopes and CSV | trip-point histogram and `StopTrigger_1b_results.csv` |

Per-unit scatter, all assumed rather than measured:

| Part | Spread (1 σ) |
|---|---|
| LDR constant $A$ | 20% (lognormal) |
| LDR exponent $\gamma$ | $\pm 0.05$ around 0.8 |
| Phototransistor gain (current per light) | 25% (lognormal) |
| $R_{fixed}$ | 0.5% |
| Vref setting (both) | 10 mV |

## Running it

- `StopTrigger_Bench_1b.slx`: the bench. Press Run for one nominal run. It logs `Tsig` (clean light), `Tnoisy` (light with noise), `LDR` and `PT`.
- `StopTrigger_1b_mc.m`: the Monte Carlo.

In the MATLAB command window:

```matlab
cd <your-directory>
R = StopTrigger_1b_mc(100);          % 100 units, 1% noise, about 6 minutes
R = StopTrigger_1b_mc(100, 0.02);    % same, 2% noise
```

It prints the summary table, draws the histogram and writes `StopTrigger_1b_results.csv` with one row per unit. The random draws use a fixed seed, so reruns give the same units. Change the noise level or the spread sizes by editing the top of the `.m` file.

To see the circuit's voltages and currents: `Vs` and `Va` are logged and on the scopes. The sensor current flows through $R_{fixed}$, so for the LDR $I = V_s / R_{fixed}$ and for the phototransistor $I = (V_{cc} - V_s) / R_{fixed}$. Nominal values are about 320 to 110 µA (LDR, clear to dark) and 360 to 45 µA (phototransistor).

## Limits of this run

- The spread sizes and the 1% noise are assumptions. Replace them with TEPT4400 datasheet limits and noise measured on the real rig.
- Noise is applied to the light and is shared by both sensors. Electrical noise at the comparator is not modelled.
- Op-amp and comparator are ideal, and the sigmoid still stands in for the real reaction.

## Next

- Size the hysteresis or filter from measured noise, then rerun with the phototransistor.
- Replace the assumed spreads with measured values.
- Stage 2: latch, coil driver and relay.
