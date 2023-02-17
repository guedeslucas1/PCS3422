library IEEE;
use IEEE.std_logic_1164.all;

entity fu_id_sel is
  port (
    clock, rst: std_logic;

    --in
    op     : in std_logic_vector(6 downto 0);
    fu_busy: in std_logic_vector(2 downto 0); -- 0: mem, 1: alu_1, 2:alu_2

    --out
    fu_id:  out std_logic_vector(2 downto 0)
  ) ;
end fu_id_sel;

architecture fu_id_sel of fu_id_sel is
begin
    fu_id <= "000" when op = "0000000" else
             "100" when op = "0000011" or op = "0100011" else -- LOAD or STORE
             "010" when (op = "0110011" or op = "0010011") and fu_busy(1)='0' else -- ARIT
             "001";
             
end fu_id_sel ; -- fu_id_sel