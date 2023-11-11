% Define an array of directory names
data_dirs = {'numa\', 'numb\', 'numc\', 'numd\', 'nume\'};

impedance_mag = zeros(1, 10);
impedance_phase = zeros(1, 10);

mag_error = zeros(1,10);
phase_error = zeros(1,10);

osr = zeros(1,10);
SNR = zeros(1,10);

Fs = [227278 114887 77424 58692 47453 39960 34607 30595 27473 24975];

for dir_idx = 1:length(data_dirs)
    data_dir = data_dirs{dir_idx};
    
    % Loop over multiple CSV files in the current directory
    for file_number = 0:9
        % Construct the file path
        file_path = sprintf('%sraw_data_%d.csv', data_dir, file_number);
        counter = file_number + 1;

        % Read the data from the CSV file
        data = readtable(file_path);
        voltage = data.Voltage;
        current = data.Current;

        % Calculate FFT and other parameters as before
        voltage_fft = fft(voltage);
        current_fft = fft(current);

        % Calculate impedance for this file
        [max_value, index] = max(voltage_fft);

        impedance = voltage_fft(index) / current_fft(index);

        impedance_mag(counter) = impedance_mag(counter) + abs(impedance);
        impedance_phase(counter) = impedance_phase(counter) + angle(impedance);

        SNR(counter) = SNR(counter) + (snr(voltage, Fs(counter)) + snr(current, Fs(counter)))/2;
        osr(counter) = osr(counter) + Fs(counter)/(2*90);

        phase_error(counter) = phase_error(counter) + abs(angle(impedance)/(2*pi))*100;
        mag_error(counter) = mag_error(counter) + abs(abs(impedance) - 1)*100;
    end
    % Add any code here that should be executed after processing all files in the current directory.
end

impedance_mag = impedance_mag/5;
impedance_phase = impedance_phase/5;

mag_error = mag_error/5;
phase_error = phase_error/5;

osr = osr/5;
SNR = SNR/5;

% Plot the original data and the fitted line
figure
plot(mag_error, 'o-','LineWidth', 2)
xlabel('Number of Cycles');
ylabel('Magnitude Percentage Error [%]');
grid on
xlim([0,11])

% Plot the original data and the fitted line
figure
plot(phase_error, '*-', LineWidth=2);  % 'o' for points
xlabel('Number of Cycles');
ylabel('Phase Percentage Error [%]');
xlim([0,11])
grid on;


figure
plot(osr, SNR,'o-','LineWidth', 2)
xlabel('Oversampling Ratio');
ylabel('Signal to Noise Ratio [dB]');
grid on;