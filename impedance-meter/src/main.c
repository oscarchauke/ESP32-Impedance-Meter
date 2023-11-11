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

#include "im_adc.h"

#include "driver/spi_common.h"
#include "pcd8544.h"

#include "fft.h"
#include <math.h>

#define ADC_GET_CHANNEL(p_data) ((p_data)->type1.channel)
#define ADC_GET_DATA(p_data) ((p_data)->type1.data)

#define LED_PIN GPIO_NUM_2
#define READY_PIN GPIO_NUM_5

#define FFT_SAMPLES (NUM_SAMPLES / 4)
#define NUM_BINS (9)
enum STATE
{
    START,
    INIT_ADC,
    SAMPLE_ADC,
    SEND_RAW_DATA,
    COMPUTE_IMPENDACE,
    SEND_IMPEDANCE_DATA,
    RECONFIG_ADC,
    IDLE
};

typedef struct
{
    uint32_t frequency;
    uint32_t sampling_frequency;
    float amplitude;
    float phase;
} impedanceBin;

static TaskHandle_t s_task_handle;
adc_continuous_handle_t adc_handle = NULL;
enum STATE state = START;

impedanceBin binItem;
uint8_t binIndex = 0;

esp_err_t ret;
uint32_t ret_num = 0;
uint8_t result[NUM_SAMPLES] = {0};

float voltage_magPhase[FFT_SAMPLES];
float current_magPhase[FFT_SAMPLES];

fft_config_t *voltage_fft_plan;
fft_config_t *current_fft_plan;

const uint32_t freq = 250000;

impedanceBin binList[] = {
    {1000, (freq), 0, 0},
    {2000, (freq), 0, 0},
    {3000, (freq), 0, 0},
    {4000, (freq), 0, 0},
    {5000, (freq), 0, 0},
    {6000, (freq), 0, 0},
    {7000, (freq), 0, 0},
    {8000, (freq), 0, 0},
    {9000, (freq), 0, 0},
    {10000, (freq), 0, 0}};

void start();
void init_adc();
void sample_adc();
void compute_impedance();
void send_raw_data();
void reconfig_adc();
void remove_dc(float *array, size_t array_len);
void ComplexToMagnitude(fft_config_t *fft_plan, float *magPhase);
uint16_t MajorPeak(float *magPhase, uint16_t samples);

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
    voltage_fft_plan = fft_init(FFT_SAMPLES, FFT_REAL, FFT_FORWARD, NULL, NULL);
    current_fft_plan = fft_init(FFT_SAMPLES, FFT_REAL, FFT_FORWARD, NULL, NULL);

    pcd8544_config_t config = {
        .spi_host = HSPI_HOST,
        .is_backlight_common_anode = true,
    };
    pcd8544_init(&config);
    pcd8544_clear_display();
    pcd8544_finalize_frame_buf();
    pcd8544_puts("WELCOME TO IMPEDANCE METER");
    pcd8544_sync_and_gc();

    binItem = binList[binIndex];
    s_task_handle = xTaskGetCurrentTaskHandle();

    while (1)
    {
        vTaskDelay(1);
        switch (state)
        {
        case START:
            start();
            break;

        case INIT_ADC:
            init_adc();
            break;

        case SAMPLE_ADC:
            sample_adc();
            break;

        case COMPUTE_IMPENDACE:
            compute_impedance();
            break;

        case SEND_RAW_DATA:
            send_raw_data();
            break;
        case RECONFIG_ADC:
            reconfig_adc();
            break;

        case IDLE:

            break;

        default:
            break;
        }
    }
}

void start()
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
    state = INIT_ADC;
}

void init_adc()
{
    printf("%d Change the frequency to %ld and press the ready button\n", binIndex, binItem.frequency);

    pcd8544_clear_display();
    pcd8544_finalize_frame_buf();
    pcd8544_set_pos(3, 1);
    pcd8544_puts("Set Frequency");
    pcd8544_set_pos(40, 3);
    pcd8544_puts("to");
    pcd8544_set_pos(20, 5);
    pcd8544_printf("%2.1f Hz", (float)binItem.frequency);
    pcd8544_sync_and_gc();

    while (!gpio_get_level(READY_PIN))
    {
        vTaskDelay(1);
    }
    vTaskDelay(20);

    continuous_adc_init(binItem.sampling_frequency, &adc_handle);
    ESP_ERROR_CHECK(adc_continuous_register_event_callbacks(adc_handle, &cbs, NULL));
    ESP_ERROR_CHECK(adc_continuous_start(adc_handle));
    ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
    printf("Done initializing app.\n");
    fflush(stdout);
    state = SAMPLE_ADC;
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
                voltage_fft_plan->input[k] = (float)voltage_data;
                current_fft_plan->input[k] = (float)current_data;
                k++;
            }
            else
            {
                printf("Error while sampling ADC\n");
                fflush(stdout);
                break;
            }
        }
        printf("Recorded %d samples\n", k);

        state = COMPUTE_IMPENDACE;
        ESP_ERROR_CHECK(adc_continuous_stop(adc_handle));
        ESP_ERROR_CHECK(adc_continuous_deinit(adc_handle));
        return;
    }
    else if (ret == ESP_ERR_TIMEOUT)
    {
        printf("Changing state to default\n");
        fflush(stdout);
        state = IDLE;
    }
    state = IDLE;
}

void compute_impedance()
{
    pcd8544_clear_display();
    pcd8544_finalize_frame_buf();
    pcd8544_set_pos(10, 2);
    pcd8544_puts("Calculating");
    pcd8544_set_pos(15, 4);
    pcd8544_puts("Impedance");
    pcd8544_sync_and_gc();

    remove_dc(voltage_fft_plan->input, voltage_fft_plan->size);
    remove_dc(current_fft_plan->input, current_fft_plan->size);

    fft_execute(voltage_fft_plan);
    fft_execute(current_fft_plan);

    ComplexToMagnitude(voltage_fft_plan, voltage_magPhase);
    ComplexToMagnitude(current_fft_plan, current_magPhase);

    uint16_t vIndex = MajorPeak(voltage_magPhase, voltage_fft_plan->size);
    if (vIndex == MajorPeak(current_magPhase, current_fft_plan->size))
    {
        float magnitude = (float)(voltage_magPhase[vIndex]/current_magPhase[vIndex]);
        float phase = (float)(voltage_magPhase[vIndex+512] - current_magPhase[vIndex+512]);
        pcd8544_clear_display();
        pcd8544_finalize_frame_buf();
        pcd8544_set_pos(15, 0);
        pcd8544_puts("Impedance");
        pcd8544_set_pos(5, 2);
        pcd8544_printf("at %2.1f Hz", (float)binItem.frequency);
        pcd8544_set_pos(5, 3);
        pcd8544_printf("mag  :%2.3f", magnitude);
        pcd8544_set_pos(5, 4);
        pcd8544_printf("phase:%2.3f",phase);
        pcd8544_sync_and_gc();
        vTaskDelay(1000);
    }
    else
    {
        pcd8544_clear_display();
        pcd8544_finalize_frame_buf();
        pcd8544_puts("Signals not of the same frequency");
        pcd8544_sync_and_gc();
        vTaskDelay(1000);
    }

    state = SEND_RAW_DATA;
}

void send_raw_data()
{
    int k = 0;
    state = RECONFIG_ADC;
    pcd8544_clear_display();
    pcd8544_finalize_frame_buf();
    pcd8544_set_pos(20, 1);
    pcd8544_puts("Sending");
    pcd8544_set_pos(40, 3);
    pcd8544_puts("raw");
    pcd8544_set_pos(35, 5);
    pcd8544_puts("data");
    pcd8544_sync_and_gc();

    printf("START_RAW_DATA\n");
    printf(">%f:%f:%f:0:%f:0\n", voltage_fft_plan->input[0], current_fft_plan->input[0], voltage_fft_plan->output[0], current_fft_plan->output[0]); // DC is at [0]
    for (k = 1; k < voltage_fft_plan->size / 2; k++)
        printf(">%f:%f:%f:%f:%f:%f\n", voltage_fft_plan->input[k], current_fft_plan->input[k], voltage_fft_plan->output[2 * k], voltage_fft_plan->output[2 * k + 1],
               current_fft_plan->output[2 * k], current_fft_plan->output[2 * k + 1]);
    for (; k < voltage_fft_plan->size; k++)
        printf(">%f:%f:0:0:0:0\n", voltage_fft_plan->input[k], current_fft_plan->input[k]);
    printf("END_RAW_DATA\n");
}

void reconfig_adc()
{
    if (binIndex < NUM_BINS)
    {
        binItem = binList[++binIndex];
        state = INIT_ADC;
    }
    else
    {
        state = IDLE;

        pcd8544_clear_display();
        pcd8544_finalize_frame_buf();
        pcd8544_puts("Done");
        pcd8544_sync_and_gc();
        printf("END_TEST\n");
    }
}
void remove_dc(float *array, size_t array_len)
{
    // calculate the mean of vData
    float mean = 0;
    for (size_t i = 0; i < array_len; i++)
    {
        mean += array[i];
    }
    mean /= array_len;
    // Subtract the mean from vData
    for (size_t i = 0; i < array_len; i++)
    {
        array[i] -= mean;
    }
}

void ComplexToMagnitude(fft_config_t *fft_plan, float *magPhase)
{
    printf("Calculating magnitude and phase...\n");
    uint16_t samples = fft_plan->size / 2;
    for (uint16_t i = 1; i < samples; i++)
    {
        magPhase[i] = sqrt((fft_plan->output[2 * i] * fft_plan->output[2 * i]) + (fft_plan->output[2 * i + 1] * fft_plan->output[2 * i + 1]));
        magPhase[samples + i] = atan2(fft_plan->output[2 * i + 1], fft_plan->output[2 * i]);
        vTaskDelay(1);
    }
}

uint16_t MajorPeak(float *magPhase, uint16_t samples)
{
    double maxY = 0;
    uint16_t IndexOfMaxY = 0;
    for (uint16_t i = 1; i < ((samples >> 1) + 1); i++)
    {
        if ((magPhase[i - 1] < magPhase[i]) &&
            (magPhase[i] > magPhase[i + 1]))
        {
            if (magPhase[i] > maxY)
            {
                maxY = magPhase[i];
                IndexOfMaxY = i;
            }
        }
    }
    printf("Major is in index %d\n", IndexOfMaxY);
    return IndexOfMaxY;
}