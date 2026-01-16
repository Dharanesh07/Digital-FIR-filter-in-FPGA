import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import firwin, lfilter


# Parameters
sampling_freq = 1000  # Sampling frequency in Hz
cutoff_freq = 200     # Cutoff frequency in Hz
num_taps = 8        # Number of filter taps (must be odd for a low-pass filter)

SRC_FILE = "sig.txt"
SIM_FILE = "uartout.txt"

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
    binary_data = []
    with open(f_name,'r') as file:
        for line in file:
            binary_data.append(line.rstrip('\n'))
    decimal_out =[]
    for num in binary_data:
        #decimal_out.append(todecimal(num,RES_BIT_WIDTH)/(2**(2*(RES_BIT_WIDTH-1))))
        decimal_out.append(todecimal(num,(IP_BIT_n+IP_BIT_m))/(2**(IP_BIT_n)))
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
    fir_coeff = firwin(num_taps, cutoff_freq,window='hamming', fs=sampling_freq)
    print(fir_coeff)
    # Apply the FIR filter of the signal
    filtered_signal = lfilter(fir_coeff, 1.0, input_sinwav)
    return filtered_signal

def plot_waveform(source_sig, simulation_sig, py_sig):
    plt.figure(figsize=(10, 6))
    
    plt.subplot(3,1,1)
    plt.plot(source_sig, linestyle='-',linewidth='3', label='Input Signal', color='b')
    #plt.ylim(-3,3)
    plt.grid(True)
    plt.legend()
    
    plt.subplot(3,1,2) 
    plt.plot(simulation_sig,linestyle='-', linewidth='3',color='r',label='Simulation Output')
    #plt.ylim(-3,3)
    plt.grid(True)
    plt.legend()
    
    plt.subplot(3,1,3) 
    plt.plot(py_sig, linestyle='-', linewidth='3',color='g', label='python FIR filter')
    #plt.ylim(-3,3)
    plt.grid(True)
    plt.legend()
    
    plt.show()



if __name__ == "__main__":
    
    #filt_sig = fir_filter(src_sig) 
    in_sig  = read_input_sig(SRC_FILE) 
    sim_sig = read_output_sig(SIM_FILE)
    pyfir_sig = fir_filter(in_sig)
    print(in_sig)
    print(sim_sig)
    print("Lengths - input signal:", len(in_sig), "sim_sig:", len(sim_sig), "filt_sig:",) 
    plot_waveform(in_sig,sim_sig, pyfir_sig)


