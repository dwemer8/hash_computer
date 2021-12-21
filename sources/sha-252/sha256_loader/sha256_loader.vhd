library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.sha256_loaderAndTb_pkg.all;

entity sha256_loader is
	port (
		--common
		clk_i : in std_logic;
		rst_i : in std_logic;

		--to memory
		data_i : in std_logic_vector(7 downto 0);
		pull_o : out std_logic;

		--to sha256
		data_ready_i : in std_logic;
		data_valid_o : out std_logic;
		word_address_i : in std_logic_vector(3 downto 0);
		msg_word_o : out std_logic_vector(31 downto 0);

		--to top module
		start_i : in std_logic;
		msg_length_i : in integer; --in bytes
		ready_o : out std_logic		
	);
end sha256_loader;

architecture sha256_loader_arc of sha256_loader is

	type state_type is (idle, reading, padding, loading, waiting);
	type rec_type is record
		state : state_type;
		msg_block : std_logic_vector(511 downto 0);
		msg_length, msg_rem_length : integer;
		cnt : integer;
		waitFlag, notPutOneFlag : std_logic;
	end record;

	constant rst_rec : rec_type := (state => idle,
									msg_block => (others => '0'),
									msg_length => 0,
									msg_rem_length => 0,
									cnt => 0,
									waitFlag => '0',
									notPutOneFlag => '0'
									);
	signal rec, rec_in : rec_type := rst_rec;

begin

	process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			if rst_i = '1' then 
				rec <= rst_rec;

			else
				rec <= rec_in;
			end if;
		end if;
	end process;

	process (rec, start_i, data_i, msg_length_i, data_ready_i, word_address_i)
		variable var : rec_type := rst_rec;
	begin
		ready_o <= '0';
		pull_o <= '0';
		data_valid_o <= '0';
		msg_word_o <= (others => '0');
		var := rec;

		case (rec.state) is
			when idle =>
				ready_o <= '1';

				if (start_i = '1') then
					ready_o <= '0';
					var.msg_length := msg_length_i;
					var.msg_rem_length := msg_length_i;
					var.msg_block := (others => '0');

					if (msg_length_i /= 0) then
						pull_o <= '1';
						var.state := reading;
					else
						var.state := padding;
					end if;
				end if;

			when reading =>
				if (rec.cnt < 63 and rec.cnt < rec.msg_rem_length - 1) then
					pull_o <= '1';
				end if;
				var.cnt := rec.cnt + 1;
				var.msg_block(512 - 1 - rec.cnt*8 downto 512 - 8 - rec.cnt*8) := data_i;

				if (rec.cnt >= 63 or rec.cnt >= rec.msg_rem_length - 1) then
					var.cnt := 0;
					var.state := padding;
				end if;

			when padding =>
				if (rec.msg_rem_length = 0) then
					if (rec.notPutOneFlag = '0') then
						var.msg_block(511) := '1';
					end if;
					var.msg_block(63 downto 0) := slv(rec.msg_length*8, 64);
					var.notPutOneFlag := '0';

				elsif (rec.msg_rem_length <= 55) then --64 - 8 - 1
					var.msg_block(512 - rec.msg_rem_length*8 - 1) := '1';
					var.msg_block(63 downto 0) := slv(rec.msg_length*8, 64);

				elsif (rec.msg_rem_length <= 63) then
					var.msg_block(512 - rec.msg_rem_length*8 - 1) := '1';
					var.notPutOneFlag := '1';
					var.waitFlag := '1';

				else
					var.waitFlag := '1';
				end if;

				if (data_ready_i = '1') then
					var.cnt := 0;
					var.state := loading;
					msg_word_o <= var.msg_block(511 - 32*int(word_address_i) downto 512 - 32*int(word_address_i) - 32);

					if (rec.msg_rem_length > 64) then 
						var.msg_rem_length := rec.msg_rem_length - 64;
					else 
						var.msg_rem_length := 0;
					end if;
				end if;
				data_valid_o <= '1';

			when loading =>
				msg_word_o <= rec.msg_block(511 - 32*int(word_address_i) downto 512 - 32*int(word_address_i) - 32);

				if (word_address_i = b"1111") then
					if (rec.waitFlag = '1') then
						var.state := waiting;
					else
						var.state := idle;
					end if;
				end if;

			when waiting =>
				if (data_ready_i = '1') then
					var.waitFlag := '0';
					var.msg_block := (others => '0');

					if (rec.msg_rem_length = 0) then
						var.state := padding;

					else
						pull_o <= '1';
						var.state := reading;
					end if;
				end if;

			when others =>
				assert false report "Unknown state" severity failure;
		end case;

		rec_in <= var;
	end process;

end sha256_loader_arc;