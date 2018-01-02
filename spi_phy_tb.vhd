----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.06.2017 19:49:13
-- Design Name: 
-- Module Name: spi_phy_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_phy_tb is
--  Port ( );
end spi_phy_tb;

ARCHITECTURE Behavioral OF spi_phy_tb IS
    
    CONSTANT N_slaves_tb : natural := 2;
    
    SIGNAL clk_in : STD_LOGIC := '0';
    SIGNAL reset : STD_LOGIC := '0';
    SIGNAL kickout : STD_LOGIC := '0'; -- Lathes dataput signals and begins SPI transmit, active high
    SIGNAL data_tx_master : STD_LOGIC_VECTOR (7 downto 0); -- here we want MSB left like it is in usual case with data
    SIGNAL slave_addr : STD_LOGIC_VECTOR ( N_slaves_tb - 1 downto 0 ) := (OTHERS => '0');
    SIGNAL data_rx_master : STD_LOGIC_VECTOR (7 downto 0);
    SIGNAL rx_valid_master : STD_LOGIC;
    SIGNAL busy_master : STD_LOGIC;
    SIGNAL sck : STD_LOGIC;
    SIGNAL cs : STD_LOGIC_VECTOR (N_slaves_tb-1 downto 0);
    SIGNAL mosi : STD_LOGIC;
    SIGNAL miso : STD_LOGIC;
    
    -- SLAVE SIGNALS
    signal data_tx_slave0, data_rx_slave0 : std_logic_vector(7 downto 0) := (others => '0');
    signal data_tx_slave1, data_rx_slave1 : std_logic_vector(7 downto 0) := (others => '0');
    signal busy_slave0 : std_logic := '0';
    signal busy_slave1 : std_logic := '0';
    signal rx_valid_slave0 : std_logic := '0';
    signal rx_valid_slave1 : std_logic := '0';

    
BEGIN

spi_master_DUT : entity work.spi_master_phy
GENERIC MAP(
    N_slaves => N_slaves_tb,
    F_clk_in => 100,
    F_clk_out => 10
)
PORT MAP(
    clk  => clk_in,
    kickout  => kickout,
    data_tx  => data_tx_master,
    slave_addr  => slave_addr,
    data_rx  => data_rx_master,
    rx_valid  => rx_valid_master,
    busy  => busy_master,
    sck  => sck,
    cs  => cs,
    mosi  => mosi,
    miso =>  miso
);

spi_slave_DUT0 : entity work.spi_slave_phy(rtl)
PORT MAP(
    clk  => clk_in,
    data_tx  => data_tx_slave0,
    data_rx  => data_rx_slave0,
    rx_valid  => rx_valid_slave0,
    sck  => sck,
    cs  => cs(0),
    mosi  => mosi,
    miso =>  miso
);

spi_slave_DUT1 : entity work.spi_slave_phy(rtl)
PORT MAP(
    clk  => clk_in,
    data_tx  => data_tx_slave1,
    data_rx  => data_rx_slave1,
    rx_valid  => rx_valid_slave1,
    sck  => sck,
    cs  => cs(1),
    mosi  => mosi,
    miso =>  miso
);

clk_generator : PROCESS
BEGIN
    clk_in <= '0';
    WAIT FOR 5 ns;
    clk_in <= '1';
    WAIT FOR 5 ns;
END PROCESS;

stimulus_generator : PROCESS
BEGIN
    reset <= '0';
    data_tx_master <= x"55";
    data_tx_slave0 <= x"80";
    data_tx_slave1 <= x"40";
    kickout <= '0';
    slave_addr <= "00";
    --miso <= '0';
    WAIT FOR 20 ns;
    reset <= '1';
    WAIT FOR 20 ns;
    reset <= '0';
    WAIT FOR 20 ns;
    kickout <= '1';
    WAIT FOR 20 ns;
    kickout <= '0';
    slave_addr <= "01";
    WAIT FOR 20 ns;
    data_tx_master <= x"55";
    WAIT FOR 2000 ns;
    kickout <= '1';
    WAIT FOR 100 ns;
    --slave_addr <= "10";
    WAIT FOR 1000 ns;
    kickout <= '0';

    -- endless wait...
    WAIT;
END PROCESS;

--miso <= mosi;

END Behavioral;
