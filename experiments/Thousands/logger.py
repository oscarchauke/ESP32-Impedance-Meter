import serial
import csv
import os

# Initialize variables
csv_file = None
csv_writer = None
counter = 0

# Open the UART port
ser = serial.Serial('COM3', baudrate=115200)

# sort out file naming
test_name = input("Enter test name: ")
script_path = os.path.abspath(__file__)
script_directory = os.path.dirname(script_path)
test_folder = os.path.join(script_directory, test_name)

if not os.path.exists(test_folder):
    os.makedirs(test_folder)
    print(f'Test folder {test_name} created')

print("Press ready button")
print('-'*60)

while True:
    # Read a line from UART
    uart_data = ser.readline().decode('utf-8').strip()

    # Check for "START_RAW_DATA"
    if uart_data == "START_RAW_DATA":
        # Close the previous CSV file if it's open
        if csv_file:
            csv_file.close()

        # Create a new CSV file
        file_name = os.path.join(test_folder, f"raw_data_{counter}.csv")
        print(f'Writting to {file_name}')
        csv_file = open(file_name, 'w', newline='')
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow(["Voltage", "Current", "V_Real", "V_Imag", "C_Real", "C_Imag"])
        counter = counter + 1

    # Check for "END_RAW_DATA"
    elif uart_data == "END_RAW_DATA":
        # Close the CSV file
        if csv_file:
            csv_file.close()
            csv_file = None
            csv_writer = None
        print("-"*60)

    # Otherwise, write data to the CSV file
    elif uart_data.startswith(">"):
        csv_writer.writerow(uart_data[1:].split(':'))

    elif uart_data == "END_TEST":
        # Close the CSV file
        if csv_file:
            csv_file.close()
            csv_file = None
            csv_writer = None
        break

    else:
        print(uart_data)

# Close the UART port when done
ser.close()
