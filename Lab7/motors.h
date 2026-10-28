/*
 * motors.h - Motor control for the Pololu 3pi+ 32U4 (ECE 2218 Lab 7)
 *
 * Motor driver pins (Pololu 3pi+ 32U4 User's Guide, section 5.9):
 *   PB1  Right motor direction (DIR)
 *   PB2  Left  motor direction (DIR)
 *   PB5  Right motor speed     (OC1A, Timer1 PWM)
 *   PB6  Left  motor speed     (OC1B, Timer1 PWM)
 *
 * Each motor has a DRV8838 driver: the speed pin enables the motor,
 * the direction pin picks forward or reverse. Speed pin LOW = brake.
 *
 * Two modes:
 *   Digital mode (Lab parts 2-3): speed pins are plain on/off outputs,
 *                                 so the motors run at full speed or brake.
 *   PWM mode     (Lab part 4):    Timer1 drives the speed pins with
 *                                 phase-correct PWM for variable speed.
 */
#ifndef MOTORS_H
#define MOTORS_H

#include <stdint.h>

/* Direction / state for digital (full-speed) mode */
typedef enum {
    MOTOR_BRAKE = 0,
    MOTOR_FORWARD,
    MOTOR_REVERSE
} motor_state_t;

/* Timer1 clock prescaler choices (CS12:CS10 bits in TCCR1B).
 * PWM freq (8-bit phase correct) = 16 MHz / (2 * N * 255)          */
typedef enum {
    PRESCALE_1    = 1,   /* ~31.4 kHz */
    PRESCALE_8    = 2,   /* ~3.92 kHz */
    PRESCALE_64   = 3,   /* ~490 Hz   */
    PRESCALE_256  = 4,   /* ~123 Hz   */
    PRESCALE_1024 = 5    /* ~30.6 Hz  */
} pwm_prescale_t;

/* Full speed is 255 in PWM mode (8-bit, TOP = 255) */
#define MOTOR_SPEED_MAX     255
#define MOTOR_SPEED_QUARTER  64

/* Set up all four motor pins as outputs and brake both motors.
 * Leaves the motors in digital (full-speed on/off) mode.          */
void motors_init(void);

/* Digital mode: run each motor at full speed forward/reverse, or brake. */
void motors_set_full(motor_state_t left, motor_state_t right);

/* Switch to PWM mode: Timer1 phase-correct 8-bit PWM on OC1A/OC1B.
 * inverting = 0 for non-inverting output, 1 for inverting output.  */
void motors_pwm_init(pwm_prescale_t prescale, uint8_t inverting);

/* Change the PWM prescaler without touching anything else. */
void motors_pwm_set_prescale(pwm_prescale_t prescale);

/* PWM mode: speed from -255 (full reverse) to +255 (full forward).
 * 0 brakes that motor.                                             */
void motors_set_speed(int16_t left, int16_t right);

/* Brake both motors (works in either mode). */
void motors_brake(void);

#endif /* MOTORS_H */