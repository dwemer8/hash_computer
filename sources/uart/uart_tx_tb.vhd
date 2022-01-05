--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : UART_tx_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Thu Dec  2 10:15:01 2021
-- Last update : Wed Jan  5 22:34:04 2022
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

--Тестбенч для проверки модуля UART_tx. 
--Проверяет правильность отправки двух посылок.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

-----------------------------------------------------------

entity UART_tx_tb is

end entity UART_tx_tb;

-----------------------------------------------------------

architecture testbench of UART_tx_tb is

	component UART_tx is
		generic (
			FREQUENCY : integer;
			BAUDRATE  : integer;
			BYTE_SIZE : integer
		);
		port (
			Clk_i     : in  STD_LOGIC;
			Rst_i     : in  STD_LOGIC;
			Tx_o      : out STD_LOGIC;
			Tx_busy_o : out STD_LOGIC;
			Tx_load_i : in  STD_LOGIC;
			Tx_data_i : in  STD_LOGIC_VECTOR (BYTE_SIZE-1 downto 0)
		);
	end component;	

	-- Testbench DUT generics
	constant FREQUENCY : INTEGER := 50;
	constant BAUDRATE  : INTEGER := 25_000_000;
	constant BYTE_SIZE : INTEGER := 8;

	-- Testbench DUT ports
	signal Clk_i     : STD_LOGIC := '1';
	signal Rst_i     : STD_LOGIC := '1';
	signal Tx_o      : STD_LOGIC;
	signal Tx_busy_o : STD_LOGIC;
	signal Tx_load_i : STD_LOGIC := '0';
	signal Tx_data_i : STD_LOGIC_VECTOR (BYTE_SIZE-1 downto 0);

	signal data_out : STD_LOGIC_VECTOR (BYTE_SIZE-1 downto 0);
	signal i_sig : integer := 7;

	-- Other constants
	constant clk_period : time := 20 ns; --(1000/FREQUENCY);
	constant uart_period : time := 40 ns; --(clk_period * FREQUENCY*1_000_000/BAUDRATE);

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	clk_i <= not clk_i after clk_period/2;
	rst_i <= '0' after clk_period*10;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------
	process
	begin
		wait for clk_period*11;

		Tx_data_i <= "01010101";
		Tx_load_i <= '1';
		wait until Tx_o = '0';
		Tx_load_i <= '0';
		wait for uart_period*3/2;
		for i in 0 to data_out'length - 1 loop
			data_out(i) <= Tx_o;
			i_sig <= i;
			wait for uart_period;
		end loop;
		if (Tx_o /= '1') then
			assert false report "Failure 1 tx" severity failure;
		elsif (data_out /= "01010101") then
		 	assert false report "Failure 1 data" severity failure;
		end if;
		data_out <= (others => '0');

		wait for uart_period;

		Tx_data_i <= "00001111";
		Tx_load_i <= '1';
		wait until Tx_o = '0';
		Tx_load_i <= '0';
		wait for uart_period*3/2;
		for i in 0 to data_out'length - 1 loop
			data_out(i) <= Tx_o;
			i_sig <= i;
			wait for uart_period;
		end loop;
		if (Tx_o /= '1') then
			assert false report "Failure 2 tx" severity failure;
		elsif (data_out /= "00001111") then
		 	assert false report "Failure 2 data" severity failure;
		end if;
		data_out <= (others => '0');

		assert false report "Success" severity failure;
		wait;
	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : UART_tx
		generic map (
			FREQUENCY => FREQUENCY,
			BAUDRATE  => BAUDRATE,
			BYTE_SIZE => BYTE_SIZE
		)
		port map (
			Clk_i     => Clk_i,
			Rst_i     => Rst_i,
			Tx_o      => Tx_o,
			Tx_busy_o => Tx_busy_o,
			Tx_load_i => Tx_load_i,
			Tx_data_i => Tx_data_i
		);

end architecture testbench;