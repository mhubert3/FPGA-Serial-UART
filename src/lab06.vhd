library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity lab06 is
	port(
		clk: in    std_logic;
		rx:  in    std_logic;
		tx:  out   std_logic;
		srx: out   std_logic;-- PIC pin 9 RS-232 (FPGA TX -> PIC RX)
		stx: in    std_logic;-- PIC pin 10 RS-232 (PIC TX -> FPGA RX)
		nss: out   std_logic;-- PIC pin 11 SPI
		sck: out   std_logic;-- PIC pin 12 SPI
		sdi: out   std_logic;-- PIC pin 4 SPI
		sdo: in    std_logic;-- PIC pin 3 SPI
		scl: inout std_logic;-- PIC pin 6 I2C
		sda: inout std_logic -- PIC pin 5 I2C
	);
end lab06;

architecture arch of lab06 is
    component lab06_gui
        port(
            clk_i:  in  std_logic;
            rx_i:   in  std_logic;
            tx_o:   out std_logic;
            data_o: out std_logic_vector(7 downto 0);
            data_i: in  std_logic_vector(7 downto 0);
            trig_o: out std_logic
        );
    end component;

    component uart_tx
        port (
            clk_i   : in  std_logic;
            tx_en_i : in  std_logic;
            data_i  : in  std_logic_vector(7 downto 0);
            tx_o    : out std_logic;
            ready_o : out std_logic
        );
    end component;

    component uart_rx
        port (
            clk_i     : in  std_logic;
            rx_i      : in  std_logic;
            data_o    : out std_logic_vector(7 downto 0);
            data_en_o : out std_logic
        );
    end component;

    signal gui_data_out : std_logic_vector(7 downto 0);
    signal gui_data_in  : std_logic_vector(7 downto 0);
    signal gui_trig     : std_logic;
    
    signal rx_valid     : std_logic;
begin
    -- MATLAB GUI Interface
    gui: lab06_gui port map(
        clk_i  => clk,
        rx_i   => rx,
        tx_o   => tx,
        data_o => gui_data_out,
        data_i => gui_data_in,
        trig_o => gui_trig
    );

    -- FPGA to PIC Transmitter
    pic_tx: uart_tx port map(
        clk_i   => clk,
        tx_en_i => gui_trig,
        data_i  => gui_data_out,
        tx_o    => srx,      -- Drive PIC RX pin
        ready_o => open
    );

    -- PIC to FPGA Receiver
    pic_rx: uart_rx port map(
        clk_i     => clk,
        rx_i      => stx,    -- Receive from PIC TX pin
        data_o    => gui_data_in,
        data_en_o => rx_valid
    );

    -- Unused interfaces driven to idle states
    nss <= '1';
    sck <= '0';
    sdi <= '0';
    scl <= 'Z';
    sda <= 'Z';
end arch;