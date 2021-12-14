--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : sha1_loader_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Tue Dec 14 11:12:16 2021
-- Last update : Tue Dec 14 23:14:09 2021
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
use work.sha1_pkg.all;

-----------------------------------------------------------

entity sha1_loader_tb is

end entity sha1_loader_tb;

-----------------------------------------------------------

architecture testbench of sha1_loader_tb is

	-- Testbench DUT generics
	component sha1_loader is
		port (
			clk_i : in std_logic;
			rst_i : in std_logic;

			data_i : in  std_logic_vector(7 downto 0);
			pull_o : out std_logic;

			data_ready_i : in  std_logic;
			data_valid_o : out std_logic;
			msg_block_o  : out std_logic_vector(511 downto 0);

			start_i      : in  std_logic;
			msg_length_i : in  integer;
			ready_o      : out std_logic
		);
	end component sha1_loader;

	-- Testbench DUT ports
	signal clk_i        : std_logic                    := '1';
	signal rst_i        : std_logic                    := '1';
	signal data_i       : std_logic_vector(7 downto 0) := (others => '0');
	signal pull_o       : std_logic;
	signal data_ready_i : std_logic := '0';
	signal data_valid_o : std_logic;
	signal msg_block_o  : std_logic_vector(511 downto 0);
	signal start_i      : std_logic := '0';
	signal msg_length_i : integer   := 0;
	signal ready_o      : std_logic;

	-- Other constants
	constant clk_period : time := 20 ns;
	constant rst_delay  : time := clk_period * 5;

	signal s_i : integer := 100;
	signal testNum : integer := 0;

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	clk_i <= not clk_i after clk_period/2;
	rst_i <= '0' after rst_delay;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------

	process
		variable msg : string(1 to 43) := "The quick brown fox jumps over the lazy dog";
	begin
		wait for rst_delay;


		---test with length < 55---------------------------------------------------------------------
		testNum <= 1;
		msg_length_i <= 43;
		start_i      <= '1';

		for i in msg'range loop
			s_i <= i;
			wait until clk_i = '1';
			if (pull_o = '1') then
				data_i <= slv(msg(i));
			end if;

			if (i = 1) then
				start_i <= '0';
			end if;
		end loop;

		wait until data_valid_o = '1';
		data_ready_i <= '1';
		wait for clk_period;
		data_ready_i <= '0';

		assert msg_block_o = strToMsg(msg) 													report "FAIL 1" severity failure;
		report "Message 1 is sent";

		---test with length = 64---------------------------------------------------------------------
		testNum <= 2;
		msg_length_i <= 64;
		data_i       <= (others => '1');
		start_i      <= '1';
		wait for clk_period;
		start_i <= '0';

		wait until data_valid_o = '1';
		data_ready_i <= '1';
		wait for clk_period;
		data_ready_i <= '0';
		assert msg_block_o = max_vec(512) 													report "FAIL 2 1" severity failure;
		report "Block 1 in message 2 is sent";
		wait for clk_period;

		data_ready_i <= '1';
		wait until data_valid_o = '1';
		wait for clk_period;
		data_ready_i <= '0';

		assert msg_block_o(511) = '1' 														report "FAIL 2 2" severity failure;
		assert msg_block_o(510 downto 64) = zero_vec(510 - 64 + 1) 							report "FAIL 2 3" severity failure;
		assert msg_block_o(63 downto 0) = slv(msg_length_i*8, 64) 							report "FAIL 2 4" severity failure;
		report "Block 2 in message 2 is sent";

		---test with length = 0---------------------------------------------------------------------
		testNum <= 3;
		msg_length_i <= 0;
		start_i      <= '1';
		wait for clk_period;
		start_i <= '0';

		wait until data_valid_o = '1';
		data_ready_i <= '1';
		wait for clk_period;
		data_ready_i <= '0';

		assert msg_block_o(511) = '1'		 												report "FAIL 3 1" severity failure;
		assert msg_block_o(510 downto 64) = zero_vec(510 - 64 + 1) 							report "FAIL 3 2" severity failure;
		assert msg_block_o(63 downto 0) = slv(msg_length_i*8, 64) 							report "FAIL 3 3" severity failure;
		report "Message 3 is sent";

		----test with length > 64 + 55--------------------------------------------------------------------
		testNum <= 4;
		msg_length_i <= 64 + 56;
		data_i       <= (others => '1');
		start_i      <= '1';
		wait for clk_period;
		start_i <= '0';

		wait until data_valid_o = '1';
		data_ready_i <= '1';
		wait for clk_period;
		data_ready_i <= '0';
		assert msg_block_o = max_vec(512) 													report "FAIL 4 1" severity failure;
		report "Block 1 in message 4 is sent";
		wait for clk_period;

		data_ready_i <= '1';
		wait until data_valid_o = '1';
		wait for clk_period;
		data_ready_i <= '0';
		assert msg_block_o(511 downto 512 - 56*8) = max_vec(56*8) 							report "FAIL 4 2" severity failure;
		assert msg_block_o(512 - 56*8 - 1) = '1' 											report "FAIL 4 3" severity failure;
		assert msg_block_o(512 - 56*8 - 2 downto 0) = zero_vec(512 - 56*8 - 1) 				report "FAIL 4 4" severity failure;
		report "Block 2 in message 4 is sent";
		wait for clk_period*5;

		data_ready_i <= '1';
		assert data_valid_o = '1' 															report "FAIL 4 5" severity failure;
		wait for clk_period;
		data_ready_i <= '0';
		assert msg_block_o(511 downto 64) = zero_vec(512 - 64) 								report "FAIL 4 6" severity failure;
		assert msg_block_o(63 downto 0) = slv(msg_length_i*8, 64) 							report "FAIL 4 7" severity failure;
		report "Block 3 in message 4 is sent";

		assert false 																		report "SUCCESS" severity failure;
		wait;
	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : sha1_loader
		port map (
			clk_i        => clk_i,
			rst_i        => rst_i,
			data_i       => data_i,
			pull_o       => pull_o,
			data_ready_i => data_ready_i,
			data_valid_o => data_valid_o,
			msg_block_o  => msg_block_o,
			start_i      => start_i,
			msg_length_i => msg_length_i,
			ready_o      => ready_o
		);

end architecture testbench;