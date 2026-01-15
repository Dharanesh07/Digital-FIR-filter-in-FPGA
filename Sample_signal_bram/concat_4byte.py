def process_uart_data(input_file, output_file):
    try:
        # Open the input file for reading
        with open(input_file, 'r') as infile:
            binary_strings = [line.strip() for line in infile.readlines()]

        # Open the output file for writing
        with open(output_file, 'w') as outfile:
            sync_pattern = '01001001'
            found_sync = False
            buffer = []
            
            for line in binary_strings:
                if not found_sync:
                    # Look for sync pattern
                    if line == sync_pattern:
                        found_sync = True
                        buffer = [line]  # Start new frame with sync pattern
                else:
                    # Collect data after sync
                    buffer.append(line)
                    
                    # When we have sync + 4 bytes, process the frame
                    if len(buffer) == 5:  # sync + 4 bytes
                        # Verify the sync pattern is still at start (in case of false sync)
                        if buffer[0] == sync_pattern:
                            # Concatenate the 4 data bytes (skip the sync pattern)
                            concatenated = ''.join(buffer[1:5])
                            outfile.write(concatenated + '\n')
                        
                        # Reset to look for next sync
                        found_sync = False
                        buffer = []

        print(f"Successfully processed UART data to {output_file}")

    except FileNotFoundError:
        print(f"Error: The file {input_file} does not exist.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
input_file = "output.txt"  # Replace with your input file path
output_file = "uartout.txt"  # Replace with your output file path
process_uart_data(input_file, output_file)
