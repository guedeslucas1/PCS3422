LIBRARY ieee;
USE ieee.std_logic_1164.all;

use std.textio.all;
use work.txt_util.all;

entity rs_tb is
end rs_tb;

 architecture behav of rs_tb is
    --  Declaration of the component that will be instantiated.
    component rs is
        port (
            clk, reset: in std_logic;
        
            -- in
            we:    in std_logic; -- bit do fu_id (fu_id_sel)
            rs_in: in std_logic_vector(146 downto 0)
    
        ) ;    
    end component;
   --  Specifies which entity is bound with the component.
   -- for rom_0: rom use entity work.rom;

   signal dado_in: std_logic_vector(146 downto 0) := (others => '0');
   signal reset, clk : std_logic := '0';

   constant PERIOD : time := 20 ns;
   signal finished: boolean := false;

begin
    dado_in <= "111" & x"000000001000000001000000001000000001";
    clk <= not clk after PERIOD/2 when not finished else '0';
    finished <= true after 100 ns;
   --  Component instantiation.
    rs_0: rs
        port map (
            clk => clk,
            reset => '0',
            rs_in => dado_in,
            we => '1'
        );
end behav;
