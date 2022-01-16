--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : lcd_loader_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Fri Dec 31 13:35:50 2021
-- Last update : Sun Jan 16 19:00:12 2022
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Copyright (c) 2021 User Company Name
-------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.

--Тестбенч для lcd_loader. Проверка работоспособности модуля осуществляется по wave-формам. Модуль должен загружать данные в LCD, если data_type_i "01" или "10" - переодически, проматывая бегущей строкой на экране значения хэшей.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.lcd_pkg.all;

-----------------------------------------------------------

entity lcd_loader_tb is

end entity lcd_loader_tb;

-----------------------------------------------------------

architecture testbench of lcd_loader_tb is

	-- Testbench DUT generics


	-- Testbench DUT ports
	signal clk_i           : std_logic := '1';
	signal rst_i           : std_logic := '1';
	signal data_valid_i    : std_logic := '0';
	signal data_ready_o : std_logic;
	signal data_type_i     : std_logic_vector(1 downto 0) := (others => '0');
	signal data_i          : std_logic_vector(255 downto 0) := (others => '0');
	signal rw_o, rs_o, e_o : std_logic;
	signal lcd_data_o      : std_logic_vector(7 downto 0);

	-- Other constants
	constant clk_period : time := 20 ns; -- NS

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	CLK_GEN : process
	begin
		clk_i <= '1';
		wait for clk_period / 2;
		clk_i <= '0';
		wait for clk_period / 2;
	end process CLK_GEN;

	RESET_GEN : process
	begin
		rst_i <= '1',
		         '0' after 2*clk_period;
		wait;
	end process RESET_GEN;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------
	process
	begin
		wait for clk_period*2;
		wait until data_ready_o = '1';

		---crc32---------------------------------------------------------------------
		wait for clk_period;
		data_valid_i <= '1';
		data_type_i <= "00";
		data_i(255 downto 224) <= x"FC891918";
		wait for clk_period;  
		data_valid_i <= '0';
		wait until lcd_data_o = b"1111_1110"; --space code

		wait for clk_period;
		wait for 10 ms;

		---sha1---------------------------------------------------------------------
		wait for clk_period;
		data_valid_i <= '1';
		data_type_i <= "01";
		data_i <= (others => '1');
		wait for clk_period;  
		data_valid_i <= '0';
		wait until rs_o = '0' and rw_o = '0' and lcd_data_o = b"1100_1111"; --address of 32th character on lcd

		wait for clk_period;
		wait for 30 ms;

		assert false report "SUCCESS" severity failure;
		wait;
	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : entity work.lcd_loader
		port map (
			clk_i        => clk_i,
			rst_i        => rst_i,
			data_valid_i => data_valid_i,
			data_ready_o => data_ready_o,
			data_type_i  => data_type_i,
			data_i       => data_i,
			rw_o         => rw_o,
			rs_o         => rs_o,
			e_o          => e_o,
			lcd_data_o   => lcd_data_o
		);

end architecture testbench;