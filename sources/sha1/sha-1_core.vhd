library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.sha1_pkg.all;

entity SHA1_core is
	port (
			clk_i : in std_logic;
			rst_i : in std_logic;
			msg_block_i : in std_logic_vector(511 downto 0);
			start_i : in std_logic;
			digest_o : out std_logic_vector(159 downto 0);
			ready_o : out std_logic
		);
end entity SHA1_core;

architecture behaviour of SHA1_core is

	----------------------------------------SHA1 specific funtions------------------------------------

	function F_op(
		m : std_logic_vector;
		l : std_logic_vector;
		k : std_logic_vector;
		t : integer
	) return std_logic_vector is
	begin
		if (t <= 19) then
			return ((m and l) or ((not m) and k));
		elsif (t <= 39) then
			return (m xor l xor k);
		elsif (t <= 59) then
			return ((m and l) or (m and k) or (l and k));
		else
			return (m xor l xor k);
		end if;
	end function;

	function K_const(
		t : integer
	) return std_logic_vector is
	begin
		if (t <= 19) then
			return x"5A827999";
		elsif (t <= 39) then
			return x"6ED9EBA1";
		elsif (t <= 59) then
			return x"8F1BBCDC";
		else
			return x"CA62C1D6";
		end if;
	end function;

	----------------------------------------SHA1 specific constants------------------------------------

	constant A_init : std_logic_vector(31 downto 0) := x"67452301";
	constant B_init : std_logic_vector(31 downto 0) := x"EFCDAB89";
	constant C_init : std_logic_vector(31 downto 0) := x"98BADCFE";
	constant D_init : std_logic_vector(31 downto 0) := x"10325476";
	constant E_init : std_logic_vector(31 downto 0) := x"C3D2E1F0";

	----------------------------------------Signals and types-------------------------------------

	type state_type is (idle, W_filling, main_cycle, ending);
	type W_type is array (0 to 79) of std_logic_vector(31 downto 0);
	type rec_type is record
		state : state_type;
		start : std_logic;
		W : W_type;
		h1, h2, h3, h4, h5, a, b, c, d, e : std_logic_vector(31 downto 0);
		cnt : integer;
	end record;
	constant rst_rec : rec_type := (state => idle,
									start => '0',
									W => (others => (others => '0')),
									h1 => A_init,
									h2 => B_init,
									h3 => C_init,
									h4 => D_init,
									h5 => E_init,
									a => (others => '0'),
									b => (others => '0'),
									c => (others => '0'),
									d => (others => '0'),
									e => (others => '0'),
									cnt => 0
									);
	signal rec, rec_in : rec_type := rst_rec;

begin

	digest_o <= rec_in.h1 & rec_in.h2 & rec_in.h3 & rec_in.h4 & rec_in.h5;
	
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

	process (rec, start_i, msg_block_i)
		variable var : rec_type := rst_rec;
		variable temp : std_logic_vector(31 downto 0) := (others => '0');

	begin
		ready_o <= '0';
		var := rec;
		var.start := start_i;

		temp := (others => '0');

		case (rec.state) is
			when idle =>
				if (start_i = '1' and rec.start = '0') then
					var.state := W_filling;
				end if;

			when W_filling =>
				if (rec.cnt = 0) then
					var.cnt := 16;
					W_beginning : for t in 0 to 15 loop
						var.W(t) := msg_block_i((512 - 1 - t*32) downto (512 - 32 - t*32));
					end loop;

				else
					var.cnt := rec.cnt + 1;
					temp := rec.W(rec.cnt - 3) xor rec.W(rec.cnt - 8) xor rec.W(rec.cnt - 14) xor rec.W(rec.cnt - 16);
					var.W(rec.cnt) := rot_left(temp, 1);

					if (rec.cnt >= 79) then
						var.cnt := 0;
						var.a := rec.h1;
						var.b := rec.h2;
						var.c := rec.h3;
						var.d := rec.h4;
						var.e := rec.h5;

						var.state := main_cycle;
					end if;
				end if;

			when main_cycle =>
				var.cnt := rec.cnt + 1;
				var.e := rec.d;
				var.d := rec.c;
				var.c := rot_left(rec.b, 30);
				var.b := rec.a;
				var.a := slv(uns(rot_left(rec.a, 5)) + uns(F_op(rec.b, rec.c, rec.d, rec.cnt)) + uns(rec.e) + uns(rec.W(rec.cnt)) + uns(K_const(rec.cnt)));

				if (rec.cnt >= 79) then
					var.cnt := 0;
					var.state := ending;
				end if;	

			when ending =>
				var.h1 := slv(uns(rec.h1) + uns(rec.a));
				var.h2 := slv(uns(rec.h2) + uns(rec.b));
				var.h3 := slv(uns(rec.h3) + uns(rec.c)); 
				var.h4 := slv(uns(rec.h4) + uns(rec.d));
				var.h5 := slv(uns(rec.h5) + uns(rec.e));
				ready_o <= '1';
				var.state := idle;

			when others =>
				assert false report "Unknown state" severity failure;
		end case;

		rec_in <= var;
	end process;
end architecture;