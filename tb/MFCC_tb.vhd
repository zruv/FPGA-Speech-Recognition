library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Mel_Coeff_Pkg.ALL;

entity MFCC_tb is
-- Testbench has no ports
end MFCC_tb;

architecture Behavioral of MFCC_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component MFCC_Accelerator
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        start       : in  STD_LOGIC;
        sample_in   : in  SIGNED(15 downto 0);
        sample_valid: in  STD_LOGIC;
        
        mel_out     : out SIGNED(31 downto 0);
        mel_valid   : out STD_LOGIC;
        busy        : out STD_LOGIC
    );
    end component;

    -- Signal Definitions
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal start        : std_logic := '0';
    signal sample_in    : signed(15 downto 0) := (others => '0');
    signal sample_valid : std_logic := '0';
    
    signal mel_out      : signed(31 downto 0);
    signal mel_valid    : std_logic;
    signal busy         : std_logic;

    -- Clock Period
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the UUT
    uut: MFCC_Accelerator Port Map (
        clk          => clk,
        reset        => reset,
        start        => start,
        sample_in    => sample_in,
        sample_valid => sample_valid,
        mel_out      => mel_out,
        mel_valid    => mel_valid,
        busy         => busy
    );

    -- Clock Process
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus Process
    stim_proc: process
    begin
        -- Hold reset state
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for clk_period;

        -- Start Processing
        start <= '1';
        wait for clk_period;
        start <= '0';
        
        -- Feed Audio Data from Package (TEST_AUDIO_DATA)
        -- This mimics the data arriving from a buffer/ADC
        for i in 0 to 399 loop
            sample_in <= to_signed(TEST_AUDIO_DATA(i), 16);
            sample_valid <= '1';
            wait for clk_period; 
        end loop;
        
        sample_valid <= '0';

        -- Wait for processing to complete
        wait until busy = '0';
        wait for 100 ns;

        assert false report "Simulation Completed Successfully!" severity note;
        wait;
    end process;

end Behavioral;
