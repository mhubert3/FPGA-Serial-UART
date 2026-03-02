library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tb is
-- Testbenches don't have ports
end uart_tb;

architecture sim of uart_tb is

    -- Component Declarations
    component uart_tx
        generic ( CLKS_PER_BIT : integer := 104 );
        port (
            clk_i   : in  std_logic;
            tx_en_i : in  std_logic;
            data_i  : in  std_logic_vector(7 downto 0);
            tx_o    : out std_logic;
            ready_o : out std_logic
        );
    end component;

    component uart_rx
        generic ( CLKS_PER_BIT : integer := 104 );
        port (
            clk_i     : in  std_logic;
            rx_i      : in  std_logic;
            data_o    : out std_logic_vector(7 downto 0);
            data_en_o : out std_logic
        );
    end component;

    -- Constants
    constant CLK_PERIOD : time := 83.33 ns; -- ~12 MHz Clock
    constant TEST_DATA  : std_logic_vector(7 downto 0) := x"A5"; -- 10100101

    -- Signals
    signal clk        : std_logic := '0';
    signal tx_en      : std_logic := '0';
    signal tx_data_in : std_logic_vector(7 downto 0) := (others => '0');
    signal serial_out : std_logic;
    signal tx_ready   : std_logic;

    signal rx_data_out : std_logic_vector(7 downto 0);
    signal rx_valid    : std_logic;

begin

    -- Instantiate the Transmitter
    UUT_TX: uart_tx
        generic map ( CLKS_PER_BIT => 104 )
        port map (
            clk_i   => clk,
            tx_en_i => tx_en,
            data_i  => tx_data_in,
            tx_o    => serial_out,
            ready_o => tx_ready
        );

    -- Instantiate the Receiver, looping serial_out into rx_i
    UUT_RX: uart_rx
        generic map ( CLKS_PER_BIT => 104 )
        port map (
            clk_i     => clk,
            rx_i      => serial_out,
            data_o    => rx_data_out,
            data_en_o => rx_valid
        );

    -- Clock Generation Process
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus and Verification Process
    stimulus: process
    begin
        -- Initialize and wait for a few clock cycles
        wait for CLK_PERIOD * 10;
        
        -- Provide test data and pulse the enable flag
        tx_data_in <= TEST_DATA;
        tx_en <= '1';
        wait for CLK_PERIOD;
        tx_en <= '0'; -- Clear the enable flag so we only send once
        
        -- Wait for the transaction to complete
        -- It takes 1 start bit + 8 data bits + 1 stop bit = 10 bits
        -- Each bit is 104 clocks so wait a safe margin beyond that
        wait for CLK_PERIOD * 104 * 12; 
        
        -- Check that the RX module flagged valid data

        -- In a fully synchronous testbench, we might wait ON the rx_valid signal,
        -- but waiting for a fixed time allows us to check for timeouts
        
        -- Assertion
        -- Self-Checking Logic
        assert (rx_data_out = TEST_DATA) 
            report "TEST FAILED: Receiver output (" & integer'image(to_integer(unsigned(rx_data_out))) & 
                   ") does not match Transmitter input (" & integer'image(to_integer(unsigned(TEST_DATA))) & ")."
            severity failure;
            
        -- If the assertion passes without failure, then
        report "TEST PASSED: UART Loopback successful. Received 0xA5 correctly." severity note;
        
        -- Stop simulation
        wait;
    end process;

end sim;