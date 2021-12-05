--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : CRC32_Core_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Sat Dec  4 17:04:36 2021
-- Last update : Sun Dec  5 13:41:52 2021
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
use std.textio.all;
use ieee.std_logic_textio.all;

-----------------------------------------------------------

entity CRC32_Core_tb is

end entity CRC32_Core_tb;

-----------------------------------------------------------

architecture testbench of CRC32_Core_tb is

	component CRC32_Core is
		port (
			Clock   : in  STD_LOGIC;
			Reset   : in  STD_LOGIC;
			Data_In : in  STD_LOGIC;
			CRC32   : out STD_LOGIC_VECTOR (31 downto 0)
		);
	end component;	

	-- Testbench DUT generics


	-- Testbench DUT ports
	signal Clock   : STD_LOGIC := '1';
	signal Reset   : STD_LOGIC := '1';
	signal Data_In : STD_LOGIC := '0';
	signal CRC32   : STD_LOGIC_VECTOR (31 downto 0);

	signal s_j : integer := 10;
	signal s_i : integer := 10;
	signal s_character_buf : std_logic_vector(7 downto 0) := (others => '0');
	signal s_result : std_logic_vector(31 downto 0) := (others => '0');

	-- Other constants
	constant clk_period : time := 20 ns; -- NS

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	Clock <= not Clock after clk_period/2;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------
	--CRC-32/BZIP2
	s_result <= x"FFFFFFFF" xor CRC32;

	process
		variable character_buf : std_logic_vector(7 downto 0) := (others => '0');

		function to_slv(
			symb : character
		) return std_logic_vector is
		begin
			return std_logic_vector(to_unsigned(character'pos(symb), 8));
		end to_slv;

	begin
		wait for clk_period*10;

		Reset <= '0';

		send_loop : for i in 1 to 9 loop 
			s_i <= i;
			character_buf := std_logic_vector(to_unsigned(48 + i, 8));
			s_character_buf <= character_buf;
			bit_loop : for j in 7 downto 0 loop	
				s_j <= j;
				Data_In <= character_buf(j); --charcter'pos("0") = 48
				wait for clk_period;
			end loop bit_loop;
		end loop;

		--padding_loop: for i in 1 to 32 loop
		--	s_i <= i;
		--	Data_In <= '1';
		--	wait for clk_period;
		--end loop;

		Reset <= '1';

		wait;
	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : CRC32_Core
		port map (
			Clock   => Clock,
			Reset   => Reset,
			Data_In => Data_In,
			CRC32   => CRC32
		);

end architecture testbench;