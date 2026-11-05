// Button A is on PB3. It connects the pin to ground when pressed, so we
// turn on the ATmega32U4's internal pull-up: released = HIGH, pressed = LOW.

#ifndef BUTTON_H
#define BUTTON_H

#include <stdint.h>

// Make PB3 an input with its pull-up enabled.
void button_a_init(void);

// 1 if button A is held down right now, 0 if not.
uint8_t button_a_pressed(void);

// Wait for a full press and release of button A (debounced).
void button_a_wait(void);

// Wait until button A is released (debounced). Call this after
// button_a_pressed() returns 1 so one press is only counted once.
void button_a_wait_release(void);

#endif // BUTTON_H
