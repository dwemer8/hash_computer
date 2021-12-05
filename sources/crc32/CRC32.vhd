--*****************************************************************************
--* CRC32 Core
--*****************************************************************************
--*
--* Derek Schacht
--* 10/05/2015
--*
--* This file contains an implementation of the CRC32 Algorithm using the 
--* IEEE Standard 0x04c11db7 Poly. This module is intended to compute the 
--* CRC32 on a stream of bits.
--*
--* Various sources were used to understand the CRC32 algorithm. The one that
--* finally clicked can be found:
--*   http://www.zlib.net/crc_v3.txt
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CRC32_Core is

    Port ( Clock   : in     STD_LOGIC;
           Reset   : in     STD_LOGIC;
           Data_In : in     STD_LOGIC;
           CRC32   :   out  STD_LOGIC_VECTOR (31 downto 0));

end CRC32_Core;

architecture Behavioral of CRC32_Core is

   -- Need a signal since the output port cannot be read. Using the CRC32_Reg directly
   -- causes the whole thing to be optimized away.

   signal CRC32_Net : STD_LOGIC_VECTOR (31 downto 0);

begin

   -- Assign the data onto the output port.

   CRC32 <= CRC32_Net;

   process (Clock)
   
      variable CRC32_Reg : STD_LOGIC_VECTOR (31 downto 0);
   
   begin
   
      -- Assign the data onto the signal net for the CRC32 data.

      CRC32_Net <= CRC32_Reg;
   
      if rising_edge(Clock) then

         if Reset = '1' then
         
            -- Reset should fill the CRC32 Register with 1's

            CRC32_Reg := (others => '1');
         
         else
            -- 0x04c11db7
            -- x32 + x26 + x23 + x22 + x16 + x12 + x11 + x10 + x8 + x7 + x5 + x4 + x2 + x1 + x0

            -- This will perform the shift and subtract all at the same time.

            CRC32_Reg(0)  := CRC32_Net(31) xor Data_In;                       -- x0
            CRC32_Reg(1)  := CRC32_Net(0) xor CRC32_Net(31) xor Data_In;      -- x1
            CRC32_Reg(2)  := CRC32_Net(1) xor CRC32_Net(31) xor Data_In;      -- x2 
            CRC32_Reg(3)  := CRC32_Net(2);                                    

            CRC32_Reg(4)  := CRC32_Net(3) xor CRC32_Net(31) xor Data_In;      -- x4
            CRC32_Reg(5)  := CRC32_Net(4) xor CRC32_Net(31) xor Data_In;      -- x5
            CRC32_Reg(6)  := CRC32_Net(5);                                    
            CRC32_Reg(7)  := CRC32_Net(6) xor CRC32_Net(31) xor Data_In;      -- x7

            CRC32_Reg(8)  := CRC32_Net(7) xor CRC32_Net(31) xor Data_In;      -- x8
            CRC32_Reg(9)  := CRC32_Net(8);
            CRC32_Reg(10) := CRC32_Net(9) xor CRC32_Net(31) xor Data_In;      -- x10
            CRC32_Reg(11) := CRC32_Net(10) xor CRC32_Net(31) xor Data_In;     -- x11

            CRC32_Reg(12) := CRC32_Net(11) xor CRC32_Net(31) xor Data_In;     -- x12
            CRC32_Reg(13) := CRC32_Net(12);
            CRC32_Reg(14) := CRC32_Net(13);
            CRC32_Reg(15) := CRC32_Net(14);

            CRC32_Reg(16) := CRC32_Net(15) xor CRC32_Net(31) xor Data_In;     -- x16
            CRC32_Reg(17) := CRC32_Net(16);
            CRC32_Reg(18) := CRC32_Net(17);
            CRC32_Reg(19) := CRC32_Net(18);

            CRC32_Reg(20) := CRC32_Net(19);
            CRC32_Reg(21) := CRC32_Net(20);
            CRC32_Reg(22) := CRC32_Net(21) xor CRC32_Net(31) xor Data_In;     -- x22
            CRC32_Reg(23) := CRC32_Net(22) xor CRC32_Net(31) xor Data_In;     -- x23

            CRC32_Reg(24) := CRC32_Net(23);
            CRC32_Reg(25) := CRC32_Net(24);
            CRC32_Reg(26) := CRC32_Net(25) xor CRC32_Net(31) xor Data_In;     -- x26
            CRC32_Reg(27) := CRC32_Net(26);

            CRC32_Reg(28) := CRC32_Net(27);
            CRC32_Reg(29) := CRC32_Net(28);
            CRC32_Reg(30) := CRC32_Net(29);
            CRC32_Reg(31) := CRC32_Net(30);
         
         end if;
      end if;
   end process;
end Behavioral;