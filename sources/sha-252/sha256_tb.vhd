--Тестбенч проверки работоспособности sha256_core и sha256_loader. Проверяет правильность вычисления хешей для сообщений различной длины.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sha256_loaderAndTb_pkg.all;

entity sha256_tb is
	
end entity sha256_tb;

architecture behavior of sha256_tb is

	component sha256_core is
		port (
			clk          : in  std_logic;
			reset        : in  std_logic;
			enable       : in  std_logic;
			ready        : out std_logic;
			update       : in  std_logic;
			word_address : out std_logic_vector(3 downto 0);
			word_input   : in  std_logic_vector(31 downto 0);
			hash_output  : out std_logic_vector(255 downto 0);
			debug_port   : out std_logic_vector(31 downto 0)
		);
	end component;		

	component sha256_loader is
		port (
			clk_i          : in  std_logic;
			rst_i          : in  std_logic;
			data_i         : in  std_logic_vector(7 downto 0);
			pull_o         : out std_logic;
			data_ready_i   : in  std_logic;
			data_valid_o   : out std_logic;
			word_address_i : in  std_logic_vector(3 downto 0);
			msg_word_o     : out std_logic_vector(31 downto 0);
			start_i        : in  std_logic;
			msg_length_i   : in  integer;
			ready_o        : out std_logic
		);
	end component sha256_loader;		

	signal clk_i       : std_logic := '1';
	signal data_ready : std_logic;
	signal data_valid : std_logic;
	signal word_address : std_logic_vector(3 downto 0);
	signal word : std_logic_vector(31 downto 0);
	
	signal core_rst_i       : std_logic := '1';
	signal core_enable_i 		: std_logic := '1';
	signal core_digest_o    : std_logic_vector(255 downto 0);
	signal core_debug_port_o		: std_logic_vector(31 downto 0);

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
		assert core_digest_o = x"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" report "FAIL 0" severity failure;
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
		assert core_digest_o = x"d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592" report "FAIL 1" severity failure;
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

		wait until data_ready = '1'; --for the first block
		wait until data_ready = '1'; --final value
		wait for clk_period;
		assert core_digest_o = x"876337f0af55e3bb7666d5858b11513b9fdb288f595c3fd77b1b6ff2ea0a7bdc" report "FAIL 2" severity failure;
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

		wait until data_ready = '1'; --for the first block
		wait until data_ready = '1'; --final value
		wait for clk_period;
		assert core_digest_o = x"b0dbe7c1f2e4ec8b7c4297d731ba12117f8434a1b8d04cffaa84de3a562d88b9" report "FAIL 3" severity failure;
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
		for i in 65 to msg4'length loop
			s_i <= i;
			wait until clk_i = '1';
			if (loader_pull_o = '1') then
				loader_data_i <= slv(msg4(i));
			end if;
		end loop;

		wait until data_ready = '1';
		wait for clk_period;
		assert core_digest_o = x"bee5756b629d63b69d80c59fc4977b85ca02d03498d82f43bdab354fd37a61d7" report "FAIL 4" severity failure;
		report "Hash 4 is calculated";

		assert false report "SUCCESS" severity failure; 
		wait;
	end process;

	sha256_core_1 : sha256_core
		port map (
			clk          => clk_i,
			reset        => core_rst_i,
			enable       => core_enable_i,
			ready        => data_ready,
			update       => data_valid,
			word_address => word_address,
			word_input   => word,
			hash_output  => core_digest_o,
			debug_port   => core_debug_port_o
		);		

	sha256_loader_1 : sha256_loader
		port map (
			clk_i          => clk_i,
			rst_i          => loader_rst_i,
			data_i         => loader_data_i,
			pull_o         => loader_pull_o,
			data_ready_i   => data_ready,
			data_valid_o   => data_valid,
			word_address_i => word_address,
			msg_word_o     => word,
			start_i        => loader_start_i,
			msg_length_i   => loader_msg_length_i,
			ready_o        => loader_ready_o
		);	
	
end architecture;