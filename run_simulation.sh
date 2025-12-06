#!/bin/bash

# Stop on error
set -e

echo "=============================================="
echo "   FPGA Speech Recognition - VHDL Simulation  "
echo "=============================================="

# Check for GHDL
if ! command -v ghdl &> /dev/null; then
    echo "Error: GHDL is not installed."
    echo "Please install it using: sudo apt update && sudo apt install ghdl gtkwave"
    exit 1
fi

# 1. Cleanup previous runs
echo "[1/4] Cleaning up..."
ghdl --clean
rm -f work-obj93.cf wave.ghw || true # Remove waveform file if it exists, ignore error if not

# 2. Analyze (Compile) files
# Order matters: Package -> Design -> Testbench
echo "[2/4] Analyzing VHDL files..."
ghdl -a --std=08 Mel_Coeff_Pkg.vhd
ghdl -a --std=08 MFCC_Accelerator.vhd
ghdl -a --std=08 MFCC_tb.vhd

# 3. Elaborate & Run
echo "[3/4] Running Simulation..."
ghdl -e --std=08 MFCC_tb
ghdl -r --std=08 MFCC_tb --wave=wave.ghw --stop-time=5ms

# 4. View Waveform
echo "=============================================="
echo "Simulation Complete! Waveform saved to 'wave.ghw'"
echo "To view the results, run:"
echo "  gtkwave wave.ghw"
echo "=============================================="
