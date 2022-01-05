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

-- Модуль для приема данный по UART.
-- clk_i - тактовый сигнал 
-- rst_i - сигнал сброса
-- rx_i - сигнал данных
-- rx_busy_o - сигнал, показывающий, что модуль принимает посылку/свободен. После его падения можно считывать данные.
-- rx_error_o - сигнал ошибки при передаче
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
        rx_busy: std_logic;
        rx_data: std_logic_vector (BYTE_SIZE - 1 downto 0);
        rx_error : std_logic;
        cntBit : integer;
        cntIn : integer;
    end record;
    
    constant uart_period_in_clocks : integer := FREQUENCY * 1_000_000 / BAUDRATE;
    constant rstRec : rec_type := (idle, '0', (others => '0'), '0', 0, 0);
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
    
    process (prevRec, rx_i, rst_i)
        variable var : rec_type := rstRec;
    begin
        var := prevRec;

        case (prevRec.state) is
        when idle =>
            if (rx_i = '0') then
                var.state := start;
                var.rx_busy := '1';
                var.cntIn := uart_period_in_clocks/2 - 1;
                var.rx_error := '0';
            end if;

        when start =>
            if (prevRec.cntIn /= 0) then
                var.cntIn := prevRec.cntIn - 1;

            else
                --data stream started
                if (rx_i = '0') then
                    var.state := data;
                    var.cntIn := uart_period_in_clocks - 1;

                --noise happened
                else
                    var.state := idle;
                    var.rx_busy := '0';
                end if;
            end if;

        when data =>
            if (prevRec.cntIn /= 0) then
                var.cntIn := prevRec.cntIn - 1;

            else
                var.cntIn := uart_period_in_clocks - 1;
                var.rx_data(prevRec.cntBit) := rx_i;

                if (prevRec.cntBit /= BYTE_SIZE - 1) then
                    var.cntBit := prevRec.cntBit + 1;

                else 
                    var.cntBit := 0;
                    var.state := stop;
                end if;
            end if;
            
        when stop =>
            if (prevRec.cntIn /= 0) then
                var.cntIn := prevRec.cntIn - 1;

            else
                var.rx_busy := '0';
                var.state := idle;
                if (rx_i /= '1') then
                    var.rx_error := '1';
                end if;
            end if;
        end case;

        nextRec <= var;
    end process;

    rx_data_o <= nextRec.rx_data;
    rx_busy_o <= nextRec.rx_busy; 
    rx_error_o <= nextRec.rx_error; 
end Behavioral;
