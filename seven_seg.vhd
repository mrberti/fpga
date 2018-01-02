----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Simon Bertling
-- 
-- Create Date: 01.07.2017 07:32:50
-- Design Name: 
-- Module Name: seven_seg - Behavioral
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

entity seven_seg is
    port ( 
        clk : in STD_LOGIC;
        number : in STD_LOGIC_VECTOR (7 downto 0);
        dp : in STD_LOGIC;
        drive_high : in std_logic := '1';
           
        -- output signals to drive the 7 segment display
        -- LSB := A
        segment_drive : out STD_LOGIC_VECTOR (6 downto 0);
        dp_drive : out STD_LOGIC
     );
end seven_seg;

architecture rtl of seven_seg is
    
    --signal segment_drive_d : STD_LOGIC_VECTOR (6 downto 0);

begin

    drive : process (clk)
        variable segment_drive_d : STD_LOGIC_VECTOR (6 downto 0);
    begin
        if rising_edge(clk) then
            case number is                     --"GFEDCBA"
                when x"00" => segment_drive_d := "0111111";
                when x"01" => segment_drive_d := "0000110";
                when x"02" => segment_drive_d := "1011011";
                when x"03" => segment_drive_d := "1001111";
                when x"04" => segment_drive_d := "1100110";
                when x"05" => segment_drive_d := "1101101";
                when x"06" => segment_drive_d := "1111101";
                when x"07" => segment_drive_d := "0000111";
                when x"08" => segment_drive_d := "1111111";
                when x"09" => segment_drive_d := "1100111";
                when x"0A" => segment_drive_d := "1110111";
                when x"0B" => segment_drive_d := "1111100"; -- b
                when x"0C" => segment_drive_d := "0111001";
                when x"0D" => segment_drive_d := "1011110"; -- d
                when x"0E" => segment_drive_d := "1111001";
                when x"0F" => segment_drive_d := "1110001";
                when others => segment_drive_d := number(6 downto 0);
            end case;
            if (drive_high = '0') then
                segment_drive <= not segment_drive_d;
                dp_drive <= not dp;
            else
                segment_drive <= segment_drive_d;
                dp_drive <= dp;
            end if;   
        end if;
    end process;

end rtl;
