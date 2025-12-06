library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Mel_Coeff_Pkg.ALL;

entity MFCC_Accelerator is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        start       : in  STD_LOGIC;
        sample_in   : in  SIGNED(15 downto 0);
        sample_valid: in  STD_LOGIC;
        
        mel_out     : out SIGNED(31 downto 0); -- Higher bit width for accumulation result
        mel_valid   : out STD_LOGIC;
        busy        : out STD_LOGIC
    );
end MFCC_Accelerator;

architecture Behavioral of MFCC_Accelerator is

    -- State Machine
    type state_type is (IDLE, WINDOWING, FFT_Processing, MEL_FILTERING, DONE);
    signal current_state : state_type := IDLE;
    
    -- Internal Signals
    signal frame_counter : integer range 0 to 399 := 0;
    signal windowed_data : signed(31 downto 0); -- 16bit data * 16bit coeff = 32bit
    
    -- Simulation Placeholders
    signal fft_dummy_out : signed(31 downto 0); 
    
begin

    -- =========================================================================
    -- Main Processing Pipeline
    -- =========================================================================
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_state <= IDLE;
                frame_counter <= 0;
                busy <= '0';
                mel_valid <= '0';
                mel_out <= (others => '0');
            else
                case current_state is
                    
                    -- 1. IDLE: Wait for start signal
                    when IDLE =>
                        busy <= '0';
                        mel_valid <= '0';
                        if start = '1' then
                            current_state <= WINDOWING;
                            frame_counter <= 0;
                            busy <= '1';
                        end if;
                        
                    -- 2. WINDOWING: Multiply Input by Hamming Window
                    -- Note: In a real pipeline, this would buffer data. 
                    -- Here we simulate processing one sample per clock as it arrives (or from buffer)
                    when WINDOWING =>
                        if sample_valid = '1' then
                            -- Perform Fixed-Point Multiplication
                            -- Result is scaled by C_SCALE_FACTOR (4096)
                            windowed_data <= sample_in * to_signed(HAMMING_WINDOW(frame_counter), 16);
                            
                            if frame_counter < 399 then
                                frame_counter <= frame_counter + 1;
                            else
                                current_state <= FFT_Processing;
                                frame_counter <= 0;
                            end if;
                        end if;
                        
                    -- 3. FFT PROCESSING (Placeholder)
                    -- Real implementation requires complex FFT IP Core or large behavioral model.
                    -- We skip this for simulation and assume "Energy" is just the windowed data magnitude.
                    when FFT_Processing =>
                        -- Simulate some delay or processing
                        fft_dummy_out <= abs(windowed_data); -- Simplified "Energy"
                        current_state <= MEL_FILTERING;
                        
                    -- 4. MEL FILTERING
                    -- Multiply "FFT Energy" by Mel Filterbank Coefficients
                    -- Using Loop for simulation clarity (Hardware would use parallel MACs)
                    when MEL_FILTERING =>
                        -- Simple pass-through for simulation demo
                        -- Real hardware iterates through MEL_FILTERS(m, k) * fft_bin(k)
                        mel_out <= fft_dummy_out; 
                        mel_valid <= '1';
                        
                        current_state <= IDLE; -- Go back to IDLE for next frame
                        
                    when others =>
                        current_state <= IDLE;
                        
                end case;
            end if;
        end if;
    end process;

end Behavioral;
