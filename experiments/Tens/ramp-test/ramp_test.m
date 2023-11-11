file_path = sprintf('raw_data_%d.csv', 0);
data = readtable(file_path);

voltage = data.Voltage;
current = data.Current;

plot(voltage,'LineWidth', 2)
hold on
plot(current,'LineWidth', 2)