data_dirs = {'Thousands\F100K-A\', 'Thousands\F100K-B\', 'Thousands\F100K-C\', 'Thousands\F100K-D\', 'Thousands\F100K-E\'};
data_drs = {'Hundreds\F100K-A\', 'Hundreds\F100K-B\', 'Hundreds\F100K-C\', 'Hundreds\F100K-D\', 'Hundreds\F100K-E\'};

F_signal = [1000 2000 3000 4000 5000 6000 7000 8000 9000 10000];
Fs = 100000;

theoTime = 0;
interTime = 0;

impedance_phaseT = zeros(1,10);
impedance_phaseM = zeros(1,10);
Iimpedance_phaseC = zeros(1,10); 

for dir_idx = 1:length(data_dirs)
    data_dir = data_dirs{dir_idx};
    % Loop over multiple CSV files in the current directory
    for file_number = 0:9
        % Construct the file path
        file_path = sprintf('%sraw_data_%d.csv', data_dir, file_number);
        counter = file_number + 1;

        impedance_phaseT(counter) = (F_signal(counter)/(2*Fs))*2*pi;

        % Read the data from the CSV file
        data = readtable(file_path);
        voltage = data.Voltage;
        current = data.Current;

        tic
        % Calculate FFT and other parameters as before
        voltage_fft = fft(voltage);
        current_fft = fft(current);

        % Calculate impedance for this file
        [max_value, index] = max(voltage_fft);
        impedance = voltage_fft(index) / current_fft(index);
        impedance_phaseM(counter) = impedance_phaseM(counter) + abs(angle(impedance));
        theoTime = theoTime + toc;


        tic
        voltage = interp(voltage,2,5);
        current = interp(current,2,5);

        voltage = voltage(1:end-1);
        current = current(2:end);

        % Calculate FFT and other parameters as before
        voltage_fft = fft(voltage);
        current_fft = fft(current);

        % Calculate impedance for this file
        [max_value, index] = max(voltage_fft);
        impedance = voltage_fft(index) / current_fft(index);
        Iimpedance_phaseC(counter) = Iimpedance_phaseC(counter) + abs(angle(impedance));
        
        interTime = interTime + toc;

    end
   
end

tic
Timpedance_phaseC = ((abs(((impedance_phaseM/5) - impedance_phaseT)))/2*pi)*100;
theoTime = theoTime + toc;

tic
Iimpedance_phaseC = ((abs(Iimpedance_phaseC/5))/2*pi)*100;
interTime = interTime + toc;

impedance_phaseM = (abs(impedance_phaseM)/2*pi)*100;

interTime
theoTime
figure
plot(F_signal, (Timpedance_phaseC), 'o-','LineWidth', 2)

%legend("Theoretical", "Interpolation")
xlabel('Signal Frequency');
ylabel('Compasented Phase Error [%]');
grid on
hold off

fprintf("-------------------------------------------------------------\n")
fprintf("%.6f & %.6f & %.6f\n", std(impedance_phaseM/5), std(Timpedance_phaseC), std(Iimpedance_phaseC))
fprintf("%.6f & %.6f & %.6f\n", mean(impedance_phaseM/5), mean(Timpedance_phaseC), mean(Iimpedance_phaseC))