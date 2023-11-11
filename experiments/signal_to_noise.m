Tdata_dirs = {'Thousands\F10K-A\', 'Thousands\F10K-B\', 'Thousands\F10K-C\', 'Thousands\F10K-D\', 'Thousands\F10K-E\'};
Hdata_dirs = {'Hundreds\F10K-A\', 'Hundreds\F10K-B\', 'Hundreds\F10K-C\', 'Hundreds\F10K-D\', 'Hundreds\F10K-E\'};
Tendata_dirs = {'Tens\F10K-A\', 'Tens\F10K-B\', 'Tens\F10K-C\', 'Tens\F10K-D\', 'Tens\F10K-E\'};

%Create arrays to snr and osr
osr = zeros(1,10);
SNR = zeros(1,10);
mag_error = zeros(1,10);
phase_error = zeros(1,10);

% sampling frequency is kept constant
fs = 10000;

for dir_idx = 1:length(Hdata_dirs)
    data_dir = Tdata_dirs{dir_idx};
% Load the sampled data from the CSV file

for file_number = 0:9
    file_path = sprintf('%sraw_data_%d.csv', data_dir, file_number);
    data = readtable(file_path);

    % change f_signal based on the file name
    f_signal = (file_number+1)*1000;

    voltage = data.Voltage;
    current = data.Current;

    voltage_fft = fft(voltage);
    current_fft = fft(current);
    
    [max_value, index] = max(voltage_fft);
    impedance = voltage_fft(index) / current_fft(index);
    phase_error(file_number + 1) = phase_error(file_number + 1) + abs(angle(impedance)/(2*pi))*100;
    mag_error(file_number + 1) = mag_error(file_number + 1) + abs(abs(impedance) - 1)*100;

    osr_v = (fs/(f_signal*2));

    osr(file_number + 1) = osr_v;
    SNR(file_number + 1) = snr(voltage) + SNR(file_number + 1);
end
end

SNR = SNR/5;
phase_error = rad2deg(phase_error/5);
mag_error = mag_error/5;
% Plot the original data and the fitted line
figure
plot(osr, SNR, 'o-', LineWidth=2);
xlabel('Oversampling Ratio');
ylabel('Signal to Noise Ration [dB]');
legend('SNR');
grid on;

figure
plot(osr, phase_error, 'o-', LineWidth=2);
xlabel('Oversampling Ratio');
ylabel('Phase Error [degrees (°)]');
legend('SNR');
grid on;

figure
plot(osr, mag_error, 'o-', LineWidth=2);
xlabel('Oversampling Ratio');
ylabel('Magnitude Error [ohm (Ω)]');
legend('SNR');
grid on;


%%
file_path1 = sprintf('%sraw_data_%d.csv', data_dir, 0);
data1 = readtable(file_path1);

file_path2 = sprintf('%sraw_data_%d.csv', data_dir, 9);
data2 = readtable(file_path2);

% Extract voltage data from the two datasets
v1 = data1.Voltage;
v2 = data2.Voltage;

% Compute the FFT and frequency axis
Fs = 25000;
N = length(v1); % Length of the signal
frequencies = Fs*(0:(N/2))/N; % Frequency axis for the FFT

v1_fft = fft(v1);
v2_fft = fft(v2);

% Take the one-sided spectrum
v1_fft = v1_fft(1:N/2+1);
v2_fft = v2_fft(1:N/2+1);

% Compute the magnitude of the FFT
v1_mag = abs(v1_fft)/N;
v2_mag = abs(v2_fft)/N;


% Plot the frequency domain representation
figure;
stem(frequencies, v1_mag, LineWidth=2);
xlabel('Frequency (Hz)');
ylabel('Magnitude');

figure
stem(frequencies, v2_mag, LineWidth=2);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
