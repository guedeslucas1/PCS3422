-- Design unit header --
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity execute is 
    port(
        -- input
        clock, reset: std_logic;

        -- interface IS/EX
        IS_EX: in std_logic_vector(431 downto 0);
        -- op_1:     in std_logic_vector(6 downto 0);
        -- funct3_1: in std_logic_vector(2 downto 0);
        -- Vj_1:     in std_logic_vector(31 downto 0);
        -- Vk_1:     in std_logic_vector(31 downto 0);
        -- Imm_1:    in std_logic_vector(31 downto 0);
        -- PC_in_1:  in std_logic_vector(31 downto 0);
        -- rd_1:  in std_logic_vector(4 downto 0);

        -- op_2:     in std_logic_vector(6 downto 0);
        -- funct3_2: in std_logic_vector(2 downto 0);
        -- Vj_2:     in std_logic_vector(31 downto 0);
        -- Vk_2:     in std_logic_vector(31 downto 0);
        -- Imm_2:    in std_logic_vector(31 downto 0);
        -- PC_in_2:  in std_logic_vector(31 downto 0);
        -- rd_2:  in std_logic_vector(4 downto 0);

        -- op_3:     in std_logic_vector(6 downto 0);
        -- funct3_3: in std_logic_vector(2 downto 0);
        -- Vj_3:     in std_logic_vector(31 downto 0);
        -- Vk_3:     in std_logic_vector(31 downto 0);
        -- Imm_3:    in std_logic_vector(31 downto 0);
        -- PC_in_3:  in std_logic_vector(31 downto 0);
        -- rd_3:  in std_logic_vector(4 downto 0);

        -- interface EX/COM

        EX_COM : out std_logic_vector(44 downto 0); 

        -- rd:     out std_logic_vector(4 downto 0);
        -- w_val:  out std_logic_vector(31 downto 0);
        -- op:     out std_logic_vector(6 downto 0);
        -- commit: out std_logic;

        -- input (memory interface)
        data_read_in: in std_logic_vector(31 downto 0);

        -- output (memory interface)
        rw_out:         out std_logic;
        data_write:     out std_logic_vector(31 downto 0);
        address_out:    out std_logic_vector(31 downto 0);

        -- output (cdb)
        cdb_3:            out std_logic_vector(32 downto 0);
        cdb_2:            out std_logic_vector(32 downto 0);
        cdb_1:            out std_logic_vector(32 downto 0)
    );
end entity;

architecture execute_arch of execute is

    component execute_alu is 
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
    end component;

    component execute_mem1 is 
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
    end component;

    component execute_mem2 is 
        port (
            -- input
            op_in:         in std_logic_vector(6 downto 0);
            address_in :   in std_logic_vector(31 downto 0);
            w_value :      in std_logic_vector(31 downto 0);
            PC_in:         in std_logic_vector(31 downto 0);
            rw_in:         in std_logic;
            rd_in:         in std_logic_vector(4 downto 0);
            data_ready_in: in std_logic;

            -- output 
            op_out:         out std_logic_vector(6 downto 0);
            data_ready_out: out std_logic;
            data_read_out: out std_logic_vector(31 downto 0);
            PC_out:        out std_logic_vector(31 downto 0);
            rd_out:   out std_logic_vector(4 downto 0);

            -- input (memory interface)
            data_read_in: in std_logic_vector(31 downto 0);

            -- output (memory interface)
            rw_out:         out std_logic;
            data_write:     out std_logic_vector(31 downto 0);
            address_out:    out std_logic_vector(31 downto 0)
        );
    end component;

    component reg is
        generic(
             NB : integer := 32;
             t_prop : time := 1 ns;
             t_hold : time := 0.25 ns;
             t_setup : time := 0.25 ns
        );
        port(
             clk : in std_logic;
             CE : in std_logic;
             R : in std_logic;
             S : in std_logic;
             D : in std_logic_vector(NB - 1 downto 0);
             Q : out std_logic_vector(NB - 1 downto 0)
        );
    end component;

    -- signals for IS/EX interface
    signal m_op_1: std_logic_vector(6 downto 0);
    signal m_funct3_1: std_logic_vector(2 downto 0);
    signal m_Vj_1, m_Vk_1, m_Imm_1, m_pc_1: std_logic_vector(31 downto 0);
    signal m_data_ready_1: std_logic;
    signal m_rd_1: std_logic_vector(4 downto 0);
    
    signal m_op_2: std_logic_vector(6 downto 0);
    signal m_funct3_2: std_logic_vector(2 downto 0);
    signal m_Vj_2, m_Vk_2, m_Imm_2, m_pc_2: std_logic_vector(31 downto 0);
    signal m_data_ready_2: std_logic;
    signal m_rd_2: std_logic_vector(4 downto 0);

    signal m_op_3: std_logic_vector(6 downto 0);
    signal m_funct3_3: std_logic_vector(2 downto 0);
    signal m_Vj_3, m_Vk_3, m_Imm_3, m_pc_3: std_logic_vector(31 downto 0);
    signal m_data_ready_3: std_logic;
    signal m_rd_3: std_logic_vector(4 downto 0);
    
    -- signals for EX/COM interface
    signal m_rd: std_logic_vector(4 downto 0);
    signal m_w_val: std_logic_vector(31 downto 0);
    signal m_op: std_logic_vector(6 downto 0);
    signal m_commit: std_logic;

    -- internal signals
    signal ula_out_1, ula_out_2, mem_out: std_logic_vector(31 downto 0);
    signal pc_out_1, pc_out_2, pc_out_3: std_logic_vector(31 downto 0);
    signal rd_out_1, rd_out_2, rd_out_3: std_logic_vector(4 downto 0);
    signal op_out_1, op_out_2, op_out_3: std_logic_vector(6 downto 0);
    signal data_ready_1, data_ready_2, data_ready_3: std_logic;

    signal mem1_add, mem2_add, mem1_w_value, mem2_w_value, mem1_pc, mem2_pc: std_logic_vector(31 downto 0);
    signal mem1_rd, mem2_rd: std_logic_vector(4 downto 0);
    signal mem1_rw, mem2_rw, mem1_data_ready, mem2_data_ready: std_logic;
    signal mem1_mem2_out, mem1_mem2_in: std_logic_vector(102 downto 0);
    signal mem1_op: std_logic_vector(6 downto 0);
    signal commit_counter_in, commit_counter_out: std_logic_vector(31 downto 0) := (others => '0');
    signal update_counter: std_logic := '0';

    begin

        --IS/EX

        m_data_ready_3 <=   IS_EX(431);
        m_pc_3 <=           IS_EX(430 downto 399);
        m_rd_3 <=           IS_EX(398 downto 394);
        m_Imm_3 <=          IS_EX(393 downto 362);
        m_Vk_3 <=           IS_EX(361 downto 330);
        m_Vj_3 <=           IS_EX(329 downto 298);
        m_funct3_3 <=       IS_EX(297 downto 295);
        m_op_3 <=           IS_EX(294 downto 288);

        m_data_ready_2 <=   IS_EX(287);
        m_pc_2 <=           IS_EX(286 downto 255);
        m_rd_2 <=           IS_EX(254 downto 250);
        m_Imm_2 <=          IS_EX(249 downto 218);
        m_Vk_2 <=           IS_EX(217 downto 186);
        m_Vj_2 <=           IS_EX(185 downto 154);
        m_funct3_2 <=       IS_EX(153 downto 151);
        m_op_2 <=           IS_EX(150 downto 144);

        m_data_ready_1 <=   IS_EX(143);
        m_pc_1 <=           IS_EX(142 downto 111);
        m_rd_1 <=           IS_EX(110 downto 106);
        m_Imm_1 <=          IS_EX(105 downto 74);
        m_Vk_1 <=           IS_EX(73 downto 42);
        m_Vj_1 <=           IS_EX(41 downto 10);
        m_funct3_1 <=       IS_EX(9 downto 7);
        m_op_1 <=           IS_EX(6 downto 0);

        -- EX/COM

        EX_COM(44) <= m_commit;
        EX_COM(43 downto 37) <= m_op;
        EX_COM(36 downto 5) <= m_w_val;
        EX_COM(4 downto 0) <= m_rd;

        alu_1: execute_alu
        port map(
            -- input
            op_in => m_op_1,
            funct3 => m_funct3_1,
            Vj => m_Vj_1,
            Vk => m_Vk_1,
            Imm => m_Imm_1,
            PC_in => m_PC_1,
            rd_in => m_rd_1,

            -- output
            op_out => op_out_1,
            data_ready => data_ready_1,
            ula_out => ula_out_1,
            PC_out => pc_out_1,
            rd_out => rd_out_1
        );

        alu_2: execute_alu
        port map(
            -- input
            op_in => m_op_2,
            funct3 => m_funct3_2,
            Vj => m_Vj_2,
            Vk => m_Vk_2,
            Imm => m_Imm_2,
            PC_in => m_PC_2,
            rd_in => m_rd_2,

            -- output
            op_out => op_out_2,
            data_ready => data_ready_2,
            ula_out => ula_out_2,
            PC_out => pc_out_2,
            rd_out => rd_out_2
        );
        
        mem1: execute_mem1
        port map(
            -- input
            op_in => m_op_3,
            funct3 => m_funct3_3,
            Vj => m_Vj_3,
            Vk => m_Vk_3,
            Imm => m_Imm_3,
            PC_in => m_PC_3,
            rd_in => m_rd_3,

            -- output
            op_out => mem1_op,
            data_ready => mem1_data_ready,
            address => mem1_add,
            w_value => mem1_w_value,
            PC_out => mem1_pc,
            rd_out => mem1_rd,
            rw => mem1_rw
        );

        mem1_mem2_in <= mem1_data_ready & mem1_rw & mem1_pc & mem1_w_value & mem1_add & mem1_rd;

        mem1_mem2_reg: reg
        generic map(
            NB => 103,
            t_prop => 1 ns,
            t_hold => 0.25 ns,
            t_setup => 0.25 ns
        )
        port map(
            clk => clock,
            CE => '1',
            R => reset,
            S => '0',
            D => mem1_mem2_in,
            Q => mem1_mem2_out
        );
        
        mem2_data_ready <= mem1_mem2_out(102);
        mem2_rw         <= mem1_mem2_out(101);
        mem2_pc         <= mem1_mem2_out(100 downto 69);
        mem2_w_value    <= mem1_mem2_out(68 downto 37);
        mem2_add        <= mem1_mem2_out(36 downto 5);
        mem2_rd         <= mem1_mem2_out(4 downto 0);

        mem2: execute_mem2
        port map(
            -- input
            op_in => mem1_op,
            address_in => mem2_add,
            w_value => mem2_w_value,
            PC_in => mem2_pc,
            rw_in => mem2_rw,
            rd_in => mem2_rd,
            data_ready_in => mem2_data_ready,

            -- output 
            op_out => op_out_3,
            data_ready_out => data_ready_3,
            data_read_out => mem_out,
            PC_out => pc_out_3,
            rd_out => rd_out_3,

            -- input (memory interface)
            data_read_in => data_read_in,

            -- output (memory interface)
            rw_out => rw_out,
            data_write => data_write,
            address_out => address_out
        );

        commit_counter: reg
        generic map(
            NB => 32,
            t_prop => 1 ns,
            t_hold => 0.25 ns,
            t_setup => 0.25 ns
        )
        port map(
            clk => clock,
            CE => update_counter,
            R => reset,
            S => '0',
            D => commit_counter_in,
            Q => commit_counter_out
        );

        commit_counter_in <= std_logic_vector(unsigned(commit_counter_out) + to_unsigned(4, 32));
        
        update_counter <= '1' when ((pc_out_1 = commit_counter_out and data_ready_1 = '1') or 
                                   (pc_out_2 = commit_counter_out and data_ready_2 = '1') or 
                                   (pc_out_3 = commit_counter_out and data_ready_3 = '1')) 
                                   else '0';
       
        m_w_val <= ula_out_1 when pc_out_1 = commit_counter_out and data_ready_1 = '1' else
                 ula_out_2 when pc_out_2 = commit_counter_out and data_ready_2 = '1' else
                 mem_out   when pc_out_3 = commit_counter_out and data_ready_3 = '1' else
                 (others=>'0');
                
        m_rd <= rd_out_1 when pc_out_1 = commit_counter_out and data_ready_1 = '1' else
              rd_out_2 when pc_out_2 = commit_counter_out and data_ready_2 = '1' else
              rd_out_3 when pc_out_3 = commit_counter_out and data_ready_3 = '1' else
              (others=>'0');
        
        m_op <= op_out_1 when pc_out_1 = commit_counter_out and data_ready_1 = '1' else
              op_out_2 when pc_out_2 = commit_counter_out and data_ready_2 = '1' else
              op_out_3 when pc_out_3 = commit_counter_out and data_ready_3 = '1' else
              (others=>'0');
        

        m_commit <= update_counter;

        cdb_3 <= data_ready_3 & mem_out;
        cdb_2 <= data_ready_2 & ula_out_2;
        cdb_1 <= data_ready_1 & ula_out_1;

end architecture execute_arch ; 
