-- Design unit header --
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sign_ext is
    generic(
       t_sel    : time := 0.5 ns;
       t_data   : time := 0.25 ns
    );
    port(
        inst        : in 	std_logic_vector(31 downto 0);
        op      	: in 	std_logic_vector(6 downto 0);
        result 	    : out 	std_logic_vector(31 downto 0)
    );
end sign_ext;

architecture sign_ext_arch of sign_ext is

---- Architecture declarations -----
signal m_i_out : signed(31 downto 0) := (others => '0');
signal m_s_out : signed(31 downto 0) := (others => '0');
signal m_b_out : signed(31 downto 0) := (others => '0');
signal m_j_out : signed(31 downto 0) := (others => '0');
-- Atualização de result
begin

---- User Signal Assignments ----
m_i_out <= resize(signed(inst(31 downto 20)), 32);
m_s_out <= resize(signed(inst(31 downto 25) & inst(11 downto 7)), 32);
m_b_out <= resize(signed(inst(31) & inst(7) & inst(30 downto 25) & inst(11 downto 8) & "0"), 32);
m_j_out <= resize(signed(inst(31) & inst(19 downto 12) & inst(20) & inst(30 downto 21) & "0"), 32);

-- Resultado da Operação
result <=   std_logic_vector(m_i_out) after t_sel when op = "0010011" or op = "0000011" else
            std_logic_vector(m_s_out) after t_sel when op = "0100011" else
            std_logic_vector(m_b_out) after t_sel when op = "1100011" else
            std_logic_vector(m_j_out) after t_sel when op = "1101111" else 
            (others => '0');

end sign_ext_arch;
