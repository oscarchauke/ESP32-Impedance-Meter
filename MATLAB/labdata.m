% Load the CSV file
data = readtable('../Lab-Data/phaseZero/f80000/f80000A-0.csv');
% Extract columns for Voltage and Current
Voltage = ((data.Voltage - 128) ./ 4095).*1.1;
Current = ((data.Current -128) ./4095).*1.1;

fprintf("SNR Voltage: %f\n", snr(Voltage));
fprintf("SNR Current: %f\n", snr(Current));

% Define the sampling frequency and time vector
Fs = 32800/4;  % Sampling frequency (Hz)
T = 1/Fs;   % Sampling period
N = length(Voltage); % Length of the signal

t = (0:(N-1)) / Fs;
Frange = Fs/2;

Vfft = fftshift((data.Real_V_ + 1i .* data.Imag_V_)/N/2);
Cfft = fftshift((data.Real_C_ + 1i .* data.Imag_C_)/N/2);
Impe = Vfft ./ Cfft;

f = 3200;
rt = (N/2) + round((N*f)/Fs);
for i = (rt-2):(rt+2)
    fprintf("######## %d Item #########\n",i);
    fprintf("Voltage %f\t%f\n", abs(Vfft(i)), angle(Vfft(i)));
    fprintf("Current %f\t%f\n", abs(Cfft(i)), angle(Cfft(i)));
    phase = angle(Impe(i));
    mag = abs(Impe(i));
 
    fprintf("Impedance\t%f\t%f\n" ,mag, phase);
    fprintf("Error %f\t%f\n\n", abs((mag-1)*100), abs(((phase)/2*pi)*100));
    
end

% Calculate FFT for voltage and current signals
frequencies = (-Fs/2):(Fs/N):(Fs/2-Fs/N); % Frequency vector for FFT

%plot time domain signals
plot(t, Voltage, t, Current);
legend('Voltage', 'Current');
xlabel('Time');
title('Time Domain Signals');
grid on;

% Plot FFT of signals
figure;
subplot(2,1,1);
plot(frequencies, abs(Vfft), 'b-o');
title('FFT of Voltage Signal');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
xlim([0 Frange]);
grid on;

subplot(2,1,2);
plot(frequencies, abs(Cfft), 'b-o');
title('FFT of Current Signal');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
xlim([0 Frange]);
grid on;

figure;
subplot(2,1,1);
plot(frequencies, abs(Impe));
title('Magnitude of the Impedance');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
xlim([0 Frange]);
grid on;

subplot(2,1,2);
plot(frequencies, angle(Impe));
title('Phase of the Impedance');
xlabel('Frequency (Hz)');
ylabel('Phase');
xlim([0 Frange]);
grid on;