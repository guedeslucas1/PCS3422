library IEEE;
use IEEE.std_logic_1164.all;

entity rs is
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
end rs;


architecture rs of rs is
    component rs_reg is
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
            Q : out std_logic_vector(NB - 1 downto 0);
            
            cdb_3: in std_logic_vector(32 downto 0);
            cdb_2: in std_logic_vector(32 downto 0);
            cdb_1: in std_logic_vector(32 downto 0)
        );
    end component;

    type rs_t is array (0 to 2)
        of std_logic_vector (146 downto 0);
 
    signal we_buff: std_logic_vector(2 downto 0) := (others=>'0');

    signal m_busy: std_logic_vector(2 downto 0) := (others=>'0');

    signal DOUT: rs_t := (others => (others => '0'));
    signal DIN, data_out : std_logic_vector (146 downto 0);

begin

    we_buff <= "000" when we = '0' else 
               "100" when m_busy(0) /= '0' else
               "010" when m_busy(1) /= '0' else 
               "001";

    DIN <= (PC_in & rd_in & funct3_in & op_in & Vj_in & Vk_in & Qj_in & QK_in & Imm_in);

    GEN_REG:
    for I in 0 to 2 generate
        REGX : rs_reg generic map(
            NB => 147,
            t_prop => 1 ns,
            t_hold => 0.25 ns,
            t_setup => 0.25 ns
        )
        port map(
             clk => clk, 
             R => reset, 
             CE => we_buff(I),
             S => '0',
             D => DIN,
             Q => DOUT(I),

             cdb_3 => cdb_3,
             cdb_2 => cdb_2,
             cdb_1 => cdb_1
        );

    end generate;

    data_out <= DOUT(0) when DOUT(0)(35 downto 34) = "00" and DOUT(0)(33 downto 32) = "00" and m_busy(0) = '1' else
                DOUT(1) when DOUT(1)(35 downto 34) = "00" and DOUT(1)(33 downto 32) = "00" and m_busy(1) = '1' else
                DOUT(2) when DOUT(2)(35 downto 34) = "00" and DOUT(2)(33 downto 32) = "00" and m_busy(2) = '1' else
                (others => '0');

    busy_up :
    process (clk, we_buff)
    begin
        if (clk'event and clk='1') then
            if we_buff = "001" then
                m_busy(0) <= '1'; 
            elsif we_buff = "010" then
                m_busy(1) <= '1';
            elsif we_buff = "100" then
                m_busy(2) <= '1';
            end if;
        end if;
    end process;

    registers_rename:
    process (clk, cdb_1, cdb_2, cdb_3)
    begin

        
    end process;

    -- busy_down :
    -- process (data_out)
    -- begin
    --     if data_out = DOUT(0) then
    --         m_busy(0) <= '0';    
    --     elsif data_out = DOUT(1) then
    --         m_busy(1) <= '0';
    --     elsif data_out = DOUT(2) then
    --         m_busy(2) <= '0';
    --     end if;
    -- end process;


    data_ready <= '1' when data_out /= (data_out'range => '0');

    PC_out     <=  data_out(146 downto 115);
    rd_out     <=  data_out(114 downto 110);
    funct3_out <=  data_out(109 downto 107);
    op_out     <=  data_out(106 downto 100);
    Vj_out     <=  data_out(99 downto 68);
    Vk_out     <=  data_out(67 downto 36);
    --(35 downto 34)
    --(33 downto 32)
    imm_out    <=  data_out(31 downto 0);

    busy <= '0' when m_busy = "000" else '1';
        
end rs ; -- rs