--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : FIFO_8x10240_mod_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Sun Dec 26 21:35:13 2021
-- Last update : Sun Jan  2 12:25:58 2022
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
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fifo_mod_pkg.all;

-----------------------------------------------------------

entity FIFO_8x10240_mod_tb is

end entity FIFO_8x10240_mod_tb;

-----------------------------------------------------------

architecture testbench of FIFO_8x10240_mod_tb is

	component FIFO_8x10240_mod is
		generic (
			DATA_WIDTH : integer := 8
		);
		port (
			clk      : in  STD_LOGIC;
			rst      : in  STD_LOGIC;
			rAddrRst : in  std_logic;
			rStartSet : in std_logic;
			dataIn   : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
			dataOut  : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
			push     : in  STD_LOGIC;
			pop      : in  STD_LOGIC;
			isFull   : out STD_LOGIC;
			isEmpty  : out STD_LOGIC
		);
	end component;	

	-- Testbench DUT generics
	constant DATA_WIDTH : integer := 8;

	-- Testbench DUT ports
	signal clk      : STD_LOGIC := '1';
	signal rst      : STD_LOGIC := '1';
	signal rAddrRst : std_logic := '0';
	signal rStartSet : std_logic := '0';
	signal dataIn   : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0) := (others => '0');
	signal dataOut  : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
	signal push     : STD_LOGIC := '0';
	signal pop      : STD_LOGIC := '0';
	signal isFull   : STD_LOGIC;
	signal isEmpty  : STD_LOGIC;

	-- Other constants
	constant clk_period : time := 20 ns;
	constant rst_delay : time := clk_period * 3;

	signal s_i : integer := 100;

begin
	clk <= not clk after clk_period/2;
	rst <= '0' after rst_delay;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------

	process
	begin
		wait for rst_delay;

		pop <= '1';
		push <= '1';
		wait for clk_period;
		push <= '0';
		pop <= '0';
		wait for clk_period;

		push <= '1';
		push_loop : for i in 0 to 550 loop
			s_i <= i;
			dataIn <= slv(i, 8);
			wait for clk_period;
		end loop;
		push <= '0';

		pop <= '1';
		for i in 0 to 510 loop
			s_i <= i;
			wait for clk_period/2;
			if (i /= 0) then
				assert dataOut = slv(i - 1, 8) report "FAILURE" severity failure;
			end if;
			wait for clk_period/2;
		end loop;
		pop <= '0';
		wait for clk_period/2;
		assert dataOut = slv(510, 8) report "FAILURE" severity failure;
		wait for clk_period/2;

		rStartSet <= '1';
		wait for clk_period;
		rStartSet <= '0';

		rAddrRst <= '1';
		wait for clk_period;
		rAddrRst <= '0';

		pop <= '1';
		for i in 511 to 550 loop
			s_i <= i;
			wait for clk_period/2;
			if (i /= 0) then
				assert dataOut = slv(i - 1, 8) report "FAILURE" severity failure;
			end if;
			wait for clk_period/2;
		end loop;
		pop <= '0';
		wait for clk_period/2;
		assert dataOut = slv(550, 8) report "FAILURE" severity failure;
		wait for clk_period/2;

		wait for clk_period;
		assert false report "SUCCESS" severity failure;
		wait;
	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	FIFO_8x10240_mod_2 : entity work.FIFO_8x10240_mod
		generic map (
			DATA_WIDTH => DATA_WIDTH
		)
		port map (
			clk      => clk,
			rst      => rst,
			rAddrRst => rAddrRst,
			rStartSet => rStartSet,
			dataIn   => dataIn,
			dataOut  => dataOut,
			push     => push,
			pop      => pop,
			isFull   => isFull,
			isEmpty  => isEmpty
		);		



end architecture testbench;