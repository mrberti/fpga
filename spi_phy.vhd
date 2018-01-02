----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.06.2017 21:17:07
-- Design Name: 
-- Module Name: spi_phy - Behavioral
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

entity spi_master_phy is
    generic ( 
        N_slaves    : natural := 1;
        F_clk_in    : natural := 100;
        F_clk_out   : natural :=  1;
        N_data_bits : natural range 1 to 10 := 8
    );
    port ( 
        -- GENERAL SIGNALS
        clk   : in std_logic := '0';
        
        -- SPI MASTER CONTROL SIGNALS
        kickout    : in std_logic := '0'; -- begins SPI transmit, active high. when held high => continues transfer
        cpol       : in std_logic := '1'; -- 1 => idle high
        cpha       : in std_logic := '1'; -- 1 => sample on second flank after cs low
        slave_addr : in std_logic_vector ( N_slaves - 1 downto 0 ) := (others => '0');
        
        -- TRX Data signals
        data_tx : in  std_logic_vector (N_data_bits-1 downto 0) := (others => '0');
        data_rx : out std_logic_vector (N_data_bits-1 downto 0) := (others => '0');
       
        -- STATUS OUTPUT SIGNALS
        rx_valid : out std_logic := '0';
        busy     : out std_logic := '0';
       
        -- SPI PINS
        cs   : out std_logic_vector (N_slaves-1 downto 0) := (others => '1');
        sck  : out std_logic := '0';
        mosi : out std_logic := 'Z';
        miso : in  std_logic := 'Z'
     );
            
end spi_master_phy;

architecture rtl of spi_master_phy is

    -- DATATYPES
    type spi_state_type IS (SPI_IDLE, SPI_TRANSCEIVING, SPI_FINISH);

    -- calculate the counter overflow from frequencies
    constant N_clk_div : integer := F_clk_in / F_clk_out;
    
    signal clk_counter : integer range 0 to N_clk_div - 1 := 0;
    signal bit_counter : natural range 0 to N_data_bits := N_data_bits - 1;
    
    signal spi_state   : spi_state_type := SPI_IDLE;
    
    -- These signals indicate the first and second flank for each SCK cycle
    signal flank_1, flank_2 : std_logic := '0';
    
    -- latches
    signal cpol_d    : std_logic := cpol;
    signal cpha_d    : std_logic := cpha;
    signal kickout_d : std_logic := '0';
    signal miso_d    : std_logic := '0';
    signal data_rx_d : std_logic_vector( N_data_bits-1 downto 0 ) := (others => '0');
    signal data_tx_d : std_logic_vector( N_data_bits-1 downto 0 ) := (others => '0');
    signal address_d : std_logic_vector( N_slaves-1    downto 0 ) := (others => '0');

begin

    -- This process generates the SPI clock.
    -- Only active when transceiving
    clock_divider : process( clk )
    begin
        if rising_edge(clk) then
            if spi_state = SPI_TRANSCEIVING then
                clk_counter <= clk_counter + 1;                
                if clk_counter = N_clk_div-1 then
                    clk_counter <= 0;
                end if;
             else
                clk_counter <= 0;
             end if;
        end if;
    end process;
    
    -- This process generates the flanks for advancing the state machine
    flank_creator : process( clk )
    begin
        if rising_edge(clk) then
            if clk_counter = N_clk_div/2-1 then
                flank_1 <= '1';
            else
                flank_1 <= '0'; 
            end if;
            if clk_counter = N_clk_div-1 then
                flank_2 <= '1';
            else
                flank_2 <= '0';
            end if;
        end if;
    end process;

    -- This process controls the tranceiving procedure
    spi_state_machine : process (clk)
    begin
        if rising_edge(clk) then
        
            --sampling miso
            miso_d <= miso;
            kickout_d <= kickout;
        
            case spi_state is
                when SPI_IDLE =>
                    busy <= '0';
                    mosi <= 'Z';
                    cs <= (OTHERS => '1');
                    sck <= cpol_d;
                    -- while idling, constantly latch in data
                    cpol_d <= cpol;
                    cpha_d <= cpha;
                    
                    data_tx_d <= data_tx;
                    address_d <= slave_addr;
                    
                    if cpha_d = '1' then
                        bit_counter <= N_data_bits;
                    else
                        bit_counter <= N_data_bits-1;
                    end if;
                    
                    -- listen for kickout and advance state
                    if kickout_d = '1' then
                        spi_state <= SPI_TRANSCEIVING;
                    end if;
                    
                when SPI_TRANSCEIVING =>
                    -- set signals
                    busy <= '1';
                    rx_valid <= '0';
                    cs(to_integer(unsigned(address_d))) <= '0';
                    
                    mosi <= data_tx_d( data_rx_d'length-1 ); -- MSB out first
                    
                    if flank_1 = '1' or flank_2 = '1' then
                        -- create SCK signal
                        sck <= (not cpol_d and flank_1) or (cpol_d and flank_2);
                        
                        if (flank_1 = '1' and cpha_d = '1') or (flank_2 = '1' and cpha_d = '0') then
                            bit_counter <= bit_counter - 1;
                            if bit_counter > 0 then
                                if bit_counter < N_data_bits then
                                    data_tx_d <= data_tx_d( data_tx_d'length - 2 downto 0 ) & '0';
                                end if;
                            else
                                sck <= cpol_d;
                                spi_state <= SPI_FINISH;
                            end if;
                        elsif (flank_1 = '1' and cpha_d = '0') or (flank_2 = '1' and cpha_d = '1') then
                            data_rx_d <= data_rx_d(data_rx_d'length-2 downto 0) & miso_d;
                        end if;
                    end if;
                    
                when SPI_FINISH =>
                    -- write data to output
                    data_rx <= data_rx_d;
                    rx_valid <= '1';
                 
                    if kickout_d = '1' then
                        -- continue sending but latch in tx_data before
                        data_tx_d <= data_tx;
                        spi_state <= SPI_TRANSCEIVING;
                        if cpha_d = '1' then
                            bit_counter <= N_data_bits;
                        else
                            bit_counter <= N_data_bits-1;
                        end if;
                    else 
                        -- Finished sending, so go back to idling mode
                        spi_state <= SPI_IDLE;
                    end if;
                when others =>
                    -- should not appear
                    spi_state <= SPI_IDLE;
                    rx_valid <= '0';
                    
            end case;
        end if;
    end process;

end rtl;

------------------------------
-- SPI SLAVE
------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_slave_phy is
    generic ( 
        N_data_bits : natural range 1 to 10 := 8
    );
    port ( 
        -- GENERAL SIGNALS
        clk   : in std_logic := '0';
        
        -- SPI MASTER CONTROL SIGNALS
        cpol       : in std_logic := '1'; -- 1 => idle high
        cpha       : in std_logic := '1'; -- 1 => sample on second flank after cs low
        
        -- TRX Data signals
        data_tx : in  std_logic_vector (N_data_bits-1 downto 0) := (others => '0');
        data_rx : out std_logic_vector (N_data_bits-1 downto 0) := (others => '0');
       
        -- STATUS OUTPUT SIGNALS
        rx_valid : out std_logic := '0';
       
        -- SPI PINS
        cs   : in  std_logic := '1';
        sck  : in  std_logic := '0';
        mosi : in  std_logic := 'Z';
        miso : out std_logic := 'Z'
     );
            
end spi_slave_phy;

architecture rtl of spi_slave_phy is
    
    signal bit_counter_tx, bit_counter_rx : natural range 0 to N_data_bits := 0;
    
    -- latches
    signal sck_d     : std_logic_vector(1 downto 0) := (others => cpol);
    signal cs_d      : std_logic_vector(1 downto 0) := (others => cpol);
    signal cpol_d    : std_logic := cpol;
    signal cpha_d    : std_logic := cpha;
    signal mosi_d    : std_logic := '0';
    signal data_rx_d : std_logic_vector( N_data_bits-1 downto 0 ) := (others => '0');
    signal data_tx_d : std_logic_vector( N_data_bits-1 downto 0 ) := (others => '0');

begin

    -- This process controls the tranceiving procedure
    spi_state_machine : process (clk)
    begin
        if rising_edge(clk) then
        
            --sampling SPI pins
            mosi_d <= mosi;
            cs_d <= (1 => cs_d(0), 0 => cs);
            sck_d <= (1 => sck_d(0), 0 => sck);
            
            if cs_d = "00" then

                if     (sck_d = (1 => cpol_d, 0 => not cpol_d) and cpha_d = '0') 
                    or (sck_d = (1 => not cpol_d, 0 => cpol_d) and cpha_d = '1') 
                then
                    bit_counter_rx <= bit_counter_rx + 1;
                    data_rx_d <= data_rx_d(data_rx_d'length-2 downto 0) & mosi_d;
                    rx_valid <= '0';
                end if;
                
                if     (sck_d = (1 => cpol_d, 0 => not cpol_d) and cpha_d = '1') 
                    or (sck_d = (1 => not cpol_d, 0 => cpol_d) and cpha_d = '0') 
                then
                    bit_counter_tx <= bit_counter_tx + 1;
                    miso <= data_tx_d( N_data_bits - 1 - bit_counter_tx ); -- MSB out first
                end if;
                
                if bit_counter_rx = N_data_bits and bit_counter_tx = N_data_bits then
                    rx_valid <= '1';
                    data_rx <= data_rx_d;
                    data_tx_d <= data_tx;
                    bit_counter_rx <= 0;
                    bit_counter_tx <= 0;
                end if;
                
            elsif cs_d = "10" and cpha_d = '0' then
                -- when cpha_d is 0 then we need to start sending out data as soon as cs goes low
                bit_counter_tx <= bit_counter_tx + 1;
                rx_valid <= '0';
                miso <= data_tx_d( N_data_bits - 1 - bit_counter_tx ); -- MSB out first
            else
                miso <= 'Z';
                
                cpol_d <= cpol;
                cpha_d <= cpha;
                
                data_tx_d <= data_tx;
                
                bit_counter_tx <= 0;
                bit_counter_rx <= 0;
            end if;

        end if;
    end process;

end rtl;

architecture state_based of spi_slave_phy is

    -- DATATYPES
    type spi_state_type IS (SPI_IDLE, SPI_TRANSCEIVING, SPI_FINISH);
    
    signal bit_counter_tx, bit_counter_rx : natural range 0 to N_data_bits := 0;
    
    signal spi_state   : spi_state_type := SPI_IDLE;
    
    -- latches
    signal sck_d     : std_logic_vector(1 downto 0) := (others => cpol);
    signal cs_d      : std_logic_vector(1 downto 0) := (others => cpol);
    signal cpol_d    : std_logic := cpol;
    signal cpha_d    : std_logic := cpha;
    signal mosi_d    : std_logic := '0';
    signal data_rx_d : std_logic_vector( N_data_bits-1 downto 0 ) := (others => '0');
    signal data_tx_d : std_logic_vector( N_data_bits-1 downto 0 ) := (others => '0');

begin

    -- This process controls the tranceiving procedure
    spi_state_machine : process (clk)
    begin
        if rising_edge(clk) then
        
            --sampling SPI pins
            mosi_d <= mosi;
            cs_d <= (1 => cs_d(0), 0 => cs);
            sck_d <= (1 => sck_d(0), 0 => sck);
                
            case spi_state is
                when SPI_IDLE =>
                    busy <= '0';
                    miso <= 'Z';
                    -- while idling, constantly latch in data
                    cpol_d <= cpol;
                    cpha_d <= cpha;
                    
                    data_tx_d <= data_tx;
                    
                    bit_counter_tx <= 0;
                    bit_counter_rx <= 0;
                    
                    -- listen for cs falling flank and advance state
                    if cs_d = "10" then
                        spi_state <= SPI_TRANSCEIVING;
                    end if;
                    
                when SPI_TRANSCEIVING =>
                    -- set signals
                    busy <= '1';
                    rx_valid <= '0';
                    
                    if     (sck_d = (1 => cpol_d, 0 => not cpol_d) and cpha_d = '0') 
                        or (sck_d = (1 => not cpol_d, 0 => cpol_d) and cpha_d = '1') 
                    then
                        bit_counter_rx <= bit_counter_rx + 1;
                        data_rx_d <= data_rx_d(data_rx_d'length-2 downto 0) & mosi_d;
                    end if;
                    
                    if     (sck_d = (1 => cpol_d, 0 => not cpol_d) and cpha_d = '1') 
                        or (sck_d = (1 => not cpol_d, 0 => cpol_d) and cpha_d = '0') 
                    then
                        miso <= data_tx_d( N_data_bits - 1 - bit_counter_tx ); -- MSB out first
                        bit_counter_tx <= bit_counter_tx + 1;
                    end if;
                    
                    if bit_counter_rx = N_data_bits and bit_counter_tx = N_data_bits then
                        spi_state <= SPI_FINISH;
                    end if;
                    
                    -- listen for cs rising flank
                    -- this should not appear before all N_Data_bits are written
                    -- So we return to idle state without making the rx_data valid
                    if cs_d = "01" then
                        spi_state <= SPI_IDLE;
                    end if;
                    
                when SPI_FINISH =>
                    -- write data to output
                    data_rx <= data_rx_d;
                    rx_valid <= '1';
                 
                    if cs_d = "01" then
                        spi_state <= SPI_IDLE;
                    end if;
                    
--                    if cs_d(0) = '0' then
--                        -- continue sending but latch in tx_data before
--                        data_tx_d <= data_tx;
--                        spi_state <= SPI_TRANSCEIVING;
--                        bit_counter <= N_data_bits-1;
--                    else 
--                        -- Finished sending, so go back to idling mode
--                        spi_state <= SPI_IDLE;
--                    end if;
                when others =>
                    -- should not appear
                    spi_state <= SPI_IDLE;
                    rx_valid <= '0';
                    
            end case;
        end if;
    end process;

end state_based;

