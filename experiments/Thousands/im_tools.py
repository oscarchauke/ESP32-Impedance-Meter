import pandas as pd
import numpy as np
import os
import math
import matplotlib.pyplot as plt
import process as pro
from scipy.optimize import curve_fit
import re

FREQUENCIES = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000]
if not os.path.exists("Results"):
    os.makedirs("Results")
    print(f'Results folder created')

# Define the linear function
def linear_function(x, a, b):
    return a * x + b

def get_tests(test_name):
    """Get a list of all folders (directories) in the specified path."""
    folders = []
    for item in os.listdir():
        if item.startswith(test_name):
            item_path = os.path.join(item)
            if os.path.isdir(item_path):
                folders.append(item)
    return folders

def get_filenames(tests):
    file_names = []
    for test in tests:
        file_names.append(test+'/results.csv')
    return file_names

def plot_time_domain(voltage, current):
    plt.figure(figsize=(10,6))
    plt.xlabel("Time")
    plt.ylabel("Magnitude")
    plt.plot(voltage, label="Voltage")
    plt.plot(current, label="Current")
    plt.legend()
    plt.grid(True)
    plt.show()

def plot_compare_fft(python_fft, esp_fft):
    plt.figure(figsize=(10,6))
    plt.xlabel("Frequency index")
    plt.ylabel("Magnitude")
    plt.plot(np.abs(python_fft), label="Voltage")
    plt.plot(np.abs(esp_fft), label="Current")
    plt.legend()
    plt.grid(True)
    plt.show()

def export_error_plots(test):
    plt.figure(figsize=(10, 6))
    plt.xlabel("Signal Frequency")
    plt.ylabel("Percentage Error")
    plt.title("Magnitude Error")
    for file_name in get_filenames(get_tests(test)):
        df = pd.read_csv(file_name)
        plt.plot(df['Frequency'], df['Magnitude Error (%)'], marker='*' , label=file_name)
    plt.legend()
    plt.grid(True)
    plt.savefig(os.path.join("Results/"+test,"magnitude_plot.png"))
    plt.close()

    plt.figure(figsize=(10, 6))
    plt.xlabel("Signal Frequency")
    plt.ylabel("Percentage Error")
    plt.title("Phase Error")
    for file_name in get_filenames(get_tests(test)):
        df = pd.read_csv(file_name)
        plt.plot(df['Frequency'], df['Phase Error (%)'], marker='*',label=file_name)
    plt.legend()
    plt.grid(True)
    plt.savefig(os.path.join("Results/"+test,"phase_plot.png"))
    plt.close()


def avarege_tests(test):
    if not os.path.exists("Results/"+test):
        os.makedirs("Results/"+test)
        print(f'Results folder created')
    
    output_file = 'Results/'+test+'/results.csv'
    csv_files = get_filenames(get_tests(test))
    
    df = pd.read_csv(csv_files[0])
    for file_name in csv_files:
        df = pd.read_csv(file_name) + df
    df = df - pd.read_csv(csv_files[0])
    df = df/5
    df.to_csv(output_file, index=False)
    print(f'Created avareges for {test}')
    print(f'Average magnitude error {np.average(df["Magnitude Error (%)"])}')
    print(f'Average of phase error {np.average(df["Phase Error (%)"])}')
    

    plt.figure(figsize=(10, 6))
    plt.xlabel("Signal Frequency")
    plt.ylabel("Percentage Error")
    plt.title("Magnitude Error")
    plt.plot(df['Frequency'], df['Magnitude Error (%)'], marker='*' , label=file_name)
    plt.legend()
    plt.grid(True)
    plt.savefig(os.path.join("Results/"+test,"magnitude_plot_avareges.png"))
    plt.close()

    x_data = df['Frequency']
    y_data = df['Phase Error (%)']
    # Fit the data to the linear function
    params, covariance = curve_fit(linear_function, x_data, y_data)
    a_fit, b_fit = params

    # Plot the original data and the fitted linear function with the equation as the label
    plt.figure(figsize=(10, 6))
    plt.xlabel("Signal Frequency")
    plt.ylabel("Percentage Error")
    plt.title("Phase Error")
    plt.scatter(x_data, y_data, label='Average Phase Error')
    equation_label = f'Fitted Phase Error: y = {a_fit:.9f}x + {b_fit:.6f}'
    plt.plot(x_data, linear_function(x_data, a_fit, b_fit), 'r', label=equation_label)
    plt.legend()
    plt.grid(True)
    plt.savefig(os.path.join("Results/"+test,"phase_plot_avareges.png"))
    plt.close()
    print(f'Fitted slope is {a_fit}')
    print(f'-'*60)

def process_file(file_name, counter):
    f_s = int(re.search(r'F(\d+)K',file_name).group(1))
    
    data = pd.read_csv(file_name)
    voltage_fft = data['V_Real'] + 1j*data['V_Imag']
    current_fft = data['C_Real'] + 1j*data['C_Imag']
    N = len(voltage_fft)

    fft_bin = int((N*(counter+1)*1000)/(f_s*1000))
    if fft_bin > 512 or fft_bin == 512:
        results_df = pd.DataFrame({
        'Frequency': [FREQUENCIES[counter]],
        'Magnitude': [0],
        'Phase': [0],
        'Magnitude Error (%)': [0],
        'Phase Error (%)': [0]
        })
        return results_df
    
    start_index = fft_bin - 2
    end_index = fft_bin + 2

    if start_index < 0:
        start_index = 0
    if end_index > len(voltage_fft):
        end_index = len(voltage_fft)

    max_index = fft_bin + np.argmax(abs(voltage_fft[start_index:end_index]))
    print(f'{file_name}\t{max_index} fft bin {fft_bin}')
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

    return results_df

def print_min_errors(test, testName):
    for file_name in get_tests(test):
        if file_name == "Results":
            pass
        else:
            df = pd.read_csv(file_name+'/'+testName+'/results.csv')
            print(file_name)
            magMin = np.min(df['Magnitude Error (%)'])
            magMax = np.max(df['Magnitude Error (%)'])
            phaseMin = np.min(df['Phase Error (%)'])
            phaseMax = np.max(df['Phase Error (%)'])
            print(f'Mag\t{magMax}')
            print(f'Phase\t{phaseMax}')
            print('-'*90)

def getTests():
    folders = [f for f in os.listdir() if os.path.isdir(os.path.join(f)) & os.path.join(f).startswith("F") and os.path.join(f).endswith('A')]
    tests = []
    for t in folders:
        tests.append(t[:-2])

    return tests