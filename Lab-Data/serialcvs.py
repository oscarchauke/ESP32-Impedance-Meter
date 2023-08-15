import serial
import csv
import os

BAUD_RATE = 115200
SERIAL_PORT = 'COM3'

fileName = input("Enter filename: ")
script_path = os.path.abspath(__file__)
script_directory = os.path.dirname(script_path)
CSV_FILE = script_directory+ "\\" + fileName + '.csv'


print("Opening ", CSV_FILE, ' and logging from ', SERIAL_PORT)
print('#'*10, "    START LOGGING DATA   ",'#'*10)
DATA_LABELS = ['Voltage', 'Current']

ser = serial.Serial(SERIAL_PORT, BAUD_RATE)

with open(CSV_FILE, 'w', newline='') as csv_file:
    csv_writer = csv.writer(csv_file)
    csv_writer.writerow(DATA_LABELS)
    try:
        while True:
            line = ser.readline().decode('utf-8').strip()
            if line.startswith('>'):
                data = line[1:].split(':')
                csv_writer.writerow(data)
            elif line.startswith('#'):
                print('#'*10, "    DONE LOGGING DATA   ",'#'*10)
                break
            else:
                print(line)
    except KeyboardInterrupt:
            print("Keyboard interrupt detected. Exiting...")
    except Exception as e:
        print(f"Error: {e}")
ser.close()