/*
 * button.h - User pushbutton A on the Pololu 3pi+ 32U4 (ECE 2218 Lab 7)
 *
 * Button A is on PB3. It connects the pin to ground when pressed, so we
 * turn on the ATmega32U4's internal pull-up: released = HIGH, pressed = LOW.
 */
#ifndef BUTTON_H
#define BUTTON_H

#include <stdint.h>

/* Make PB3 an input with its pull-up enabled. */
void button_a_init(void);

/* 1 if button A is held down right now, 0 if not. */
uint8_t button_a_pressed(void);

/* Loop until button A is pressed and released (with debouncing).
 * The robot starts moving only after you let go of the button.   */
void button_a_wait(void);

#endif /* BUTTON_H */