----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Simon Bertling
-- 
-- Create Date: 01.07.2017 11:03:57
-- Design Name: 
-- Module Name: seven_seg_4 - basys
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

entity seven_seg_4 is
    generic (
        F_clk : integer := 100000000; -- Hz
        F_cycle : integer := 60*4 -- Hz
    );
    port ( 
        clk : in std_logic;
        enable : in std_logic := '1';
        
        drive_high : in std_logic := '1';
        
        --  "10000000" firt bit indicates, that decoding will directly feedthrough lower 7 bits
        number1 : in std_logic_vector(7 downto 0) := "10000000";
        number2 : in std_logic_vector(7 downto 0) := "10000000";
        number3 : in std_logic_vector(7 downto 0) := "10000000";
        number4 : in std_logic_vector(7 downto 0) := "10000000";
        
        dp1 : in std_logic := '0';
        dp2 : in std_logic := '0';
        dp3 : in std_logic := '0';
        dp4 : in std_logic := '0';     
        
        segment_drive : out std_logic_vector (6 downto 0);
        dp_drive : out std_logic;
        
        -- an_drive will be used to multiplex the segments, only one bit may be active!
        an_drive : out std_logic_vector(3 downto 0)
       );
end seven_seg_4;

architecture compact of seven_seg_4 is
    
    constant N_count_max : integer := F_clk / F_cycle - 1;
    
    signal clk_counter : integer range 0 to N_count_max := 0;
      
    -- only 1 actvive bit, will be rotated through while running  
    signal an_drive_i : natural range 0 to 3 := 0;
    
    signal number : std_logic_vector(7 downto 0) := "10000000";
    signal dp : std_logic := '0';
    
    -- input latches
    signal enable_d : std_logic := '0';
    signal drive_high_d : std_logic := '0';
    signal number1_d,  number2_d, number3_d, number4_d: std_logic_vector(7 downto 0) := "10000000";
    signal dp1_d, dp2_d, dp3_d, dp4_d : std_logic := '0';
    
    -- output latch
    signal an_drive_d : std_logic_vector(3 downto 0);
        
begin

    digit_encoder : entity work.seven_seg port map( clk=>clk, number=>number,dp=>dp,drive_high=>drive_high,segment_drive=>segment_drive,dp_drive=>dp_drive);

    counter : process(clk)
    begin
        if rising_edge(clk) then
            if clk_counter < N_count_max then
                clk_counter <= clk_counter + 1;
            else
                clk_counter <= 0;
                if an_drive_i < 3 then
                    an_drive_i <= an_drive_i + 1;
                else
                    an_drive_i <= 0;
                end if;
            end if;
        end if;
    end process;
    
    latch_in : process(clk)
    begin
        if rising_edge(clk) then
            -- latch in inputs
            number1_d <= number1;
            number2_d <= number2;
            number3_d <= number3;
            number4_d <= number4;
            dp1_d <= dp1;
            dp2_d <= dp2;
            dp3_d <= dp3;
            dp4_d <= dp4;
            enable_d <= enable;
            drive_high_d <= drive_high;
       end if;
    end process;
    
    multiplex : process(clk)
    begin
        if rising_edge(clk) then
            case an_drive_i is
                -- number1 is most left digit which is MSB in an_drive
                when 0 => 
                    number <= number1_d;
                    dp <= dp1_d;
                    an_drive_d <= (3 => drive_high_d, OTHERS => not drive_high_d);
                when 1 => 
                    number <= number2_d;
                    dp <= dp2_d;
                    an_drive_d <= (2 => drive_high_d, OTHERS => not drive_high_d);
                when 2 => 
                    number <= number3_d;
                    dp <= dp3_d;
                    an_drive_d <= (1 => drive_high_d, OTHERS => not drive_high_d);
                when 3 => 
                    number <= number4_d;
                    dp <= dp4_d;
                    an_drive_d <= (0 => drive_high_d, OTHERS => not drive_high_d);
            end case;
            
            -- disable anode outputs when not enabled
            if enable_d = '0' then 
                an_drive_d <= (OTHERS => not drive_high_d);
            end if;
            
            -- as the digit encoder has 1 delay, we need to delay the output 1 clk here, too
            an_drive <= an_drive_d;
        end if;
    end process;

end compact;
