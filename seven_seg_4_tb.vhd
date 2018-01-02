----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Simon Bertling
-- 
-- Create Date: 01.07.2017 11:21:53
-- Design Name: 
-- Module Name: seven_seg_4_tb - Behavioral
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

entity seven_seg_4_tb is
--  Port ( );
end seven_seg_4_tb;

architecture Behavioral of seven_seg_4_tb is

    signal clk : std_logic := '0';
    signal reset, enable, drive_high, dp1, dp2, dp3, dp4, dp_drive : STD_LOGIC;
    signal number1, number2, number3, number4 : STD_LOGIC_VECTOR( 7 downto 0);
    signal segment_drive : STD_LOGIC_VECTOR( 6 downto 0);
    signal an_drive : STD_LOGIC_VECTOR( 3 downto 0);

    
begin

    seven_segment_4_DUT : entity work.seven_seg_4(compact)
    generic map(
        F_cycle => 10000000
    )
    port map (
        clk => clk,
        enable => enable,
        
        number1 => number1,
        number2 => number2,
        number3 => number3,
        number4 => number4,
        
        dp1 => dp1,
        dp2 => dp2,
        dp3 => dp3,
        dp4 => dp4,
        
        drive_high => drive_high,
        segment_drive => segment_drive,
        dp_drive => dp_drive,    
        
        an_drive => an_drive
    );

    clk <= not clk after 5 ns;
    
    stimulus : process
        variable loop_count : integer := 0;
    begin
        enable <= '0';
        number1 <= "00000001";
        number2 <= "00000010";
        number3 <= "00000011";
        number4 <= "00000100";
        drive_high <= '1';
        dp1 <= '0';
        dp2 <= '0';
        dp3 <= '1';
        dp4 <= '0';
        
        wait for 15 ns;
        enable <= '1';
        
        while loop_count < 16 loop
            --number <= number + 1;
            wait for 27 ns;
            loop_count := loop_count + 1;
            --number1 <= std_logic_vector(to_unsigned(loop_count, number1'length));
            --number2 <= 
        end loop;
        
        enable <= '0';
        wait for 100 ns;
        enable <= '1';
        
        dp1 <= '1';
        
        wait;
    end process;


end Behavioral;
