library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity issue is
  port (
    clock, reset: in std_logic;

    -- interface ID/IS
    ID_IS:  in std_logic_vector(152 downto 0);
    -- output

    --interface IS/EX
    IS_EX: out std_logic_vector(431 downto 0);  
    -- -- output rs1

    -- in (cdb)
    cdb_3: in std_logic_vector(32 downto 0);
    cdb_2: in std_logic_vector(32 downto 0);
    cdb_1: in std_logic_vector(32 downto 0)
  ) ;
end issue;

architecture issue_arch of issue is
    component fu_id_sel is
        port (
            clock, rst: std_logic;
        
            --in
            op     : in std_logic_vector(6 downto 0);
            fu_busy: in std_logic_vector(2 downto 0); -- 0: mem, 1: alu_1, 2:alu_2
        
            --out
            fu_id:  out std_logic_vector(2 downto 0)
        ) ;
      end component;

    component reg_status is
        generic(
            NBadd : integer := 5;
            NBfu : integer := 2; 
            t_read : time := 5 ns;
            t_write : time := 5 ns
        );
        port(
            clk, reset    : in std_logic;
            we            : in std_logic;
            reg_read_a    : in std_logic_vector(NBadd - 1 downto 0);
            reg_read_B    : in std_logic_vector(NBadd - 1 downto 0);
            reg_write_add : in std_logic_vector(NBadd - 1 downto 0);
            reg_write_in  : in std_logic_vector(NBfu - 1 downto 0);
            status_out_a  : out std_logic_vector(NBfu - 1 downto 0);
            status_out_b  : out std_logic_vector(NBfu - 1 downto 0)
        );
    end component;
      
    component rs_encode is
        port (
            -- inputs
            op          : in std_logic_vector(6  downto 0);
            funct3      : in std_logic_vector(2  downto 0);
            rs1_status  : in std_logic_vector(1  downto 0);
            rs2_status  : in std_logic_vector(1  downto 0);
            rs1_value   : in std_logic_vector(31 downto 0);
            rs2_value   : in std_logic_vector(31 downto 0);
            rd          : in std_logic_vector(4  downto 0);
            fu_id       : in std_logic_vector(2  downto 0);

            --outputs
            Qj  : out std_logic_vector(1  downto 0);
            Qk  : out std_logic_vector(1  downto 0);
            Vj  : out std_logic_vector(31 downto 0);
            Vk  : out std_logic_vector(31 downto 0);
            Imm_out : out std_logic_vector(31 downto 0);

            rd_new_status: out std_logic_vector(1 downto 0);
            we_out       : out std_logic
        );
    end component;

    component rs is
        port (
            clk, reset: in std_logic;
        
            -- in
            we:    in std_logic; -- bit do fu_id (fu_id_sel)
    
            funct3_in: in std_logic_vector(2  downto 0); 
            Op_in:     in std_logic_vector(6  downto 0);
            Vj_in:     in std_logic_vector(31 downto 0);
            Vk_in:     in std_logic_vector(31 downto 0);
            Qj_in:     in std_logic_vector(1  downto 0);
            Qk_in:     in std_logic_vector(1  downto 0);
            Imm_in:    in std_logic_vector(31 downto 0);
            rd_in:     in std_logic_vector(4  downto 0);
            PC_in:     in std_logic_vector(31 downto 0);
    
            -- out
            data_ready: out std_logic;
    
            Vj_out:     out std_logic_vector(31 downto 0);
            Vk_out:     out std_logic_vector(31 downto 0);
            Imm_out:    out std_logic_vector(31 downto 0);
            funct3_out: out std_logic_vector(2  downto 0);
            rd_out:     out std_logic_vector(4  downto 0);
            PC_out:     out std_logic_vector(31 downto 0);
            op_out:     out std_logic_vector(6  downto 0);
            busy:       out std_logic;
    
            -- in (cdb)
            cdb_3: in std_logic_vector(32 downto 0);
            cdb_2: in std_logic_vector(32 downto 0);
            cdb_1: in std_logic_vector(32 downto 0)
        ) ;
    end component;

    -- signals for ID/IS interface
    signal m_op:                std_logic_vector(6 downto 0);
    signal m_funct3:            std_logic_vector(2 downto 0);
    signal m_imm:               std_logic_vector(31 downto 0);
    signal m_rd, m_rs1, m_rs2:  std_logic_vector(4 downto 0);
    signal m_rs1_v, m_rs2_v, m_pc:    std_logic_vector(31 downto 0);

    --signals for IS/EX interface
    signal m_op_1: std_logic_vector(6 downto 0);
    signal m_funct3_1: std_logic_vector(2 downto 0);
    signal m_Vj_1, m_Vk_1, m_Imm_1, m_pc_1: std_logic_vector(31 downto 0);
    signal m_data_ready_1: std_logic;
    signal m_rd_1: std_logic_vector(4 downto 0);
    signal m_busy_1: std_logic;
    
    signal m_op_2: std_logic_vector(6 downto 0);
    signal m_funct3_2: std_logic_vector(2 downto 0);
    signal m_Vj_2, m_Vk_2, m_Imm_2, m_pc_2: std_logic_vector(31 downto 0);
    signal m_data_ready_2: std_logic;
    signal m_rd_2: std_logic_vector(4 downto 0);
    signal m_busy_2: std_logic;
    
    signal m_op_3: std_logic_vector(6 downto 0);
    signal m_funct3_3: std_logic_vector(2 downto 0);
    signal m_Vj_3, m_Vk_3, m_Imm_3, m_pc_3: std_logic_vector(31 downto 0);
    signal m_data_ready_3: std_logic;
    signal m_rd_3: std_logic_vector(4 downto 0);
    signal m_busy_3: std_logic;

    -- internal signals
    signal m_fu_sel_out: std_logic_vector(2 downto 0) := (others=> '0');
    signal m_status_out_a, m_status_out_b: std_logic_vector(1 downto 0) := (others=> '0');

    signal m_rs_code_out: std_logic_vector(166 downto 0) := (others=> '0');
    signal m_rd_new_status: std_logic_vector(1 downto 0);
    signal m_we_out: std_logic;
    signal m_rs_busy: std_logic_vector(2 downto 0);

    signal m_Vk, m_Vj: std_logic_vector(31 downto 0);
    signal m_Qk, m_Qj: std_logic_vector(1 downto 0);

begin
    --ID/IS
    m_pc    <= ID_IS(152 downto 121);
    m_rs2_v <= ID_IS(120 downto 89);
    m_rs1_v <= ID_IS(88 downto 57);
    m_rs2 <= ID_IS(56 downto 52);
    m_rs1 <= ID_IS(51 downto 47);
    m_rd <= ID_IS(46 downto 42);
    m_imm <= ID_IS(41 downto 10);
    m_funct3 <= ID_IS(9 downto 7);
    m_op <= ID_IS(6 downto 0);
    

    --IS/EX

    IS_EX(431) <= m_data_ready_3;
    IS_EX(430 downto 399) <= m_pc_3;
    IS_EX(398 downto 394) <= m_rd_3;
    IS_EX(393 downto 362) <= m_Imm_3;
    IS_EX(361 downto 330) <= m_Vk_3;
    IS_EX(329 downto 298) <= m_Vj_3;
    IS_EX(297 downto 295) <= m_funct3_3;
    IS_EX(294 downto 288) <= m_op_3;

    IS_EX(287) <= m_data_ready_2;
    IS_EX(286 downto 255) <= m_pc_2;
    IS_EX(254 downto 250) <= m_rd_2;
    IS_EX(249 downto 218) <= m_Imm_2;
    IS_EX(217 downto 186) <= m_Vk_2;
    IS_EX(185 downto 154) <= m_Vj_2;
    IS_EX(153 downto 151) <= m_funct3_2;
    IS_EX(150 downto 144) <= m_op_2;

    IS_EX(143) <= m_data_ready_1;
    IS_EX(142 downto 111) <= m_pc_1;
    IS_EX(110 downto 106) <= m_rd_1;
    IS_EX(105 downto 74) <= m_Imm_1;
    IS_EX(73 downto 42) <= m_Vk_1;
    IS_EX(41 downto 10) <= m_Vj_1;
    IS_EX(9 downto 7) <= m_funct3_1;
    IS_EX(6 downto 0) <= m_op_1;

    m_rs_busy <= m_busy_3 & m_busy_2 & m_busy_1;

    fu_id_sel_inst: fu_id_sel
    port map(
        clock => clock,
        rst => reset,
        op  => m_op,
        fu_busy => m_rs_busy,
        fu_id => m_fu_sel_out
    );

    reg_status_inst: reg_status
    port map(
        clk => clock,
        reset => reset,
        we => m_we_out,
        reg_read_a => m_rs1,
        reg_read_B => m_rs2,
        reg_write_add => m_rd,
        reg_write_in => m_rd_new_status,
        status_out_a => m_status_out_a,
        status_out_b => m_status_out_b
    );

    m_rd_new_status <= "01" when m_fu_sel_out = "001" else
                       "10" when m_fu_sel_out = "010" else
                       "11" when m_fu_sel_out = "100" else
                       "00";

    rs_encode_int: rs_encode
    port map(
        op => m_op,
        funct3 => m_funct3,
        rs1_status => m_status_out_a,
        rs2_status => m_status_out_b,
        rs1_value => m_rs1_v,
        rs2_value => m_rs2_v,
        rd => m_rd,
        fu_id => m_fu_sel_out,

        --outputs
        Qj  => m_Qj,
        Qk  => m_Qk,
        Vj  => m_Vj,
        Vk  => m_Vk
    );

    rs_alu1: rs
    port map(
        clk => clock,
        reset => reset,
    
        -- in
        we => m_fu_sel_out(0),

        funct3_in => m_funct3,
        Op_in  => m_op,
        Vj_in  => m_Vj,
        Vk_in  => m_Vk,
        Qj_in  => m_Qj,
        Qk_in  => m_Qk,
        Imm_in => m_Imm,
        rd_in  => m_rd,
        pc_in  => m_pc,

        -- out
        data_ready => m_data_ready_1,

        Vj_out =>     m_Vj_1,
        Vk_out =>     m_Vk_1,
        Imm_out =>    m_Imm_1,
        funct3_out => m_funct3_1,
        op_out     => m_op_1,
        pc_out     => m_pc_1,
        rd_out     => m_rd_1,
        busy       => m_busy_1,

        cdb_3 => cdb_3,
        cdb_2 => cdb_2,
        cdb_1 => cdb_1
    );

    rs_alu2: rs
    port map(
        clk => clock,
        reset => reset,
    
        -- in
        we => m_fu_sel_out(1),

        funct3_in => m_funct3, 
        Op_in  => m_op,
        Vj_in  => m_Vj,
        Vk_in  => m_Vk,
        Qj_in  => m_Qj,
        Qk_in  => m_Qk,
        Imm_in => m_Imm,
        rd_in  => m_rd,
        pc_in  => m_pc,

        -- out
        data_ready => m_data_ready_2,

        Vj_out =>     m_Vj_2,
        Vk_out =>     m_Vk_2,
        Imm_out =>    m_Imm_2,
        funct3_out => m_funct3_2,
        op_out     => m_op_2,
        pc_out     => m_pc_2,
        rd_out     => m_rd_2,
        busy       => m_busy_2,

        cdb_3 => cdb_3,
        cdb_2 => cdb_2,
        cdb_1 => cdb_1
    );

    rs_alu3: rs
    port map(
        clk => clock,
        reset => reset,
    
        -- in
        we => m_fu_sel_out(2),

        funct3_in => m_funct3,
        Op_in  => m_op,
        Vj_in  => m_Vj,
        Vk_in  => m_Vk,
        Qj_in  => m_Qj,
        Qk_in  => m_Qk,
        Imm_in => m_Imm,
        rd_in  => m_rd,
        pc_in  => m_pc,

        -- out
        data_ready => m_data_ready_3,

        Vj_out =>     m_Vj_3,
        Vk_out =>     m_Vk_3,
        Imm_out =>    m_Imm_3,
        funct3_out => m_funct3_3,
        op_out     => m_op_3,
        pc_out     => m_pc_3,
        rd_out     => m_rd_3,
        busy       => m_busy_3,

        cdb_3 => cdb_3,
        cdb_2 => cdb_2,
        cdb_1 => cdb_1

    );
end issue_arch ; -- issue_arch