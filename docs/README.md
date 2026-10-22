# Chem-E-Car Stop Trigger

This repository documents and simulates an optical stop-trigger circuit for a
Chem-E-Car. The circuit senses the solution darkening as the reaction finishes,
then signals the motor power to switch off. The notes follow the system from
the light sensor through to the car's stopping distance.

## Stage documents

Read the documents in order:

1. [Stage 1a: Sensor and comparator simulation](Stage1a.md) introduces the
   Simulink bench, explains the LDR and phototransistor circuits, and compares
   their trip behavior with a clean light signal.
2. [Stage 1b: Sensor variation and noise](Stage1b.md) tests 100 simulated
   units with component variation and light noise. It compares trip-point
   spread and chatter, and discusses per-car calibration and filtering.
3. [Stage 2: Latch, driver, relay, and motor shutdown](Stage2.md.md) models
   what happens after the comparator fires, including latch behavior, relay
   delay, flyback protection, and estimated time to switch off the motors.
4. [Stage 3: Vehicle stopping distance](Stage3.md) adds a car model to estimate
   travel during relay delay and coasting, and compares the stopping point for
   the two sensor types.

## Important limitations

The simulation results depend on assumptions. In particular, Stage 1b uses
assumed component spreads and noise, Stage 2 uses an assumed relay contact
travel time, and Stage 3 uses placeholder car parameters. Treat the results as
estimates until the relevant parts and vehicle behavior are measured on the
actual build. All circuits were built under the assumption of an iodine clock being used as the stopping mechanism.