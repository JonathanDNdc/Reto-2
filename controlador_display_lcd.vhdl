library ieee;
use ieee.std_logic_1164.all;

entity CONTROLADOR_DISPLAY_LCD is
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
end CONTROLADOR_DISPLAY_LCD;

architecture arch of CONTROLADOR_DISPLAY_LCD is
    type state_type is (POWER_ON, INITIALIZE, IDLE, WRITE_R);
    signal state : state_type := POWER_ON;
begin

    process (clk)
        variable count : integer := 0;
    begin
        if rst = '0' then
            state <= POWER_ON;
        elsif rising_edge(clk) then
            case state is

                when POWER_ON =>
                    if count < (50000 * freq) then -- wait for more than 40 ms (50 ms)
                        count := count + 1;
                        state <= POWER_ON;
                    else
                        count    := 0;
                        rs_out   <= '0';
                        rw_out   <= '0';
                        data_out <= "00110000";
                        state    <= INITIALIZE;
                    end if;

                when INITIALIZE =>
                    count := count + 1;
                    if count < (10 * freq) then -- Function set
                        data_out <= "0011" & display_lines & character_font & "00";
                        en       <= '1';
                        state    <= INITIALIZE;
                    elsif count < (60 * freq) then -- wait 50 us
                        data_out <= "00000000";
                        en       <= '0';
                        state    <= INITIALIZE;
                    elsif count < (70 * freq) then -- Display off
                        data_out <= "00001000";
                        en       <= '1';
                        state    <= INITIALIZE;
                    elsif count < (120 * freq) then -- wait 50 us
                        data_out <= "00000000";
                        en       <= '0';
                        state    <= INITIALIZE;
                    elsif count < (130 * freq) then -- Display clear
                        data_out <= "00000001";
                        en       <= '1';
                        state    <= INITIALIZE;
                    elsif count < (2130 * freq) then --wait 2 ms
                        data_out <= "00000000";
                        en       <= '0';
                        state    <= INITIALIZE;
                    elsif count < (2140 * freq) then -- Entry mode set
                        data_out <= "000001" & inc_dec & shift;
                        en       <= '1';
                        state    <= INITIALIZE;
                    elsif count < (2200 * freq) then -- wait 60 us
                        data_out <= "00000000";
                        en       <= '0';
                        state    <= INITIALIZE;
                    else
                        count := 0;
                        state <= IDLE;
                    end if;

                when IDLE =>
                    if rw_in = '0' then
                        count    := 0;
                        rs_out   <= rs_in;
                        rw_out   <= rw_in;
                        data_out <= data_in;
                        state    <= WRITE_R;
                    else
                        rs_out   <= '0';
                        rw_out   <= '0';
                        data_out <= "00000000";
                        count    := 0;
                        state    <= IDLE;
                    end if;

                when WRITE_R =>
                    if count < (50 * freq) then --stay for 50 us
                        if count < freq then
                            en <= '0';
                        elsif count < (14 * freq) then
                            en <= '1';
                        elsif count < (27 * freq) then
                            en <= '0';
                        end if;
                        count := count + 1;
                        state <= WRITE_R;
                    else
                        count := 0;
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end arch;