/*
 * button.c - User pushbutton A on the Pololu 3pi+ 32U4 (ECE 2218 Lab 7)
 */
#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include <avr/io.h>
#include <util/delay.h>
#include "button.h"

#define BTN_A  PB3

void button_a_init(void)
{
    DDRB  &= ~(1 << BTN_A);   /* input                         */
    PORTB |=  (1 << BTN_A);   /* enable internal pull-up       */
    _delay_us(10);            /* let the pin settle high       */
}

uint8_t button_a_pressed(void)
{
    return (PINB & (1 << BTN_A)) == 0;   /* LOW = pressed */
}

void button_a_wait(void)
{
    /* Wait for a press that stays pressed through the bounce time */
    do {
        while (!button_a_pressed())
            ;                    /* loop indefinitely until pressed */
        _delay_ms(20);           /* debounce                        */
    } while (!button_a_pressed());

    /* Wait for release, again debounced */
    do {
        while (button_a_pressed())
            ;
        _delay_ms(20);
    } while (button_a_pressed());
}