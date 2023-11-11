file_path = sprintf('numa\\raw_data_%d.csv', 9);
data = readtable(file_path);

sine_wave = medfilt1(data.Voltage,20);

% Calculate the number of cycles
threshold = 0.5; % Set a threshold to detect when the signal crosses zero
positive_crossings = 0;
negative_crossings = 0;

for i = 2:length(sine_wave)
    if sine_wave(i) > threshold && sine_wave(i - 1) <= threshold
        positive_crossings = positive_crossings + 1;
    elseif sine_wave(i) < -threshold && sine_wave(i - 1) >= -threshold
        negative_crossings = negative_crossings + 1;
    end
end

% Total number of cycles is the sum of positive and negative crossings
total_cycles = (positive_crossings + negative_crossings) / 2;

fprintf('Number of complete cycles: %.2f\n', total_cycles);

% Plot the sine wave and zero crossings
figure;
plot(sine_wave);
hold on;
plot(zeros(size(sine_wave)), 'r--');
title('Sine Wave and Zero Crossings');
xlabel('Time (s)');
legend('Sine Wave', 'Zero Crossing');

