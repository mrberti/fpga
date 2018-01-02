----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.07.2017 17:58:20
-- Design Name: 
-- Module Name: serial_tb - Behavioral
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

entity serial_tb is
--  Port ( );
end serial_tb;

architecture Behavioral of serial_tb is

    component serial
    generic (
        F_clk_in  : integer := 100000000; 
        F_baud    : integer :=    256000;
        pol_idle  : std_logic := '1'; -- state of the idle pin
        N_data_bits : integer range 1 to 9 := 8;
        N_stop_bits : integer range 0 to 2 := 1;
        N_parity : integer := 0 -- no implementation yet 
    );
    Port ( 
        clk : in STD_LOGIC;
        reset : in std_logic;
        
        data_tx : in std_logic_vector(N_data_bits-1 downto 0);
        data_rx : out std_logic_vector(N_data_bits-1 downto 0);
        
        kickout : in std_logic;
        busy : out std_logic;
        rx_valid : out std_logic;
        
        -- These flags are indicating a failure during transmission
        -- the transceiver needs to be reset then
        tx_fail : out std_logic;
        rx_fail : out std_logic;
        
        -- physical pins
        rx : in std_logic; -- async receive pin
        tx : out std_logic
        );
    end component;
    
    constant N_data_bits : integer := 8;
    
    signal clk, reset, kickout, busy, rx, tx : std_logic := '0';
    signal data_tx, data_rx : std_logic_vector(N_data_bits-1 downto 0) := (OTHERS => '0');

begin

    serial_DUT : serial
    generic map ( F_baud => 5000000, N_data_bits => N_data_bits, pol_idle => '0', N_stop_bits => 2 )
    port map (
        clk => clk, reset => reset, data_tx => data_tx, data_rx => data_rx, kickout => kickout, busy => busy, rx => rx, tx => tx
    );

    clk <= not clk after 5 ns;
    
    rx <= tx;
    
    stim : process
    begin   
        reset <= '0';
        data_tx <= x"55";
        kickout <= '0';
        --rx <= '0';
        WAIT FOR 20 ns;
        reset <= '1';
        WAIT FOR 20 ns;
        reset <= '0';
        WAIT FOR 50 ns;
        kickout <= '1';
        WAIT FOR 20 ns;
        kickout <= '0';
        WAIT FOR 20 ns;
        data_tx <= x"aa";
        WAIT FOR 200 ns;
        kickout <= '1';
        WAIT FOR 40 ns;
        kickout <= '0';
        WAIT FOR 2234 ns;
        kickout <= '1';
        
        wait;
    end process;

end Behavioral;
