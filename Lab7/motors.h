#ifndef MOTORS_H
#define MOTORS_H

#include <stdint.h>

// Direction / state
typedef enum {
    MOTOR_BRAKE = 0,
    MOTOR_FORWARD,
    MOTOR_REVERSE
} motor_state_t;

typedef enum {
    PRESCALE_1    = 1,   // ~31.4 kHz
    PRESCALE_8    = 2,   // ~3.92 kHz
    PRESCALE_64   = 3,   // ~490 Hz
    PRESCALE_256  = 4,   // ~123 Hz
    PRESCALE_1024 = 5    // ~30.6 Hz
} pwm_prescale_t;


#define MOTOR_SPEED_MAX     255
#define MOTOR_SPEED_QUARTER  64

void motors_init(void);

void motors_set_full(motor_state_t left, motor_state_t right);

void motors_pwm_init(pwm_prescale_t prescale, uint8_t inverting);

void motors_pwm_set_prescale(pwm_prescale_t prescale);

void motors_set_speed(int16_t left, int16_t right);

void motors_brake(void);

#endif // MOTORS_H