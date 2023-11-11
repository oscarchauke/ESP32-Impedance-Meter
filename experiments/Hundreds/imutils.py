import os
import pandas as pd
import numpy as np
import math
import re

FREQUENCIES = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]

def process_file(file_name,counter):
    f_s = int(re.search(r'F(\d+)K',file_name).group(1))
    print(f'Sampling Frequency {f_s}')
    data = pd.read_csv(file_name)
    voltage_fft = data['V_Real'] + 1j*data['V_Imag']
    current_fft = data['C_Real'] + 1j*data['C_Imag']
    N = len(voltage_fft)

    fft_bin = int((N*counter*100)/(f_s*1000))
    print(f'FFT bin {fft_bin}')
    start_index = fft_bin - 2
    end_index = fft_bin + 2

    if start_index < 0:
        start_index = 0
    if end_index > len(voltage_fft):
        end_index = len(voltage_fft)

    max_index = start_index + np.argmax(abs(voltage_fft[start_index:end_index]))
    impedance = voltage_fft[max_index] / current_fft[max_index]

    magnitude = np.abs(impedance)
    phase = np.angle(impedance)

    phase_error = abs(phase/(2*math.pi))*100
    magnitude_error = abs(magnitude - 1)*100

    results_df = pd.DataFrame({
        'Frequency': [FREQUENCIES[counter]],
        'Magnitude': [magnitude],
        'Phase': [phase],
        'Magnitude Error (%)': [magnitude_error],
        'Phase Error (%)': [phase_error]
    })
    print(results_df)
    return results_df

process_file("F25K-A/raw_data_9.csv",9)