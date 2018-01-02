----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.06.2017 14:04:44
-- Design Name: 
-- Module Name: clk_div_tb - Behavioral
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

entity clk_div_tb is
--  Port ( );
end clk_div_tb;

architecture Behavioral of clk_div_tb is
    
    component clk_div 
        GENERIC (
            F_clk_in : integer := 50;
            F_clk_out : integer := 1;
            N_counter_bitsize : integer := 32
        );
        PORT ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               clk_out : out STD_LOGIC
        );
    end component;
    
    signal clk : STD_LOGIC := '0';
    signal reset : STD_LOGIC := '0';
    signal clk_out : STD_LOGIC := '1';

begin

    clk_div_DUT : clk_div
    generic map (
        F_clk_in => 50000000,
        F_clk_out => 100
    )
    port map (
        clk => clk,
        reset => reset,
        clk_out => clk_out
    );
    
    clk <= not clk after 10 ns;
    
    --clk_proc : process
    --begin
        
    --end process;
    
    stimulus : process
    begin
        reset <= '0';
        wait for 35 ns;
        reset <= '1';
        wait for 30 ns;
        reset <= '0';
        
        wait;
    end process;

end Behavioral;
