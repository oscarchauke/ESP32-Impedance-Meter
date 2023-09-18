#include <string.h>
#include <stdio.h>
#include "sdkconfig.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include "esp_adc/adc_continuous.h"
#include "esp_timer.h"
#include "driver/gpio.h"

#include "fft.h"

#include "im_adc.h"

#define STATE_START 99
#define STATE_INIT 0
#define STATE_SAMPLE_ADC 1
#define STATE_fft_FFT 2
#define STATE_COMPUTE_IMPEDANCE 3
#define STATE_SEND_DATA 4
#define STATE_RECONFIG 5
#define STATE_IDLE 255

#define ADC_GET_CHANNEL(p_data) ((p_data)->type1.channel)
#define ADC_GET_DATA(p_data) ((p_data)->type1.data)

#define NFFT (NUM_SAMPLES / 4)

#define LED_PIN GPIO_NUM_2
#define READY_PIN GPIO_NUM_15

uint8_t STATE = STATE_START;
static TaskHandle_t s_task_handle;
adc_continuous_handle_t adc_handle = NULL;

fft_config_t *voltage_fft;
fft_config_t *current_fft;

float voltage_samples[NFFT];
float current_sample[NFFT];

esp_err_t ret;
uint32_t ret_num = 0;
uint8_t result[NUM_SAMPLES] = {0};

typedef struct
{
    float frequency;
    uint16_t sampling_frequency;
    float amplitude;
    float phase;
} impedanceBin;

impedanceBin binItem;
uint8_t binIndex = 0;

impedanceBin binList[] = {
    {0.1, 20000, 0, 0},
    {1, 20000, 0, 0},
    {10.0, 20000, 0, 0},
    {100.0, 20000, 0, 0},
    {1000.0, 20000, 0, 0},
    {5000.0, 20000, 0, 0}};

void start_app();
void init_app();
void sample_adc();
void compute_impedance();
void send_data();
void reconfig();
void removeDC(fft_config_t *signal);

static bool IRAM_ATTR s_conv_done_cb(adc_continuous_handle_t handle, const adc_continuous_evt_data_t *edata, void *user_data)
{
    BaseType_t mustYield = pdFALSE;
    // Notify that ADC continuous driver has done enough number of conversions
    vTaskNotifyGiveFromISR(s_task_handle, &mustYield);

    return (mustYield == pdTRUE);
}
adc_continuous_evt_cbs_t cbs = {
    .on_conv_done = s_conv_done_cb,
};
void app_main()
{
    binItem = binList[binIndex];
    s_task_handle = xTaskGetCurrentTaskHandle();

    while (1)
    {
        vTaskDelay(1);
        switch (STATE)
        {
        case STATE_START:
            printf("start\n");
            start_app();
            break;
        case STATE_INIT:
            printf("%d\tinit\n", binIndex);
            init_app();
            gpio_set_level(LED_PIN, 1);
            break;
        case STATE_SAMPLE_ADC:
            printf("sample adc\n");
            sample_adc();
            break;
        case STATE_COMPUTE_IMPEDANCE:
            printf("compute impedance\n");
            compute_impedance();
            break;
        case STATE_SEND_DATA:
            printf("send data\n");
            send_data();
            break;
        case STATE_RECONFIG:
            gpio_set_level(LED_PIN, 0);
            printf("Reconfiguring Bin\n");
            reconfig();
            break;
        default:

            break;
        }
    }
}

void start_app()
{
    gpio_config_t io_conf;
    io_conf.intr_type = GPIO_INTR_DISABLE;        // Disable interrupt
    io_conf.mode = GPIO_MODE_OUTPUT;              // Set as output mode
    io_conf.pin_bit_mask = (1ULL << LED_PIN);     // Bitmask to select the GPIO pin
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE; // Disable pull-down
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;     // Disable pull-up
    gpio_config(&io_conf);                        // Configure the GPIO pin

    io_conf.mode = GPIO_MODE_INPUT;             // Set INPUT_PIN as input mode
    io_conf.pin_bit_mask = (1ULL << READY_PIN); // Bitmask for INPUT_PIN
    gpio_config(&io_conf);                      // Configure INPUT_PIN
    STATE = STATE_INIT;
}

void init_app()
{
    printf("*\n");
    printf("Change the frequency and press the ready button\n");
    while (!gpio_get_level(READY_PIN))
    {
        vTaskDelay(1);
    }
    vTaskDelay(20);

    voltage_fft = fft_init(NFFT, FFT_REAL, FFT_BACKWARD, NULL, NULL);
    current_fft = fft_init(NFFT, FFT_REAL, FFT_BACKWARD, NULL, NULL);

    continuous_adc_init(binItem.sampling_frequency, &adc_handle);
    ESP_ERROR_CHECK(adc_continuous_register_event_callbacks(adc_handle, &cbs, NULL));
    ESP_ERROR_CHECK(adc_continuous_start(adc_handle));
    ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
    printf("Done initializing app.\n");
    STATE = STATE_SAMPLE_ADC;
}

void sample_adc()
{
    memset(result, 0xcc, NUM_SAMPLES);
    esp_err_t ret = adc_continuous_read(adc_handle, result, NUM_SAMPLES, &ret_num, 0);
    if (ret == ESP_OK)
    {
        int k = 0;
        for (int i = 0; i < ret_num - 2; i += SOC_ADC_DIGI_RESULT_BYTES * 2)
        {
            adc_digi_output_data_t *v = (adc_digi_output_data_t *)&result[i];
            adc_digi_output_data_t *c = (adc_digi_output_data_t *)&result[i + 2];

            uint32_t voltage_data = ADC_GET_DATA(v);
            uint32_t current_data = ADC_GET_DATA(c);
            /* Check the channel number validation, the data is invalid if the channel num exceed the maximum channel */
            if ((ADC_GET_CHANNEL(c) == CURRENT_CHANNEL) & ((ADC_GET_CHANNEL(v) == VOLTAGE_CHANNEL)))
            {
                voltage_samples[k] = (float)voltage_data;
                current_sample[k] = (float)current_data;
                voltage_fft->input[k] = voltage_data;
                current_fft->input[k] = current_data;
                k++;
            }
            else
            {
                fft_destroy(voltage_fft);
                fft_destroy(current_fft);
                printf("Error while sampling ADC\n");
                break;
            }
        }
        printf("Recorded %d samples\n", k);
        STATE = STATE_COMPUTE_IMPEDANCE;
        ESP_ERROR_CHECK(adc_continuous_stop(adc_handle));
        ESP_ERROR_CHECK(adc_continuous_deinit(adc_handle));
        return;
    }
    else if (ret == ESP_ERR_TIMEOUT)
    {
        printf("Changing state to default\n");
        STATE = STATE_IDLE;
    }
    STATE = STATE_IDLE;
}

void compute_impedance()
{
    printf("Calculating Impedance at frequency %f\n", binItem.frequency);
    fft_execute(voltage_fft);
    fft_execute(current_fft);

    STATE = STATE_SEND_DATA;
}

void reconfig()
{
    if (binIndex < 5)
    {
        binItem = binList[++binIndex];
        STATE = STATE_INIT;
    }
    else
    {
        STATE = STATE_IDLE;
        printf("^\n");
    }
}

void send_data()
{
    STATE = STATE_RECONFIG;
    printf("Sending data\n");
    for (int i = 0; i < voltage_fft->size / 2; i++)
    {
        printf(">%f:%f:%f:%f:%f:%f\n", voltage_samples[i], current_sample[i],
               voltage_fft->output[2 * i], voltage_fft->output[2 * i + 1],
               current_fft->output[2 * i], current_fft->output[2 * i + 1]);
    }
    for (int i = (voltage_fft->size / 2); i < voltage_fft->size; i++)
    {
        printf(">%f:%f:0:0:0:0\n", voltage_samples[i], current_sample[i]);
    }
    printf("#\n");

    fft_destroy(voltage_fft);
    fft_destroy(current_fft);
}

void removeDC(fft_config_t *signal)
{
    double mean = 0;
    for (int i = 0; i < signal->size; i++)
        mean += signal->input[i];

    mean = mean / NFFT;
    printf("Mean: %f\n", mean);

    for (int i = 0; i < signal->size; i++)
    {
        signal->input[i] -= mean;
    }
}