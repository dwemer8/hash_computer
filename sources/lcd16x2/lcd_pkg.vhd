library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package lcd_pkg is

	function uns(val: integer; size : natural) return unsigned;
	function uns(val : std_logic_vector) return unsigned;
	function slv(val : unsigned) return std_logic_vector;
	function slv(a : integer; size : natural) return std_logic_vector;
	function s_slv(intValue : integer; vecLength : integer) return std_logic_vector;
	function int(val : std_logic_vector) return integer;

	function zero_vec(size     : integer) return std_logic_vector;
	function max_vec(vecLength : integer) return std_logic_vector;

end lcd_pkg;

package body lcd_pkg is

	function uns(val: integer; size : natural) return unsigned is
	begin
		return to_unsigned(val, size);
	end function;

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
    end function;

	function s_slv(intValue : integer;
            vecLength : integer
        ) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(intValue, vecLength));
    end function;

    function int(val : std_logic_vector) return integer is
    begin
    	return to_integer(unsigned(val));
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

end lcd_pkg;