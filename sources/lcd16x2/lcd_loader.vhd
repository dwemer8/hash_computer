library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.lcd_pkg.all;

entity lcd_loader is
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;

		data_valid_i : in std_logic;
		data_ready_o : out std_logic;
		data_type_i : in std_logic_vector(1 downto 0);
		data_i : in std_logic_vector(255 downto 0);

		rw_o, rs_o, e_o : out std_logic;
		lcd_data_o : out std_logic_vector(7 downto 0)
	);
end lcd_loader;

architecture lcd_loader_arch of lcd_loader is
	component lcd_controller is
		generic (
			clk_freq       : INTEGER   := 50;
			display_lines  : STD_LOGIC := '1';
			character_font : STD_LOGIC := '0';
			display_on_off : STD_LOGIC := '1';
			cursor         : STD_LOGIC := '0';
			blink          : STD_LOGIC := '0';
			inc_dec        : STD_LOGIC := '1';
			shift          : STD_LOGIC := '0'
		);
		port (
			clk        : IN  STD_LOGIC;
			reset_n    : IN  STD_LOGIC;
			lcd_enable : IN  STD_LOGIC;
			lcd_bus    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
			busy       : OUT STD_LOGIC := '1';
			rw, rs, e  : OUT STD_LOGIC;
			lcd_data   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	end component;

	constant clk_freq       : INTEGER   := 50;
	constant ctrl_display_lines  : STD_LOGIC := '1';
	constant ctrl_character_font : STD_LOGIC := '0';
	constant ctrl_display_on_off : STD_LOGIC := '1';
	constant ctrl_cursor         : STD_LOGIC := '0';
	constant ctrl_blink          : STD_LOGIC := '0';
	constant ctrl_inc_dec        : STD_LOGIC := '1';
	constant ctrl_shift          : STD_LOGIC := '0';

	constant space_code : std_logic_vector(7 downto 0) := b"1111_1110";
	constant char_delay : integer := 500 * 1000 * clk_freq; -- 0,5 s
	constant end_delay : integer := 3 * 1000 * 1000 * clk_freq; -- 3 s

	signal ctrl_reset_n    : STD_LOGIC := '0';
	signal ctrl_lcd_enable : STD_LOGIC := '0';
	signal ctrl_lcd_bus    : STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
	signal ctrl_busy       : STD_LOGIC;

	type state_type is (screen_loading, delay);
	type screen_type is array (0 to 31) of std_logic_vector(3 downto 0);
	type char_loading_state_type is (char_address, char_data);
	type rec_type is record
		state : state_type;
		data : std_logic_vector(255 downto 0);
		data_type : std_logic_vector(1 downto 0);
		start_shift : integer;
		screen_buffer : screen_type;
		char_cnt: integer;
		delay_cnt: integer;
		lcd_bus : std_logic_vector(9 DOWNTO 0);
		screen_address : std_logic_vector(6 downto 0);
		char_loading_state : char_loading_state_type;
		ready : std_logic;
	end record;
	constant rst_rec : rec_type := (screen_loading,
									(others => '0'),
									(others => '0'),
									0,
									(others => (others => '0')),
									0,
									char_delay,
									(others => '0'),
									(others => '0'),
									char_address,
									'0'
									);
	signal rec, rec_in : rec_type := rst_rec;

	function charCode(val : std_logic_vector(3 downto 0)) return std_logic_vector is
	begin
		if (unsigned(val) <= 9) then return ("0011" & val);
		else return ("0100" & slv(uns(val) - uns(9, 4)));
		end if;
	end function;

	function plusOne (val : std_logic_vector) return std_logic_vector is
	begin
		return slv(uns(val) + uns(1, val'length));
	end function;

	function nextAddress (address : std_logic_vector) return std_logic_vector is
	begin
		case (address) is
		when b"000_1111" =>
			return b"100_0000";
		when b"100_1111" =>
			return b"000_0000";
		when others =>
			return plusOne(address);
		end case;
	end function;

	--procedure screenBufLoad (
	--	data : in std_logic_vector(255 downto 0);
	--	start_shift : in integer;
	--	screen_buffer : out screen_type
	--) is
	--begin
	--	if (start_shift >= 0 and start_shift <= 32) then
	--		screen_init_loop : for i in 0 to 31 loop
	--			screen_buffer(i) := data(255 - start_shift*4 - i*4 downto 252 - start_shift*4 - i*4);
	--		end loop;
	--	else
	--		assert false report "Unvalid shift" severity failure;
	--	end if;
	--end procedure screenBufLoad;

begin

	ctrl_lcd_bus <= rec_in.lcd_bus;
	ctrl_reset_n <= not rst_i;
	data_ready_o <= rec.ready;

	process(clk_i)
	begin
		if (rising_edge(clk_i)) then
			if (rst_i = '1') then
				rec <= rst_rec;
			else
				rec <= rec_in;
				if (ctrl_busy = '0') then
					rec.ready <= '1';
				end if;
			end if;
		end if;
	end process;

	process(rec, data_valid_i, data_type_i, data_i, ctrl_busy)
		variable var : rec_type := rst_rec;

	begin
		var := rec;
		ctrl_lcd_enable <= '0';

		if (data_valid_i = '1' and rec.ready = '1') then
			var := rst_rec;
			var.ready := '1';
			var.data := data_i;
			var.data_type := data_type_i;
			--screenBufLoad(data_i, 0, var.screen_buffer);

			for i in 0 to 31 loop
				var.screen_buffer(i) := data_i(255 - i*4 downto 252 - i*4);
			end loop;
			var.start_shift := 1;

			var.state := screen_loading;
		end if;	

		case (rec.state) is
		when screen_loading =>
			if (ctrl_busy = '0') then
				case rec.char_loading_state is
				when char_address =>
					var.lcd_bus := "001" & rec.screen_address;
					ctrl_lcd_enable <= '1';
					var.screen_address := nextAddress(rec.screen_address);
					var.char_loading_state := char_data;

				when char_data =>
					if (rec.data_type = "00" and rec.char_cnt >= 8) then
						var.lcd_bus := "10" & space_code;
					else
						var.lcd_bus := "10" & charCode(var.screen_buffer(rec.char_cnt));
					end if;
					ctrl_lcd_enable <= '1';
					var.char_loading_state := char_address;

					var.char_cnt := rec.char_cnt + 1;
					if (rec.char_cnt = 31) then
						var.char_cnt := 0;
						var.state := delay;
					end if; 
				end case;
			end if;

		when delay => 
			var.delay_cnt := rec.delay_cnt - 1;
			if (rec.delay_cnt = 0) then
				var.delay_cnt := char_delay;
				--screenBufLoad(rec.data, rec.start_shift, var.screen_buffer);

				for i in 0 to 31 loop
					var.screen_buffer(i) := rec.data(255 - rec.start_shift*4 - i*4 downto 252 - rec.start_shift*4 - i*4);
				end loop;
				var.start_shift := rec.start_shift + 1;
				var.state := screen_loading;

				case (rec.data_type) is
				when "00" => --crc32	32 / 4 = 8 characters
					var.start_shift := 0;

				when "01" => --sha1 	160 / 4 = 40 characters
					if (rec.start_shift = 7) then
						var.delay_cnt := end_delay;
					elsif (rec.start_shift = 8) then
						var.start_shift := 0;
					end if;

				when "10" => --sha256	256 / 4 = 64 characters
					if (rec.start_shift = 31) then
						var.delay_cnt := end_delay;
					elsif (rec.start_shift = 32) then
						var.start_shift := 0;
					end if;

				when others =>
					assert false report "Unknown data type" severity failure;
				end case;
			end if;
			
		when others =>
			assert false report "Unknown state" severity failure;
		end case;

		rec_in <= var;
	end process;

	lcd_controller_1 : lcd_controller
		generic map (
			clk_freq       => clk_freq,
			display_lines  => ctrl_display_lines,
			character_font => ctrl_character_font,
			display_on_off => ctrl_display_on_off,
			cursor         => ctrl_cursor,
			blink          => ctrl_blink,
			inc_dec        => ctrl_inc_dec,
			shift          => ctrl_shift
		)
		port map (
			clk        => clk_i,
			reset_n    => ctrl_reset_n,
			lcd_enable => ctrl_lcd_enable,
			lcd_bus    => ctrl_lcd_bus,
			busy       => ctrl_busy,
			rw         => rw_o,
			rs         => rs_o,
			e          => e_o,
			lcd_data   => lcd_data_o
		);	
	
end architecture lcd_loader_arch;