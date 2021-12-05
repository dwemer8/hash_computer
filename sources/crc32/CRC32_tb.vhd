--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : CRC32_Core_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Sat Dec  4 17:04:36 2021
-- Last update : Sun Dec  5 19:20:46 2021
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

-----------------------------------------------------------

entity CRC32_tb is

end entity CRC32_tb;

-----------------------------------------------------------

architecture testbench of CRC32_tb is

	component CRC32 is
		generic (
			INIT   : STD_LOGIC_VECTOR (31 downto 0);
			XOROUT : STD_LOGIC_VECTOR (31 downto 0)
		);
		port (
			clk_i        : in  STD_LOGIC;
			rst_i        : in  STD_LOGIC;
			data_i       : in  STD_LOGIC;
			data_valid_i : in  STD_LOGIC;
			checksum_o   : out STD_LOGIC_VECTOR (31 downto 0)
		);
	end component;

	-- Testbench DUT generics


	-- Testbench DUT ports
	signal clk_i        : STD_LOGIC := '1';
	signal rst_i        : STD_LOGIC := '1';
	signal data_i       : STD_LOGIC := '0';
	signal checksum_o   : STD_LOGIC_VECTOR (31 downto 0);
	signal data_valid_i : std_logic := '0';

	signal s_j : integer := 10;
	signal s_i : integer := 10;

	-- Other constants
	constant clk_period : time := 20 ns; -- NS
	constant rst_delay  : time := clk_period*10;

begin
	-----------------------------------------------------------
	-- clk_i and rst_i
	-----------------------------------------------------------
	clk_i <= not clk_i after clk_period/2;
	rst_i <= '0' after rst_delay;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------
	process
		variable character_buf : std_logic_vector(7 downto 0) := (others => '0');

	begin
		wait for rst_delay + clk_period;

		--loading of "123456789"
		data_valid_i <= '1';
		send_loop : for i in 1 to 9 loop
			s_i           <= i;
			character_buf := std_logic_vector(to_unsigned(48 + i, 8)); --charcter'pos("0") = 48
			
			bit_loop : for j in 7 downto 0 loop
				s_j    <= j;
				data_i <= character_buf(j);
				wait for clk_period;
			end loop bit_loop;
		end loop;
		data_valid_i <= '0';

		wait for clk_period*3;
		-- FC891918 - checksum for 123456789 string
		assert checksum_o = x"FC891918" report "FAILURE" severity failure;
		assert false report "SUCCESS" severity failure;

		wait;

	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : CRC32
		generic map (
			--CRC-32/BZIP2
			INIT   => x"FFFFFFFF",
			XOROUT => x"FFFFFFFF"
		)
		port map (
			clk_i        => clk_i,
			rst_i        => rst_i,
			data_i       => data_i,
			data_valid_i => data_valid_i,
			checksum_o   => checksum_o
		);

end architecture testbench;