
def get_sampling_rate(NumCycles, OSR, Fsig):
    f1 = (1024/NumCycles)*Fsig
    if(f1 > 100000):
        f1 = 100000
    f2 = 2*OSR*Fsig
    if(f2 > 100000):
        f2 = 100000
    
    fs = Fsig/1024
    print(f'F1: {f1}\t F2: {f2}')
    return round(f2 / fs) * fs

fadc = get_sampling_rate(10,10,1050)
print(fadc)