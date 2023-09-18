% Load the CSV file
data = readtable('test-0.csv');
% Extract columns for Voltage and Current
Voltage = (data.Voltage ./ 4095).*1.1;
Current = (data.Current ./4095).*1.1;

fprintf("SNR Voltage: %f\n", snr(Voltage));
fprintf("SNR Current: %f\n", snr(Current));

% Define the sampling frequency and time vector
Fs = 8200;  % Sampling frequency (Hz)
T = 1/Fs;   % Sampling period
N = length(Voltage); % Length of the signal

t = (0:N-1)*T; % Time vector
t = (0:(N-1)) / Fs;
Frange = Fs/2;


fft_voltage = fftshift(fft(Voltage)/N);
fft_current = fftshift(fft(Current)/N);

impedance = fft_voltage ./ fft_current;

Vfft = fftshift((data.Real_V_ + 1i .* data.Imag_V_)/N/2);
Cfft = fftshift((data.Real_C_ + 1i .* data.Imag_C_)/N/2);
Impe = Vfft ./ Cfft;

% Calculate FFT for voltage and current signals
frequencies = (-Fs/2):(Fs/N):(Fs/2-Fs/N); % Frequency vector for FFT

%plot time domain signals
plot(t, Voltage, t, Current, 'r-o');
legend('Voltage', 'Current');
xlabel('Time');
title('Time Domain Signals');
grid on;

% Plot FFT of signals
figure;
subplot(2,1,1);
plot(frequencies, abs(fft_voltage), 'b-o');
title('FFT of Voltage Signal');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
xlim([0 Frange]);
grid on;

subplot(2,1,2);
plot(frequencies, abs(fft_current), 'b-o');
title('FFT of Current Signal');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
xlim([0 Frange]);
grid on;

figure;
subplot(2,1,1);
plot(frequencies, abs(impedance));
title('Magnitude of the Impedance');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
xlim([0 Frange]);
grid on;

subplot(2,1,2);
plot(frequencies, angle(impedance));
title('Phase of the Impedance');
xlabel('Frequency (Hz)');
ylabel('Phase');
xlim([0 Frange]);
grid on;