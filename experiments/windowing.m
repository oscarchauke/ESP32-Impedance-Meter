% Define an array of directory names
Tdata_dirs = {'Thousands\F20K-A\', 'Thousands\F20K-B\', 'Thousands\F20K-C\', 'Thousands\F20K-D\', 'Thousands\F20K-E\'};
Hdata_dirs = {'Hundreds\F10K-A\', 'Hundreds\F10K-B\', 'Hundreds\F10K-C\', 'Hundreds\F10K-D\', 'Hundreds\F10K-E\'};
data_dirs = {'Tens\F10K-A\', 'Tens\F10K-B\', 'Tens\F10K-C\', 'Tens\F10K-D\', 'Tens\F10K-E\'};
N = 1024;

rmag_error = zeros(1,10);
rphase_error = zeros(1,10);
rsnr = zeros(1,10);

bmag_error = zeros(1,10);
bphase_error = zeros(1,10);
bsnr = zeros(1,10);

hmag_error = zeros(1,10);
hphase_error = zeros(1,10);
hsnr = zeros(1,10);

hhmag_error = zeros(1,10);
hhphase_error = zeros(1,10);
hhsnr = zeros(1,10);


Fs = 25000;

F_signal = [1000 2000 3000 4000 5000 6000 7000 8000 9000 10000];

for dir_idx = 1:length(data_dirs)
    data_dir = Tdata_dirs{dir_idx};
    
    % Loop over multiple CSV files in the current directory
    for file_number = 0:9
        % Construct the file path
        file_path = sprintf('%sraw_data_%d.csv', data_dir, file_number);
        counter = file_number + 1;

        F_signal(file_number+1) = (file_number+1)*1000;

        blackW = blackman(N);
        hannW = hanning(N);
        hammW = hamming(N);

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
        rphase_error(counter) = rphase_error(counter) + abs(angle(impedance)/(2*pi))*100;
        rmag_error(counter) = rmag_error(counter) + abs(abs(impedance) - 1)*100;
        rsnr(counter) = rsnr(counter) + (snr(voltage)+snr(current))/2;

        % Calculate FFT and other parameters as before
        voltage_fft = fft(voltage.*blackW);
        current_fft = fft(current.*blackW);
        % Calculate impedance for this file
        [max_value, index] = max(voltage_fft);
        impedance = voltage_fft(index) / current_fft(index);
        bphase_error(counter) = bphase_error(counter) + abs(angle(impedance)/(2*pi))*100;
        bmag_error(counter) = bmag_error(counter) + abs(abs(impedance) - 1)*100;
        bsnr(counter) = bsnr(counter) + (snr(voltage.*blackW)+snr(current.*blackW))/2;


        % Calculate FFT and other parameters as before
        voltage_fft = fft(voltage.*hannW);
        current_fft = fft(current.*hannW);
        % Calculate impedance for this file
        [max_value, index] = max(voltage_fft);
        impedance = voltage_fft(index) / current_fft(index);
        hphase_error(counter) = hphase_error(counter) + abs(angle(impedance)/(2*pi))*100;
        hmag_error(counter) = hmag_error(counter) + abs(abs(impedance) - 1)*100;
        hsnr(counter) = hsnr(counter) + (snr(voltage.*hannW)+snr(current.*hannW))/2;


        % Calculate FFT and other parameters as before
        voltage_fft = fft(voltage.*hammW);
        current_fft = fft(current.*hammW);
        % Calculate impedance for this file
        [max_value, index] = max(voltage_fft);
        impedance = voltage_fft(index) / current_fft(index);
        hhphase_error(counter) = hhphase_error(counter) + abs(angle(impedance)/(2*pi))*100;
        hhmag_error(counter) = hhmag_error(counter) + abs(abs(impedance) - 1)*100;
        hhsnr(counter) = hhsnr(counter) + (snr(voltage.*hammW)+snr(current.*hammW))/2;
    end
    % Add any code here that should be executed after processing all files in the current directory.
end

rmag_error = rmag_error/5;
rphase_error = rphase_error/5;
rsnr = rsnr/5;

bmag_error = bmag_error/5;
bphase_error = bphase_error/5;
bsnr = bsnr/5;

hmag_error = hmag_error/5;
hphase_error = hphase_error/5;
hsnr = hsnr/5;

hhmag_error = hhmag_error/5;
hhphase_error = hhphase_error/5;
hhsnr = hhsnr/5;

% Plot the original data and the fitted line
figure
plot(F_signal, rmag_error, 'o-','LineWidth', 2)
hold on
plot(F_signal, bmag_error, 'o-','LineWidth', 2)
plot(F_signal, hmag_error, 'o-','LineWidth', 2)
plot(F_signal, hhmag_error, 'o-','LineWidth', 2)
xlabel('Signal Frequency');
ylabel('Magnitude Percentage Error [%]');
legend("Rectangular", "Blackman", "Hanning", "Hamming");
grid on

% Plot the original data and the fitted line
figure
plot(F_signal, rphase_error, '*-', LineWidth=2);  % 'o' for points
hold on
plot(F_signal, bphase_error, '*-', LineWidth=2);
plot(F_signal, hphase_error, '*-', LineWidth=2);
plot(F_signal, hhphase_error, '*-', LineWidth=2);
xlabel('Signal Frequency');
ylabel('Phase Percentage Error [%]');
legend("Rectangular", "Blackman", "Hanning", "Hamming");
grid on;

disp(['Window Function Mean(Mag)  Mean(Phase)']);
disp(['Rectang: ' num2str(mean(rmag_error))  '  ' num2str(mean(rphase_error)) '  ' num2str(mean(rsnr))]);
disp(['BlackMa: ' num2str(mean(bmag_error)) '  ' num2str(mean(bphase_error)) '  ' num2str(mean(bsnr))]);
disp(['Hamming: ' num2str(mean(hmag_error))  '  ' num2str(mean(hphase_error)) '  ' num2str(mean(hsnr))]);
disp(['Hanning: ' num2str(mean(hhmag_error))  '  ' num2str(mean(hhphase_error)) '  ' num2str(mean(hhsnr))]);
