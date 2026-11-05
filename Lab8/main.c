/*
 * main.c - ECE 3218 Lab 8: Controlling and Reading Volatile Sensors
 *
 * Reads all five down-facing IR reflectance sensors of the Pololu 3pi+
 * 32U4 over and over (see sensors.c for how one reading works) and shows
 * the discharge time of each sensor on the OLED, left sensor on top.
 *
 * Each value on screen is the average of SAMPLES_PER_UPDATE readings, in
 * microseconds. The averaging steadies the numbers and gives the
 * "average timeout period" asked for in Part 3.1 directly: put the robot
 * on a bright or dark surface and copy down the five numbers.
 *
 *   small number = bright surface (lots of reflected IR)
 *   large number = dark surface   (10000 us = timed out)
 */
#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include <avr/io.h>
#include <stdio.h>
#include "OLED.h"
#include "sensors.h"

/* Readings averaged into each displayed value */
#define SAMPLES_PER_UPDATE  16

/* The array the rest of the course builds on: latest brightness under
 * each sensor, left to right, in Timer3 ticks.                          */
static uint16_t sensor_values[SENSOR_COUNT];

static const char *const sensor_names[SENSOR_COUNT] = {
    "DN1 L", "DN2  ", "DN3 C", "DN4  ", "DN5 R"
};

static void oled_setup(void)
{
    OLED_init();
    OLED_reset();
    OLED_clearDisplayRam();
    OLED_configureDefault();
}

int main(void)
{
    char text[OLED_TEXT_MAX + 1];

    oled_setup();
    sensors_init();

    snprintf(text, sizeof text, "Avg of %u (us)", SAMPLES_PER_UPDATE);
    OLED_writeTextLine(0, text);

    for (;;) {
        uint32_t sum[SENSOR_COUNT] = { 0 };

        for (uint8_t n = 0; n < SAMPLES_PER_UPDATE; n++) {
            sensors_read(sensor_values);
            for (uint8_t i = 0; i < SENSOR_COUNT; i++)
                sum[i] += sensor_values[i];
        }

        for (uint8_t i = 0; i < SENSOR_COUNT; i++) {
            uint16_t avg_us = (uint16_t)(sum[i]
                / (SAMPLES_PER_UPDATE * SENSOR_TICKS_PER_US));
            snprintf(text, sizeof text, "%s %5uus", sensor_names[i], avg_us);
            OLED_writeTextLine(i + 2, text);
        }
    }
}
