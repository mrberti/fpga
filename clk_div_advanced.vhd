----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Simon Bertling
-- 
-- Create Date: 07.07.2017 19:30
-- Design Name: 
-- Module Name: clk_div_advanced
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
use IEEE.NUMERIC_STD.ALL;

entity clk_div_element is
    generic (
        N_count_max : natural := 16
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        enable : in std_logic := '1';
        q : out std_logic := '0';
        count : buffer natural range 0 to N_count_max - 1 := 0
    );
end clk_div_element;

architecture rtl of clk_div_element is

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
use IEEE.NUMERIC_STD.ALL;

entity clk_div_advanced is
    generic (
        F_clk : natural :=   100000000; -- Hz
        F_cycle : natural :=         1000000; -- Hz
        N_counter_size : natural := 32 -- clk count for each counter element
    );
    port ( 
        clk : in std_logic;
        q_pulse: out std_logic; -- active only one input clk cycle
        q_50 : out std_logic -- active 50% of output clk cycle
    );
end clk_div_advanced;

architecture rtl of clk_div_advanced is

    -- This function calculates the amount of required counter elements
    -- basically this is a ceil(log()) function
    function calculate_N_counters(
        N_count_max : natural;
        N_counter_size : natural
    )
    return natural is
        variable remainder : integer := 0;
        variable x : natural := 1;
    begin
        remainder := N_count_max;
        while remainder > 0 loop
            remainder := remainder / N_counter_size;
            if remainder > 0 then
                x := x + 1;
            end if;
        end loop;
        return x;      
    end function;
    
    constant N_count_max : natural := F_clk / F_cycle;
    constant N_count_max_50 : natural := F_clk / F_cycle / 2;
    constant N_counters : natural := calculate_N_counters(N_count_max, N_counter_size);

    type natural_array_type is array (0 to N_counters-1) of natural range 0 to N_count_max - 1;
    
    -- This function initializes the compare value vectors
    function init_N_vector(
        a : integer
    )
    return natural_array_type is
        variable N : natural_array_type;
        variable divider : natural := 1;
        variable remainder : natural := a;
    begin
        for i in N_counters-1 downto 0 loop
            divider := (remainder-1)/(N_counter_size**i);
            remainder := remainder - N_counter_size**i * divider;
            N(i) := divider;
        end loop;
        return N;
    end function;

    constant N : natural_array_type := init_N_vector(N_count_max);
    constant N_50 : natural_array_type := init_N_vector(N_count_max_50);
    
    signal counters : natural_array_type;
    signal r : std_logic_vector(0 to N_counters-1) := (OTHERS => '0');
    signal q_d : std_logic_vector(0 to N_counters) := (0 => '1', OTHERS => '0');
           
begin --architecture

    -- Generate all counter elements
    counter_gen : for i in 0 to N_counters-1 generate
        cnt : entity work.clk_div_element
        generic map (
            N_count_max => N_counter_size
        )
        port map (
            clk => clk,
            reset => r(i),
            enable => q_d(i), -- enable signal is output from preceding counter element
            q => q_d(i+1),
            count => counters(i)
        );
    end generate;
    
    -- This process checks the counters for equality with our compare vectors
    reset_gen : process(clk, counters)
        variable v_p, v_50, v_0 : integer range 0 to N_counters := N_counters;
    begin
        -- reset variables
        v_0 := N_counters;
        v_p := N_counters;
        v_50 := N_counters;
        
        -- check all counters
        for i in 0 to N_counters-1 loop
            if counters(i) = 0 then
                v_0 := v_0 - 1;
            end if;
            
            if counters(i) = N_50(i) then
                v_50 := v_50 - 1;        
            end if;
            
            if counters(i) = N(i) then
                v_p := v_p - 1;
            end if;
        end loop;
        
        -- reset all counter elements
        if v_p = 0 then           
            r <= (OTHERS => '1');
        else
            r <= (OTHERS => '0');
        end if;
        
        -- output for 50% duty cycle
        if v_0 = 0 then
            q_50 <= '0';
        elsif v_50 = 0 then        
            q_50 <= '1';
        end if; 

    end process;    
    
    -- output for pulsed output
    q_pulse <= r(0);

end rtl;
