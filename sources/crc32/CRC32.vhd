library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CRC32_Core is

   Port ( Clock : in STD_LOGIC;
      Reset   : in  STD_LOGIC;
      Data_In : in  STD_LOGIC;
      CRC32   : out STD_LOGIC_VECTOR (31 downto 0));

end CRC32_Core;

architecture Behavioral of CRC32_Core is

   signal reg, reg_in : STD_LOGIC_VECTOR (31 downto 0);

begin

   process(Clock)
   begin
      if (rising_edge(Clock)) then
         if (Reset = '1') then
            -- Reset should fill the CRC32 Register with 1's
            reg <= (others => '1');
         else
            reg <= reg_in;
         end if;
      end if;
   end process;

   -- 0x04c11db7
   -- x32 + x26 + x23 + x22 + x16 + x12 + x11 + x10 + x8 + x7 + x5 + x4 + x2 + x1 + x0

   reg_in(0) <= reg(31) xor Data_In;               -- x0
   reg_in(1) <= reg(0) xor reg(31) xor Data_In;    -- x1
   reg_in(2) <= reg(1) xor reg(31) xor Data_In;    -- x2 
   reg_in(3) <= reg(2);

   reg_in(4) <= reg(3) xor reg(31) xor Data_In;    -- x4
   reg_in(5) <= reg(4) xor reg(31) xor Data_In;    -- x5
   reg_in(6) <= reg(5);
   reg_in(7) <= reg(6) xor reg(31) xor Data_In;    -- x7

   reg_in(8)  <= reg(7) xor reg(31) xor Data_In;   -- x8
   reg_in(9)  <= reg(8);
   reg_in(10) <= reg(9) xor reg(31) xor Data_In;   -- x10
   reg_in(11) <= reg(10) xor reg(31) xor Data_In;  -- x11

   reg_in(12) <= reg(11) xor reg(31) xor Data_In;  -- x12
   reg_in(13) <= reg(12);
   reg_in(14) <= reg(13);
   reg_in(15) <= reg(14);

   reg_in(16) <= reg(15) xor reg(31) xor Data_In;  -- x16
   reg_in(17) <= reg(16);
   reg_in(18) <= reg(17);
   reg_in(19) <= reg(18);

   reg_in(20) <= reg(19);
   reg_in(21) <= reg(20);
   reg_in(22) <= reg(21) xor reg(31) xor Data_In;  -- x22
   reg_in(23) <= reg(22) xor reg(31) xor Data_In;  -- x23

   reg_in(24) <= reg(23);
   reg_in(25) <= reg(24);
   reg_in(26) <= reg(25) xor reg(31) xor Data_In;  -- x26
   reg_in(27) <= reg(26);

   reg_in(28) <= reg(27);
   reg_in(29) <= reg(28);
   reg_in(30) <= reg(29);
   reg_in(31) <= reg(30);

   CRC32 <= reg_in;

end Behavioral;