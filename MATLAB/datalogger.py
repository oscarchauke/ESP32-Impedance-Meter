import serial
import csv
import os

def log_data_to_csv(CSV_FILE, DATA_LABELS, serial_port):
    with open(CSV_FILE, 'w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow(DATA_LABELS)
        try:
            while True:
                line = serial_port.readline().decode('utf-8').strip()
                if line.startswith('>'):
                    data = line[1:].split(':')
                    csv_writer.writerow(data)
                elif line.startswith('#'):
                    print('#'*10, "    DONE LOGGING DATA   ",'#'*10)
                    csv_file.close()
                    break
                else:
                    print(line)
        except KeyboardInterrupt:
            print("Keyboard interrupt detected. Exiting...")
        except Exception as e:
            print(f"Error: {e}")

BAUD_RATE = 115200
SERIAL_PORT = 'COM4'

testName = input("Enter test name: ")
script_path = os.path.abspath(__file__)
script_directory = os.path.dirname(script_path)

DATA_LABELS = ['Voltage', 'Current', 'Real(V)', 'Imag(V)','Real(C)', 'Imag(C)']

ser = serial.Serial(SERIAL_PORT, BAUD_RATE)
testNumber = 0
print('#'*15, "    TEST STARTED   ",'#'*15)

while True:
    line = ser.readline().decode('utf-8').strip()
    if line.startswith("*"):
        CSV_FILE = script_directory+ "\\" + testName +'-'+ str(testNumber) + '.csv'
        print("Opening ", CSV_FILE, ' and logging from ', SERIAL_PORT)
        testNumber = testNumber + 1
        log_data_to_csv(CSV_FILE=CSV_FILE, DATA_LABELS=DATA_LABELS, serial_port=ser)
    elif line.startswith('^'):
        print('#'*15, "    TEST DONE   ",'#'*15)
        break
ser.close()
