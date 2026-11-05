// Down-facing IR reflectance sensors on the Pololu 3pi+ 32U4, left to right:
//
//   index  name          pin
//     0    DN1 (left)    PD6
//     1    DN2           PF7
//     2    DN3 (center)  PF5
//     3    DN4           PF4   (the handout's table calls this one "DN5")
//     4    DN5 (right)   PF1
//
// Emitter control is PB7: high = line sensor emitters on, low = bump sensor
// emitters on, input = all emitters off.
//
// A reading is how long the sensor's capacitor takes to discharge.
// Bright surface = small number, dark surface = large number.
// Timed with Timer3 at 16 MHz / 8, so 1 tick = 0.5 us.

#ifndef SENSORS_H
#define SENSORS_H

#include <stdint.h>

#define SENSOR_COUNT         5
#define SENSOR_TICKS_PER_US  2

// Sensors still high after this many ticks read as exactly this value.
// 20000 ticks = 10 ms, as in the handout example.
#define SENSOR_TIMEOUT       20000u

// Set up the emitter pin, the sensor pins and Timer3. Call once.
void sensors_init(void);

// Read all five sensors at once. values[i] is the discharge time of
// sensor i in ticks. Takes at most SENSOR_TIMEOUT ticks.
void sensors_read(uint16_t values[SENSOR_COUNT]);

#endif // SENSORS_H
