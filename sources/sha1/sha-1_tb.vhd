--Тестбенч для SHA1_core и sha1_loader. Проверяет правильность вычисления sha1 сообщений различной длины.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sha1_pkg.all;

entity sha1_tb is
	
end entity sha1_tb;

architecture behavior of sha1_tb is

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

	component sha1_loader is
		port (
			clk_i        : in  std_logic;
			rst_i        : in  std_logic;
			data_i       : in  std_logic_vector(7 downto 0);
			pull_o       : out std_logic;
			data_ready_i : in  std_logic;
			data_valid_o : out std_logic;
			msg_block_o  : out std_logic_vector(511 downto 0);
			start_i      : in  std_logic;
			msg_length_i : in  integer;
			ready_o      : out std_logic
		);
	end component;	

	signal clk_i       : std_logic := '1';
	signal msg_block : std_logic_vector(511 downto 0);
	signal data_ready : std_logic;
	signal data_valid : std_logic;
	
	signal core_rst_i       : std_logic := '1';
	signal core_digest_o    : std_logic_vector(159 downto 0);

	signal loader_rst_i		: std_logic := '1';
	signal loader_start_i     : std_logic := '0';
	signal loader_data_i       : std_logic_vector(7 downto 0) := (others => '0');
	signal loader_pull_o       : std_logic;
	signal loader_msg_length_i : integer := 0;
	signal loader_ready_o      : std_logic;

	signal s_i : integer := 100;
	signal testNum : integer := 100;

	constant clk_period : time := 20 ns;
	constant rst_delay : time := clk_period * 2;	

	constant msg1 : string(1 to 43) := "The quick brown fox jumps over the lazy dog";
	constant msg2 : string(1 to 63) := "1111111 1111111 1111111 1111111 1111111 1111111 1111111 1111111";
	constant msg3 : string(1 to 64) := "1111111 1111111 1111111 1111111 1111111 1111111 1111111 1111111 ";
	constant msg4 : string(1 to 72) := "1111111 1111111 1111111 1111111 1111111 1111111 1111111 1111111 1111111 ";

begin

	clk_i <= not clk_i after clk_period/2;
		
	process	   
	begin
		core_rst_i <= '1';
		loader_rst_i <= '1';
		wait for rst_delay;
		core_rst_i <= '0';
		loader_rst_i <= '0';

		--msg length = 0----------------------------------------------------------------------
		testNum <= 0;
		core_rst_i <= '1';
		wait for clk_period;
		core_rst_i <= '0';
		loader_msg_length_i <= 0;
		loader_start_i      <= '1';
		wait for clk_period;
		loader_start_i      <= '0';

		wait until data_ready = '1';
		wait for clk_period;
		assert core_digest_o = x"da39a3ee_5e6b4b0d_3255bfef_95601890_afd80709" report "FAIL 0" severity failure;
		report "Hash 0 is calculated";

		--msg length <= 55----------------------------------------------------------------------
		testNum <= 1;
		core_rst_i <= '1';
		wait for clk_period;
		core_rst_i <= '0';
		loader_msg_length_i <= msg1'length;
		loader_start_i      <= '1';
		for i in msg1'range loop
			s_i <= i;
			wait until clk_i = '1';
			if (loader_pull_o = '1') then
				loader_data_i <= slv(msg1(i));
			end if;

			if (i = 1) then
				loader_start_i <= '0';
			end if;
		end loop;

		wait until data_ready = '1';
		wait for clk_period;
		assert core_digest_o = x"2fd4e1c6_7a2d28fc_ed849ee1_bb76e739_1b93eb12" report "FAIL 1" severity failure;
		report "Hash 1 is calculated";

		--56 <= msg length <= 63----------------------------------------------------------------------
		testNum <= 2;
		core_rst_i <= '1';
		wait for clk_period;
		core_rst_i <= '0';
		loader_msg_length_i <= msg2'length;
		loader_start_i      <= '1';
		for i in msg2'range loop
			s_i <= i;
			wait until clk_i = '1';
			if (loader_pull_o = '1') then
				loader_data_i <= slv(msg2(i));
			end if;

			if (i = 1) then
				loader_start_i <= '0';
			end if;
		end loop;

		wait until data_ready = '1';
		wait until data_ready = '1';
		wait for clk_period;
		assert core_digest_o = x"edac1be8_2f7b7b9c_547a0328_742e09b3_5e44ef7d" report "FAIL 2" severity failure;
		report "Hash 2 is calculated";

		--msg length = 64----------------------------------------------------------------------
		testNum <= 3;
		core_rst_i <= '1';
		wait for clk_period;
		core_rst_i <= '0';
		loader_msg_length_i <= msg3'length;
		loader_start_i      <= '1';
		for i in msg3'range loop
			s_i <= i;
			wait until clk_i = '1';
			if (loader_pull_o = '1') then
				loader_data_i <= slv(msg3(i));
			end if;

			if (i = 1) then
				loader_start_i <= '0';
			end if;
		end loop;

		wait until data_ready = '1';
		wait until data_ready = '1';
		wait for clk_period;
		assert core_digest_o = x"b7949a7c_2b5551d6_099fea77_142e7d89_99efb0bd" report "FAIL 3" severity failure;
		report "Hash 3 is calculated";

		--msg length > 64----------------------------------------------------------------------
		testNum <= 4;
		core_rst_i <= '1';
		wait for clk_period;
		core_rst_i <= '0';
		loader_msg_length_i <= msg4'length;
		loader_start_i      <= '1';
		for i in 1 to 64 loop
			s_i <= i;
			wait until clk_i = '1';
			if (loader_pull_o = '1') then
				loader_data_i <= slv(msg4(i));
			end if;

			if (i = 1) then
				loader_start_i <= '0';
			end if;
		end loop;

		wait until loader_pull_o = '1';
		wait until loader_pull_o = '1'; --caused by instability of signal in simulation due to zero latencies
		for i in 65 to msg4'length loop
			s_i <= i;
			wait until clk_i = '1';
			if (loader_pull_o = '1') then
				loader_data_i <= slv(msg4(i));
			end if;
		end loop;

		wait until data_ready = '1';
		wait for clk_period;
		assert core_digest_o = x"2049f342_044adc72_a93cd356_6681649f_2dac57cc" report "FAIL 4" severity failure;
		report "Hash 4 is calculated";

		assert false report "SUCCESS" severity failure; 
		wait;
	end process;

	SHA1_core_1 : SHA1_core
		port map (
			clk_i       => clk_i,
			rst_i       => core_rst_i,
			msg_block_i => msg_block,
			data_valid_i     => data_valid,
			digest_o    => core_digest_o,
			data_ready_o     => data_ready
		);

	sha1_loader_1 : sha1_loader
		port map (
			clk_i        => clk_i,
			rst_i        => loader_rst_i,
			data_i       => loader_data_i,
			pull_o       => loader_pull_o,
			data_ready_i => data_ready,
			data_valid_o => data_valid,
			msg_block_o  => msg_block,
			start_i      => loader_start_i,
			msg_length_i => loader_msg_length_i,
			ready_o      => loader_ready_o
		);		
	
end architecture;