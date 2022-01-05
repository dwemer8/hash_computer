--Модуль для вычисления CRC-32/BZIP2. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CRC32 is
   generic (
      --CRC-32/BZIP2
      INIT   : STD_LOGIC_VECTOR (31 downto 0) := x"FFFFFFFF"; --начальное значение регистра 
      XOROUT : STD_LOGIC_VECTOR (31 downto 0) := x"FFFFFFFF" --значение, с которым выполнятся XOR результата вычислений
   );
   Port (
      clk_i        : in  STD_LOGIC; --тактовый сигнал
      rst_i        : in  STD_LOGIC; --сигнал сброса. Модуль должен быть сброшен перед каждым новым вычислением.
      data_valid_i : in  STD_LOGIC; --сигнал валидности данных. Если в 1, data_i на этом такте используется для вычисления, если в 0, то нет.
      data_i       : in  STD_LOGIC; --бит данных сообщения, CRC32 которого вычисляется
      checksum_o   : out STD_LOGIC_VECTOR (31 downto 0) --контрольная сумма
   );
end CRC32;

architecture Behavioral of CRC32 is

   signal reg, reg_in : STD_LOGIC_VECTOR (31 downto 0);

begin

   process(clk_i)
   begin
      if (rising_edge(clk_i)) then
         if (rst_i = '1') then
            reg <= INIT;
         else
            reg <= reg_in;
         end if;
      end if;
   end process;

   -- 0x04c11db7
   -- x32 + x26 + x23 + x22 + x16 + x12 + x11 + x10 + x8 + x7 + x5 + x4 + x2 + x1 + x0

   process (reg, data_i, data_valid_i)
   begin
      if (data_valid_i = '1') then
         reg_in(0) <= reg(31) xor data_i;            -- x0
         reg_in(1) <= reg(0) xor reg(31) xor data_i; -- x1
         reg_in(2) <= reg(1) xor reg(31) xor data_i; -- x2 
         reg_in(3) <= reg(2);

         reg_in(4) <= reg(3) xor reg(31) xor data_i; -- x4
         reg_in(5) <= reg(4) xor reg(31) xor data_i; -- x5
         reg_in(6) <= reg(5);
         reg_in(7) <= reg(6) xor reg(31) xor data_i; -- x7

         reg_in(8)  <= reg(7) xor reg(31) xor data_i; -- x8
         reg_in(9)  <= reg(8);
         reg_in(10) <= reg(9) xor reg(31) xor data_i;  -- x10
         reg_in(11) <= reg(10) xor reg(31) xor data_i; -- x11

         reg_in(12) <= reg(11) xor reg(31) xor data_i; -- x12
         reg_in(13) <= reg(12);
         reg_in(14) <= reg(13);
         reg_in(15) <= reg(14);

         reg_in(16) <= reg(15) xor reg(31) xor data_i; -- x16
         reg_in(17) <= reg(16);
         reg_in(18) <= reg(17);
         reg_in(19) <= reg(18);

         reg_in(20) <= reg(19);
         reg_in(21) <= reg(20);
         reg_in(22) <= reg(21) xor reg(31) xor data_i; -- x22
         reg_in(23) <= reg(22) xor reg(31) xor data_i; -- x23

         reg_in(24) <= reg(23);
         reg_in(25) <= reg(24);
         reg_in(26) <= reg(25) xor reg(31) xor data_i; -- x26
         reg_in(27) <= reg(26);

         reg_in(28) <= reg(27);
         reg_in(29) <= reg(28);
         reg_in(30) <= reg(29);
         reg_in(31) <= reg(30);

      else
         reg_in <= reg;

      end if;
   end process;

   checksum_o <= reg_in xor XOROUT;

end Behavioral;