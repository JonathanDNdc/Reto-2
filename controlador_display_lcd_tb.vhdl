library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity controlador_display_lcd_tb is
end entity;

architecture arch of controlador_display_lcd_tb is
    component controlador_display_lcd is
        generic(
            freq           : integer   := 50; -- frecuencia del reloj en MHz
            display_lines  : std_logic := '1';
            character_font : std_logic := '0';
            inc_dec        : STD_LOGIC := '1';
            shift          : STD_LOGIC := '0'
        );
        port(
            clk      : in  std_logic;
            rst      : in  std_logic;
            rs_in    : in  std_logic;
            rw_in    : in  std_logic;
            data_in  : in  std_logic_vector(7 downto 0);
            rs_out   : out std_logic;
            rw_out   : out std_logic;
            en       : out std_logic;
            data_out : out std_logic_vector(7 downto 0)
        );
    end component;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal rs_in    : std_logic;
    signal rw_in    : std_logic;
    signal data_in  : std_logic_vector(7 downto 0);
    signal rs_out   : std_logic;
    signal rw_out   : std_logic;
    signal en       : std_logic;
    signal data_out : std_logic_vector(7 downto 0);
    signal period   : time      := 20 ns;
    signal finished : std_logic := '0';

begin
        uut : controlador_display_lcd port map (clk,rst,rs_in,rw_in,data_in,rs_out,rw_out,en,data_out);

    clk <= not clk after period/2 when finished = '0' else '0';

    process

        file fin  : TEXT open READ_MODE is "input.txt";
        file fout : TEXT open WRITE_MODE is "output.txt";

        variable current_read_line   : line;
        variable current_write_line  : line;
        variable current_read_field0 : std_logic;                    --rst
        variable current_read_field1 : std_logic;                    --rs_in
        variable current_read_field2 : std_logic;                    --rw_in
        variable current_read_field3 : std_logic_vector(7 downto 0); --data_in

    begin
        wait for 50 ms;
        readFile : while (not endfile(fin)) loop
            readline(fin, current_read_line);
            read(current_read_line, current_read_field0);
            read(current_read_line, current_read_field1);
            read(current_read_line, current_read_field2);
            read(current_read_line, current_read_field3);


            rst     <= current_read_field0;
            rs_in   <= current_read_field1;
            rw_in   <= current_read_field2;
            data_in <= current_read_field3;
            wait for 100 ms;
            if (rst = '1') then
                if (rw_in = '0') then
                    if (rs_in = '0') then
                        write(current_write_line, string'("instr(0x"));
                    elsif (rs_in = '1') then
                        write(current_write_line, string'("data(0x"));
                    end if;
                    hwrite(current_write_line, data_out);
                    write(current_write_line, string'(");"));
                    writeline(fout, current_write_line);
                end if;
            else -- initialization
                write(current_write_line, string'("instr(0x38);"));
                writeline(fout, current_write_line);
                write(current_write_line, string'("instr(0x0F);"));
                writeline(fout, current_write_line);
                write(current_write_line, string'("instr(0x01);"));
                writeline(fout, current_write_line);
                write(current_write_line, string'("instr(0x06);"));
                writeline(fout, current_write_line);
            end if;
        end loop;
        finished <= '1';
        wait;
    end process;
end arch;