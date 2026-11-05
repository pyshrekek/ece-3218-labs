// Turns raw sensor times into "how dark" values and a line position.
//
// Sensor positions come from Pololu's 3pi+ 32U4 OLED control board drawing
// (bottom view): DN2-DN4 are 10 mm apart, and DN1/DN5 are 30 mm from the
// center and sit about 12 mm behind the other three. Check with a ruler.

#ifndef LINE_H
#define LINE_H

#include <stdint.h>
#include "sensors.h"

// Sideways position of each sensor from the center, in tenths of a mm
// (left is negative).
#define LINE_SENSOR_X_TENTHS_MM  { -300, -100, 0, 100, 300 }

// A sensor must change by at least this much (Timer3 ticks) between
// white and black during calibration, or calibration is rejected.
#define LINE_CAL_MIN_RANGE  500

// Fully dark reads as this value after normalizing.
#define LINE_DARK_MAX  1000

// Below this total darkness there is no line under the sensors.
#define LINE_MIN_TOTAL  300

typedef struct {
    uint16_t min[SENSOR_COUNT];    // whitest time seen (ticks)
    uint16_t max[SENSOR_COUNT];    // darkest time seen (ticks)
} line_cal_t;

// Start a new calibration.
void line_cal_reset(line_cal_t *cal);

// Widen each sensor's min/max with one reading.
void line_cal_update(line_cal_t *cal, const uint16_t values[SENSOR_COUNT]);

// Index of the first sensor whose min/max range is too small (it never
// saw both white and black), or -1 if every sensor is calibrated.
int8_t line_cal_check(const line_cal_t *cal);

// Darkness of each sensor: 0 on white, LINE_DARK_MAX on black.
void line_normalize(const line_cal_t *cal, const uint16_t values[SENSOR_COUNT],
                    uint16_t dark[SENSOR_COUNT]);

// Darkness-weighted average of the sensor positions, in tenths of a mm
// (0 = line centered, negative = line to the left). Returns 0 and leaves
// *x unchanged if there is no line under the sensors.
uint8_t line_position(const uint16_t dark[SENSOR_COUNT], int16_t *x);

#endif // LINE_H
