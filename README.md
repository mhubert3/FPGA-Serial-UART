# VHDL RS-232 UART Transceiver 

## Overview
This repository contains a fully synthesizable RS-232 Universal Asynchronous Receiver-Transmitter (UART) implemented in VHDL. The project features a customized finite state machine (FSM) architecture for both the transmitter and receiver, designed to interface with peripheral microcontrollers and a host PC via a MATLAB-based software GUI.

This project was developed and tested on an FPGA development board, utilizing cycle-accurate simulations and hardware-in-the-loop verification to ensure robust asynchronous serial communication.

## Architecture & State Machine Design

The design is broken into modular, parameterized components:
* **`lab06` (Top-Level):** Integrates the TX and RX modules, routing the physical I/O to the FPGA's PMOD headers for external communication with the target PIC microcontroller.
* **`uart_tx` (Transmitter FSM):** Converts parallel 8-bit data into a serial bitstream. The FSM handles the precise generation of the Start bit (low), sequential shifting of the LSB-first data bits, and the assertion of the Stop bit (high).
* **`uart_rx` (Receiver FSM):** Samples incoming asynchronous serial data. It employs a multi-stage metastability shift register on the input to mitigate synchronization issues. The FSM detects the Start bit falling edge, deliberately waits 1.5 bit periods to align with the center of the data "eye," and systematically samples the subsequent 8 data bits for maximum signal integrity.

## Clock Domain & Baud Rate Calculations

The system operates on a 12 MHz system clock (83.33 ns period). The target transmission speed is 115,200 Baud. 

To achieve this asynchronous timing without a dedicated clock signal between nodes, the bit period is calculated as:
* **Bit Period:** `12,000,000 Hz / 115,200 Baud = 104.167 clock cycles per bit`

Both the transmitter and receiver FSMs utilize an integer counter tuned to exactly `104` clock cycles to regulate the shifting and sampling of the data lines.

## Verification
The design includes a robust VHDL testbench (`uart_tb.vhd`) to validate asynchronous timing margins prior to synthesis. 
* The testbench instantiates both the TX and RX modules in a closed-loop configuration.
* It injects a worst-case alternating bit pattern (`0xA5` / `10100101`) to rigorously test baud rate timing alignment over extended bit sequences.
* Automated VHDL `assert` statements continuously monitor the output, failing the simulation if the RX decoded output does not perfectly match the transmitted payload.
* Hardware-in-the-loop verification was subsequently conducted by bridging the PMOD TX and RX pins (`stx` and `srx`) for physical loopback testing, confirming bidirectional communication with the custom MATLAB serial interface.

## Repository Structure
* `/src` - Synthesizable VHDL source code.
* `/tb` - Self-checking VHDL simulation testbench.
* `/constraints` - XDC pin mapping for the 12 MHz clock and PMOD headers.
* `/scripts` - MATLAB GUI script for hardware interfacing.
* `/docs` - Project specifications and RS-232 protocol references.

## Technologies & Tools
* **Hardware Description Language:** VHDL
* **Development Board:** Digilent Cmod A7-35T (Xilinx Artix-7 XC7A35T FPGA)
* **Peripheral Hardware:** Microchip PIC16F18326 Microcontroller (Target Node)
* **EDA Tools:** Xilinx Vivado (Synthesis, Place & Route, Bitstream Generation), Vivado XSIM (RTL Simulation)
* **Software Integration:** MATLAB (Hardware-in-the-Loop UART GUI)