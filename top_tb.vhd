----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.06.2017 15:12:18
-- Design Name: 
-- Module Name: top_tb - Behavioral
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

entity top_tb is
end top_tb;

architecture Behavioral of top_tb is
    
    signal sw : std_logic_vector ( 15 downto 0 );
    --signal led : std_logic_vector ( 15 downto 0 );
    --signal seg : std_logic_vector ( 6 downto 0 );
    --signal an : std_logic_vector ( 15 downto 0 );
    
    signal btnC, btnU, btnL, btnR, btnD : std_logic := '0';
    
    signal RsRx, RsTx: std_logic := '0';
    
    signal clk : std_logic := '0';
    
    alias reset : std_logic is btnC;    
    alias number : std_logic_vector (7 downto 0) is sw(15 downto 8);

begin
    
    top_DUT : entity work.top(rtl)
    port map(
        clk => clk,
        sw => sw,
        btnC => btnC,
        btnU => btnU,
        btnL => btnL,
        btnR => btnR,
        btnD => btnD,
        RsRx => RsRx,
        RsTx => RsTx           
    );
    
    clk <= not clk after 5 ns;
        
    stimulus : process
        variable loop_count : integer := 0;
    begin
        btnC <= '1';
        sw <= x"77FF";
        wait for 35 ns;
        btnC <= '0';
        wait for 35 ns;
        sw(1) <= '1';
        
        wait for 35 ns;
        sw(15 downto 8) <= x"DE";
        wait for 35 ns;
        btnR <= '1'; 
       
        
        --while loop_count < 16 loop
        --    wait for 27 ns;
        --    loop_count := loop_count + 1;
        --    number <= std_logic_vector(to_unsigned(loop_count, number'length));
        --end loop;
        
        --wait for 10 us;
        --btnC <= '1';
        --wait for 100 ns;
        --btnC <= '0';
        
        wait;
    end process;
    
    RsRx <= RsTx;
    
    stimulus_rs232 : process
    begin
        wait for 50 ns;
        btnU <= '1';
    end process;
    
    


end Behavioral;
