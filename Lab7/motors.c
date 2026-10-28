/*
 * motors.c - Motor control for the Pololu 3pi+ 32U4 (ECE 2218 Lab 7)
 * See motors.h for the pin map and an overview.
 */
#include <avr/io.h>
#include "motors.h"

/* ---- Pin definitions (all on Port B) ---------------------------------- */
#define R_DIR  PB1   /* right motor direction             */
#define L_DIR  PB2   /* left  motor direction             */
#define R_PWM  PB5   /* right motor speed, OC1A           */
#define L_PWM  PB6   /* left  motor speed, OC1B           */

/* Direction pin level for FORWARD. Pololu's library drives DIR low for
 * forward, so 0 here. If a motor turns the wrong way on your robot,
 * change that motor's value to 1.                                        */
#define L_FWD_LEVEL 0
#define R_FWD_LEVEL 0

static uint8_t pwm_inverting = 0;   /* remembered from motors_pwm_init() */

/* Set a direction pin for forward (reverse = 0) or reverse (reverse = 1). */
static void set_dir(uint8_t pin, uint8_t fwd_level, uint8_t reverse)
{
    uint8_t level = fwd_level ^ reverse;   /* flip the level for reverse */
    if (level)
        PORTB |=  (1 << pin);
    else
        PORTB &= ~(1 << pin);
}

/* Value to load into OCR1x for a duty of 0..255.
 * Non-inverting: output is HIGH for the first OCR counts -> OCR = duty.
 * Inverting:     output is LOW  for the first OCR counts -> OCR = 255 - duty.
 * Either way, duty 0 holds the pin LOW (brake) and 255 holds it HIGH.     */
static uint8_t duty_to_ocr(uint8_t duty)
{
    return pwm_inverting ? (uint8_t)(255 - duty) : duty;
}

void motors_init(void)
{
    /* Disconnect Timer1 from the pins so PORTB controls them directly */
    TCCR1A = 0;
    TCCR1B = 0;

    /* All four motor pins low (= brake), then make them outputs */
    PORTB &= ~((1 << R_DIR) | (1 << L_DIR) | (1 << R_PWM) | (1 << L_PWM));
    DDRB  |=  ((1 << R_DIR) | (1 << L_DIR) | (1 << R_PWM) | (1 << L_PWM));
}

/* One motor in digital mode: speed pin HIGH = full speed, LOW = brake. */
static void set_full_one(uint8_t dir_pin, uint8_t pwm_pin,
                         uint8_t fwd_level, motor_state_t state)
{
    if (state == MOTOR_BRAKE) {
        PORTB &= ~(1 << pwm_pin);
    } else {
        set_dir(dir_pin, fwd_level, state == MOTOR_REVERSE);
        PORTB |= (1 << pwm_pin);
    }
}

void motors_set_full(motor_state_t left, motor_state_t right)
{
    set_full_one(L_DIR, L_PWM, L_FWD_LEVEL, left);
    set_full_one(R_DIR, R_PWM, R_FWD_LEVEL, right);
}

void motors_pwm_init(pwm_prescale_t prescale, uint8_t inverting)
{
    pwm_inverting = inverting ? 1 : 0;

    /* Start with both motors braked */
    OCR1A = duty_to_ocr(0);
    OCR1B = duty_to_ocr(0);

    /* TCCR1A:
     *   COM1A1:0 and COM1B1:0 = 10 non-inverting, 11 inverting
     *   WGM11:10 = 01  -> with WGM13:12 = 00 this is Mode 1,
     *                     "PWM, Phase Correct, 8-bit", TOP = 0x00FF   */
    TCCR1A = (1 << COM1A1) | (1 << COM1B1) | (1 << WGM10);
    if (pwm_inverting)
        TCCR1A |= (1 << COM1A0) | (1 << COM1B0);

    /* TCCR1B: WGM13:12 = 00, CS12:10 = prescaler (starts the timer) */
    TCCR1B = (uint8_t)prescale & 0x07;
}

void motors_pwm_set_prescale(pwm_prescale_t prescale)
{
    TCCR1B = (TCCR1B & ~0x07) | ((uint8_t)prescale & 0x07);
}

/* Clamp a signed speed to -255..255 */
static int16_t clamp_speed(int16_t s)
{
    if (s >  MOTOR_SPEED_MAX) return  MOTOR_SPEED_MAX;
    if (s < -MOTOR_SPEED_MAX) return -MOTOR_SPEED_MAX;
    return s;
}

void motors_set_speed(int16_t left, int16_t right)
{
    left  = clamp_speed(left);
    right = clamp_speed(right);

    set_dir(L_DIR, L_FWD_LEVEL, left  < 0);
    set_dir(R_DIR, R_FWD_LEVEL, right < 0);

    OCR1B = duty_to_ocr((uint8_t)(left  < 0 ? -left  : left));   /* left  = OC1B */
    OCR1A = duty_to_ocr((uint8_t)(right < 0 ? -right : right));  /* right = OC1A */
}

void motors_brake(void)
{
    if (TCCR1A & ((1 << COM1A1) | (1 << COM1B1))) {
        /* PWM mode: 0% duty holds both speed pins low */
        OCR1A = duty_to_ocr(0);
        OCR1B = duty_to_ocr(0);
    } else {
        /* Digital mode */
        PORTB &= ~((1 << R_PWM) | (1 << L_PWM));
    }
}