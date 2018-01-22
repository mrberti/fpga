----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.07.2017 22:06:30
-- Design Name: 
-- Module Name: pmod_oledrgb_tb - testbench
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pmod_oledrgb_tb is
--  Port ( );
end pmod_oledrgb_tb;

architecture testbench of pmod_oledrgb_tb is

    signal clk : std_logic := '0';
    
    signal enable_display : std_logic := '0';
    signal sck, mosi, d_c, res, cs, vccen, pmoden : std_logic := '0';
    
begin
    
    pmod_oledrgb_DUT : entity work.pmod_oledrgb(rtl)
    generic map(
        startup_wait => 1, -- us
        F_sck => 10000000
    )
    port map (
        clk => clk,
        enable_display => enable_display,
        sck => sck,
        mosi => mosi,
        d_c => d_c,
        res => res,
        cs => cs,
        vccen => vccen,
        pmoden => pmoden
    ); 
    
    clk <= not clk after 5 ns;
    
    process
    begin
        wait for 100 ns;
        enable_display <= '1';
        wait;
    end process;


end testbench;
