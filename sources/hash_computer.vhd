--Устройство ретранслирует сообщения по интерфейсу UART (максимальная длина
--сообщения 10Кбайт) и вычисляет хеш-сумму ретранслированных данных по алгоритмам
--CRC32, SHA-1, SHA-2 (SHA256). Значение хеш-функции выводится на LCD16x2,
--переключение осуществляется с помощью кнопок.

--Сначало устройство, находясь в состоянии ретрансляции, считывает через UART_rx сообщение, запоминая его в FIFO_8x10240_mod и ретранcлируя через UART_tx. 
--По кнопке start_comp_i устройство переходит в состояние вычисления хеша, какой хеш вычисляется, зависит от режима вычисления. 
--В модуль crc32 данные обрабатываемого сообщения из FIFO загружаются топ-модулем, для остальных вычислителей написаны загрузчики-препроцессоры.
--После вычисления устройство переходит в состояние отображения, топ-модуль загружает вычисленное значения хеша в lcd_loader. 
--В этом состоянии могут быть осуществлены либо переключение режима кнопкой switch_mode_i, тогда устройство вернется в состояние вычисления, 
--где будет считать новый хеш, а после его отобразит, либо в переход состояние ретрансляции, если начать передавать по UART новые данные.

--На кнопках start_comp_i и switch_mode_i висят устранители дребезга.

library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std;

 entity hash_computer is
 	generic ( FREQUENCY : integer := 50; --MHz
              BAUDRATE : integer := 19200;
              BYTE_SIZE : integer := 8;
              CRC32_INIT : std_logic_vector(31 downto 0) := x"FFFFFFFF";
              CRC32_XOROUT : std_logic_vector(31 downto 0) := x"FFFFFFFF"
            );
 	port (
 			clk_i : in std_logic;
 			--buttons
 			rst_i : in std_logic;
 			start_comp_i : in std_logic;
 			switch_mode_i : in std_logic;
 			--connection
            uart_rx_i : in std_logic;
            uart_tx_o : out std_logic;
            --lcd
            rw_o, rs_o, e_o : out std_logic;
			lcd_data_o      : out std_logic_vector(7 downto 0);
			--led
			ready_o : out std_logic
 		);
 end entity hash_computer;

 architecture rtl of hash_computer is

 	constant clearing_delay : integer := 10 * 1000 * FREQUENCY;

	signal clear_start_comp, clear_switch_mode : std_logic := '0';

	signal rx_busy  : STD_LOGIC;
	signal rx_error : std_logic;
	signal rx_data  : STD_LOGIC_VECTOR (BYTE_SIZE - 1 downto 0);

	signal tx_busy : STD_LOGIC;
	signal tx_load : STD_LOGIC;
	signal tx_data : STD_LOGIC_VECTOR (BYTE_SIZE-1 downto 0);	

	signal fifo_rAddrRst  : std_logic;
	signal fifo_rStartSet : std_logic;
	signal fifo_dataIn    : STD_LOGIC_VECTOR (BYTE_SIZE - 1 downto 0);
	signal fifo_dataOut   : STD_LOGIC_VECTOR (BYTE_SIZE - 1 downto 0);
	signal fifo_push      : STD_LOGIC;
	signal fifo_pop       : STD_LOGIC;
	signal fifo_isFull    : STD_LOGIC;
	signal fifo_isEmpty   : STD_LOGIC;

	signal crc32_rst        : STD_LOGIC;
	signal crc32_data_valid : STD_LOGIC;
	signal crc32_data       : STD_LOGIC;
	signal crc32_checksum   : STD_LOGIC_VECTOR (31 downto 0);		

	signal sha1_data_ready : std_logic;
	signal sha1_data_valid : std_logic;
	signal sha1_msg_block  : std_logic_vector(511 downto 0);

	signal sha1_ldr_data       : std_logic_vector(7 downto 0);
	signal sha1_ldr_pull       : std_logic;
	signal sha1_ldr_start      : std_logic;
	signal sha1_ldr_msg_length : integer;
	signal sha1_ldr_ready      : std_logic;	

	signal sha1_core_rst        : std_logic;
	signal sha1_core_digest     : std_logic_vector(159 downto 0);	

	signal sha256_data_ready   : std_logic;
	signal sha256_data_valid   : std_logic;
	signal sha256_word_address : std_logic_vector(3 downto 0);
	signal sha256_msg_word     : std_logic_vector(31 downto 0);

	signal sha256_ldr_data         : std_logic_vector(7 downto 0);
	signal sha256_ldr_pull         : std_logic;
	signal sha256_ldr_start        : std_logic;
	signal sha256_ldr_msg_length   : integer;
	signal sha256_ldr_ready        : std_logic;	

	signal sha256_core_rst        : std_logic;
	signal sha256_core_enable       : std_logic;
	signal sha256_core_hash  : std_logic_vector(255 downto 0);
	signal sha256_core_debug_port   : std_logic_vector(31 downto 0);	

	signal lcd_data_valid    : std_logic;
	signal lcd_data_ready    : std_logic;
	signal lcd_data_type     : std_logic_vector(1 downto 0);
	signal lcd_data          : std_logic_vector(255 downto 0);	

	type state_type is (retranslation, calculation, showing);
	type calc_state_type is (crc32, sha1, sha256);
	type rec_type is record
		state : state_type;
		calc_state : calc_state_type;
		start_comp, switch_mode : std_logic;
		msg_length : integer;
		rx_busy, to_process : std_logic;
		data_buf : std_logic_vector(BYTE_SIZE - 1 downto 0);
		crc32_cnt : integer;
		sha1_cnt : integer;
		sha256_cnt : integer;
		hash_buf : std_logic_vector(255 downto 0);
		lcd_cnt : integer;
	end record;	
	constant rst_rec : rec_type := (retranslation,
									crc32,
									'0', '0',
									0,
									'0', '0',
									(others => '0'),
									0,
									0,
									0,
									(others => '0'),
									0
									);
	signal rec, rec_in : rec_type := rst_rec;

 begin
 
	signals_cleaning : process(clk_i)
		variable start_comp_cnt, switch_mode_cnt : integer := 0;
	begin
		if (rising_edge(clk_i)) then
			if (start_comp_cnt = 0) then
				if (start_comp_i = '1') then
					start_comp_cnt := start_comp_cnt + 1;

				else
					clear_start_comp <= '0';
				end if;
			else
				start_comp_cnt := start_comp_cnt + 1;

				if (start_comp_cnt = clearing_delay and start_comp_i = '1') then --10 ms
					start_comp_cnt := 0;
					clear_start_comp <= '1';
				end if;
			end if;

			if (switch_mode_cnt = 0) then
				if (switch_mode_i = '1') then
					switch_mode_cnt := switch_mode_cnt + 1;
					
				else
					clear_switch_mode <= '0';
				end if;
			else
				switch_mode_cnt := switch_mode_cnt + 1;

				if (switch_mode_cnt = clearing_delay and switch_mode_i = '1') then --10 ms
					switch_mode_cnt := 0;
					clear_switch_mode <= '1';
				end if;
			end if;
		end if;
	end process;

	process(clk_i)
	begin
		if (rising_edge(clk_i)) then
			if (rst_i = '1') then
				rec <= rst_rec;

			else
				rec <= rec_in;
			end if;
		end if;
	end process;

	process(rec, 
			rst_i, clear_start_comp, clear_switch_mode, 
			rx_busy, tx_busy, 
			fifo_isEmpty, 
			sha1_ldr_ready, sha1_data_ready, 
			sha256_ldr_ready, sha256_data_ready, 
			lcd_data_ready)
		variable var : rec_type := rst_rec;

	begin
		tx_load <= '0';

		fifo_push <= '0';
		fifo_pop <= '0';
		fifo_rAddrRst <= '0';
		fifo_rStartSet <= '0';

		crc32_rst <= rst_i;
		crc32_data_valid <= '0';
		crc32_data <= '0';

		sha1_ldr_start <= '0';
		sha1_ldr_msg_length <= 0;
		sha1_core_rst <= rst_i;

		sha256_ldr_start <= '0';
		sha256_ldr_msg_length <= 0;
		sha256_core_rst <= rst_i;

		lcd_data_valid <= '0';

		ready_o <= '0';

		var := rec;
		var.rx_busy := rx_busy;
		var.start_comp := clear_start_comp;
		var.switch_mode := clear_switch_mode;

		case (rec.state) is
		when retranslation =>
			if(rx_busy = '0' and rec.rx_busy = '1') then
				var.to_process := '1';
				var.data_buf := rx_data;
			end if;

			if (tx_busy = '0' and rec.to_process = '1') then
				tx_load <= '1';
				fifo_push <= '1';
				var.msg_length := rec.msg_length + 1;
				var.to_process := '0';
			end if;

			if (clear_start_comp = '1' and rec.start_comp = '0') then
				var.state := calculation;
			end if;

		when calculation => 
			case (rec.calc_state) is
			when crc32 =>
				if (fifo_isEmpty = '0') then
					var.crc32_cnt := rec.crc32_cnt + 1;

					if (rec.crc32_cnt = 0) then
						fifo_pop <= '1';
						crc32_rst <= '1';
						
					elsif (rec.crc32_cnt = 1) then
						var.data_buf := fifo_dataOut;
						crc32_data <= var.data_buf(BYTE_SIZE - 1);
						crc32_data_valid <= '1';

					elsif (rec.crc32_cnt <= 8) then
						crc32_data <= var.data_buf(BYTE_SIZE - rec.crc32_cnt);
						crc32_data_valid <= '1';

						if (rec.crc32_cnt = 8) then
							fifo_pop <= '1';
							var.crc32_cnt := 1;
						end if;
					end if;
				else
					var.crc32_cnt := 0;
					var.hash_buf := (others => '0');
					var.hash_buf(255 downto 224) := crc32_checksum;
					var.state := showing;
				end if;

			when sha1 =>
				if (rec.sha1_cnt = 0) then
					sha1_ldr_msg_length <= rec.msg_length;
					sha1_ldr_start <= '1';
					sha1_core_rst <= '1';
					var.sha1_cnt := 1;

				else
					fifo_pop <= sha1_ldr_pull;

					if (sha1_ldr_ready = '1' and sha1_data_ready = '1') then
						var.sha1_cnt := 0;
						var.hash_buf := (others => '0');
						var.hash_buf(255 downto 96) := sha1_core_digest;
						var.state := showing;
					end if;
				end if;

			when sha256 =>
				if (rec.sha256_cnt = 0) then
					sha256_ldr_msg_length <= rec.msg_length;
					sha256_ldr_start <= '1';
					sha256_core_rst <= '1';
					var.sha256_cnt := 1;

				else
					fifo_pop <= sha256_ldr_pull;

					if (sha256_ldr_ready = '1' and sha256_data_ready = '1') then
						var.sha256_cnt := 0;
						var.hash_buf := (others => '0');
						var.hash_buf := sha256_core_hash;
						var.state := showing;
					end if;
				end if;
				
			when others =>
				assert false report "Unknown calculation type" severity failure;
			end case;

		when showing =>
			ready_o <= '1';

			if (rec.lcd_cnt = 0) then
				lcd_data_valid <= '1';
				var.lcd_cnt := rec.lcd_cnt + 1;

			elsif (rec.lcd_cnt = 1) then
				lcd_data_valid <= '1';

				if (lcd_data_ready = '1') then
					var.lcd_cnt := rec.lcd_cnt + 1;
				end if;
			end if;

			if (clear_switch_mode = '1' and rec.switch_mode = '0') then
				fifo_rAddrRst <= '1';
				var.lcd_cnt := 0;
				var.state := calculation;

				case (rec.calc_state) is
				when crc32 =>
					var.calc_state := sha1;

				when sha1 =>
					var.calc_state := sha256;

				when sha256 =>	
					var.calc_state := crc32;

				when others =>
					assert false report "Unknown calculation type" severity failure;
				end case;
			end if;

			if (rx_busy = '0' and rec.rx_busy = '1') then				
				var.to_process := '1';
				var.data_buf := rx_data;

				fifo_rStartSet <= '1';
				var.lcd_cnt := 0;
				var.state := retranslation;
			end if;

		when others =>
			assert false report "Unknown state" severity failure;
		end case;

		rec_in <= var;
	end process;

	tx_data <= rec_in.data_buf;
	fifo_dataIn <= rec_in.data_buf;
	sha1_ldr_data <= fifo_dataOut;
	sha256_ldr_data <= fifo_dataOut;
	sha256_core_enable <= '1';
	lcd_data <= rec_in.hash_buf;
	with rec.calc_state select lcd_data_type <= "00" when crc32,
												"01" when sha1,
												"10" when sha256;

	UART_rx_1 : entity work.UART_rx
		generic map (
			FREQUENCY => FREQUENCY,
			BAUDRATE  => BAUDRATE,
			BYTE_SIZE => BYTE_SIZE
		)
		port map (
			clk_i      => clk_i,
			rst_i      => rst_i,
			rx_i       => uart_rx_i,
			rx_busy_o  => rx_busy,
			rx_error_o => rx_error,
			rx_data_o  => rx_data
		);	

	UART_tx_1 : entity work.UART_tx
		generic map (
			FREQUENCY => FREQUENCY,
			BAUDRATE  => BAUDRATE,
			BYTE_SIZE => BYTE_SIZE
		)
		port map (
			Clk_i     => clk_i,
			Rst_i     => rst_i,
			Tx_o      => uart_tx_o,
			Tx_busy_o => tx_busy,
			Tx_load_i => tx_load,
			Tx_data_i => tx_data
		);	

	FIFO_8x10240_mod_1 : entity work.FIFO_8x10240_mod
		generic map (
			DATA_WIDTH => BYTE_SIZE
		)
		port map (
			clk       => clk_i,
			rst       => rst_i,
			rAddrRst  => fifo_rAddrRst,
			rStartSet => fifo_rStartSet,
			dataIn    => fifo_dataIn,
			dataOut   => fifo_dataOut,
			push      => fifo_push,
			pop       => fifo_pop,
			isFull    => fifo_isFull,
			isEmpty   => fifo_isEmpty
		);	

	CRC32_1 : entity work.CRC32
		generic map (
			INIT   => CRC32_INIT,
			XOROUT => CRC32_XOROUT
		)
		port map (
			clk_i        => clk_i,
			rst_i        => crc32_rst,
			data_valid_i => crc32_data_valid,
			data_i       => crc32_data,
			checksum_o   => crc32_checksum
		);	

	sha1_loader_1 : entity work.sha1_loader
		port map (
			clk_i        => clk_i,
			rst_i        => rst_i,
			data_i       => sha1_ldr_data,
			pull_o       => sha1_ldr_pull,
			data_ready_i => sha1_data_ready,
			data_valid_o => sha1_data_valid,
			msg_block_o  => sha1_msg_block,
			start_i      => sha1_ldr_start,
			msg_length_i => sha1_ldr_msg_length,
			ready_o      => sha1_ldr_ready
		);	

	SHA1_core_1 : entity work.SHA1_core
		port map (
			clk_i        => clk_i,
			rst_i        => sha1_core_rst,
			msg_block_i  => sha1_msg_block,
			data_valid_i => sha1_data_valid,
			digest_o     => sha1_core_digest,
			data_ready_o => sha1_data_ready
		);	
	
	sha256_loader_1 : entity work.sha256_loader
		port map (
			clk_i          => clk_i,
			rst_i          => rst_i,
			data_i         => sha256_ldr_data,
			pull_o         => sha256_ldr_pull,
			data_ready_i   => sha256_data_ready,
			data_valid_o   => sha256_data_valid,
			word_address_i => sha256_word_address,
			msg_word_o     => sha256_msg_word,
			start_i        => sha256_ldr_start,
			msg_length_i   => sha256_ldr_msg_length,
			ready_o        => sha256_ldr_ready
		);

	sha256_core_1 : entity work.sha256_core
		port map (
			clk          => clk_i,
			reset        => sha256_core_rst,
			enable       => sha256_core_enable,
			ready        => sha256_data_ready,
			update       => sha256_data_valid,
			word_address => sha256_word_address,
			word_input   => sha256_msg_word,
			hash_output  => sha256_core_hash,
			debug_port   => sha256_core_debug_port
		);		

	lcd_loader_1 : entity work.lcd_loader
		port map (
			clk_i        => clk_i,
			rst_i        => rst_i,
			data_valid_i => lcd_data_valid,
			data_ready_o => lcd_data_ready,
			data_type_i  => lcd_data_type,
			data_i       => lcd_data,
			rw_o         => rw_o,
			rs_o         => rs_o,
			e_o          => e_o,
			lcd_data_o   => lcd_data_o
		);	

 end rtl;



