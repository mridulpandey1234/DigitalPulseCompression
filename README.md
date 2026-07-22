# Radar Pulse Compression using FFT

## Overview

This project implements radar pulse compression using frequency-domain matched filtering.

The matched filtering operation is performed using the Fast Fourier Transform (FFT):

\[
y(n)=IFFT\left(FFT(x(n))\times FFT(h(n))\right)
\]

where

- x(n) = received radar signal
- h(n) = matched filter impulse response

This reduces the computational complexity from

O(N²)

to

O(N log N)

making FFT-based convolution significantly faster than direct convolution.

---

# Project Flow

```
Memory Files

↓

RAM_RX
RAM_MF

↓

FFT_RX
FFT_MF

↓

Complex Multiplier

↓

IFFT

↓

Output RAM

↓

Compressed Pulse
```

---

# Repository Structure

## RTL

### Memory
- ram_rx.v
- ram_mf.v
- output_ram.v

### FFT
- fft_rx_wrapper.v
- fft_mf_wrapper.v
- ifft_wrapper.v

### Arithmetic
- complex_multiplier.v

### Control
- controller.v

### Top Module
- top.v

<details>
<summary><strong>Testbench</strong></summary>

- fft_rx_tb.v
- fft_mf_tb.v
- ifft_tb.v
- top_tb.v

</details>

<details>
<summary><strong>Memory Files</strong></summary>

- rx_real.mem
- rx_imag.mem
- mf_real.mem
- mf_imag.mem

</details>

<details>
<summary><strong>IP</strong></summary>

- fft_rx.xci
- fft_mf.xci
- ifft.xci

</details>

---

# Vivado Workflow

## Step 1

Create a new RTL Project.

---

## Step 2

Add RTL Sources

```
ram_rx.v
ram_mf.v
complex_multiplier.v
controller.v
top.v
```

---

## Step 3

Create FFT IP

```
IP Catalog

↓

Fast Fourier Transform
```

Configuration

- 4096 Point
- Pipelined Streaming I/O
- Fixed Point
- 16-bit Input
- Natural Output Order
- Scaling Enabled

Generate Output Products for

- FFT_RX
- FFT_MF
- IFFT

---

## Step 4

Add Memory Files

```
rx_real.mem
rx_imag.mem

mf_real.mem
mf_imag.mem
```

---

## Step 5

Instantiate RAMs

Two memories are used

```
RAM_RX
```

Stores received signal.

```
RAM_MF
```

Stores matched filter coefficients.

Each memory outputs

```
Real (16-bit)

Imaginary (16-bit)
```

---

## Step 6

Pack Complex Samples

```
{Imaginary, Real}
```

becomes

```
31........16
Imaginary

15.........0
Real
```

and is streamed into the FFT.

---

## Step 7

FFT Configuration

Before sending samples

Send one AXI Configuration Word.

Wait until

```
config_tready
```

becomes HIGH.

Then stream the frame.

---

## Step 8

FFT Streaming

For each sample

```
Read RAM

↓

Pack Sample

↓

TVALID = 1

↓

Wait for TREADY

↓

Increment Address

↓

Repeat
```

Last sample

```
TLAST = 1
```

---

## Step 9

Complex Multiplication

```
FFT(RX)

×

FFT(MF)
```

Implemented using

```
(a+jb)(c+jd)
```

Result

```
Real

Imaginary
```

---

## Step 10

Inverse FFT

```
IFFT

↓

Compressed Pulse
```

---

## Step 11

Simulation

Behavioral Simulation

```
fft_rx_tb.v
```

verifies

- AXI Handshake
- FFT Configuration
- Input Streaming
- Output Streaming

---

## Step 12

Synthesis

```
Run Synthesis
```

Verify

- Timing
- DSP Usage
- BRAM Usage

---

## Step 13

Implementation

```
Run Implementation
```

Check

- Timing Report
- Utilization Report

---

# AXI4-Stream Handshake

```
Producer

↓

TVALID

↓

Consumer

↓

TREADY

↓

Transfer Occurs

↓

Next Sample
```

A transfer only occurs when

```
TVALID == 1

AND

TREADY == 1
```

---

# Current Progress

- Memory modules completed
- FFT IP configured
- AXI Stream interface implemented
- FFT simulation under verification
- Complex multiplier in progress
- IFFT integration pending

---

# Future Work

- FFT verification
- FFT(MF) integration
- Complex multiplier verification
- IFFT verification
- Pulse compression validation

---

# Tools Used

- Vivado 2025.2
- Verilog HDL
- Xilinx FFT IP

---

# References

1. Xilinx Fast Fourier Transform Product Guide (PG109)
2. Skolnik, *Radar Handbook*
3. Richards, *Fundamentals of Radar Signal Processing*
4. Digital Pulse Compression using FFT
