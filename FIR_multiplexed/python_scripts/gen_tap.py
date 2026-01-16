#! /usr/bin/python3
import csv

output_data=[]
buf=[]
TAP_BIT_M = 2
TAP_BIT_N = 30
INPUT_FILE = "coeff.txt"
OUTPUT_FILE = "tap.txt"

'''
with open('coeff.txt',mode='r') as file:
    dat_in = csv.reader(file, delimiter=',')
    for lines in dat_in:
        data_out = lines[0].strip()     #Remove spaces from the csv file
        if(data_out[0] == "[" ):
            print(data_out.strip("["))  #Remove [ bracket
        elif(data_out[-1] == "]"):
            print(data_out.strip("]"))  #Remove ] bracket
        else:
            print(data_out)
'''

def fixed_to_float(input_fixed_val,n_bits):
    c = abs(input_fixed_val)
    sign = 1 
    if input_fixed_val < 0:
        # convert back from two's complement
        c = input_fixed_val - 1 
        c = ~c
        sign = -1
    float_val = (1.0 * c) / (2 ** n_bits)
    float_val = float_val * sign
    return float_val

def float_to_fixed(input_float_val,n_bits):
    a = input_float_val* (2**n_bits)
    fixed_val = int(round(a))
    if a < 0:
        # next three lines turns b into it's 2's complement.
        fixed_val = abs(fixed_val)
        fixed_val = ~fixed_val
        fixed_val = fixed_val + 1
    return fixed_val

def to_binary(num,n_bits):
    # Compute 2s complement 
    if(num<0):
       num = (1<<n_bits) + num
    bin_val = format(num, f'0{n_bits}b')
    return bin_val

def read_data(file_name):
    data_list = []
    with open(file_name,mode='r') as file:
        dat_in = csv.reader(file, delimiter=',')
        for lines in dat_in:
            data_out = lines[0].strip()     #Remove spaces from the csv file
            if(data_out[0] == "[" ):
                data_list.append(float(data_out.strip("[")))  #Remove [ bracket
            elif(data_out[-1] == "]"):
                data_list.append(float(data_out.strip("]")))  #Remove [ bracket
            else:
                data_list.append(float(data_out))  #Remove [ bracket
    return data_list 

def write_to_file(data):
    with open(OUTPUT_FILE, "w") as output_file:
        for binary_value in data:
            output_file.write(binary_value + "\n")


buf = read_data(INPUT_FILE)
for i in range(0,len(buf),1):
    output_data.append(to_binary((float_to_fixed(buf[i],TAP_BIT_N)),(TAP_BIT_M + TAP_BIT_N)))
print(output_data)
write_to_file(output_data)
