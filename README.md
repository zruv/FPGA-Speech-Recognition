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

*   **`src/`**: VHDL source files.
    *   `MFCC_Accelerator.vhd`: The core hardware design.
    *   `Mel_Coeff_Pkg.vhd`: Auto-generated VHDL package with coefficients.
*   **`tb/`**: Testbench files.
    *   `MFCC_tb.vhd`: Simulation testbench.
*   **`scripts/`**: Automation and generation scripts.
    *   `generate_fpga_coefficients.m`: MATLAB script for coefficient generation.
    *   `run_simulation.sh`: Script to run GHDL simulation.
*   **`data/`**: Input data.
    *   `speech.wav`: Source audio file.
*   **`docs/`**: Documentation and images.

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
    chmod +x scripts/run_simulation.sh
    ./scripts/run_simulation.sh
    ```

2.  **View Waveforms:**
    After the simulation completes, a `wave.ghw` file is generated. Open it with GTKWave:
    ```bash
    gtkwave wave.ghw
    ```

3.  **(Optional) Regenerate Coefficients:**
    If you modify system parameters (e.g., FFT size, Frame Length), open `scripts/generate_fpga_coefficients.m` in MATLAB and run it. This will overwrite `src/Mel_Coeff_Pkg.vhd` with new constants.

## 📊 Status

*   **Implemented:** MATLAB Coefficient Generator, VHDL Package Generation, Windowing Stage, Testbench infrastructure.
*   **In Progress:** FFT Engine, Mel Filterbank Logic, DCT.

## 🤝 Contributing

Feel free to open issues or submit pull requests to help complete the MFCC pipeline stages!
