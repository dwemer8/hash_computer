----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2019 03:48:07 PM
-- Design Name: 
-- Module Name: UART_rx - Behavioral
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
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_rx is
    generic ( FREQUENCY : INTEGER; --MHz
              BAUDRATE : INTEGER;
              BYTE_SIZE : INTEGER);
    Port ( clk_i : in STD_LOGIC;
           rst_i : in STD_LOGIC;
           rx_i: in STD_LOGIC;
           rx_busy_o : out STD_LOGIC;
           rx_error_o : out std_logic;
           rx_data_o : out STD_LOGIC_VECTOR (BYTE_SIZE - 1 downto 0));
end UART_rx;

architecture Behavioral of UART_rx is

    type state_type is (idle, start, data, stop);
    type rec_type is record
        state: state_type;
        rx_i: std_logic;
        rxBusy: std_logic;
        rxData: std_logic_vector (BYTE_SIZE - 1 downto 0);
        cntBit : integer;
        cntIn : integer;
        rxError : std_logic;
    end record;
    
    constant rstRec : rec_type := (idle, '1', '0', (others => '0'), 0, 0, '0');
    signal prevRec, nextRec: rec_type := rstRec;
    
begin

    process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                prevRec <= rstRec;
            else
                prevRec <= nextRec;
            end if;
        end if;
    end process;
    
    process (prevRec, Rx_i, rst_i)
    begin
        if (prevRec.state = idle) then
            if (rx_i = '1') then
                nextRec.state <= idle;
                nextRec.rx_i<= Rx_i;
                nextRec.rxBusy <= '0';
                nextRec.rxData <= (others => '0');
                nextRec.cntBit <= 0;
                nextRec.cntIn <= 0;
                nextRec.rxError <= '0'; 
            else
                nextRec.state <= start;
                nextRec.rx_i<= Rx_i;
                nextRec.rxBusy <= '1';
                nextRec.rxData <= (others => '0');
                nextRec.cntBit <= 0;
                nextRec.cntIn <= FREQUENCY*1000000/BAUDRATE/2;
                nextRec.rxError <= '0';
            end if;
        elsif (prevRec.state = start) then
            nextRec <= prevRec;
            if (prevRec.cntIn /= 0) then
                nextRec.cntIn <= prevRec.cntIn - 1;
            else
                if (rx_i= '0') then
                    nextRec.state <= data;
                    nextRec.rx_i<= Rx_i;
                    nextRec.rxBusy <= '1';
                    nextRec.rxData <= (others => '0');
                    nextRec.cntBit <= 0;
                    nextRec.cntIn <= FREQUENCY*1000000/BAUDRATE - 1;
                else
                    nextRec.state <= idle;
                    nextRec.rx_i<= Rx_i;
                    nextRec.rxBusy <= '0';
                    nextRec.rxData <= (others => '0');
                    nextRec.cntBit <= 0;
                    nextRec.cntIn <= 0;
                end if;
            end if;
        elsif (prevRec.state = data) then
            nextRec <= prevRec;
            if (prevRec.cntIn /= 0) then
                nextRec.cntIn <= prevRec.cntIn - 1;
            else
                if (prevRec.cntBit /= BYTE_SIZE - 1) then
                    nextRec.cntBit <= prevRec.cntBit + 1;
                    nextRec.cntIn <= FREQUENCY*1000000/BAUDRATE - 1;
                    nextRec.rxData(prevRec.cntBit) <= Rx_i;
                else 
                    nextRec.state <= stop;
                    nextRec.cntBit <= 0;
                    nextRec.cntIn <= FREQUENCY*1000000/BAUDRATE - 1;
                    nextRec.rxData(prevRec.cntBit) <= Rx_i;
                end if;
            end if;
        elsif (prevRec.state = stop) then
            nextRec <= prevRec;
            if (prevRec.cntIn /= 0) then
                nextRec.cntIn <= prevRec.cntIn - 1;
            else
                nextRec.rxBusy <= '0';
                rx_data_o <= prevRec.rxData;
                nextRec.state <= idle;
                if (rx_i/= '1') then
                    nextRec.rxError <= '1';
                end if;
            end if;
        end if;
    end process;

    rx_busy_o <= nextRec.rxBusy; 
    rx_error_o <= nextRec.rxError; 
end Behavioral;
