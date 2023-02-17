-- Design unit header --
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity execute_alu is 
    port (
        -- input
        op_in:     in std_logic_vector(6 downto 0);
        funct3: in std_logic_vector(2 downto 0);
        Vj:     in std_logic_vector(31 downto 0);
        Vk:     in std_logic_vector(31 downto 0);
        Imm:    in std_logic_vector(31 downto 0);
        PC_in:  in std_logic_vector(31 downto 0);
        rd_in:  in std_logic_vector(4 downto 0);

        -- output
        data_ready: out std_logic;
        ula_out :   out std_logic_vector(31 downto 0);
        PC_out:     out std_logic_vector(31 downto 0);
        rd_out:     out std_logic_vector(4 downto 0);
        op_out:     out std_logic_vector(6 downto 0)
    );
end entity;

architecture execute_arch of execute_alu is

    component mux2x1 is 
        generic(
            NB : integer := 32;
            t_sel : time := 0.5 ns;
            t_data : time := 0.25 ns
        );
        port(
            Sel : in std_logic;
            I0 : in std_logic_vector(NB - 1 downto 0);
            I1 : in std_logic_vector(NB - 1 downto 0);
            O : out std_logic_vector(NB - 1 downto 0)
        );
    end component;

    component alu_control is
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
    end component;

    component alu is 
        generic(
            NB 	: integer := 32;
            t_sum 	: time := 1 ns;
            t_sub 	: time := 1.25 ns;
            t_shift	: time := 1 ns
        );
        port(
            A 		     : in 	std_logic_vector(NB - 1 downto 0);
            B 		     : in 	std_logic_vector(NB - 1 downto 0);
            alu_ctrl	 : in 	std_logic_vector(3 downto 0);
            N   	     : out 	std_logic;
            Z   	     : out 	std_logic;
            result 	     : out 	std_logic_vector(NB - 1 downto 0)
        );
    end component;

    -- logic signals input
    signal m_mux1_out: std_logic_vector(31 downto 0);
    signal m_alu_src: std_logic;
    signal m_alu_ctrl: std_logic_vector(3 downto 0);

    begin

        MUX1: mux2x1
        generic map(
            NB => 32,
            t_sel => 0.5 ns,
            t_data => 0.25 ns
        )
        port map(
            Sel => m_alu_src,
            I0 =>  Vk,
            I1 => Imm,
            O => m_mux1_out
        );

        ALU1_CONTROL: alu_control
        generic map(
            t_sel => 0.5 ns,
            t_data => 0.25 ns
        )
        port map(
            funct3 => funct3,
            opcode => op_in,
            alu_ctrl => m_alu_ctrl,
            alu_src => m_alu_src
        );

        ALU1: alu
        generic map(
            NB => 32,
            t_sum => 1 ns,
            t_sub => 1.25 ns,
            t_shift => 1 ns
        )
        port map(
            A => Vj,
            B => m_mux1_out,
            alu_ctrl => m_alu_ctrl,
            N => open, --TODO
            Z => open, --TODO
            result => ula_out
        );

        PC_out <= PC_in;
        rd_out <= rd_in;
        op_out <= op_in;
        data_ready <= '1' when op_in /= "0000000" else '0';
end architecture execute_arch ; 
