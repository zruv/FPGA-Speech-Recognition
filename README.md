# FPGA Speech Recognition - MFCC Accelerator

This project implements a hardware accelerator for **Mel-Frequency Cepstral Coefficients (MFCC)** feature extraction, designed for FPGA implementation. It utilizes a hybrid software/hardware workflow where complex coefficients and test data are pre-calculated in MATLAB and exported as fixed-point VHDL constants for efficient hardware processing.

## 🚀 Overview

The system is designed to process audio input (16kHz) through a standard MFCC pipeline:
`Audio Input -> Buffer -> Pre-emphasis -> Windowing -> FFT -> Mel Filter -> DCT -> Output`

### Key Features
*   **Hybrid Workflow:** Leverages MATLAB for complex math (generating filterbanks/windows) and VHDL for real-time hardware execution.
*   **Fixed-Point Optimization:** Converts floating-point coefficients to **Q4.12 Fixed-Point** format to minimize FPGA resource usage.
*   **Self-Contained Simulation:** Includes a generated `TEST_AUDIO_DATA` array within the VHDL package, allowing for functional verification without external hardware.
*   **GHDL Automation:** Provides a shell script to automate compilation and simulation.

## 📂 File Structure

*   **`MFCC_Accelerator.vhd`**: The core VHDL hardware design. Currently implements the **Windowing** stage with placeholders for FFT and Mel Filtering.
*   **`Mel_Coeff_Pkg.vhd`**: Auto-generated VHDL package containing:
    *   `MEL_FILTERS`: Fixed-point Mel Filterbank coefficients.
    *   `HAMMING_WINDOW`: Hamming window coefficients.
    *   `TEST_AUDIO_DATA`: Sample audio data for simulation.
*   **`MFCC_tb.vhd`**: VHDL Testbench that verifies the accelerator using the generated test data.
*   **`generate_fpga_coefficients.m`**: MATLAB script that:
    1.  Reads audio (`speech.wav`).
    2.  Calculates Mel filters and Hamming window.
    3.  Quantizes values to fixed-point.
    4.  Generates the `Mel_Coeff_Pkg.vhd` file.
*   **`run_simulation.sh`**: Bash script to clean, analyze, and run the GHDL simulation.
*   **`speech.wav`**: Source audio file ("Hello, Welcome to the matrix") used for generating test data.

## 🛠️ Prerequisites

To simulate this project, you need:
*   **GHDL**: An open-source VHDL simulator.
*   **GTKWave**: A waveform viewer.
*   *(Optional)* **MATLAB**: Required only if you wish to regenerate coefficients or test data.

**Installation (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install ghdl gtkwave
```

## ▶️ How to Run

1.  **Run Simulation:**
    Execute the provided script to compile the VHDL files and run the simulation.
    ```bash
    chmod +x run_simulation.sh
    ./run_simulation.sh
    ```

2.  **View Waveforms:**
    After the simulation completes, a `wave.ghw` file is generated. Open it with GTKWave:
    ```bash
    gtkwave wave.ghw
    ```

3.  **(Optional) Regenerate Coefficients:**
    If you modify system parameters (e.g., FFT size, Frame Length), open `generate_fpga_coefficients.m` in MATLAB and run it. This will overwrite `Mel_Coeff_Pkg.vhd` with new constants.

## 📊 Status

*   **Implemented:** MATLAB Coefficient Generator, VHDL Package Generation, Windowing Stage, Testbench infrastructure.
*   **In Progress:** FFT Engine, Mel Filterbank Logic, DCT.

## 🤝 Contributing

Feel free to open issues or submit pull requests to help complete the MFCC pipeline stages!
