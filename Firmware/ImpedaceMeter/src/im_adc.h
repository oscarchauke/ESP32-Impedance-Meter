#include "esp_adc/adc_continuous.h"
#include "esp_log.h"
#include "string.h"

#define NUM_SAMPLES 4096
#define CHANNEL_NUM 2
#define CURRENT_CHANNEL 6
#define VOLTAGE_CHANNEL 7

void continuous_adc_init(uint16_t frequency, adc_continuous_handle_t *out_handle);