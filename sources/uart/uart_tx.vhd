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
        cnt_bit : integer;
        cnt_out : integer;
        data_reg : std_logic_vector (BYTE_SIZE - 1 downto 0);
    end record;
    
    signal rnext, rprev : rec_type := (idle, '0', '1', 0, 0, (others => '0'));
begin
    process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                rprev.state <= idle;
                rprev.tx_busy_o <= '0';
                rprev.tx_o <= '1';
                rprev.cnt_bit <= 0;
                rprev.cnt_out <= 0;
                rprev.data_reg <= (others => '0');
            else
                rprev <= rnext;
            end if;
        end if;
    end process;
    
    process (rprev, Tx_load_i, Tx_data_i)
    begin
        if (rprev.state = idle) then
            rnext.state <= idle;
            rnext.tx_busy_o <= '0';
            rnext.tx_o <= '1';
            rnext.cnt_bit <= 0;
            rnext.cnt_out <= 0;
            rnext.data_reg <= (others => '0');
            if (Tx_load_i = '1') then
                rnext.state <= start;
                rnext.cnt_out <= FREQUENCY*1000000/BAUDRATE - 1;
                rnext.tx_busy_o <= '1';
                rnext.data_reg <= Tx_data_i;
            end if;
        elsif (rprev.state = start) then
            rnext <= rprev;
            rnext.tx_o <= '0';
            if (rprev.cnt_out /= 0) then
                rnext.cnt_out <= rprev.cnt_out - 1;
            else
                rnext.state <= data;
                rnext.cnt_bit <= 0;
                rnext.cnt_out <= FREQUENCY*1000000/BAUDRATE - 1;
            end if;
        elsif (rprev.state = data) then
            rnext <= rprev;
            rnext.tx_o <= rprev.data_reg(rprev.cnt_bit);
            if (rprev.cnt_out /= 0) then
                rnext.cnt_out <= rprev.cnt_out - 1;
            else
                if (rprev.cnt_bit /= BYTE_SIZE - 1) then
                    rnext.cnt_out <= FREQUENCY*1000000/BAUDRATE - 1;
                    rnext.cnt_bit <= rprev.cnt_bit + 1;
                else
                    rnext.cnt_out <= FREQUENCY*1000000/BAUDRATE - 1;
                    rnext.state <= stop;
                end if;
            end if;
        else
            rnext <= rprev;
            rnext.tx_o <= '1';
            if (rprev.cnt_out /= 0) then
                rnext.cnt_out <= rprev.cnt_out - 1;
            else
                rnext.state <= idle;
                rnext.tx_busy_o <= '0';
            end if;
        end if;
    end process;
    Tx_o <= rprev.tx_o; 
    Tx_busy_o <= rprev.tx_busy_o;
end Behavioral;
