#include "esp_adc/adc_continuous.h"
#include "esp_log.h"
#include "string.h"

#define NUM_SAMPLES 4096
#define CHANNEL_NUM 2

void continuous_adc_init(uint16_t frequency, adc_continuous_handle_t *out_handle);