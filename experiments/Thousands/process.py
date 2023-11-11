import im_tools
import os
import pandas as pd
import numpy as np

def process_all_files():
    print("Processing all data files...")
    tests = [f for f in os.listdir() if os.path.isdir(os.path.join(f)) & os.path.join(f).startswith("n")]

    for test in tests:
        output_file = test + '/results.csv'
        all_results = []
        counter = 0
        csv_files = [f for f in os.listdir(test+'/') if f.endswith('.csv')]
        print(f'Working on test {test}')

        for file in csv_files:
            if file.startswith("resu"):
                break
            print(f"{counter}\tProcessing file {file}")
            results_df = im_tools.process_file(os.path.join(test, file), counter)
            all_results.append(results_df)
            counter = counter + 1

        all_results_df = pd.concat(all_results, ignore_index=True)
        all_results_df.to_csv(output_file, index=False)
        print(f'All results saved to {output_file}')
        print(f'-'*60)

def check_time_domain(test, file):
    if not os.path.exists(test):
        print(f'{test} NOT AVALIABLE')
        return
    file_name = os.path.join(test, f'raw_data_{file}.csv')
    if os.path.exists(file_name):
        data = pd.read_csv(file_name)
        im_tools.plot_time_domain(data['Voltage'], data['Current'])

def check_frequency_domain(test, file):
    if not os.path.exists(test):
        print(f'{test} NOT AVALIABLE')
        return
    file_name = os.path.join(test, f'raw_data_{file}.csv')
    if os.path.exists(file_name):
        data = pd.read_csv(file_name)
        voltage_fft = abs(data["V_Real"]+1j*data["V_Imag"])
        current_fft = abs(data["C_Real"]+1j*data["C_Imag"])
        im_tools.plot_compare_fft(voltage_fft, current_fft)

def main():
    print("-"*60)
    print("CHOOSE OPTION")
    print("0\tProcess all files")
    print("1\tProcess test")
    print("2\tCheck time domain")
    print("3\tCheck Frequency domain")
    print("4\tPrint error min and max")
    print("99\tExit")
    print("-"*60)

    option = input("Choose an option: ")
  
    if option == '0':
        process_all_files()
        tests = im_tools.getTests()
        for test in tests:
            im_tools.avarege_tests(test)
            im_tools.export_error_plots(test)
    elif option == '1':
        test = input("Enter test name: ")
        im_tools.avarege_tests(test)
        im_tools.export_error_plots(test)
    elif option == '2':
        test = input("Enter test name: ")
        file = input("Enter test number: ")
        check_time_domain(test, file)
    elif option == '3':
        test = input("Enter test name: ")
        file = input("Enter test number: ")
        check_frequency_domain(test, file)
    elif option == '4':
        test = input("Enter test name: ")
        im_tools.print_min_errors("Results", test)
    elif option == '99':
        return
    else:
        print("Option not valid")
    main()

if __name__ == "__main__":
    main()