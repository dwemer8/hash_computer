library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sha1_pkg is

	function uns(val : std_logic_vector) return unsigned;
	function slv(val : unsigned) return std_logic_vector;
	function rot_left(val : std_logic_vector; shift : integer) return std_logic_vector;

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

end sha1_pkg;