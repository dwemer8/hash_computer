--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : UART_rx_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Dec  1 15:07:46 2021
-- Last update : Wed Jan  5 22:29:29 2022
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

--Тестбенч для модуля uart_rx.
--Симулирует отправку по UART двух посылок, проверяет правильность приема.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------

entity UART_rx_tb is

end entity UART_rx_tb;

-----------------------------------------------------------

architecture testbench of UART_rx_tb is

	component UART_rx is
		generic (
			FREQUENCY : INTEGER;
			BAUDRATE  : INTEGER;
			BYTE_SIZE : INTEGER
		);
		port (
			Clk_i      : in  STD_LOGIC;
			Rst_i      : in  STD_LOGIC;
			Rx_i      : in  STD_LOGIC;
			Rx_busy_o  : out STD_LOGIC;
			Rx_error_o : out std_logic;
			Rx_data_o  : out STD_LOGIC_VECTOR (BYTE_SIZE - 1 downto 0)
		);
	end component;

	-- Testbench DUT generics
	constant FREQUENCY : INTEGER := 50;
	constant BAUDRATE  : INTEGER := 25_000_000;
	constant BYTE_SIZE : INTEGER := 8;

	-- Testbench DUT ports
	signal Clk      : STD_LOGIC := '1';
	signal Rst      : STD_LOGIC := '1';
	signal Rx       : STD_LOGIC := '1';
	signal Rx_busy  : STD_LOGIC;
	signal Rx_error : STD_LOGIC;
	signal Rx_data  : STD_LOGIC_VECTOR (7 downto 0);

	signal data_in : STD_LOGIC_VECTOR(7 downto 0);

	-- Other constants
	constant clk_period : time := 20 ns; --(1000/FREQUENCY);
	constant uart_period : time := 40 ns; --(clk_period * FREQUENCY*1_000_000/BAUDRATE);

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	Clk <= not Clk after clk_period/2;
	Rst <= '0' after clk_period*10;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------

	process
	begin
		wait for clk_period*11;

		data_in <= "01010101";
		Rx <= '0';
		wait for uart_period;
		for i in 0 to data_in'length - 1 loop
			Rx <= data_in(i);
			wait for uart_period;
		end loop;
		Rx <= '1';
		wait for uart_period;

		if (rx_data /= data_in) then
		 	assert false report "Failure 1" severity failure;
		end if;

		data_in <= "00001111";
		Rx <= '0';
		wait for uart_period;
		for i in 0 to data_in'length - 1 loop
			Rx <= data_in(i);
			wait for uart_period;
		end loop;
		Rx <= '1';
		wait for uart_period;

		if (rx_data /= data_in) then
		 	assert false report "Failure 2" severity failure;
		end if;

		assert false report "Success" severity failure;

		wait;
	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : uart_rx
		generic map (
			FREQUENCY => FREQUENCY,
			BAUDRATE  => BAUDRATE,
			BYTE_SIZE => BYTE_SIZE
		)
		port map (
			Clk_i      => Clk,
			Rst_i      => Rst,
			Rx_i       => Rx,
			Rx_busy_o  => Rx_busy,
			Rx_error_o => Rx_error,
			Rx_data_o  => Rx_data
		);

end architecture testbench;