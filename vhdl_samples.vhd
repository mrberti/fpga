----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.06.2017 22:39:01
-- Design Name: 
-- Module Name: samples - Behavioral
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
use IEEE.STD_NUMERIC.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity samples is
    GENERIC ( width : integer := 16 );
    Port ( clk      : in STD_LOGIC;
           reset    : in STD_LOGIC;
           data_in  : in STD_LOGIC_VECTOR (width-1 downto 0);
           data_out : out STD_LOGIC_VECTOR (width-1 downto 0));
end samples;

architecture Behavioral of samples is
    --------------------
    -- TYP DEKLARATIONEN
    --------------------
    type my_counter_type is RANGE 0 to 20;
    type state_type is (IDLE, START, STOP, FINISH);
    -- arrays
    type Memory4k16 is array (0 to 4095) of std_logic_vector( 15 downto 0 );
    -- records
    type my_record_type is record
        a : std_logic;
        b : std_logic;
    end record;
    
    -------------
    -- KONSTANTEN
    -------------
    constant loopnumber : integer := 4;
    
    -- ALIASES
    alias low_byte : STD_LOGIC_VECTOR(7 downto 0) IS data_in( 7 DOWNTO 0 );
    alias high_byte : STD_LOGIC_VECTOR(7 downto 0) IS data_in( width-1 DOWNTO width-8 );
    
    -- SIGNALS
    signal test_signal : STD_LOGIC;
    signal my_counter : my_counter_type;
    signal char : character;
    signal mem : Memory4k16;
    signal my_record : my_record_type;
    signal state : state_type;
    ---------------------
    -- OPERATIONEN
    ---------------------
    -- + - * / mod rem ** abs
    -- = /= < <= > >=
    -- Shift: ssl, sla, rol, srl, sra, ror
    -- Verknüpfung: res <= ( a & b );
    

    
begin

    ----------------
    -- SIMULATION
    -------------
    process_example : PROCESS(test_signal)
    BEGIN
        test_signal <= test_signal AFTER 2 ns;
        test_signal <= '0', '1' after 2 ns, '0' after 4 ns;
        -- Transport delay
        test_signal <= TRANSPORT test_signal AFTER 2 ns;       
        
        FOR i IN mem'RANGE LOOP
            
        END LOOP;
    END PROCESS;
    
    process_example2 : PROCESS
    BEGIN
        WAIT FOR 10 ns;
        WAIT UNTIL clk = '1';
        WAIT ON clk;
    END PROCESS;
    
    process_example3 : PROCESS( state )
    BEGIN
        CASE state IS
            WHEN IDLE =>
                test_signal <= '0';
                state <= START;
            WHEN OTHERS =>
                state <= IDLE;
        END CASE;
    END PROCESS;

    update : PROCESS( clk, reset)
        VARIABLE num_of_ones : integer := 0;
    BEGIN
        IF (reset = '1') THEN
            data_out <= (OTHERS => '0');
        ELSE
            IF (clk'event AND clk = '1') THEN
                data_out <= data_in;
                FOR i IN width-1 downto 0 LOOP
                    NEXT WHEN data_in(i) = '0';
                    num_of_ones := num_of_ones + 1;
                END LOOP;
            END IF;
        END IF;
        
    END PROCESS;


end Behavioral;
