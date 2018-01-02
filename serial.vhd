----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.07.2017 17:57:46
-- Design Name: 
-- Module Name: serial - Behavioral
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

----------------------------------------------------------------------------------
-- TX Component ------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial_tx is
    generic (
        F_clk_in  : integer := 100000000; 
        F_baud    : integer :=    256000;
        pol_idle  : std_logic := '1'; -- state of the idle pin
        N_data_bits : integer range 1 to 9 := 8;
        N_stop_bits : integer range 0 to 2 := 1;
        N_parity : integer := 0 -- no implementation yet 
    );
    port ( 
        clk : in std_logic;
        reset : in std_logic;
        data_tx : in std_logic_vector(N_data_bits-1 downto 0);
        
        kickout : in std_logic;
        busy : out std_logic := '0';
        
        -- These flags are indicating a failure during transmission
        -- the transceiver needs to be reset then
        tx_fail : out std_logic := '0';
        
        -- physical pins
        tx : out std_logic := '0'
        );
        
end serial_tx;

architecture rtl of serial_tx is

    type state_tx_type is (TX_IDLE, TX_START, TX_SEND, TX_STOP1, TX_STOP2, TX_FAILED);
    
    constant N_counter_max : integer := F_clk_in / F_baud - 1;

    signal data_tx_d : std_logic_vector(N_data_bits-1 downto 0) := (OTHERS => '0');
    
    signal clk_counter_tx : integer range 0 to N_counter_max := 0; --(15 downto 0);
    signal clk_counter_tx_overflow, rx_do_sample : std_logic := '0';

    signal state_tx : state_tx_type := TX_IDLE;
    
begin
    
    clk_counter_tx_proc : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' or state_tx = TX_IDLE then
                clk_counter_tx <= 0;
                clk_counter_tx_overflow <= '0';              
            else
                if clk_counter_tx < N_counter_max then
                    clk_counter_tx_overflow <= '0';
                    clk_counter_tx <= clk_counter_tx + 1;
                else
                    clk_counter_tx_overflow <= '1';
                    clk_counter_tx <= 0;
                end if;
            end if;
        end if;
    end process;
    
    tx_state_machine : process(clk)
        variable bit_counter_tx : integer range 0 to N_data_bits - 1;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state_tx <= TX_IDLE;
                bit_counter_tx := 0;
                tx <= pol_idle;
                tx_fail <= '0';
                busy <= '0';
            else
                case state_tx is
                    when TX_IDLE  => 
                        tx_fail <= '0';
                        data_tx_d <= data_tx;
                        busy <= '0';
                        tx <= pol_idle;
                        if kickout = '1' then
                            state_tx <= TX_START;
                        end if;
                    when TX_START =>
                        tx <= not pol_idle;
                        busy <= '1';
                        bit_counter_tx := 0;
                        if clk_counter_tx_overflow = '1' then
                            state_tx <= TX_SEND;
                        end if;
                    when TX_SEND => 
                        tx <= data_tx_d(bit_counter_tx) xor not pol_idle;
                        if clk_counter_tx_overflow = '1' then
                            if bit_counter_tx = N_data_bits - 1 then
                                state_tx <= TX_STOP1;
                            else
                                bit_counter_tx := bit_counter_tx + 1;
                            end if;
                        end if;
                    when TX_STOP1 =>
                        tx <= pol_idle;
                        if clk_counter_tx_overflow = '1' then
                            if N_stop_bits > 1 then
                                state_tx <= TX_STOP2;
                            else
                                state_tx <= TX_IDLE;
                            end if;
                        end if;
                    when TX_STOP2 =>
                        tx <= pol_idle;
                        if clk_counter_tx_overflow = '1' then
                            state_tx <= TX_IDLE;
                        end if;                   
                    when TX_FAILED =>
                        tx_fail <= '1';
                        tx <= pol_idle;
                        state_tx <= TX_FAILED;
                    when OTHERS => state_tx <= TX_FAILED;
                end case;
            end if;
        end if;
    end process;
end rtl;

----------------------------------------------------------------------------------
-- RX Component ------------------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial_rx is
    generic (
        F_clk_in  : integer := 100000000; 
        F_baud    : integer :=    256000;
        pol_idle  : std_logic := '1'; -- state of the idle pin
        N_data_bits : integer range 1 to 9 := 8;
        N_stop_bits : integer range 0 to 2 := 1;
        N_parity : integer := 0 -- no implementation yet 
    );
    Port ( 
        clk : in std_logic;
        reset : in std_logic;
        
        data_rx : out std_logic_vector(N_data_bits-1 downto 0) := (OTHERS => '0');
        
        rx_valid : out std_logic := '0';
        
        -- These flags are indicating a failure during transmission
        -- the transceiver needs to be reset then
        rx_fail : out std_logic := '0';
        
        -- physical pins
        rx : in std_logic := '0' -- async receive pin
        );
        
end serial_rx;

architecture rtl of serial_rx is

    type state_rx_type is (RX_IDLE, RX_START, RX_SAMPLE, RX_STOP, RX_FAILED);
    
    constant N_counter_max : integer := F_clk_in / F_baud - 1;
        
    signal rx_d : std_logic_vector(1 downto 0) := "00";
    signal data_rx_d  : std_logic_vector(N_data_bits-1 downto 0) := (OTHERS => '0');
    
    signal clk_counter_rx : integer range 0 to N_counter_max := 0; --(15 downto 0);
    signal clk_counter_rx_overflow, rx_do_sample : std_logic := '0';
    
    signal state_rx : state_rx_type := RX_IDLE;
    
begin
    
    clk_counter_rx_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' or state_rx = RX_IDLE then
                clk_counter_rx <= 0;
                clk_counter_rx_overflow <= '0';
                rx_do_sample <= '0';
            else
                if clk_counter_rx = N_counter_max / 2 then
                    rx_do_sample <= '1';
                else
                    rx_do_sample <= '0';                    
                end if;
                if clk_counter_rx < N_counter_max then
                    clk_counter_rx <= clk_counter_rx + 1;
                    clk_counter_rx_overflow <= '0';
                else
                    clk_counter_rx_overflow <= '1';
                    clk_counter_rx <= 0;
                end if;                
            end if;
        end if;
    end process;
    
    rx_sampling : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_d <= (OTHERS => pol_idle);
            else
                rx_d <= rx_d(rx_d'length-2 downto 0) & rx;
            end if;
        end if;
    end process;
    
    rx_state_machine : process(clk)
        variable bit_counter_rx : integer range 0 to N_data_bits;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state_rx <= RX_IDLE;
                rx_valid <= '0';
                rx_fail <= '0';
                data_rx_d <= (OTHERS=>'0');                
            else
                case state_rx is
                    when RX_IDLE =>
                        rx_fail <= '0';
                        if (pol_idle = '1' and rx_d = "10") or (pol_idle = '0' and rx_d = "01") then
                            state_rx <= RX_START;
                        end if;
                    when RX_START =>
                        rx_valid <= '0';
                        data_rx_d <= (OTHERS=>'0');
                        -- we need to reset the bit counter, which is used in the next step
                        bit_counter_rx := 0;
                        if rx_do_sample = '1' then
                            if rx_d(rx_d'length-1) = pol_idle then
                                -- was expecting the start bit, but polarity was wrong => go back to idle
                                state_rx <= RX_IDLE;
                            else
                                state_rx <= RX_SAMPLE;
                            end if;
                        end if;
                    when RX_SAMPLE =>
                        if rx_do_sample = '1' then
                            data_rx_d <= (rx_d(rx_d'length-1) xor not pol_idle) & data_rx_d(data_rx_d'length-1 downto 1);
                            if bit_counter_rx = N_data_bits - 1 then
                                state_rx <= RX_STOP;
                            else
                                bit_counter_rx := bit_counter_rx + 1;
                            end if;
                        end if;
                    when RX_STOP =>
                        rx_valid <= '1';
                        -- directly go into idle state. no need to wait for the stop bit
                        -- here could be a stop bit error correction be implemented
                        state_rx <= RX_IDLE;
                    when RX_FAILED =>
                        rx_fail <= '1';
                        state_rx <= RX_FAILED;
                    when OTHERS =>
                        state_rx <= RX_FAILED;
                        rx_valid <= '0';
                end case;                
            end if;
        end if;
    end process;
    
    -- copy latched data into outport
    data_rx <= data_rx_d;

end rtl;

----------------------------------------------------------------------------------
-- TRANSCEIVER Component ---------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial is
    generic (
        F_clk_in  : integer := 100000000; 
        F_baud    : integer :=    256000;
        pol_idle  : std_logic := '1'; -- state of the idle pin
        N_data_bits : integer range 1 to 9 := 8;
        N_stop_bits : integer range 0 to 2 := 1;
        N_parity : integer := 0 -- no implementation yet 
    );
    Port ( 
        clk : in std_logic;
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
        
end serial;

architecture rtl of serial is   
begin

    -- Create receiver component
    serial_rx_component : entity work.serial_rx
    generic map ( 
        F_baud => F_baud, N_data_bits => N_data_bits, pol_idle => pol_idle, N_stop_bits => N_stop_bits 
    )
    port map (
        clk => clk, reset => reset, data_rx => data_rx, rx_valid => rx_valid, rx_fail => rx_fail, rx => rx
    );
    
    -- Create transmitter component
    serial_tx_component : entity work.serial_tx
    generic map ( 
        F_baud => F_baud, N_data_bits => N_data_bits, pol_idle => pol_idle, N_stop_bits => N_stop_bits 
    )
    port map (
        clk => clk, reset => reset, data_tx => data_tx, kickout => kickout, busy => busy, tx_fail => tx_fail, tx => tx
    );

end rtl;
