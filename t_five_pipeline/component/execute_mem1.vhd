-- Design unit header --
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity execute_mem1 is 
    port (
        -- input
        op_in:  in std_logic_vector(6 downto 0);
        funct3: in std_logic_vector(2 downto 0);
        Vj:     in std_logic_vector(31 downto 0);
        Vk:     in std_logic_vector(31 downto 0);
        Imm:    in std_logic_vector(31 downto 0);
        PC_in:  in std_logic_vector(31 downto 0);
        rd_in:  in std_logic_vector(4 downto 0);

        -- output
        address :   out std_logic_vector(31 downto 0);
        w_value :   out std_logic_vector(31 downto 0);
        PC_out:     out std_logic_vector(31 downto 0);
        rd_out:     out std_logic_vector(4 downto 0);
        op_out:     out std_logic_vector(6 downto 0);
        rw:         out std_logic;
        data_ready: out std_logic

    );
end entity;

architecture execute_arch of execute_mem1 is

    constant c_sw_ctrl :   std_logic_vector(6 downto 0) := "0100011";

    begin
        address <= std_logic_vector(signed(Imm) + signed(Vj));
        w_value <= Vk;
        PC_out <= PC_in;
        rw <= '1' when op_in = c_sw_ctrl else '0';
        rd_out <= rd_in;
        op_out <= op_in;
        data_ready <= '1' when op_in /= "0000000" else '0';
end architecture execute_arch ; 
