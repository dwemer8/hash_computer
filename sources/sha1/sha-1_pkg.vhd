library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sha1_pkg is

	function uns(val : std_logic_vector) return unsigned;
	function slv(val : unsigned) return std_logic_vector;
	function slv(a : integer; size : natural) return std_logic_vector;
	function s_slv(intValue : integer; vecLength : integer) return std_logic_vector;

	function zero_vec(size     : integer) return std_logic_vector;
	function max_vec(vecLength : integer) return std_logic_vector;

	----------------------------operations------------------------------------------------
	function rot_left(val : std_logic_vector; shift : integer) return std_logic_vector;

	---------------------------for testbench only-------------------------------------------------
	function slv(symb : character) return std_logic_vector;
	function strToMsg (msg: string) return std_logic_vector;

end sha1_pkg;

package body sha1_pkg is

	function uns(val : std_logic_vector) return unsigned is
	begin
		return unsigned(val);
	end function;

	function slv(val : unsigned) return std_logic_vector is
	begin
		return std_logic_vector(val);
	end function;

	function slv(a : integer; size : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(a, size));
    end;

	function s_slv(intValue : integer;
            vecLength : integer
        ) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(intValue, vecLength));
    end function;


    function zero_vec(size : integer) return std_logic_vector is
    begin
        return slv(0, size);
    end;

	function max_vec(vecLength : integer
        ) return std_logic_vector is
    begin
        return s_slv(-1, vecLength);
    end function;

    --------------------------Operations--------------------------------------------------
    function rot_left(
		val : std_logic_vector; 
		shift : integer) 
	return std_logic_vector is
	begin
		if (shift < 0) then
			assert false report "Negative shift isn't supported" severity failure;
			return val;
		elsif (shift = 0) then
			return val;
		elsif (shift = 1) then
			return val(val'length - 2 downto 0) & val(val'length - 1);
		elsif (shift < val'length - 1) then
			return val(val'length - 1 - shift downto 0) & val(val'length - 1 downto val'length - shift);
		elsif (shift = val'length - 1) then
			return val(0) & val(val'length - 1 downto 1);
		else
			assert false report "Shift more or equal then vector's size isn't supported" severity failure;
			return val;
		end if;
	end function;

	---------------------------for testbench only-------------------------------------------------
	function slv(symb : character) return std_logic_vector is
	begin
		return slv(to_unsigned(character'pos(symb), 8));
	end function;

	function strToMsg (
		msg: string
		) return std_logic_vector is
		variable msg_block : std_logic_vector(511 downto 0) := (others => '0');
	begin
		split_loop : for i in 0 to msg'length - 1 loop
			msg_block(512 - 1 - i*8 downto 512 - 8 - i*8) := slv(msg(i + 1));
		end loop;
		msg_block(512 - msg'length*8 - 1) := '1';
		msg_block(63 downto 0) := slv(to_unsigned(msg'length*8, 64));
		return msg_block;
	end strToMsg;

end sha1_pkg;