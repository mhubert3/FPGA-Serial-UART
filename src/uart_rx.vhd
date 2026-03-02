library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_rx is
    generic (
        CLKS_PER_BIT : integer := 104
    );
    port (
        clk_i     : in  std_logic;
        rx_i      : in  std_logic;
        data_o    : out std_logic_vector(7 downto 0);
        data_en_o : out std_logic
    );
end uart_rx;

architecture rtl of uart_rx is
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT, CLEANUP);
    signal state : state_type := IDLE;
    
    signal clk_count : integer range 0 to (CLKS_PER_BIT * 3)/2 := 0;
    signal bit_index : integer range 0 to 7 := 0;
    signal rx_data   : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Metastability registers
    signal rx_d1, rx_d2 : std_logic := '1';
begin
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            -- Double-flop the asynchronous RX input
            rx_d1 <= rx_i;
            rx_d2 <= rx_d1;
            
            case state is
                when IDLE =>
                    data_en_o <= '0';
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if rx_d2 = '0' then -- Start bit detected
                        state <= START_BIT;
                    end if;
                    
                when START_BIT =>
                    -- Wait 1.5 bit periods to sample middle of first data bit
                    if clk_count < (CLKS_PER_BIT + (CLKS_PER_BIT / 2)) - 1 then
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                        rx_data(0) <= rx_d2;
                        state      <= DATA_BITS;
                    end if;
                    
                when DATA_BITS =>
                    if clk_count < CLKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                        if bit_index < 6 then
                            bit_index <= bit_index + 1;
                            rx_data(bit_index + 1) <= rx_d2;
                        else
                            bit_index <= 0;
                            state     <= STOP_BIT;
                        end if;
                    end if;
                    
                when STOP_BIT =>
                    if clk_count < CLKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        data_o    <= rx_data;
                        data_en_o <= '1'; -- Pulse valid data flag
                        state     <= CLEANUP;
                    end if;
                    
                when CLEANUP =>
                    data_en_o <= '0';
                    state     <= IDLE;
                    
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end rtl;