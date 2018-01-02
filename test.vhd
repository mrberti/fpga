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

entity clk_div2 is
    generic (
        N_count_max : natural := 32
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        enable : in std_logic := '1';
        q : out std_logic := '0';
        count : buffer natural range 0 to N_count_max - 1 := 0
    );
end clk_div2;

architecture rtl of clk_div2 is

begin

    counter : process(clk)
    begin
        if rising_edge(clk) then
            q <= '0';
            if reset = '1' then
                count <= 0;
            elsif enable = '1' then
                if (count = N_count_max-1)then
                    count <= 0;
                    q <= '1';
                else
                    count <= count + 1;             
                end if;
            end if;
        end if;
    end process;
    
end rtl;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity clk_div is
    generic (
        F_clk : natural :=   100000000; -- Hz
        F_cycle : natural :=    813010; -- Hz
        N_counter_size : natural := 10;
        N_counters : natural := 4 
    );
    port ( 
        clk : in std_logic;
    
        q : out std_logic := '1'
       );
       
      
end clk_div;

architecture rtl of clk_div is

    type natural_array_type is array (0 to N_counters-1) of natural;
    
    constant N_count_max : natural := F_clk / F_cycle;
    
    function init_N_vector(
        a : integer
    )
    return natural_array_type is
        variable N : natural_array_type;
        variable divider : natural := 1;
        variable remainder : natural := N_count_max;
    begin
        for i in N_counters-1 downto 0 loop
            divider := (remainder-1)/(N_counter_size**i);
            remainder := remainder - N_counter_size**i * divider;
            N(i) := divider;
        end loop;
        return N;
    end init_N_vector;

    constant N : natural_array_type := init_N_vector(N_count_max);
    
    --constant N : natural_array_type(0 to N_counters-1);
    
    --constant N1 : natural := N_count_max / N_counter_size;
    --constant N2 : natural := N_count_max - N_counter_size*N1 - 1;
    
    signal c1, c2 : natural range 0 to N_counter_size := 0;
    
    
    signal counters : natural_array_type;
    
    signal r : std_logic_vector(0 to N_counters-1) := (OTHERS => '0');
    signal q_d : std_logic_vector(0 to N_counters) := (0 => '1', OTHERS => '0');
           
begin

    counter_gen : for i in 0 to N_counters-1 generate
        cnt : entity work.clk_div2
        generic map (
            N_count_max => N_counter_size
        )
        port map (
            clk => clk,
            reset => r(i),
            enable => q_d(i),
            q => q_d(i+1),
            count => counters(i)
        );
    end generate;
    
    reset_gen : process(clk)
    begin
        if counters(0) = N(0) and counters(1) = N(1) and counters(2) = N(2) then
            r <= (OTHERS => '1');
        else
            r <= (OTHERS => '0');
        end if;  

    end process;    
    
    q <= r(0);

end rtl;
