/*
 * sensors.h - Down-facing IR reflectance sensors on the Pololu 3pi+ 32U4
 *             (ECE 3218 Lab 8)
 *
 * Five QTR-style RC sensors, numbered left to right:
 *
 *   index  name          pin
 *     0    DN1 (left)    PD6
 *     1    DN2           PF7
 *     2    DN3 (center)  PF5
 *     3    DN4           PF4   (the handout's table calls this one "DN5")
 *     4    DN5 (right)   PF1
 *
 *   IR emitter control: PB7 (1 = emitters on)
 *
 * A reading is the time for a sensor's 2.2 nF capacitor to discharge
 * through its phototransistor. Bright surface -> lots of reflected IR ->
 * fast discharge -> SMALL number. Dark surface -> LARGE number.
 *
 * Timer3 is used for timing (Timer1 is reserved for the motor PWM from
 * Lab 7). It runs at F_CPU/8 = 2 MHz, so 1 tick = 0.5 us.
 */
#ifndef SENSORS_H
#define SENSORS_H

#include <stdint.h>

#define SENSOR_COUNT         5

/* Timer3 ticks per microsecond (16 MHz / 8 prescaler) */
#define SENSOR_TICKS_PER_US  2

/* A sensor that has not discharged after this many ticks is reported as
 * exactly SENSOR_TIMEOUT. 20000 ticks = 10 ms, as in the handout example. */
#define SENSOR_TIMEOUT       20000u

/* Set up the emitter pin, the sensor pins and Timer3.
 * Call once before sensors_read().                     */
void sensors_init(void);

/* Read all five sensors in parallel and store the discharge time of each,
 * in Timer3 ticks, in values[0..4] (left to right). Takes as long as the
 * slowest sensor, at most SENSOR_TIMEOUT ticks.
 * The emitters are on only while this function runs.                    */
void sensors_read(uint16_t values[SENSOR_COUNT]);

#endif /* SENSORS_H */
