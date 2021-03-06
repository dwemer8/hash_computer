----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/26/2019 05:36:28 PM
-- Design Name: 
-- Module Name: UART_tx - Behavioral
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
-- Модуль для отправки данных по UART.
--clk_i - тактовый сигнал
--rst_i - сигнал сброса
--tx_o - сигнал линии UART
--tx_busy_o - сигнал занятости модуля. Если в нуле, можно отправлять данные.
--Tx_load_i - сигнал отправки данных. После поднятия начинается отправка.
--Tx_data_i - данные для отправки. Буферизуются.
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

entity UART_tx is
    generic (
        FREQUENCY : integer; --MHz
        BAUDRATE : integer;
        BYTE_SIZE : integer);
    port ( Clk_i : in STD_LOGIC;
           Rst_i : in STD_LOGIC;
           Tx_o : out STD_LOGIC;--
           Tx_busy_o : out STD_LOGIC;--
           Tx_load_i : in STD_LOGIC;
           Tx_data_i : in STD_LOGIC_VECTOR (BYTE_SIZE-1 downto 0));
end UART_tx;

architecture Behavioral of UART_tx is
    type state_type is (idle, start, data, stop);
    type rec_type is record
        state : state_type;
        tx_busy_o : std_logic;
        tx_o : std_logic;
        Tx_load_i : std_logic;
        cnt_bit : integer;
        cnt_out : integer;
        data_reg : std_logic_vector (BYTE_SIZE - 1 downto 0);
    end record;
    
    constant uart_period_in_clocks : integer := FREQUENCY * 1_000_000 / BAUDRATE;
    constant rstRec : rec_type := (idle, '0', '1', '0', 0, 0, (others => '0'));
    signal rnext, rprev : rec_type := rstRec;
begin
    process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                rprev <= rstRec;
            else
                rprev <= rnext;
            end if;
        end if;
    end process;
    
    process (rprev, Tx_load_i, Tx_data_i)
        variable var : rec_type := rstRec;
    begin
        var := rprev;
        var.Tx_load_i := Tx_load_i;

        case (rprev.state) is
        when idle =>
            if (Tx_load_i = '1' and rprev.Tx_load_i = '0') then
                var.state := start;
                var.cnt_out := uart_period_in_clocks - 1;
                var.tx_busy_o := '1';
                var.data_reg := Tx_data_i;
            end if;

        when start =>
            var.tx_o := '0';
            if (rprev.cnt_out /= 0) then
                var.cnt_out := rprev.cnt_out - 1;

            else
                var.state := data;
                var.cnt_out := uart_period_in_clocks - 1;
            end if;

        when data =>
            var.tx_o := rprev.data_reg(rprev.cnt_bit);
            if (rprev.cnt_out /= 0) then
                var.cnt_out := rprev.cnt_out - 1;

            else
                if (rprev.cnt_bit /= BYTE_SIZE - 1) then
                    var.cnt_out := uart_period_in_clocks - 1;
                    var.cnt_bit := rprev.cnt_bit + 1;

                else
                    var.cnt_out := uart_period_in_clocks - 1;
                    var.cnt_bit := 0;
                    var.state := stop;
                end if;
            end if;

        when stop =>
            var.tx_o := '1';
            if (rprev.cnt_out /= 0) then
                var.cnt_out := rprev.cnt_out - 1;

            else
                var.state := idle;
                var.tx_busy_o := '0';
            end if;
        end case;

        rnext <= var;
    end process;

    Tx_o <= rnext.tx_o; 
    Tx_busy_o <= rprev.tx_busy_o;
end Behavioral;
