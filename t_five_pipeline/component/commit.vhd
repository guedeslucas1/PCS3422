-- Design unit header --
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity commit is 
    port(
        -- input
        clock, reset: std_logic;

        -- interface EX/COM
        EX_COM : in std_logic_vector(44 downto 0); 
        -- rd_in:     in std_logic_vector(4 downto 0);
        -- w_val_in:  in std_logic_vector(31 downto 0);
        -- op:     in std_logic_vector(6 downto 0);
        -- commit: in std_logic;


        -- output 
        rd_out: out std_logic_vector(4 downto 0);
        w_val_out:     out std_logic_vector(31 downto 0);
        we:  out std_logic
    );
end entity;

architecture commit_arch of commit is

    ---- Architecture declarations -----
    constant c_r_ctrl :    std_logic_vector(6 downto 0) := "0110011";
    constant c_i_ctrl :    std_logic_vector(6 downto 0) := "0010011";
    constant c_lw_ctrl :   std_logic_vector(6 downto 0) := "0000011";
    constant c_sw_ctrl :   std_logic_vector(6 downto 0) := "0100011";
    constant c_b_ctrl :    std_logic_vector(6 downto 0) := "1100011";
    constant c_jal_ctrl :  std_logic_vector(6 downto 0) := "1101111";
    constant c_jalr_ctrl : std_logic_vector(6 downto 0) := "1100111";
    
    -- signals for EX/COM interface
    signal m_rd: std_logic_vector(4 downto 0);
    signal m_w_val: std_logic_vector(31 downto 0);
    signal m_op: std_logic_vector(6 downto 0);
    signal m_commit: std_logic;

    begin
    
    m_commit <= EX_COM(44);
    m_op <= EX_COM(43 downto 37);
    m_w_val <= EX_COM(36 downto 5);
    m_rd <= EX_COM(4 downto 0);


    rd_out <= m_rd;
    w_val_out <= m_w_val;
    we <= '0' when m_commit = '0' else
          '1' when m_op = c_i_ctrl or m_op = c_lw_ctrl or m_op = c_jal_ctrl or m_op = c_jalr_ctrl else
          '0';

end architecture commit_arch ; 
