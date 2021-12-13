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

	type state_type is (idle, W_filling, main_cycle);
	type W_type is array (0 to 79) of std_logic_vector(31 downto 0);
	type reg_type is record
		state : state_type;
		start : std_logic;
		W : W_type;
		h1, h2, h3, h4, h5, a, b, c, d, e : std_logic_vector(31 downto 0);
		cnt : integer;
	end record;
	constant rst_reg : reg_type := (state => idle,
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
	signal reg, reg_in : reg_type := rst_reg;

begin

	digest_o <= reg_in.h1 & reg_in.h2 & reg_in.h3 & reg_in.h4 & reg_in.h5;
	
	process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			if rst_i = '1' then 
				reg <= rst_reg;

			else
				reg <= reg_in;
			end if;
		end if;
	end process;

	process (reg, start_i, msg_block_i)
		variable var : reg_type := rst_reg;
		variable temp : std_logic_vector(31 downto 0) := (others => '0');

	begin
		ready_o <= '0';
		var := reg;
		var.start := start_i;

		case (reg.state) is
			when idle =>
				if (start_i = '1' and reg.start = '0') then
					var.state := W_filling;
				end if;

			when W_filling =>
				if (reg.cnt = 0) then
					var.cnt := 16;
					W_beginning : for t in 0 to 15 loop
						var.W(t) := msg_block_i((512 - 1 - t*32) downto (512 - 32 - t*32));
					end loop;

				else
					var.cnt := reg.cnt + 1;
					temp := reg.W(reg.cnt - 3) xor reg.W(reg.cnt - 8) xor reg.W(reg.cnt - 14) xor reg.W(reg.cnt - 16);
					var.W(reg.cnt) := rot_left(temp, 1);

					if (reg.cnt >= 79) then
						var.cnt := 0;
						var.a := reg.h1;
						var.b := reg.h2;
						var.c := reg.h3;
						var.d := reg.h4;
						var.e := reg.h5;

						var.state := main_cycle;
					end if;
				end if;

			when main_cycle =>

				var.cnt := reg.cnt + 1;
				var.e := reg.d;
				var.d := reg.c;
				var.c := rot_left(reg.b, 30);
				var.b := reg.a;
				var.a := slv(uns(rot_left(reg.a, 5)) + uns(F_op(reg.b, reg.c, reg.d, reg.cnt)) + uns(reg.e) + uns(reg.W(reg.cnt)) + uns(K_const(reg.cnt)));

				if (reg.cnt >= 79) then
					var.cnt := 0;
					var.h1 := slv(uns(reg.h1) + uns(var.a));
					var.h2 := slv(uns(reg.h2) + uns(var.b));
					var.h3 := slv(uns(reg.h3) + uns(var.c)); 
					var.h4 := slv(uns(reg.h4) + uns(var.d));
					var.h5 := slv(uns(reg.h5) + uns(var.e));

					ready_o <= '1';
					var.state := idle;
				end if;

			when others =>
				assert false report "Unknown state" severity failure;
		end case;

		reg_in <= var;
	end process;
end architecture;