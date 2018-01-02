----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.06.2017 13:52:29
-- Design Name: 
-- Module Name: clk_div - Behavioral
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
USE IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clk_div is
    generic (
        F_clk_in : integer := 100000000; -- Hz
        F_clk_out : integer := 1 -- Hz
    );
    port ( 
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        clk_out : out STD_LOGIC
    );
end clk_div;

architecture rtl of clk_div is

    constant N_counter_max : integer := (F_clk_in / F_clk_out) - 1;
    
    signal clk_counter : integer range 0 to N_counter_max := 0;

begin

    counting : process (clk, reset)
    begin
        if rising_edge(clk) then
            if (reset = '1') then
                clk_counter <= 0;        
            else
                if clk_counter < N_counter_max then
                    clk_counter <= clk_counter + 1;
                else
                    clk_counter <= 0;
                end if;
            end if;
        end if;
    end process;
    
    clk_out_process : process (clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                clk_out <= '1';
            else
                if (clk_counter = N_counter_max/2) then
                    clk_out <= '1';
                elsif (clk_counter = N_counter_max) then
                    clk_out <= '0';
                end if;
            end if;
        end if;
    end process; 

end rtl;
