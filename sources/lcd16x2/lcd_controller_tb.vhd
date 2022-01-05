--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : lcd_controller_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Thu Dec 30 13:46:43 2021
-- Last update : Wed Jan  5 23:06:12 2022
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

--Тестбенч для проверки lcd_controller. Проверку проводить по соответствию wave-форм документации LCD-модуля.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------

entity lcd_controller_tb is

end entity lcd_controller_tb;

-----------------------------------------------------------

architecture testbench of lcd_controller_tb is	

	-- Testbench DUT generics
	constant clk_freq       : INTEGER   := 50;
	constant display_lines  : STD_LOGIC := '1';
	constant character_font : STD_LOGIC := '0';
	constant display_on_off : STD_LOGIC := '1';
	constant cursor         : STD_LOGIC := '0';
	constant blink          : STD_LOGIC := '0';
	constant inc_dec        : STD_LOGIC := '1';
	constant shift          : STD_LOGIC := '0';

	-- Testbench DUT ports
	signal clk        : STD_LOGIC := '1';
	signal reset_n    : STD_LOGIC := '0';
	signal lcd_enable : STD_LOGIC := '0';
	signal lcd_bus    : STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
	signal busy       : STD_LOGIC;
	signal rw, rs, e  : STD_LOGIC;
	signal lcd_data   : STD_LOGIC_VECTOR(7 DOWNTO 0);

	-- Other constants
	constant clk_period : time := 20 ns; -- NS
	constant rst_delay : time := clk_period*2;

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	clk <= not clk after clk_period/2;
	reset_n <= '1' after rst_delay;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------
	stim: process
	begin
		wait for rst_delay;

		wait until busy = '0';
		wait for clk_period;
		lcd_enable <= '1';
		lcd_bus <= b"1_1_00001010";
		wait for clk_period;
		lcd_enable <= '0';
		wait until busy = '0';

		wait for clk_period;
		assert false report "SUCCESS" severity failure;
		wait;
	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------

	lcd_controller_2 : entity work.lcd_controller
		generic map (
			clk_freq       => clk_freq,
			display_lines  => display_lines,
			character_font => character_font,
			display_on_off => display_on_off,
			cursor         => cursor,
			blink          => blink,
			inc_dec        => inc_dec,
			shift          => shift
		)
		port map (
			clk        => clk,
			reset_n    => reset_n,
			lcd_enable => lcd_enable,
			lcd_bus    => lcd_bus,
			busy       => busy,
			rw         => rw,
			rs         => rs,
			e          => e,
			lcd_data   => lcd_data
		);	

end architecture testbench;