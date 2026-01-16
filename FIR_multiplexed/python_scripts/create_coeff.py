def convert_tap_file(input_file='tap.txt'):
    try:
        with open(input_file, 'r') as f:
            lines = f.readlines()
        
        for i, line in enumerate(lines):
            # Remove any whitespace or newline characters
            binary_str = line.strip()
            
            # Verify the binary string is valid
            if not all(c in '01' for c in binary_str):
                print(f"Warning: Line {i+1} contains non-binary characters: {line}")
                continue
                
            # Format the output line
            formatted_line = f"coeff[{i}] <= 32'b{binary_str};"
            print(formatted_line.strip())
        
    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Run the conversion
convert_tap_file()
