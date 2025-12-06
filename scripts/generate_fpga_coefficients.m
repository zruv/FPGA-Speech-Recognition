% ==============================================================================
% FPGA Speech Recognition - Coefficient Generator & Fixed-Point Simulator
% ==============================================================================
% 1. Loads a WAV audio file or generates a test audio signal.
% 2. Calculates MFCC features (Pre-emphasis -> Window -> FFT -> Mel -> DCT).
% 3. Quantizes the Mel-Filterbank Matrix for the FPGA (Fixed-Point).
% 4. Generates VHDL constant arrays for the hardware implementation.
% ==============================================================================

clear; clc; close all;

%% 1. System Parameters
Fs = 16000;             % Sampling Frequency (16 kHz)
frame_len_ms = 25;      % Frame length (25ms)
frame_step_ms = 10;     % Frame overlap step (10ms)
num_mel_filters = 20;   % Number of Mel filterbank channels
num_fft = 512;          % FFT Size (Power of 2 for efficient FPGA implementation)
pre_emph_coeff = 0.97;  % Pre-emphasis factor

% --- Fixed-Point Parameters for FPGA ---
% We use Q15 format (1 sign bit, 15 fractional bits) roughly,
% but here we simply scale by 2^12 to keep values within 16-bit integer range.
FPGA_SCALE_FACTOR = 2^12;

%% 2. Load Real Audio Signal (Test Bench Input) or Generate Synthetic
% Specify the path to your WAV file.
% IMPORTANT: Change this path to your actual audio file.
audio_file_path = '../data/speech.wav'; % <--- CHANGE THIS TO YOUR WAV FILE PATH!

% --- Choose one of the following two options ---

% OPTION 1: Load a WAV file
if exist(audio_file_path, 'file')
    fprintf('Loading audio from %s...\n', audio_file_path);
    [audio_sig, Fs_in] = audioread(audio_file_path);

    % Ensure the audio is a single channel (mono) if it's stereo
    if size(audio_sig, 2) > 1
        audio_sig = mean(audio_sig, 2); % Convert to mono by averaging channels
    end

    % Resample if the WAV file's sampling rate is different from our target Fs
    if Fs_in ~= Fs
        fprintf('Resampling audio from %d Hz to %d Hz...\n', Fs_in, Fs);
        audio_sig = resample(audio_sig, Fs, Fs_in);
    end
else
    % OPTION 2: Generate Synthetic Audio Signal if WAV file not found
    warning('Audio file "%s" not found. Generating synthetic test signal instead.', audio_file_path);
    t = 0:1/Fs:0.5; % 0.5 seconds of audio
    audio_sig = 0.5 * sin(2*pi*1000*t) + 0.3 * sin(2*pi*3000*t);
end

% Normalize (important for both loaded and synthetic signals)
audio_sig = audio_sig / max(abs(audio_sig));


%% 3. Feature Extraction Simulation (Floating Point - The "Golden" Reference)

% A. Pre-emphasis
sig_pre = filter([1 -pre_emph_coeff], 1, audio_sig);

% B. Framing & Windowing
% Note: For this script, we calculate frame parameters but don't perform
% full frame-by-frame MFCC calculation as the primary goal is filterbank coefficients.
frame_len = round(frame_len_ms * 1e-3 * Fs);
frame_step = round(frame_step_ms * 1e-3 * Fs);
num_frames = floor((length(sig_pre) - frame_len) / frame_step) + 1;

% Generate Hamming Window
% Equation: w(n) = 0.54 - 0.46 * cos(2*pi*n/(N-1))
n_idx = 0:(frame_len-1);
hamming_window = 0.54 - 0.46 * cos(2*pi*n_idx/(frame_len-1));

% C. Create Mel Filterbank Matrix
% This matrix maps FFT bins (Linear Hz) to Mel bins (Perceptual Pitch)
f_min = 0; f_max = Fs/2;
mel_min = 1125 * log(1 + f_min/700);
mel_max = 1125 * log(1 + f_max/700);
mel_points = linspace(mel_min, mel_max, num_mel_filters + 2);
hz_points = 700 * (exp(mel_points/1125) - 1);
bin_points = floor((num_fft + 1) * hz_points / Fs);

mel_filterbank = zeros(num_mel_filters, floor(num_fft/2 + 1));

for m = 2:(num_mel_filters + 1)
    left = bin_points(m-1);
    center = bin_points(m);
    right = bin_points(m+1);

    % Create ascending slope
    for k = left:center
        if (bin_points(m) - bin_points(m-1)) ~= 0
            mel_filterbank(m-1, k+1) = (k - bin_points(m-1)) / (bin_points(m) - bin_points(m-1));
        end
    end
    % Create descending slope
    for k = center:right
        if (bin_points(m+1) - bin_points(m)) ~= 0
            mel_filterbank(m-1, k+1) = (bin_points(m+1) - k) / (bin_points(m+1) - bin_points(m));
        end
    end
end

%% 4. Fixed-Point Conversion (The "Bridge" to VHDL)
% The FPGA cannot handle floating point matrices easily.
% We scale them up and round to integers.

mel_filterbank_fixed = round(mel_filterbank * FPGA_SCALE_FACTOR);
hamming_window_fixed = round(hamming_window * FPGA_SCALE_FACTOR);

% Check for overflow (assuming 16-bit signed integers in FPGA: -32768 to 32767)
if max(max(mel_filterbank_fixed)) > 32767 || min(min(mel_filterbank_fixed)) < -32768
    warning('Mel Coefficients exceed 16-bit signed integer range! Reduce FPGA_SCALE_FACTOR.');
end

if max(hamming_window_fixed) > 32767 || min(hamming_window_fixed) < -32768
    warning('Window Coefficients exceed 16-bit signed integer range! Reduce FPGA_SCALE_FACTOR.');
end

%% 5. VHDL Code Generation
% This section prints text to the Command Window that you can copy-paste into your VHDL file.

fprintf('\n------------------------------------------------------------\n');
fprintf('COPY THE FOLLOWING INTO YOUR VHDL PACKAGE / ROM FILE:\n');
fprintf('------------------------------------------------------------\n\n');

fprintf('-- FPGA Fixed-Point Parameters\n');
fprintf('constant C_FS : integer := %d;\n', Fs);
fprintf('constant C_FRAME_LEN_MS : integer := %d;\n', frame_len_ms);
fprintf('constant C_FRAME_STEP_MS : integer := %d;\n', frame_step_ms);
fprintf('constant C_PRE_EMPH_COEFF : integer := %d; -- Scaled by %d\n', round(pre_emph_coeff * FPGA_SCALE_FACTOR), FPGA_SCALE_FACTOR);
fprintf('constant C_SCALE_FACTOR : integer := %d;\n', FPGA_SCALE_FACTOR);
fprintf('constant C_NUM_MEL_FILTERS  : integer := %d;\n', num_mel_filters);
fprintf('constant C_FFT_BIN_SIZE : integer := %d;\n\n', floor(num_fft/2 + 1));

fprintf('-- Hamming Window Coefficients\n');
fprintf('-- Format: Fixed-Point Q%d.%d (Scaled by %d)\n', ...
    16 - round(log2(FPGA_SCALE_FACTOR)), round(log2(FPGA_SCALE_FACTOR)), FPGA_SCALE_FACTOR);
fprintf('type window_type is array (0 to %d) of signed(15 downto 0);\n', frame_len-1);
fprintf('constant HAMMING_WINDOW : window_type := (\n  ');

for i = 1:length(hamming_window_fixed)
    if i == length(hamming_window_fixed)
        fprintf('%d', hamming_window_fixed(i));
    else
        fprintf('%d, ', hamming_window_fixed(i));
        if mod(i, 12) == 0
             fprintf('\n  ');
        end
    end
end
fprintf(');\n\n');

fprintf('-- Mel Filterbank Coefficients (Flattened or 2D Array)\n');
fprintf('-- Format: Fixed-Point Q%d.%d (Scaled by %d). Values are signed 16-bit integers.\n', ...
    16 - round(log2(FPGA_SCALE_FACTOR)), round(log2(FPGA_SCALE_FACTOR)), FPGA_SCALE_FACTOR);
fprintf('type mel_matrix_type is array (0 to %d, 0 to %d) of signed(15 downto 0);\n', num_mel_filters-1, floor(num_fft/2));
fprintf('constant MEL_FILTERS : mel_matrix_type := (\n');

for i = 1:num_mel_filters
    fprintf('  (');
    row_data = mel_filterbank_fixed(i, :);
    for j = 1:length(row_data)
        if j == length(row_data)
            fprintf('%d', row_data(j));
        else
            fprintf('%d, ', row_data(j));
        end
    end

    if i == num_mel_filters
        fprintf(')\n'); % End of array
    else
        fprintf('),\n');
    end
end
fprintf(');\n');

fprintf('\n-- Test Input Signal (First Frame for Simulation)\n');
fprintf('-- Paste this into the "TEST_AUDIO_DATA" constant in the package.\n');
fprintf('type audio_array_type is array (0 to %d) of signed(15 downto 0);\n', frame_len-1);
fprintf('constant TEST_AUDIO_DATA : audio_array_type := (\n  ');

% Scale audio to Fixed-Point
audio_fixed = round(audio_sig(1:frame_len) * FPGA_SCALE_FACTOR);

for i = 1:length(audio_fixed)
    if i == length(audio_fixed)
        fprintf('%d', audio_fixed(i));
    else
        fprintf('%d, ', audio_fixed(i));
        if mod(i, 12) == 0
             fprintf('\n  ');
        end
    end
end
fprintf(');\n');

fprintf('\n------------------------------------------------------------\n');
fprintf('Visualization of Coefficients (Check Figure 1)\n');
fprintf('------------------------------------------------------------\n');

%% 6. Visualization
figure;
subplot(3,1,1);
plot(audio_sig); % Plotting full signal for general overview
title('Input Audio Signal');
xlabel('Sample Index'); ylabel('Amplitude');

subplot(3,1,2);
plot(hamming_window);
title('Hamming Window Function');
xlabel('Sample Index (n)'); ylabel('Amplitude');
grid on;

subplot(3,1,3);
imagesc(mel_filterbank);
axis xy;
title('Mel Filterbank Matrix (Floating Point)');
ylabel('Mel Filter Index'); xlabel('FFT Bin Index');
colorbar;
