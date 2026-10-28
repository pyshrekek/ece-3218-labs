/*
 * main.c - ECE 2218 Lab 7: Motor Control of the Pololu 3pi+ 32U4 using PWM
 *
 * Sequence (matches the "Before the Lab" steps):
 *   1. Setup: brake motors, wait for button A.
 *   2. Full-speed test, one motor at a time.
 *   3. Full-speed test, both motors together.
 *   4. Quarter-speed tests using Timer1 phase-correct PWM.
 * After that, each press of button A switches to the next Timer1
 * prescaler and repeats step 4, for the in-lab prescaler experiment.
 */
#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>
#include "motors.h"
#include "button.h"

/* ---- Settings ---------------------------------------------------------- */

/* Set to 1 in lab once font.c, OLED.c and OLED.h are in this folder.
 * Leave at 0 to build before you have them.                          */
#define USE_OLED 0

/* Prescaler for the first run of part 4 (see pwm_prescale_t in motors.h) */
#define START_PRESCALE  PRESCALE_64

/* 0 = non-inverting PWM, 1 = inverting PWM (for the post-lab question) */
#define PWM_INVERTING   0

#define RUN_FULL_MS   1000   /* full-speed moves: 1 s                   */
#define RUN_PWM_MS    2000   /* quarter-speed moves: 2 s                */
#define PAUSE_MS      3000   /* "brake and wait a few seconds"          */

/* ---- OLED helper ------------------------------------------------------- */
#if USE_OLED
#include "OLED.h"

static char text[50];

/* Clear the screen and show one short message (keep it under ~20 chars) */
static void show(const char *msg)
{
    OLED_clearDisplayRam();
    snprintf(text, sizeof text, "%s", msg);
    OLED_writeText(text);
}

static void oled_setup(void)
{
    OLED_Init();
    OLED_reset();
    OLED_clearDisplayRam();
    OLED_configureDefault();
    show("ECE2218");
}
#else
static void show(const char *msg) { (void)msg; }   /* does nothing */
static void oled_setup(void) { }
#endif

/* ---- Timing helpers ----------------------------------------------------- */

/* _delay_ms() wants a constant, so loop 1 ms at a time */
static void delay_ms(uint16_t ms)
{
    while (ms--)
        _delay_ms(1);
}

/* Brake both motors and wait */
static void brake_and_wait(void)
{
    motors_brake();
    show("Brake");
    delay_ms(PAUSE_MS);
}

/* ---- Part 2: full speed, one motor at a time ---------------------------- */
static void part2_single_motors(void)
{
    show("L fwd");
    motors_set_full(MOTOR_FORWARD, MOTOR_BRAKE);
    delay_ms(RUN_FULL_MS);
    brake_and_wait();

    show("L rev");
    motors_set_full(MOTOR_REVERSE, MOTOR_BRAKE);
    delay_ms(RUN_FULL_MS);
    brake_and_wait();

    show("R fwd");
    motors_set_full(MOTOR_BRAKE, MOTOR_FORWARD);
    delay_ms(RUN_FULL_MS);
    brake_and_wait();

    show("R rev");
    motors_set_full(MOTOR_BRAKE, MOTOR_REVERSE);
    delay_ms(RUN_FULL_MS);
    brake_and_wait();
}

/* ---- Part 3: full speed, both motors ------------------------------------ */
static void part3_both_motors(void)
{
    show("Fwd");
    motors_set_full(MOTOR_FORWARD, MOTOR_FORWARD);
    delay_ms(RUN_FULL_MS);
    brake_and_wait();

    show("Rev");
    motors_set_full(MOTOR_REVERSE, MOTOR_REVERSE);
    delay_ms(RUN_FULL_MS);
    brake_and_wait();

    /* Spinning CCW (seen from above): left wheel back, right wheel forward */
    show("Spin CCW");
    motors_set_full(MOTOR_REVERSE, MOTOR_FORWARD);
    delay_ms(RUN_FULL_MS);
    brake_and_wait();

    /* Spinning CW: left wheel forward, right wheel back */
    show("Spin CW");
    motors_set_full(MOTOR_FORWARD, MOTOR_REVERSE);
    delay_ms(RUN_FULL_MS);
    brake_and_wait();
}

/* ---- Part 4: quarter speed with PWM ------------------------------------- */
static void part4_quarter_speed(void)
{
    const int16_t q = MOTOR_SPEED_QUARTER;

    show("1/4 fwd");
    motors_set_speed(q, q);
    delay_ms(RUN_PWM_MS);
    brake_and_wait();

    show("1/4 rev");
    motors_set_speed(-q, -q);
    delay_ms(RUN_PWM_MS);
    brake_and_wait();

    show("1/4 CCW");
    motors_set_speed(-q, q);
    delay_ms(RUN_PWM_MS);
    brake_and_wait();

    show("1/4 CW");
    motors_set_speed(q, -q);
    delay_ms(RUN_PWM_MS);
    brake_and_wait();
}

/* Label for the OLED, e.g. "N=64" */
static const char *prescale_label(pwm_prescale_t p)
{
    switch (p) {
        case PRESCALE_1:    return "N=1";
        case PRESCALE_8:    return "N=8";
        case PRESCALE_64:   return "N=64";
        case PRESCALE_256:  return "N=256";
        case PRESCALE_1024: return "N=1024";
        default:            return "N=?";
    }
}

int main(void)
{
    /* ---- Part 1: setup ---- */
    motors_init();          /* motor pins as outputs, both braked */
    button_a_init();        /* PB3 input with pull-up             */
    oled_setup();

    show("Press A");
    button_a_wait();        /* don't move until button A is pressed */
    delay_ms(500);          /* time to get your hand clear          */

    part2_single_motors();
    part3_both_motors();

    /* Switch from digital mode to Timer1 PWM */
    pwm_prescale_t prescale = START_PRESCALE;
    motors_pwm_init(prescale, PWM_INVERTING);
    show(prescale_label(prescale));
    delay_ms(1000);
    part4_quarter_speed();

    /* ---- Prescaler experiment: A = next prescaler, repeat part 4 ---- */
    for (;;) {
        show("A: next N");
        button_a_wait();

        prescale = (prescale >= PRESCALE_1024) ? PRESCALE_1 : prescale + 1;
        motors_pwm_set_prescale(prescale);

        show(prescale_label(prescale));
        delay_ms(1000);
        part4_quarter_speed();
    }
}