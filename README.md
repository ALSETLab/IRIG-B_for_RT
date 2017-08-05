# IRIG-B_for_RT
IRIG-B Signal Generator Code in Matlab/Simulink for use with Real-Time Simulators

# Source
* irig_only.mdl

This is a simulink model with the IRIG-B generator code embeded.
Double click the transmitter1 block to set the starting time (initial time)
To be able to record the data in PDC while supplying simulated IRIG-B time to the relays,
correct day of the year should be mentioned.

---------------------------------------------------------------------------------------

* irig_pulse_generator.m

This matlab script contains the code to simulate the IRIG-B Pulse.
The IRIG-B pulse amplitude is set to be 5.5V

---------------------------------------------------------------------------------------

*irig_final.mdl

Use this model to simulate time, current and vlotage inputs of the PMUs.
Voltage and Current signals might need to be amplified according to the input requirements
of the PMUs. The IRIG-B pulse of 5.5V amplitude can be fed direclty to the PMUs using a BNC cable.
The transmission delays are used to inlude the error in the timing in step of 10us.
The voltage and current signals can also be delayed by using the transmission delay blocks.
---------------------------------------------------------------------------------------
