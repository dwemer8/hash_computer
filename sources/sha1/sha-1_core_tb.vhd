--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : SHA1_core_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Mon Dec 13 15:31:22 2021
-- Last update : Wed Jan  5 23:49:58 2022
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

--Тестбенч для SHA1_core. Проверяет правильность вычисления sha1 для тестовой строки.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sha1_pkg.all;

-----------------------------------------------------------

entity SHA1_core_tb is

end entity SHA1_core_tb;

-----------------------------------------------------------

architecture testbench of SHA1_core_tb is

	-- Testbench DUT generics
	component SHA1_core is
		port (
			clk_i       : in  std_logic;
			rst_i       : in  std_logic;
			msg_block_i : in  std_logic_vector(511 downto 0);
			data_valid_i     : in  std_logic;
			digest_o    : out std_logic_vector(159 downto 0);
			data_ready_o     : out std_logic
		);
	end component;	

	-- Testbench DUT ports
	signal clk_i       : std_logic := '1';
	signal rst_i       : std_logic := '1';
	signal msg_block_i : std_logic_vector(511 downto 0) := (others => '0');
	signal data_valid_i     : std_logic := '0';
	signal digest_o    : std_logic_vector(159 downto 0);
	signal data_ready_o     : std_logic;

	-- Other constants
	constant clk_period : time := 20 ns; -- NS

begin
	-----------------------------------------------------------
	-- Clocks
	-----------------------------------------------------------
	clk_i <= not clk_i after clk_period/2;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------
	stim: process
	begin
		rst_i <= '1';
		wait for clk_period;

		rst_i <= '0';
		wait for clk_period;
		msg_block_i <= strToMsg("The quick brown fox jumps over the lazy dog");
		data_valid_i <= '1';
		wait for clk_period;
		data_valid_i <= '0';

		wait until data_ready_o = '1';
		wait for clk_period*2;
		assert digest_o = x"2fd4e1c67a2d28fced849ee1bb76e7391b93eb12" report "FAIL" severity failure;

		assert false report "SUCCESS" severity failure;
		wait;
	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : SHA1_core
		port map (
			clk_i       => clk_i,
			rst_i       => rst_i,
			msg_block_i => msg_block_i,
			data_valid_i     => data_valid_i,
			digest_o    => digest_o,
			data_ready_o     => data_ready_o
		);

end architecture testbench;