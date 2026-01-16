import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import firwin, lfilter


# Parameters
sampling_freq = 1000  # Sampling frequency in Hz
cutoff_freq = 200     # Cutoff frequency in Hz
num_taps = 8        # Number of filter taps (must be odd for a low-pass filter)

SRC_FILE = "input_sig.txt"

# This is used to convert the filter coefficients to 16-bit signed values

IP_BIT_m = 3
IP_BIT_n = 13
# source_sinewave bit width
OP_BIT_m = 6
OP_BIT_n = 26


def todecimal(x,bits):
    # Ensure the binary string is not longer than the specified bit width
    assert len(x) <= bits
    # Convert the binary string to an integer
    n = int(x,2)
    # Compute the sign bit position (e.g., for 8 bits, s = 128)
    s = 1<<(bits -1)
    # Compute the signed value
    return_val = ((n & s -1)-(n & s))
    return return_val

def read_input_sig(f_name):
    decimal_out =[]
    with open(f_name,'r') as file:
        for line in file:
            decimal_out.append(line.rstrip('\n'))
    val = np.array(decimal_out, dtype=float)
    return val

def read_output_sig(f_name):
    binary_data = []
    with open(f_name,'r') as file:
        for line in file:
            binary_data.append(line.rstrip('\n'))
    decimal_out =[]
    for num in binary_data:
        decimal_out.append(todecimal(num,(OP_BIT_n+OP_BIT_m))/(2**(OP_BIT_n)))
        #decimal_out.append(todecimal(num,RES_BIT_WIDTH)/(2**(2*(TAP_WIDTH-1))))
    val = np.array(decimal_out, dtype=float)
    return val

def fir_filter(input_sinwav):
    # Design the FIR low-pass filter
    #fir_coeff = firwin(num_taps, cutoff_freq,window='hamming', fs=sampling_freq)
    #print(type(fir_coeff))
    fir_coeff = np.array([0.000332,
    0.000487,
    0.000631,
    0.000733,
    0.000757,
    0.000666,
    0.000424,
    0.000000,
    -0.000627,
    -0.001462,
    -0.002495,
    -0.003691,
    -0.004998,
    -0.006341,
    -0.007629,
    -0.008759,
    -0.009625,
    -0.010120,
    -0.010153,
    -0.009654,
    -0.008578,
    -0.006918,
    -0.004706,
    -0.002012,
    0.001056,
    0.004359,
    0.007730,
    0.010994,
    0.013968,
    0.016485,
    0.018398,
    0.019593,
    0.020000,
    0.019593,
    0.018398,
    0.016485,
    0.013968,
    0.010994,
    0.007730,
    0.004359,
    0.001056,
    -0.002012,
    -0.004706,
    -0.006918,
    -0.008578,
    -0.009654,
    -0.010153,
    -0.010120,
    -0.009625,
    -0.008759,
    -0.007629,
    -0.006341,
    -0.004998,
    -0.003691,
    -0.002495,
    -0.001462,
    -0.000627,
    0.000000,
    0.000424,
    0.000666,
    0.000757,
    0.000733,
    0.000631,
    0.000487,
    0.000332]) 
    
    # Apply the FIR filter of the signal
    filtered_signal = lfilter(fir_coeff, 1.0, input_sinwav)
    return filtered_signal

def plot_waveform(source_sig, py_sig):
    plt.figure(figsize=(10, 6))
    
    plt.subplot(2,1,1)
    plt.plot(source_sig, linestyle='-',linewidth='3', label='Input Signal', color='b')
    #plt.ylim(-3,3)
    plt.grid(True)
    plt.legend()
    
    plt.subplot(2,1,2) 
    plt.plot(py_sig, linestyle='-', linewidth='3',color='g', label='python FIR filter')
    plt.ylim(-50,300)
    plt.grid(True)
    plt.legend()
    
    plt.show()



if __name__ == "__main__":
    
    #filt_sig = fir_filter(src_sig) 
    in_sig  = read_input_sig(SRC_FILE) 
    pyfir_sig = fir_filter(in_sig)
    print(in_sig)
    plot_waveform(in_sig, pyfir_sig)


