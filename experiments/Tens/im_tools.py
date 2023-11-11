import pandas as pd
import numpy as np
import os
import math
import matplotlib.pyplot as plt
import process as pro

FREQUENCIES = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
if not os.path.exists("Results"):
    os.makedirs("Results")
    print(f'Results folder created')

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
    plt.plot(np.abs(python_fft), label="python")
    plt.plot(np.abs(esp_fft), label="esp")
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

    plt.figure(figsize=(10, 6))
    plt.xlabel("Signal Frequency")
    plt.ylabel("Percentage Error")
    plt.title("Magnitude Error")
    plt.plot(df['Frequency'], df['Magnitude Error (%)'], marker='*' , label=file_name)
    plt.legend()
    plt.grid(True)
    plt.savefig(os.path.join("Results/"+test,"magnitude_plot_avareges.png"))

    plt.figure(figsize=(10, 6))
    plt.xlabel("Signal Frequency")
    plt.ylabel("Percentage Error")
    plt.title("Phase Error")
    plt.plot(df['Frequency'], df['Phase Error (%)'], marker='*',label=file_name)
    plt.legend()
    plt.grid(True)
    plt.savefig(os.path.join("Results/"+test,"phase_plot_avareges.png"))
    

def process_file(file_name, counter):
    data = pd.read_csv(file_name)

    window = np.hamming(len(data['Current']))

    voltage_fft = np.fft.fft(data['Voltage']*window)
    current_fft = np.fft.fft(data['Current']*window)

    index_highest_voltage_fft = np.argmax(np.abs(voltage_fft))
    index_highest_current_fft = np.argmax(np.abs(current_fft))

    if(index_highest_current_fft > 512):
        index_highest_current_fft = 1024 - index_highest_current_fft

    if(index_highest_voltage_fft > 512):
        index_highest_voltage_fft = 1024 - index_highest_voltage_fft

    impedance = voltage_fft[index_highest_voltage_fft] / current_fft[index_highest_current_fft]

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