import numpy as np

IN_FILE = "input_sig.txt"
SIG32_FILE = "binary_sig32b.txt"
SIG8_FILE = "binary_sig8b.txt"

# compouta a binary representation of the filter coefficients
# number of coefficients
IP_BIT_m = 16    
IP_BIT_n = 16



def read_input_sig(f_name):
    decimal_out =[]
    with open(f_name,'r') as file:
        for line in file:
            decimal_out.append(line.rstrip('\n'))
    val = np.array(decimal_out, dtype=float)
    return val


def write_src_sig(source_sinewave, f_name):
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
    with open(f_name,'w') as file:
        for number in list_out: 
            file.write(number+'\n')
    return list_out

def split_binary(input_data, f_name):
    line_number = 0
    with open(f_name,'w') as file:
        for line in input_data:
            line = line.strip()
            if len(line) != 32:
                print(f"Warning: Line {line_number+1} has {len(line)} bits (expected 32), skipping")
                continue
            
            # Split into four 8-bit segments
            for i in range(0, 32, 8):
                byte = line[i:i+8] 
            # Write to output file
                file.write(f"{byte}\n")
            
            line_number += 1
    

if __name__ == "__main__":
# Read data from file
    buf = read_input_sig(IN_FILE)
    thirtytwobitval = write_src_sig(buf,SIG32_FILE)
    split_binary(thirtytwobitval, SIG8_FILE)

