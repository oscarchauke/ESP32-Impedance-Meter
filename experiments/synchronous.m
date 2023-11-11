% Define an array of directory names
sdata_dirs = {'Thousands\synch-A\', 'Thousands\synch-B\', 'Thousands\synch-C\', 'Thousands\synch-D\', 'Thousands\synch-E\'};
adata_dirs = {'Thousands\F25K-A\', 'Thousands\F25K-B\', 'Thousands\F25K-C\', 'Thousands\F25K-D\', 'Thousands\F25K-E\'};

simpedance_mag = zeros(1, 10);
simpedance_phase = zeros(1, 10);
smag_error = zeros(1,10);
sphase_error = zeros(1,10);
sosr = zeros(1,10);
sSNR = zeros(1,10);

aimpedance_mag = zeros(1, 10);
aimpedance_phase = zeros(1, 10);
amag_error = zeros(1,10);
aphase_error = zeros(1,10);
aosr = zeros(1,10);
aSNR = zeros(1,10);

sFs = 25600;
aFs = 25000;

impedance_phaseT = zeros(1,10);

F_signal = [1000 2000 3000 4000 5000 6000 7000 8000 9000 10000];

for dir_idx = 1:length(sdata_dirs)
    data_dir = sdata_dirs{dir_idx};
    
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

        simpedance_mag(counter) = simpedance_mag(counter) + abs(impedance);
        simpedance_phase(counter) = simpedance_phase(counter) + angle(impedance);

        sSNR(counter) = sSNR(counter) + (snr(voltage, sFs) + snr(current, sFs))/2;
        sosr(counter) = sosr(counter) + sFs/(2*F_signal(counter));

        sphase_error(counter) = sphase_error(counter) + abs(angle(impedance)/(2*pi))*100;
        smag_error(counter) = smag_error(counter) + abs(abs(impedance) - 1)*100;
    end
    % Add any code here that should be executed after processing all files in the current directory.
end

for dir_idx = 1:length(adata_dirs)
    data_dir = adata_dirs{dir_idx};
    
    % Loop over multiple CSV files in the current directory
    for file_number = 0:9
        % Construct the file path
        file_path = sprintf('%sraw_data_%d.csv', data_dir, file_number);
        counter = file_number + 1;
        impedance_phaseT(counter) = (F_signal(counter)/(2*sFs))*2*pi;

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

        aimpedance_mag(counter) = aimpedance_mag(counter) + abs(impedance);
        aimpedance_phase(counter) = aimpedance_phase(counter) + angle(impedance);

        aSNR(counter) = aSNR(counter) + (snr(voltage, aFs) + snr(current, aFs))/2;
        aosr(counter) = aosr(counter) + aFs/(2*F_signal(counter));

        aphase_error(counter) = aphase_error(counter) + abs(angle(impedance)/(2*pi))*100;
        amag_error(counter) = amag_error(counter) + abs(abs(impedance) - 1)*100;
    end
    % Add any code here that should be executed after processing all files in the current directory.
end

simpedance_mag = simpedance_mag/5;
simpedance_phase = simpedance_phase/5;
smag_error = smag_error/5;
sphase_error = sphase_error/5;
sosr = sosr/5;
sSNR = sSNR/5;

aimpedance_mag = aimpedance_mag/5 ;
aimpedance_phase =(( aimpedance_phase/5 - impedance_phaseT)/2*pi)*100;
amag_error = amag_error/5;
aphase_error = aphase_error/5;
aosr = aosr/5;
aSNR = aSNR/5;

% Plot the original data and the fitted line
figure
plot(F_signal, amag_error, 'o-','LineWidth', 2)
xlabel('Signal Frequency');
ylabel('Magnitude Percentage Error [%]');
grid on
xlim([0,11000])

% Plot the original data and the fitted line
figure
plot(F_signal, aimpedance_phase, '*-', LineWidth=2);  % 'o' for points
xlabel('Signal Frequency');
ylabel('Phase Percentage Error [%]');
xlim([0,11000])
grid on;

figure
plot(aosr, aSNR,'o-','LineWidth', 2)
hold on
plot(sosr, sSNR,'o-','LineWidth', 2)
xlabel('Oversampling Ratio');
ylabel('Signal to Noise Ratio [dB]');
legend("Asynchronous", "Synchronous");
grid on;