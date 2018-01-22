----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.07.2017 22:05:21
-- Design Name: 
-- Module Name: pmod_oledrgb - rtl
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

entity pmod_oledrgb is
    generic (
        F_clk : integer := 100000000;
        F_sck : integer :=   1000000;
        startup_wait : integer := 100000-- us
    );
  port (
    clk : in std_logic := '0';
    reset : in std_logic := '0';
    enable_display : in std_logic := '0';
    
    sck    : out std_logic := '0'; -- serial clock
    mosi   : out std_logic := '0'; -- master out slave in
    d_c    : out std_logic := '0'; -- data/command# control
    res    : out std_logic := '0'; -- power reset
    cs     : out std_logic := '0'; -- chip select
    vccen  : out std_logic := '0'; -- vcc enable
    pmoden : out std_logic := '0'  -- Vdd logic voltage control
  );
end pmod_oledrgb;

architecture rtl of pmod_oledrgb is

    constant N_clk_div_startup_wait : integer :=  startup_wait * (F_clk / 1000000);

    type pmod_oledrgb_state_type is (
        PMOD_IDLE,
        PMOD_INITIALIZE,
        PMOD_POWER_ON_WAIT,
        PMOD_ENABLED
        );
        
    signal pmod_oledrgb_state : pmod_oledrgb_state_type := PMOD_IDLE;

    signal spi_busy, spi_kickout : std_logic := '0';
    signal spi_data_tx : std_logic_vector( 7 downto 0 ) := (others => '0');
    
    signal enable_display_d : std_logic := enable_display;
    
    signal power_on_wait_counter : integer range 0 to N_clk_div_startup_wait := 0;
    
begin

    -- Create SPI component instance
    -- SCK idle is high => cpol = '1'
    -- SPI data will be read on rising flank => cpha = '1'
    -- Data length is 8 bit
    -- D/C will be sampled on the 8th bit
    -- only data sending, no data will be received
    pmod_spi_master_comp : entity work.spi_master_phy(rtl)
    generic map (
        F_clk_in => F_clk,
        F_clk_out => f_sck,
        N_data_bits => 8
    )
    port map (
        clk => clk,
        
        -- SPI control
        kickout => spi_kickout,
        busy => spi_busy,
        rx_valid => open,
        cpol => '1',
        cpha => '1',
        
        slave_addr => (others => '0'),
        
        -- SPI data
        data_tx => spi_data_tx,
        data_rx => open,
        
        -- SPI pins
        sck => sck,
        cs(0) => cs,
        mosi => mosi,
        miso => open       
    );

    -- POWER ON SEQUENCE:
    -- 1. Apply power to VCC => PMODEN to high
    -- 2. Send Display Off command (x"AE")
    -- 3. initialize to default settings
    -- 4. clear screen 
    -- 5. apply power to VCCEN
    -- 6. Delay 100 ms
    -- 7. send display on command (x"AF")
    
    -- POWER OFF SEQUENCE
    -- 1. Send display off command (x"AE")
    -- 2. power off VCCEN
    -- 3. Delay 100 ms
    -- 4. Power off VCC (not controllable by FPGA)
    
    main : process(clk)
    begin
        if rising_edge(clk) then
            enable_display_d <= enable_display;
            
            case pmod_oledrgb_state is
                when PMOD_IDLE =>
                    if enable_display_d = '1' then
                        pmod_oledrgb_state <= PMOD_INITIALIZE;
                    end if;
                when PMOD_INITIALIZE =>
                    pmoden <= '1';
                    pmod_oledrgb_state <= PMOD_POWER_ON_WAIT;
                when PMOD_POWER_ON_WAIT =>
                    power_on_wait_counter <= power_on_wait_counter + 1;
                    if power_on_wait_counter = N_clk_div_startup_wait then
                        power_on_wait_counter <= 0;
                        pmod_oledrgb_state <= PMOD_ENABLED;
                    end if;
                when PMOD_ENABLED =>
                when others =>
            end case;

        end if;
    end process;

end rtl;
