----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.06.2017 15:08:11
-- Design Name: 
-- Module Name: top - Behavioral
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

library work;
use work.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    Port (
        clk : in STD_LOGIC;
        -- switches
        sw : in STD_LOGIC_VECTOR( 15 downto 0 );
        -- buttons
        btnC : in STD_LOGIC;
        btnU : in STD_LOGIC;
        btnL : in STD_LOGIC;
        btnR : in STD_LOGIC;
        btnD : in STD_LOGIC;
        
        -- PMOD OLEDrgb
        CS, MOSI, SCK, D_C, RES, VCCEN, PMODEN : out STD_LOGIC;
        MISO : in STD_LOGIC;
        
        -- RS232
        RsRx : in STD_LOGIC;
        RsTx : out STD_LOGIC;       
        
        -- LEDS
        led : out STD_LOGIC_VECTOR( 15 downto 0 );
        --7 Segment
        seg : out STD_LOGIC_VECTOR( 6 downto 0 );
        dp : out STD_LOGIC;
        an : out STD_LOGIC_VECTOR( 3 downto 0 )
        );
end top;

architecture rtl of top is

    ---
    -- mapping of external periphery to signals
    ---
    
    -- switches
    alias segment_drive : STD_LOGIC_VECTOR(6 downto 0) is seg;
    --alias enable_7 : STD_LOGIC is sw(1);
    --alias drive_high : std_logic is sw(0);
    
    -- buttons
    alias reset_external : STD_LOGIC is btnC;
    
    -- LEDs
    alias led_blinky : STD_LOGIC is led(0);
    alias led_blinky2 : STD_LOGIC is led(1);
    
    ----------------------------------------------------------
    -- SIGNAL DECLARATIONS
    ----------------------------------------------------------
    signal number1, number2, number3, number4 : std_logic_vector(7 downto 0);
    signal dp1, dp2, dp3, dp4 : STD_LOGIC;
    signal busy : STD_LOGIC;
    signal data_rx : STD_LOGIC_VECTOR(7 downto 0);
    
    -- global reset signal
    signal reset: std_logic := '1';
    
    -- spi slave signals
    signal data_tx_slave0, data_rx_slave0 : std_logic_vector(7 downto 0) := (others => '0');
    signal data_tx_slave1, data_rx_slave1 : std_logic_vector(7 downto 0) := (others => '0');
    signal busy_slave0 : std_logic := '0';
    signal busy_slave1 : std_logic := '0';
    signal rx_valid_slave0 : std_logic := '0';
    signal rx_valid_slave1 : std_logic := '0';
    -- spi intermediate signals
    signal sck_d : std_logic := '0';
    signal cs_d : std_logic := '0';
    signal mosi_d : std_logic := '0';
    signal miso_d : std_logic := '0';
    

begin
    
    ----------------------------------------------------------
    -- COMPONENT INSTATIONATIONS
    ----------------------------------------------------------
    blinky : entity clk_div
    generic map (
        F_clk_in => 100000000,
        F_clk_out => 1
    )
    port map (
        clk => clk,
        reset => reset,
        clk_out => led_blinky
    );
    
    blinky2 : entity clk_div_advanced
    generic map (
        F_clk => 100000000,
        F_cycle =>       1,
        N_counter_size => 32
    )
    port map (
        clk => clk,
        q_50 => led_blinky2
    );
    
    seven_segment : entity seven_seg_4
    generic map(
        F_cycle => 60*4
    )
    port map (
        clk => clk,
        enable => '1',
        
        number1 => number1,
        number2 => number2,
        number3 => number3,
        number4 => number4,
        
        dp1 => dp1,
        dp2 => dp2,
        dp3 => dp3,
        dp4 => dp4,
        
        drive_high => '0',
        segment_drive => segment_drive,
        dp_drive => dp,
        
        an_drive => an
    );
    
    spi_PMOD_oled : entity spi_master_phy
    GENERIC MAP(
        N_slaves => 1,
        F_clk_in => 100,
        F_clk_out => 1
    )
    PORT MAP(
        clk  => clk,
        kickout  => btnR,
        data_tx  => sw(15 downto 8),
        slave_addr  => (OTHERS => '0'),
        data_rx  => open,
        rx_valid  => open,
        busy  => open,
        sck  => sck_d,
        cs(0)  => CS_d,
        mosi  => MOSI_d,
        miso =>  '1'
    );
    
    spi_slave_DUT0 : entity work.spi_slave_phy(rtl)
    PORT MAP(
        clk  => clk,
        data_tx  => data_tx_slave0,
        data_rx  => data_rx_slave0,
        rx_valid  => rx_valid_slave0,
        sck  => sck_d,
        cs  => CS_d,
        mosi  => mosi_d,
        miso =>  miso_d
    );
    
    rs232_serial : entity work.serial
    generic map ( F_baud => 256000, N_data_bits => 8, pol_idle => '1', N_stop_bits => 1 )
    port map (
        clk => clk, reset => reset, data_tx => sw(15 downto 8), data_rx => data_rx, kickout => btnU, busy => busy, rx => RsRx, tx => RsTx, rx_valid => led(6)
    );
    
    ----------------------------------------------------------
    -- BEHAVIOUR CODE
    ----------------------------------------------------------
    
    D_C <= sw(3);
    VCCEN <= sw(4);
    PMODEN <= sw(5);
    RES <= btnL;
    
    
    number1(7 downto 4) <= "0000";
    number1(3 downto 0) <= sw(15 downto 12);
    
    number2(7 downto 4) <= "0000";
    number2(3 downto 0) <= sw(11 downto 8);
    
    number3(7 downto 4) <= "0000";
    number3(3 downto 0) <= data_rx(7 downto 4);
    
    number4(7 downto 4) <= "0000";
    number4(3 downto 0) <= data_rx(3 downto 0);
    
    led(15 downto 8) <= data_rx;
    led(7) <= busy;
    
    dp1 <= '0';
    dp2 <= '1';
    dp3 <= '0';
    dp4 <= '0';
    
    reset_generator : process(clk, reset)
        constant por_cycles : integer := 123;
        variable start_cycle_counter : integer range 0 to por_cycles := 0;
    begin
        if reset_external = '1' then
            reset <= '1';
        elsif rising_edge(clk) then
            -- power on reset generator
            if start_cycle_counter < por_cycles then
                reset <= '1';
                start_cycle_counter := start_cycle_counter + 1;
            else 
                reset <= '0'; 
            end if;
        end if;
    end process;    
    
    sck <= sck_d;
    mosi <= mosi_d;
    cs <= cs_d;
    
end rtl;
