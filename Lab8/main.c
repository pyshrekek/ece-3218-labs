// ECE 3218 Lab 8: Controlling and Reading Volatile Sensors
//
// Three screens, each moved on from with button A:
//
//   1. Raw     Average discharge time of each sensor in us (Part 3.1).
//   2. Cal     Sweep the robot back and forth over the line so every
//              sensor sees both white and black. A = done.
//   3. Line    Darkness of each sensor (0-99), the line position x, and
//              the angle from two positions (Part 3.2): put the robot on
//              the line, press A to mark x, slide it SLIDE_MM straight
//              forward, and read the angle.
//
// Press RESET to start over.

#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include <avr/io.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "OLED.h"
#include "button.h"
#include "line.h"
#include "sensors.h"

#define RAW_SAMPLES   16   // readings averaged per update on screen 1
#define LINE_SAMPLES  4    // readings averaged per update on screen 3
#define CAL_REDRAW    8    // readings between redraws on screen 2

// Distance to slide the robot forward between the two angle readings
#define SLIDE_MM      30

static uint16_t sensor_values[SENSOR_COUNT];
static char text[OLED_TEXT_MAX + 1];

static const char *const sensor_names[SENSOR_COUNT] = {
    "DN1 L", "DN2  ", "DN3 C", "DN4  ", "DN5 R"
};

static void line_text(uint8_t line, const char *s)
{
    snprintf(text, sizeof text, "%s", s);
    OLED_writeTextLine(line, text);
}

// 1 once per press of button A
static uint8_t a_clicked(void)
{
    if (!button_a_pressed())
        return 0;
    button_a_wait_release();
    return 1;
}

// Tenths of a mm as "+12.5"
static void format_tenths(char *out, size_t size, int16_t v)
{
    uint16_t a = (uint16_t)abs(v);
    snprintf(out, size, "%c%u.%u", v < 0 ? '-' : '+', a / 10, a % 10);
}

// Darkness 0-1000 as 0-99, so five fit on one OLED line
static unsigned dark_99(uint16_t d)
{
    unsigned v = d / 10;
    return v > 99 ? 99 : v;
}

// Average of n readings, in ticks
static void read_average(uint16_t avg[SENSOR_COUNT], uint8_t n)
{
    uint32_t sum[SENSOR_COUNT] = { 0 };

    for (uint8_t k = 0; k < n; k++) {
        sensors_read(sensor_values);
        for (uint8_t i = 0; i < SENSOR_COUNT; i++)
            sum[i] += sensor_values[i];
    }
    for (uint8_t i = 0; i < SENSOR_COUNT; i++)
        avg[i] = (uint16_t)(sum[i] / n);
}

// ---- Screen 1: raw times ----------------------------------------------------
static void raw_screen(void)
{
    uint16_t avg[SENSOR_COUNT];

    OLED_clearDisplayRam();
    snprintf(text, sizeof text, "Raw avg%u (us)", RAW_SAMPLES);
    OLED_writeTextLine(0, text);
    line_text(7, "A = calibrate");

    while (!a_clicked()) {
        read_average(avg, RAW_SAMPLES);
        for (uint8_t i = 0; i < SENSOR_COUNT; i++) {
            snprintf(text, sizeof text, "%s %5uus", sensor_names[i],
                     avg[i] / SENSOR_TICKS_PER_US);
            OLED_writeTextLine(i + 2, text);
        }
    }
}

// ---- Screen 2: calibration -------------------------------------------------
static void calibrate_screen(line_cal_t *cal)
{
    OLED_clearDisplayRam();
    line_text(0, "Sweep over line");
    line_text(1, "  min    max us");
    line_text(7, "A = done");
    line_cal_reset(cal);

    for (uint8_t n = 0; ; n++) {
        sensors_read(sensor_values);
        line_cal_update(cal, sensor_values);

        if (n % CAL_REDRAW == 0) {
            for (uint8_t i = 0; i < SENSOR_COUNT; i++) {
                snprintf(text, sizeof text, "%u %5u %5u", i + 1,
                         cal->min[i] / SENSOR_TICKS_PER_US,
                         cal->max[i] / SENSOR_TICKS_PER_US);
                OLED_writeTextLine(i + 2, text);
            }
        }

        if (a_clicked()) {
            int8_t bad = line_cal_check(cal);
            if (bad < 0)
                return;
            snprintf(text, sizeof text, "DN%d not swept!", bad + 1);
            OLED_writeTextLine(7, text);
        }
    }
}

// ---- Screen 3: line position and angle -------------------------------------
//
// x is where the line is under the sensors (+ = right of center). If x
// changes by dx while the robot slides SLIDE_MM straight forward, the
// robot's heading is atan(dx / SLIDE_MM) off the line.
// A positive angle means the robot is turned left (CCW) of the line.
static void line_screen(const line_cal_t *cal)
{
    uint16_t avg[SENSOR_COUNT];
    uint16_t dark[SENSOR_COUNT];
    int16_t  x = 0, x_mark = 0;
    uint8_t  marked = 0;
    char     num[8];

    OLED_clearDisplayRam();
    line_text(0, "Line  A = mark x");
    snprintf(text, sizeof text, "slide %umm fwd", SLIDE_MM);
    OLED_writeTextLine(7, text);

    for (;;) {
        read_average(avg, LINE_SAMPLES);
        line_normalize(cal, avg, dark);
        uint8_t found = line_position(dark, &x);

        snprintf(text, sizeof text, "d %2u %2u %2u %2u %2u",
                 dark_99(dark[0]), dark_99(dark[1]), dark_99(dark[2]),
                 dark_99(dark[3]), dark_99(dark[4]));
        OLED_writeTextLine(2, text);

        if (found) {
            format_tenths(num, sizeof num, x);
            snprintf(text, sizeof text, "x  %smm", num);
        } else {
            snprintf(text, sizeof text, "x  no line");
        }
        OLED_writeTextLine(3, text);

        if (a_clicked() && found) {
            x_mark = x;
            marked = 1;
        }

        if (marked && found) {
            int16_t dx = x - x_mark;
            int16_t deg = (int16_t)lround(atan2(dx / 10.0, SLIDE_MM)
                                          * 180.0 / M_PI);
            format_tenths(num, sizeof num, dx);
            snprintf(text, sizeof text, "dx %smm", num);
            OLED_writeTextLine(5, text);
            snprintf(text, sizeof text, "ang %+d deg", deg);
            OLED_writeTextLine(6, text);
        } else {
            line_text(5, marked ? "dx no line" : "dx (press A)");
            line_text(6, "");
        }
    }
}

int main(void)
{
    line_cal_t cal;

    OLED_init();
    OLED_reset();
    OLED_clearDisplayRam();
    OLED_configureDefault();
    sensors_init();
    button_a_init();

    raw_screen();
    calibrate_screen(&cal);
    line_screen(&cal);
}
