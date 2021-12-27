----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/11/2019 09:46:31 PM
-- Design Name: 
-- Module Name: FIFO_8x10240_mod - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.fifo_mod_pkg.all;

entity FIFO_8x10240_mod is
    generic(
        DATA_WIDTH      : integer := 8
    );
    Port (
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        rAddrRst : in std_logic;
        dataIn  : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        dataOut : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        push    : in  STD_LOGIC;
        pop     : in  STD_LOGIC;
        isFull  : out STD_LOGIC;
        isEmpty : out STD_LOGIC
    );
end FIFO_8x10240_mod;


architecture Behavioral of FIFO_8x10240_mod is

    constant RAM_ADDR_WIDTH : natural := 9; --512
    constant RAM_DATA_DEPTH : natural := 512;
    constant FIFO_ADDR_WIDTH : natural := 14; --16384 > 10240
    constant FIFO_DATA_DEPTH : natural := 10240;
    constant FIFO_MAX_ADDR : std_logic_vector(FIFO_ADDR_WIDTH - 1 downto 0) := slv(FIFO_DATA_DEPTH - 1, FIFO_ADDR_WIDTH);
    constant BRAMS_AMOUNT : natural := FIFO_DATA_DEPTH / RAM_DATA_DEPTH; 

    component simple_dual_port_ram_single_clock is
        generic (
            DATA_WIDTH : natural := 8;
            ADDR_WIDTH : natural := 9
        );
        port (
            clk   : in  std_logic;
            raddr : in  natural range 0 to 2**ADDR_WIDTH - 1;
            waddr : in  natural range 0 to 2**ADDR_WIDTH - 1;
            data  : in  std_logic_vector((DATA_WIDTH-1) downto 0);
            we    : in  std_logic := '1';
            q     : out std_logic_vector((DATA_WIDTH -1) downto 0)
        );
    end component simple_dual_port_ram_single_clock;     

    signal ram_raddr, ram_waddr : natural;
    signal ram_data : std_logic_vector((DATA_WIDTH-1) downto 0);
    signal ram_we   : std_logic_vector(0 to BRAMS_AMOUNT - 1) := (others => '0');
    type ram_q_type is array (0 to BRAMS_AMOUNT - 1) of std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal ram_q    : ram_q_type;    

    type state_type is (empty, data, full);
    type rec_type is record
        state                             : state_type;
        writePointer                      : std_logic_vector(FIFO_ADDR_WIDTH - 1 downto 0);
        readPointer                       : std_logic_vector(FIFO_ADDR_WIDTH - 1 downto 0);
        addrInBuf : std_logic_vector(FIFO_ADDR_WIDTH - 1 downto 0);
        addrOutBuf : std_logic_vector(FIFO_ADDR_WIDTH - 1 downto 0);
        transfSigIn, transfSigOut, emptyPop : std_logic;
    end record;
    signal rst_rec : rec_type :=    (empty, 
                                    (others => '0'), 
                                    (others => '0'), 
                                    (others => '0'), 
                                    (others => '0'), 
                                    '0',
                                    '0',
                                    '0');
    signal rec, rec_in : rec_type := rst_rec;

    function ramId(address : std_logic_vector) return natural is
    begin
        return int(address(FIFO_ADDR_WIDTH - 1 downto RAM_ADDR_WIDTH));
    end function ramId;

begin
    process(clk)
    begin
        if (Rising_edge(clk)) then
            ram_we <= (others => '0');

            if (rst = '1') then
                rec <= rst_rec;

            else
                rec <= rec_in;
                rec.emptyPop <= '0';

                if (rec_in.transfSigIn = '1') then
                    ram_data <= dataIn;
                    ram_waddr <= int(rec_in.addrInBuf(RAM_ADDR_WIDTH - 1 downto 0));
                    ram_we(ramId(rec_in.addrInBuf)) <= '1';
                    rec.transfSigIn         <= '0';
                end if;

                if (rAddrRst = '1' ) then
                    rec.readPointer <= zero_vec(rec.readPointer'length);
                end if;
            end if;

            if (rec_in.state = empty) then
                isEmpty <= '1';
                isFull  <= '0';
            elsif (rec_in.state = full) then
                isEmpty <= '0';
                isFull  <= '1';
            else
                isEmpty <= '0';
                isFull  <= '0';
            end if;
        end if;
    end process;

    process(rec, push, pop, dataIn, ram_q)
        variable var : rec_type := rst_rec;

    begin
        var := rec;

        if (pop = '1' and push = '1') then
            var.writePointer := slv(uns(rec.writePointer) + uns(1, rec.writePointer'length));
            var.readPointer  := slv(uns(rec.readPointer) + uns(1, rec.readPointer'length));

            case (rec.state) is
            when empty =>
                var.emptyPop := '1';
                var.transfSigOut := '1';

            when full | data =>
                ram_raddr <= int(rec.readPointer(RAM_ADDR_WIDTH - 1 downto 0));
                var.addrOutBuf := rec.readPointer;
                var.transfSigOut := '1';

                var.addrInBuf  := rec.writePointer;
                var.transfSigIn := '1';
                
            when others =>
                assert false report "Unknown state" severity failure;
            end case;

        elsif (push = '1') then
            if (rec.state /= full) then
                var.addrInBuf := rec.writePointer;
                var.transfSigIn := '1';
                var.writePointer := slv(uns(rec.writePointer) + uns(1, rec.writePointer'length));
            end if; -- else 'push' ignored to save previous data

        elsif (pop = '1') then
            if (rec.state /= empty) then
                ram_raddr <= int(rec.readPointer(RAM_ADDR_WIDTH - 1 downto 0));
                var.addrOutBuf := rec.readPointer;
                var.transfSigOut := '1';
                var.readPointer := slv(uns(rec.readPointer) + uns(1, rec.readPointer'length));
            end if; -- else 'pop' ignored to transmit last data
        end if;

        if (var.writePointer /= var.readPointer) then
            var.state := data;
        else
            if ((var.writePointer /= rec.writePointer and var.readPointer /= rec.readPointer) or (var.writePointer = rec.writePointer and var.readPointer = rec.readPointer)) then
                var.state := rec.state;
            elsif (var.writePointer /= rec.writePointer) then
                var.state := full;
            else
                var.state := empty;
            end if;
        end if;

        if (var.writePointer = slv(FIFO_DATA_DEPTH, var.writePointer'length)) then
            var.writePointer := zero_vec(var.writePointer'length);
        end if;
        if (var.readPointer = slv(FIFO_DATA_DEPTH, var.readPointer'length)) then
            var.readPointer := zero_vec(var.readPointer'length);
        end if;

        if (var.emptyPop = '0') then
            dataOut <= ram_q(ramId(rec.addrOutBuf));
        else
            dataOut <= dataIn;
        end if;

        rec_in  <= var;
    end process;

    brams_gen : for i in 0 to BRAMS_AMOUNT - 1 generate
    begin
        simple_dual_port_ram_single_clock_i: simple_dual_port_ram_single_clock
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => RAM_ADDR_WIDTH
        )
        port map (
            clk   => clk,
            raddr => ram_raddr,
            waddr => ram_waddr,
            data  => ram_data,
            we    => ram_we(i),
            q     => ram_q(i)
        );        
    end generate brams_gen; 

end Behavioral;
