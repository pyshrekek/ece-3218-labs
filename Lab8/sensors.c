// All five sensors are charged, released and polled together. Each pass of
// the polling loop packs the five pin levels into one 5-bit number
// (bit i = sensor i), so the sensors that just went low are
//
//     fell = pending & ~levels;
//
// Each one gets the current timer value and is removed from `pending`.

#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include <avr/io.h>
#include <util/delay.h>
#include "sensors.h"

#define EMIT  PB7

#define DN1   PD6
#define DN2   PF7
#define DN3   PF5
#define DN4   PF4
#define DN5   PF1

// Sensor pins grouped by port, so each port is switched in one write
#define SENSOR_MASK_D  (1 << DN1)
#define SENSOR_MASK_F  ((1 << DN2) | (1 << DN3) | (1 << DN4) | (1 << DN5))

#define ALL_SENSORS    ((1 << SENSOR_COUNT) - 1)

#define CHARGE_US      10   // 220 ohm * 2.2 nF = 0.5 us, so 10 us is plenty

// Current level of every sensor pin, packed into bits 0..4
static inline uint8_t sensor_levels(void)
{
    uint8_t d = PIND;
    uint8_t f = PINF;

    return (((d >> DN1) & 1) << 0)
         | (((f >> DN2) & 1) << 1)
         | (((f >> DN3) & 1) << 2)
         | (((f >> DN4) & 1) << 3)
         | (((f >> DN5) & 1) << 4);
}

// Driving PB7 low would turn on the bump sensor emitters, so "off" means
// making PB7 an input with no pull-up.
static void emitters_off(void)
{
    DDRB  &= ~(1 << EMIT);
    PORTB &= ~(1 << EMIT);
}

static void emitters_on(void)
{
    PORTB |= (1 << EMIT);
    DDRB  |= (1 << EMIT);
}

void sensors_init(void)
{
    // PF4, PF5 and PF7 are also JTAG pins and can't be used as I/O while
    // JTAG is on. JTD must be written twice within 4 cycles, so compute
    // the value first and then write it twice back to back.
    uint8_t mcucr = MCUCR | (1 << JTD);
    MCUCR = mcucr;
    MCUCR = mcucr;

    emitters_off();

    // Sensor pins: inputs, pull-ups off
    DDRD  &= ~SENSOR_MASK_D;
    PORTD &= ~SENSOR_MASK_D;
    DDRF  &= ~SENSOR_MASK_F;
    PORTF &= ~SENSOR_MASK_F;

    // Timer3: normal mode, clk/8 -> 0.5 us per tick
    TCCR3A = 0x00;
    TCCR3B = (1 << CS31);
}

void sensors_read(uint16_t values[SENSOR_COUNT])
{
    emitters_on();

    // Charge the capacitors: drive every sensor pin high
    PORTD |= SENSOR_MASK_D;
    PORTF |= SENSOR_MASK_F;
    DDRD  |= SENSOR_MASK_D;
    DDRF  |= SENSOR_MASK_F;
    _delay_us(CHARGE_US);

    // Release the pins and start timing. Clear DDR before PORT: clearing
    // PORT first would drive the pins low and drain the capacitors.
    // Clearing PORT afterwards turns the pull-ups off, which would
    // otherwise keep the capacitors charged.
    TCNT3 = 0;
    DDRD  &= ~SENSOR_MASK_D;
    DDRF  &= ~SENSOR_MASK_F;
    PORTD &= ~SENSOR_MASK_D;
    PORTF &= ~SENSOR_MASK_F;

    // Poll until every sensor has gone low or we time out. The time is
    // read before the pins, so a recorded time is never later than the
    // real edge.
    uint8_t  pending = ALL_SENSORS;
    uint16_t now;

    do {
        now = TCNT3;
        uint8_t fell = pending & ~sensor_levels();

        if (fell) {
            for (uint8_t i = 0; i < SENSOR_COUNT; i++) {
                if (fell & (1 << i))
                    values[i] = now;
            }
            pending &= ~fell;
        }
    } while (pending && now < SENSOR_TIMEOUT);

    // Anything still high timed out
    for (uint8_t i = 0; i < SENSOR_COUNT; i++) {
        if (pending & (1 << i))
            values[i] = SENSOR_TIMEOUT;
    }

    emitters_off();
}
