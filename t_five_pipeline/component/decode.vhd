-- Design unit header --
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity decode is 
    port(
        clk, reset: in std_logic;

        -- Interface IF/ID
        IF_ID: in   std_logic_vector(95 downto 0);
        
        -- Interface ID/IS
        ID_IS:  out std_logic_vector(152 downto 0);
        -- op:     out std_logic_vector(6  downto 0);
        -- funct3: out std_logic_vector(2  downto 0);
        -- imm:    out std_logic_vector(31 downto 0);
        -- rd:     out std_logic_vector(4  downto 0);    
        -- rs1:    out std_logic_vector(4  downto 0);
        -- rs2:    out std_logic_vector(4  downto 0);
        -- rs1_v:  out std_logic_vector(31 downto 0);
        -- rs2_v:  out std_logic_vector(31 downto 0);

        -- Entradas
        reg_write: in std_logic;
        rd_in: in std_logic_vector(4 downto 0);
        data_write: in std_logic_vector(31 downto 0)
    );
end entity;

architecture decode_arch of decode is
 

    component reg_file is  
        generic(
            NBadd : integer := 5;
            NBdata : integer := 32;
            t_read : time := 5 ns;
            t_write : time := 5 ns
        );
        port(
            clk, reset : in std_logic;
            we : in std_logic;
            adda : in std_logic_vector(NBadd - 1 downto 0);
            addb : in std_logic_vector(NBadd - 1 downto 0);
            addw : in std_logic_vector(NBadd - 1 downto 0);
            data_in : in std_logic_vector(NBdata - 1 downto 0);
            data_outa : out std_logic_vector(NBdata - 1 downto 0);
            data_outb : out std_logic_vector(NBdata - 1 downto 0)
        );
 
    end component;

    component sign_ext is
        generic(
            t_sel    : time := 0.5 ns;
            t_data   : time := 0.25 ns
         );
         port(
             inst        : in 	std_logic_vector(31 downto 0);
             op      	: in 	std_logic_vector(6 downto 0);
             result 	    : out 	std_logic_vector(31 downto 0)
         );
    end component;    
    
    -- signals for IF/ID interface
    signal m_inst, m_pc, m_npc : std_logic_vector(31 downto 0);

    --signals for ID/IS interface
    signal m_op:                std_logic_vector(6 downto 0);
    signal m_funct3:            std_logic_vector(2 downto 0);
    signal m_imm:               std_logic_vector(31 downto 0);
    signal m_rd, m_rs1, m_rs2:  std_logic_vector(4 downto 0);
    signal m_rs1_v, m_rs2_v:    std_logic_vector(31 downto 0);

begin

    --IF/ID
    m_inst <= IF_ID(31 downto 0);
    m_npc <= IF_ID(63 downto 32);
    m_pc <= IF_ID(95 downto 64);

    --ID/IS

    ID_IS(152 downto 121) <= m_pc;
    ID_IS(120 downto 89) <= m_rs2_v;
    ID_IS(88 downto 57) <= m_rs1_v;
    ID_IS(56 downto 52) <= m_rs2;
    ID_IS(51 downto 47) <= m_rs1;
    ID_IS(46 downto 42) <= m_rd;
    ID_IS(41 downto 10) <= m_imm;
    ID_IS(9 downto 7) <= m_funct3;
    ID_IS(6 downto 0) <= m_op;

    -- internal

    m_rs2    <= m_inst(24 downto 20);
    m_rs1    <= m_inst(19 downto 15);
    m_rd     <= m_inst(11 downto 7);
    m_op     <= m_inst(6 downto 0);
    m_funct3 <= m_inst(14 downto 12);

SXT: sign_ext
    generic map(
        t_sel  => 0.5 ns,
        t_data => 0.25 ns
    )
    port map(
        inst   => m_inst,
        op     => m_op,
        result => m_imm
    );

GPR: reg_file
    generic map(
        NBadd => 5,
        NBdata => 32,
        t_read => 5 ns,
        t_write => 5 ns
        )
    port map(
        clk => clk,
        reset => reset,
        we => reg_write,
        adda => m_rs1,
        addb => m_rs2,
        addw => rd_in,
        data_in => data_write,
        data_outa => m_rs1_v,
        data_outb => m_rs2_v
    );

end architecture decode_arch;
