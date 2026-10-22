# Stop trigger simulation: stage 1b

In Stage 1, both sensors switched once when given a clean, ideal light signal. Stage 1b adds variation between parts and noise to ask a more practical question: which sensor is more likely to switch near the target?

**Status:** Built and run with 100 simulated units. Stage 2 (latch, coil driver, and relay) has not started.


## The short version

- Without an individual trim adjustment for each car, neither sensor always trips close to the target. Only 28 of the 100 LDR units and 42 of the 100 phototransistor units trip within $\pm 0.05$ of it.
- The phototransistor is closer to the target on average. However, 6 of 100 units switch repeatedly (chatter) with 1% light noise, and 2 trigger much too early.
- None of the LDR units chatter in this simulation. Its slower response smooths out the noise, but its trip points are more spread out.
- Both sensor types need a trim pot to adjust $V_{ref}$. The phototransistor also needs more hysteresis or a small input filter.

## What the plot shows

![[stoptrigger_1b_spread.png]]

Each point represents one simulated car with its own randomly selected component values. The horizontal axis shows the light transmission $T$ when `STOP` triggers: 1 means a clear jar and 0.1 means a dark jar. The dashed line marks the target ($T = 0.5$); the dotted lines show the allowed range ($\pm 0.05$).

- A point to the right of the target (higher $T$) means the circuit triggered early, while the jar was still relatively clear.
- A point to the left (lower $T$) means it triggered late, after the jar had become darker than intended.
- A narrow group of points around the target means more consistent stops. A wide spread means less reliable stopping.

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

The main causes of the spread are:

- **Phototransistor gain:** All six units that chattered had gain 28% to 93% above nominal. The two earliest-triggering units had about half or two-thirds of nominal gain. One triggered at $t = 0$ because its sensor voltage in the clear state was already above the trip level.
- **LDR component variation:** Variation in $A$ and $\gamma$ shifts the trip point in either direction.
- **LDR response delay:** The simulated 50 ms delay moves the average trip point lower. Even a nominal LDR triggers at $T = 0.454$, rather than 0.5.

## What this means for the build

1. Add a $V_{ref}$ trim pot to each car and adjust it using the real jar. The assumed component variation is too large to leave either sensor untrimmed.
2. If we choose the phototransistor, add hysteresis or a 1 to 10 ms input filter before using it. Stage 1 used a 0.104 V hysteresis band. Near the trip point, the phototransistor signal changes by about 4 V for each unit change in $T$, so 1% noise is about 40 mV rms. A 0.104 V band is not enough to prevent chatter under that noise.
3. Stage 1 showed that the phototransistor has a larger voltage margin (see [[Stop Trigger Simulation]]), and this stage shows a tighter trip-point spread. But higher sensitivity also makes it more affected by noise and gain variation.

## What changed from stage 1

| What changed | Stage 1 | Stage 1b |
|---|---|---|
| Light fade | $\tau = 1$ s, $t_0 = 10$ s, 20 s run | $\tau = 0.25$ s, $t_0 = 5$ s, 10 s run |
| LDR response | none | 50 ms first-order lag (`tauL`) before the LDR model |
| Light noise | none | band-limited white noise, 1% rms of $T$, 5 ms sample time, shared by both sensors |
| Part values | one nominal set | random per unit (table below) |
| Output | scopes and CSV | trip-point histogram and `StopTrigger_1b_results.csv` |

The following part-to-part variations are assumptions, not measurements:

| Part | Spread (1 σ) |
|---|---|
| LDR constant $A$ | 20% (lognormal) |
| LDR exponent $\gamma$ | $\pm 0.05$ around 0.8 |
| Phototransistor gain (current per light) | 25% (lognormal) |
| $R_{fixed}$ | 0.5% |
| Vref setting (both) | 10 mV |

## Running it

- `StopTrigger_Bench_1b.slx` is the simulation bench. Select **Run** for one nominal run. It logs `Tsig` (clean light), `Tnoisy` (noisy light), and the `LDR` and `PT` results.
- `StopTrigger_1b_mc.m` runs the Monte Carlo test, which repeats the simulation using different component values.

Run the following in the MATLAB command window:

```matlab
cd <your-directory>
R = StopTrigger_1b_mc(100);          % 100 units, 1% noise, about 6 minutes
R = StopTrigger_1b_mc(100, 0.02);    % same, 2% noise
```

The script prints a summary table, plots a histogram, and writes `StopTrigger_1b_results.csv` with one row per simulated unit. It uses a fixed random seed, so repeated runs use the same component values. To change the noise level or component variation, edit the settings near the top of the `.m` file.

To inspect circuit voltages, view `Vs` and `Va` in the logged results or on the scopes. The sensor current flows through $R_{fixed}$. Calculate it as $I = V_s / R_{fixed}$ for the LDR and $I = (V_{cc} - V_s) / R_{fixed}$ for the phototransistor. The nominal current ranges are about 320 to 110 µA for the LDR (clear to dark) and 360 to 45 µA for the phototransistor.

## Limits of this run

- The component variation and 1% noise are assumptions. Replace them with TEPT4400 datasheet limits and noise measurements from the real rig.
- The model adds noise to the light signal, and both sensors receive the same noisy signal. It does not include electrical noise at the comparator.
- The op-amp and comparator are ideal in the simulation. The sigmoid light fade is still only an approximation of the real reaction.

## Next

- Measure the noise, use it to choose the hysteresis or filter, and then rerun the phototransistor simulation.
- Measure component variation and replace the assumed spreads with those values.
- Continue to Stage 2: latch, coil driver, and relay.
