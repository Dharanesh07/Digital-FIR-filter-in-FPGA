def concatenate_binary_strings(input_file, output_file):
    try:
        # Open the input file for reading
        with open(input_file, 'r') as infile:
            binary_strings = infile.readlines()  # Read all lines from the input file

        # Remove newline characters from each binary string
        binary_strings = [line.strip() for line in binary_strings]

        # Open the output file for writing
        with open(output_file, 'w') as outfile:
            # Iterate over the binary strings in steps of 4
            for i in range(0, len(binary_strings), 4):
                # Get up to 4 binary strings, handling cases where there are fewer than 4 remaining
                part1 = binary_strings[i] if i < len(binary_strings) else ""
                part2 = binary_strings[i + 1] if i + 1 < len(binary_strings) else ""
                part3 = binary_strings[i + 2] if i + 2 < len(binary_strings) else ""
                part4 = binary_strings[i + 3] if i + 3 < len(binary_strings) else ""

                # Concatenate the four binary strings
                concatenated = part1 + part2 + part3 + part4

                # Write the concatenated string to the output file
                outfile.write(concatenated + '\n')

        print(f"Successfully wrote concatenated binary strings to {output_file}")

    except FileNotFoundError:
        print(f"Error: The file {input_file} does not exist.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
input_file = "output.txt"  # Replace with your input file path
output_file = "uartout.txt"  # Replace with your output file path
concatenate_binary_strings(input_file, output_file)
