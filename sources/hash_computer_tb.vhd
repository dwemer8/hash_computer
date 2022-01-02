--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : hash_computer_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Sun Jan  2 00:28:58 2022
-- Last update : Sun Jan  2 14:18:13 2022
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Copyright (c) 2022 User Company Name
-------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------

entity hash_computer_tb is

end entity hash_computer_tb;

-----------------------------------------------------------

architecture testbench of hash_computer_tb is

	-- Testbench DUT generics
	constant FREQUENCY : integer := 50;
 	constant BAUDRATE : integer := 25_000_000;
 	constant BYTE_SIZE : integer := 8;
 	constant CRC32_INIT : std_logic_vector(31 downto 0) := x"FFFFFFFF";
 	constant CRC32_XOROUT : std_logic_vector(31 downto 0) := x"FFFFFFFF";

	-- Testbench DUT ports
	signal clk_i           : std_logic := '1';
	signal rst_i           : std_logic := '1';
	signal start_comp_i    : std_logic := '0';
	signal switch_mode_i   : std_logic := '0';
	signal uart_rx_i       : std_logic := '1';
	signal uart_tx_o       : std_logic;
	signal rw_o, rs_o, e_o : std_logic;
	signal lcd_data_o      : std_logic_vector(7 downto 0);
	signal ready_o         : std_logic;

	-- Other constants
	constant clk_period : time := 20 ns; -- NS
	constant uart_period : time := clk_period * FREQUENCY * 1_000_000 / BAUDRATE;
	constant rst_delay : time := clk_period*2;
	constant clearing_delay : integer := 10 * 1000 * FREQUENCY;

	signal data_in : std_logic_vector(BYTE_SIZE - 1 downto 0) := (others => '0');

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
		         '0' after rst_delay;
		wait;
	end process RESET_GEN;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------

	process
	begin
		wait for rst_delay;

		---crc32---------------------------------------------------------------------

		data_in <= "01010101";
		uart_rx_i <= '0';
		wait for uart_period;
		for i in 0 to data_in'length - 1 loop
			uart_rx_i <= data_in(i);
			wait for uart_period;
		end loop;
		uart_rx_i <= '1';
		wait for uart_period;

		start_comp_i <= '1';
		wait for clk_period * clearing_delay;
		start_comp_i <= '0';

		wait until ready_o = '1';
		lcd_loop : for i in 0 to 23 loop
			wait until lcd_data_o = b"1111_1110"; --space code
		end loop lcd_loop;
		
		wait for clk_period * FREQUENCY * 1000; --1 ms

		---sha1---------------------------------------------------------------------

		switch_mode_i <= '1';
		wait for clk_period * clearing_delay;
		switch_mode_i <= '0';

		data_in <= "01010101";
		uart_rx_i <= '0';
		wait for uart_period;
		for i in 0 to data_in'length - 1 loop
			uart_rx_i <= data_in(i);
			wait for uart_period;
		end loop;
		uart_rx_i <= '1';
		wait for uart_period;

		start_comp_i <= '1';
		wait for clk_period * clearing_delay;
		start_comp_i <= '0';

		wait until ready_o = '1';
		
		wait for clk_period * FREQUENCY * 6000; --1 ms

		assert false report "SUCCESS" severity failure;
		wait;
	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : entity work.hash_computer
		generic map (
			FREQUENCY => FREQUENCY,
			BAUDRATE  => BAUDRATE,
			BYTE_SIZE => BYTE_SIZE,
			CRC32_INIT => CRC32_INIT,
			CRC32_XOROUT => CRC32_XOROUT
		)
		port map (
			clk_i         => clk_i,

			rst_i         => rst_i,
			start_comp_i  => start_comp_i,
			switch_mode_i => switch_mode_i,

			uart_rx_i     => uart_rx_i,
			uart_tx_o     => uart_tx_o,

			rw_o          => rw_o,
			rs_o          => rs_o,
			e_o           => e_o,
			lcd_data_o    => lcd_data_o,

			ready_o       => ready_o
		);

end architecture testbench;