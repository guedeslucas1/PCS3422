-- Design unit header --
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu_control is
    generic(
       t_sel    : time := 0.5 ns;
       t_data   : time := 0.25 ns
    );
    port(
        funct3     	: in  std_logic_vector(2 downto 0);
        opcode 	    : in  std_logic_vector(6 downto 0);
        alu_ctrl    : out std_logic_vector(3 downto 0);
        alu_src     : out std_logic
    );
end alu_control;

architecture alu_control_arch of alu_control is

---- Architecture declarations -----
constant c_add_ctrl : std_logic_vector(3 downto 0) := "0000";
constant c_sub_ctrl : std_logic_vector(3 downto 0) := "1000";
constant c_slt_ctrl : std_logic_vector(3 downto 0) := "0010";
constant c_sll_ctrl : std_logic_vector(3 downto 0) := "0001";
constant c_srl_ctrl : std_logic_vector(3 downto 0) := "0101";
constant c_sra_ctrl : std_logic_vector(3 downto 0) := "1101";

constant c_r_ctrl :    std_logic_vector(6 downto 0) := "0110011";
constant c_i_ctrl :    std_logic_vector(6 downto 0) := "0010011";
constant c_lw_ctrl :   std_logic_vector(6 downto 0) := "0000011";
constant c_sw_ctrl :   std_logic_vector(6 downto 0) := "0100011";
constant c_b_ctrl :    std_logic_vector(6 downto 0) := "1100011";
constant c_jal_ctrl :  std_logic_vector(6 downto 0) := "1101111";
constant c_jalr_ctrl : std_logic_vector(6 downto 0) := "1100111";

signal m_r_ctrl : std_logic_vector(3 downto 0);
signal m_i_ctrl : std_logic_vector(3 downto 0);
signal m_alu_op: std_logic_vector(1 downto 0);

begin

    ---- User Signal Assignments ----
alu_src <= '1' when opcode = c_lw_ctrl or opcode = c_i_ctrl or opcode = c_sw_ctrl or opcode = c_jalr_ctrl else '0';

m_r_ctrl <= opcode(5) & funct3;
m_i_ctrl <= opcode(5) & funct3 when funct3 = "101" else
            "0" & funct3;

-- Resultado da Operação
alu_ctrl <= m_r_ctrl    after t_sel when m_alu_op = "00" else
            m_i_ctrl    after t_sel when m_alu_op = "01" else
            c_add_ctrl  after t_sel when m_alu_op = "10" else
            c_sub_ctrl  after t_sel when m_alu_op = "11";

m_alu_op <= "00" when opcode = c_r_ctrl or opcode = c_jal_ctrl else
            "01" when opcode  = c_i_ctrl else
            "10" when opcode = c_lw_ctrl or opcode = c_sw_ctrl or opcode = c_jalr_ctrl else
            "11" when opcode = c_b_ctrl else
            "00"; 

end alu_control_arch;
