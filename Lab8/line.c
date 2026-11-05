#include "line.h"

static const int16_t sensor_x[SENSOR_COUNT] = LINE_SENSOR_X_TENTHS_MM;

void line_cal_reset(line_cal_t *cal)
{
    for (uint8_t i = 0; i < SENSOR_COUNT; i++) {
        cal->min[i] = UINT16_MAX;
        cal->max[i] = 0;
    }
}

void line_cal_update(line_cal_t *cal, const uint16_t values[SENSOR_COUNT])
{
    for (uint8_t i = 0; i < SENSOR_COUNT; i++) {
        if (values[i] < cal->min[i]) cal->min[i] = values[i];
        if (values[i] > cal->max[i]) cal->max[i] = values[i];
    }
}

int8_t line_cal_check(const line_cal_t *cal)
{
    for (uint8_t i = 0; i < SENSOR_COUNT; i++) {
        if (cal->max[i] < cal->min[i] ||
            cal->max[i] - cal->min[i] < LINE_CAL_MIN_RANGE)
            return (int8_t)i;
    }
    return -1;
}

void line_normalize(const line_cal_t *cal, const uint16_t values[SENSOR_COUNT],
                    uint16_t dark[SENSOR_COUNT])
{
    for (uint8_t i = 0; i < SENSOR_COUNT; i++) {
        uint16_t lo = cal->min[i];
        uint16_t hi = cal->max[i];

        if (values[i] <= lo)
            dark[i] = 0;
        else if (values[i] >= hi)
            dark[i] = LINE_DARK_MAX;
        else
            dark[i] = (uint16_t)((uint32_t)(values[i] - lo) * LINE_DARK_MAX
                                 / (hi - lo));
    }
}

uint8_t line_position(const uint16_t dark[SENSOR_COUNT], int16_t *x)
{
    int32_t  weighted = 0;
    uint16_t total = 0;

    for (uint8_t i = 0; i < SENSOR_COUNT; i++) {
        weighted += (int32_t)dark[i] * sensor_x[i];
        total    += dark[i];
    }

    if (total < LINE_MIN_TOTAL)
        return 0;

    *x = (int16_t)(weighted / total);
    return 1;
}
