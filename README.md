# Digital-FIR-filter-in-FPGA
Design, Implementation and Validation of Digital Filter on Lattice iCE40UP5k FPGA

A hardware implementation of a 64-tap Finite Impulse Response (FIR) filter on Lattice iCE40UP5K FPGA.  
This project demonstrates digital signal processing in hardware using fixed-point arithmetic, FSM control, and BRAM interfacing, along with optimized resource utilization on a low-cost FPGA.

### Filter Architecture
- Features a 64-tap FIR filter
- Implemented in Verilog
- Q16.16 fixed-point arithmetic   
- Dual-port BRAM for coefficient & data storage  
- Clock domain crossing logic  
- Validated its functionality on Lattice iCE40UP5k FPGA  

Explored different filter architecture to use in iCE40UP5K FPGA and compared the tradeoffs,
- [Transposed FIR structure](Transposed_FIR) 
- [FIR Multiplexed structure](FIR_multiplexed)

### Input signal
<img width="500" height="600" src="FIR_multiplexed/python_processing/Input_sig.png">

### Filtered Output signal
<img width="700" height="600" alt="image" src="https://github.com/user-attachments/assets/48dd263e-3e39-4c11-8358-2b94561d412c" />




Note: This project was developed as part of my project work at TUHH and demonstrates practical skills in FPGA development and signal processing.
