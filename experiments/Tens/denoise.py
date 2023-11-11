import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

data = pd.read_csv("F10K-A/raw_data_1.csv")
noisey = data['Voltage']

n = len(noisey)
fhat = np.fft.fft(noisey, n)
PSD = fhat * np.conj(fhat) / n

plt.figure()
plt.plot(noisey)
plt.show()

plt.figure()
plt.plot(abs(PSD))
plt.show()