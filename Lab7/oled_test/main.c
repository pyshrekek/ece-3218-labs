/*
 * Step 1: Test out the OLED display
 */
#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include <avr/io.h>
#include <stdio.h>      /* for snprintf() */
#include "OLED.h"

int main(void)
{
    char text[50];              // define an array to hold text to be written to the display

    OLED_init();                // set up the pins for input/output that connect to the display
                                // (the handout says OLED_Init, but the provided OLED.c names it OLED_init)
    OLED_reset();               // toggle the display's reset pin
    OLED_clearDisplayRam();     // display data is held in RAM. Zero everything to blank display
    OLED_configureDefault();    // set mode, contrast, etc
    snprintf(text, 8, "%s", "ECE3218");   // copy a string constant into our variable
    OLED_writeText(text);       // display the string contents

    while (1)
        ;                       // stop here so the text stays on screen
}