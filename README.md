# VHDL RS-232 UART Transceiver 

## Overview
This repository contains a fully synthesizable RS-232 Universal Asynchronous Receiver-Transmitter (UART) implemented in VHDL. The project includes a customized FSM architecture for both the transmitter and receiver, designed to interface with a PIC microcontroller and a MATLAB-based software GUI.

This project was developed and tested on an FPGA development board, utilizing loopback debugging and hardware-in-the-loop verification.

## Architecture & State Machine Design


The UART is broken into modular, parameterized components:
* **`uart_tx` (Transmitter):** Converts parallel 8-bit data into a serial bitstream. The FSM handles the generation of the Start bit, sequential shifting of the LSB-first data bits, and the Stop bit.
* **`uart_rx` (Receiver):** Samples incoming asynchronous serial data. It employs a multi-stage metastability shift register on the input. The FSM detects the Start bit edge, waits 1.5 bit periods to align with the center of the data eye, and systematically samples the subsequent 8 data bits.
* **`lab06` (Top-Level):** Integrates the TX and RX modules, routing the physical I/O to the FPGA's PMOD headers for external communication with the PIC microcontroller.

## Clock Domain & Baud Rate Calculations
The system operates on a 12 MHz system clock. The target transmission speed is the standard 115,200 Baud. 

To achieve this, the bit period is calculated as:
* 12,000,000 Hz / 115,200 Baud = 104.167 clock cycles per bit.

Both the transmitter and receiver FSMs utilize an integer counter tuned to `104` clock cycles to regulate the shifting and sampling of the data lines.

## Verification
The design includes a robust, self-checking VHDL testbench (`uart_tb.vhd`). 
* The testbench instantiates both the TX and RX modules in a closed-loop configuration.
* It injects a worst-case alternating bit pattern (`0xA5` / `10100101`) to rigorously test baud rate timing alignment.
* Automated VHDL `assert` statements continuously monitor the output, failing the simulation if the RX output does not perfectly match the appropriate TX input.

## Repository Structure
* `/src` - Synthesizable VHDL source code.
* `/tb` - Self-checking VHDL testbench.
* `/constraints` - XDC pin mapping for the 12 MHz clock and PMOD headers.
* `/scripts` - MATLAB GUI script for hardware-in-the-loop testing.
* `/docs` - Original project specifications.