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
        rStartSet : in std_logic;
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
        state           : state_type;
        writePointer    : std_logic_vector(FIFO_ADDR_WIDTH - 1 downto 0);
        readPointer     : std_logic_vector(FIFO_ADDR_WIDTH - 1 downto 0);
        addrInBuf       : std_logic_vector(FIFO_ADDR_WIDTH - 1 downto 0);
        addrOutBuf      : std_logic_vector(FIFO_ADDR_WIDTH - 1 downto 0);
        emptyPop        : std_logic;
        ram_we          : std_logic_vector(0 to BRAMS_AMOUNT - 1);
        rStartAddr      : std_logic_vector(FIFO_ADDR_WIDTH - 1 downto 0);
    end record;
    signal rst_rec : rec_type :=    (empty, 
                                    (others => '0'), 
                                    (others => '0'), 
                                    (others => '0'), 
                                    (others => '0'), 
                                    '0',
                                    (others => '0'),
                                    (others => '0')
                                    );
    signal rec, rec_in : rec_type := rst_rec;

    function ramId(address : std_logic_vector) return natural is
    begin
        return int(address(FIFO_ADDR_WIDTH - 1 downto RAM_ADDR_WIDTH));
    end function ramId;

begin
    ram_data <= dataIn;
    ram_waddr <= int(rec_in.addrInBuf(RAM_ADDR_WIDTH - 1 downto 0));
    ram_we <= rec_in.ram_we;

    process(clk)
    begin
        if (Rising_edge(clk)) then
            if (rst = '1') then
                rec <= rst_rec;

            else
                rec <= rec_in;
            end if;
        end if;
    end process;

    process(rec, push, pop, dataIn, ram_q, rAddrRst, rStartSet)
        variable var : rec_type := rst_rec;

    begin
        var := rec;
        var.emptyPop := '0';
        var.ram_we := (others => '0');

        if (rStartSet = '1') then
            var.rStartAddr := rec.readPointer;
        end if;

        if (rAddrRst = '1') then
            var.readPointer := rec.rStartAddr;
            
            if (rec.rStartAddr /= zero_vec(rec.rStartAddr'length)) then
                var.addrOutBuf := slv(uns(rec.rStartAddr) - uns(1, rec.rStartAddr'length));
            else
                var.addrOutBuf := zero_vec(var.addrOutBuf'length);
            end if;
        end if;

        if (pop = '1' and push = '1') then
            case (rec.state) is
            when empty =>
                var.emptyPop := '1';

            when full | data =>
                ram_raddr <= int(rec.readPointer(RAM_ADDR_WIDTH - 1 downto 0));
                var.addrOutBuf := rec.readPointer;

                var.addrInBuf  := rec.writePointer;
                var.ram_we(ramId(var.addrInBuf)) := '1';
                
            when others =>
                assert false report "Unknown state" severity failure;
            end case;

            var.writePointer := slv(uns(rec.writePointer) + uns(1, rec.writePointer'length));
            var.readPointer  := slv(uns(rec.readPointer) + uns(1, rec.readPointer'length));

        elsif (push = '1') then
            if (rec.state /= full) then
                var.addrInBuf := rec.writePointer;
                var.ram_we(ramId(var.addrInBuf)) := '1';
                var.writePointer := slv(uns(rec.writePointer) + uns(1, rec.writePointer'length));
            end if; -- else 'push' ignored to save previous data

        elsif (pop = '1') then
            if (rec.state /= empty) then
                ram_raddr <= int(rec.readPointer(RAM_ADDR_WIDTH - 1 downto 0));
                var.addrOutBuf := rec.readPointer;
                var.readPointer := slv(uns(rec.readPointer) + uns(1, rec.readPointer'length));
            end if; -- else 'pop' ignored to transmit last data
        end if;

        if (var.writePointer = slv(FIFO_DATA_DEPTH, var.writePointer'length)) then
            var.writePointer := zero_vec(var.writePointer'length);
        end if;
        if (var.readPointer = slv(FIFO_DATA_DEPTH, var.readPointer'length)) then
            var.readPointer := zero_vec(var.readPointer'length);
        end if;

        if (var.writePointer /= var.readPointer) then
            var.state := data;
        else
            if ((var.writePointer /= rec.writePointer and var.readPointer /= rec.readPointer) or 
                (var.writePointer = rec.writePointer and var.readPointer = rec.readPointer)) then
                var.state := rec.state;
            elsif (var.writePointer /= rec.writePointer) then
                var.state := full;
            else
                var.state := empty;
            end if;
        end if;

        case (var.state) is
        when empty =>
            isEmpty <= '1';
            isFull  <= '0';
        when full =>
            isEmpty <= '0';
            isFull  <= '1';
        when data =>
            isEmpty <= '0';
            isFull  <= '0';
        end case;

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
