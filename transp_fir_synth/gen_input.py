import numpy as np
import matplotlib.pyplot as plt

SIG_FILE = "sig.txt"

# compouta a binary representation of the filter coefficients
# number of coefficients
IP_BIT_m = 3    
IP_BIT_n = 13


def gen_input_signal():
    # generate a noisy test signal
    timevector = np.linspace(0,2*np.pi,100)
    print(timevector)
    wave = np.sin(2*timevector) + np.cos(3*timevector) + 0.3*np.random.randn(len(timevector))
    return timevector, wave


def write_src_sig(source_sinewave):
# Each value in source_sinewave is a floating point number
# Using the following function, the signal values are converted into fixed point numbers
# This function outputs a binary string np.binary_repr(int(number * (2**(N1-1))), N2)
# The floating-point number is multiplied by 2^(𝑁1 − 1), converting it into an integer
# Return the binary representation of the input number as a string.
# For negative numbers, if width is not given, a minus sign is added to the front. If width is given, the two’s complement of the number is returned, with respect to that width.
    list_out = []
    for number in source_sinewave:
        list_out.append(np.binary_repr(int(number*(2**(IP_BIT_n))),(IP_BIT_m + IP_BIT_n)))

# Save to a file
    with open(SIG_FILE,'w') as file:
        for number in list_out: 
            file.write(number+'\n')


def plot_waveform(time, source_sig):
    plt.figure(figsize=(10, 6))
    plt.plot(time, source_sig, linestyle='-',linewidth='3', label='Input Signal', color='b')
    plt.grid(True)
    plt.legend()
    plt.show()



if __name__ == "__main__":
    time, src_sig = gen_input_signal()
    write_src_sig(src_sig)
    plot_waveform(time, src_sig)


