# Stop trigger simulation: stage 2

Stage 2 models what happens after the comparator switches: the latch, relay-coil driver, relay, and motor circuit. It answers the question: how long does it take for the motors to switch off after `STOP` fires?


Related notes: [[Stop Trigger Simulation]] (stage 1), [[Stop Trigger Simulation - Stage 1b]], [[Stop Trigger Simulation - Stage 3]], [[Stopping Sensor - LDR vs Phototransistor]], [[Propulsion Electrical Design]].

## The short version

- In the simulation, the motors switch off about **10.9 ms** after `STOP` for either sensor. The circuits after the comparator are the same, so sensor choice does not affect this delay.
- The distance travelled during a delay is $d = v\,\Delta t$. At 1 m/s, the car travels about 11 mm in 10.9 ms.
- The latch sets once and stays set. It ignores a re-arm button press while the jar is still dark.
- Most of the delay comes from the relay: about 2.3 ms for the coil current to build, followed by an assumed 8 ms for the contacts to move.

> [!warning] `Energised` is a simulation signal, and the 8 ms is an assumption
> - **Pulled in** means the coil current has reached 59.3 mA, or 75% of its rated 79 mA. At this point, the magnetic force can pull the relay arm against its spring and start moving the contact.
> - `Energised` (0 or 1) is a simulation-only flag that represents the relay being pulled in. A real relay has no such electrical signal; its arm moves physically.
> - After `Energised` changes to 1, the simulation waits an assumed **8 ms** for the contact to move and open. This is a placeholder, not a datasheet value or measurement. It accounts for about three quarters of the simulated 10.9 ms total delay.
> - Measure the actual G5LE-1 from coil-on to contact-open to get the real delay. Until then, treat 10.9 ms as an estimate, not a measured result.

## What the plot shows

![[stoptrigger_2_timeline.png]]

The timeline starts when `STOP` fires. The circuits after the comparator are identical for the LDR and phototransistor, and their results differ by less than 0.1 ms, so the plot shows one chain.

1. Comparator output `STOP` and latch output `Q` rise together.
2. Current in the relay coil increases toward 79 mA. The relay pulls in when the current reaches 59.3 mA.
3. The MOSFET drain voltage falls from 5 V to about 0 V. At switch-on, it briefly rises to 5.6 V due to a switching transient. Without the diode it reaches 6.8 V, so the diode reduces this transient. This is not the coil's flyback kick, which occurs at switch-off and is tested separately below.
4. Motor current is 0.48 A until the relay contact opens, then falls to zero. The dashed line marks when the motors are off.

## Results

Both sensors give the same result to within 0.1 ms.

| | Both sensors |
|---|---|
| Latch `Q` high after `STOP` | under 1 ms |
| Coil current reaches 59.3 mA | +2.2 to +2.3 ms |
| Motor current down 5% | +10.2 to +10.3 ms |
| **Motor current below 5% (motors off)** | **+10.8 to +10.9 ms** |
| Running motor current | 0.484 A |
| Peak driver drain voltage (turn-on) | 5.60 V |
| Latch `Q` transitions | 1 |
| `Q` after re-arm press at 2.5 s | 5 V (held) |
| Coil current, final | 79.0 mA |

The sensors differ only in when `STOP` fires. In this run, the LDR triggers at 1.109 s and the phototransistor at 1.055 s. The 54 ms difference is due to the LDR's response delay.

The model does not include the 74HC00's roughly 10 ns propagation delay, so the latch delay appears as zero.

### Flyback test (coil turn-off)

In the main bench, `Q` stays high, so the relay coil never switches off. We test the flyback diode separately by switching the coil on and then off at its full 79 mA.

| | With the diode | Without the diode |
|---|---|---|
| Drain voltage peak at turn-off | 5.6 V | above 1000 V (test limit) |
| Drain voltage peak at turn-on | 5.6 V | 6.8 V |
| Coil current below 5% after turn-off | 3.0 ms | under 1 ms (collapses at once) |

The diode limits the voltage spike when the coil switches off to about the supply voltage plus one diode drop. Without the diode, the simulated spike exceeds 1000 V—far above the IRLZ44N's roughly 55 V rating (check the datasheet). This could destroy the MOSFET. The diode is required; its striped end must face the +5 V supply.

## How it works

The circuit works in this order: `STOP` sets the SR latch, the latch output drives the MOSFET gate, and the MOSFET switches on the relay coil. When the relay pulls in, a normally closed contact in the motor circuit opens.

- **Latch:** Two cross-coupled NAND gates, as in a 74HC00, form the latch. `STOP` above 2.5 V sets it; the re-arm button resets it. Set takes priority, so the button cannot clear a stop while the jar is dark. The model presses the button at 0 s to arm the latch and again at 2.5 s to check that the press is ignored.
- **Coil driver:** An IRLZ44N MOSFET switches the coil on the 5 V rail. A flyback diode is connected across the coil. The model gives the MOSFET gate a 1 µs transition, similar to a real logic output.
- **Relay:** The coil is modelled as a resistor and inductor. The relay pulls in at 75% of its rated current and releases at 10% (59.3 mA and 7.9 mA for a 79 mA rating). At 59.3 mA, the simulation raises its `Energised` flag and assumes the contact opens after 8 ms of mechanical movement.
- **Motor circuit:** The 2.2 V battery pack powers a motor modelled as 4.5 Ω in series with 2 mH. A freewheel diode is connected across the motor, and the relay contact is in series with it. This stage does not include motor back-EMF, so it models electrical current only.

## Design choices

| Question | Choice | Why |
|---|---|---|
| Contact type | Normally closed, opens when the coil is energised | Our assumption. The audit lists the driver and relay but not which contact to use. |
| Latch inputs | Set-dominant | Re-arm cannot release a stop while the jar is still dark. |
| One block or two | One stage 2 block, copied for each sensor | Sensor choice is still open. Both feed the same downstream design. |
| Separate networks | Coil circuit and motor circuit each have their own solver block and ground | The motors run from the pack, the coil from the instrumentation rail. |

One trade-off of this contact choice is that losing power to the relay coil leaves the motors running. A normally open contact held closed by the coil would stop the car if coil power were lost, but it would draw coil current while the car is running.

## Parameters

| Item | Value | Source |
|---|---|---|
| Relay | Omron G5LE-1 DC5 | Audit |
| Coil resistance and current | 63.3 Ω, about 79 mA at 5 V | G5LE-1 DC5 rating |
| Coil inductance | 0.1 H | **Assumed.** Not on the datasheet, replace with a measurement. |
| Contact travel, open and close | 8 ms and 3 ms | **Assumed.** Typical figures for a small relay. Check against the G5LE-1 datasheet and measure. |
| MOSFET | IRLZ44N: 22 mΩ at $V_{GS} = 5$ V, $V_{th} = 1.7$ V | Audit part, datasheet values |
| Flyback diode | Generic diode (0.6 V forward) | Stand-in for the 1N4007 |
| Motor | 4.5 Ω, 2 mH, 2.2 V supply | Tamiya 70203 stall resistance, loaded pack voltage |
| Comparator | Ideal | Stand-in for the MCP6541 |

The relay timing assumptions determine most of the 10.9 ms delay. Measuring the real relay is therefore the most useful next step.

## Running it

- `StopTrigger_Bench_2.slx` is the simulation bench. Select **Run** to simulate 3 s; it takes about 30 s.
- `StopTrigger_2_report.m` runs the bench and reports the pass checks and delay for both sensors.
- `StopTrigger_2_plot.m` creates the timeline plot above.
- `StopTrigger_2_flyback_test.m` switches the coil on and off, tests with and without the diode, and reports the peak voltages.

```matlab
cd <your-directory>
R = StopTrigger_2_report();     % pass checks and timing
StopTrigger_2_plot(R);          % labelled figure
```

The results appear in the workspace as `S2_LDR` and `S2_PT`. Each contains `Q`, `Icoil`, `Vds`, `Relay`, and `Im`.

Keep the maximum solver step at 0.1 ms; `MaxStep` is set in the file. With the previous 10 ms step, the relay appeared about 10 ms late because the solver did not pass the MOSFET gate transition to the coil circuit until the next step.

Compared with Stage 1b, the light fade starts at 1 s instead of 5 s, the simulation runs for 3 s, and the re-arm pulse repeats every 2.5 s.

## Pass criteria and result

| Check | Result |
|---|---|
| `STOP` latches once and stays | Pass, both sensors |
| Coil current about 79 mA | Pass, 79.0 mA |
| Flyback diode holds the coil turn-off kick near the rail | Pass, 5.6 V with the diode (separate coil test), above 1000 V without |
| Motors off, delay logged | Pass, +10.9 ms and +10.8 ms |
| Re-arm during a dark jar is ignored | Pass |

## Limits of this model

- The relay-coil inductance and contact timing (including the 8 ms travel time) are assumptions; see **Parameters**. `Energised` is a simulation flag, not a real circuit signal.
- This stage does not model motor back-EMF or mechanics, so its 0.48 A running current is too high. Stage 3 adds both and gives a running current of about 92 mA.
- The model does not include contact bounce or arcing.
- The simulation uses nominal component values and does not include the component variation from Stage 1b.

## Next

- Measure the actual relay's coil inductance and operate and release times.
- Convert the 10.9 ms delay into a stopping distance. Stage 3 does this with placeholder car values; in that model, about 2 mm of travel occurs during the relay delay.
- Run the model with the Stage 1b component variations to estimate the spread in relay timing.
