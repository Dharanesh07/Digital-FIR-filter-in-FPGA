import serial

def read_serial_and_print_binary(port, baudrate=9600, timeout=1):
    try:
        ser = serial.Serial(port, baudrate, timeout=timeout)
        
        while True:
            data = ser.read(1)
            
            if data:
                binary_str = format(data[0], '08b')
                print(binary_str)
    
    except serial.SerialException as e:
        print(f"Serial connection error: {e}")
    except KeyboardInterrupt:
        print("\nExiting...")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()

if __name__ == "__main__":
    serial_port = "/dev/ttyUSB2"  
    read_serial_and_print_binary(serial_port)
