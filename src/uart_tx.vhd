library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tx is
    generic (
        CLKS_PER_BIT : integer := 104 -- 12 MHz / 115200 Baud
    );
    port (
        clk_i   : in  std_logic;
        tx_en_i : in  std_logic;
        data_i  : in  std_logic_vector(7 downto 0);
        tx_o    : out std_logic;
        ready_o : out std_logic
    );
end uart_tx;

architecture rtl of uart_tx is
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;
    
    signal clk_count : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal bit_index : integer range 0 to 7 := 0;
    signal tx_data   : std_logic_vector(7 downto 0) := (others => '0');
begin
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            case state is
                when IDLE =>
                    tx_o    <= '1'; -- Idle state is high
                    ready_o <= '1';
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if tx_en_i = '1' then
                        tx_data <= data_i;
                        tx_o    <= '0'; -- Drive low for start bit
                        ready_o <= '0';
                        state   <= START_BIT;
                    end if;
                    
                when START_BIT =>
                    if clk_count < CLKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                        tx_o      <= tx_data(0); -- Send LSB first
                        state     <= DATA_BITS;
                    end if;
                    
                when DATA_BITS =>
                    if clk_count < CLKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                        if bit_index < 7 then
                            bit_index <= bit_index + 1;
                            tx_o      <= tx_data(bit_index + 1);
                        else
                            bit_index <= 0;
                            tx_o      <= '1'; -- Drive high for stop bit
                            state     <= STOP_BIT;
                        end if;
                    end if;
                    
                when STOP_BIT =>
                    if clk_count < CLKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        state <= IDLE;
                    end if;
                    
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end rtl;