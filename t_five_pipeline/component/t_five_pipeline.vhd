library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity t_five_pipeline is
    port (
        clock, reset: in std_logic
    );
end entity t_five_pipeline;

architecture structural of t_five_pipeline is
    component rom is
        generic(
            BE : integer := 12;
            BP : integer := 32;
            file_name : string := "mrom.txt";
            Tread : time := 5 ns
        );
        port(
            reset : in std_logic;
            ender : in std_logic_vector(BE - 1 downto 0);
            dado_out : out std_logic_vector(BP - 1 downto 0)
        );
    end component;

    component ram is
        generic(
            BE : integer := 12;
            BP : integer := 32;
            file_name : string := "mram.txt";
            Tz : time := 2 ns;
            Twrite : time := 5 ns;
            Tread : time := 5 ns
        );
        port(
            clk, reset :   in std_logic;
            rw :           in std_logic;
            ender :        in std_logic_vector(BE - 1 downto 0);
            dado_in :      in std_logic_vector(BP - 1 downto 0);
            dado_out :     out std_logic_vector(BP - 1 downto 0)
        );
    end component ram;

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

    component fetch is
        port(
            clk, reset: in std_logic;
    
            -- Sinais de controle
            pc_src     : in std_logic;
            
            -- Branches
            NPCJ       : in    std_logic_vector(31 downto 0);
    
            -- Interface com memoria de instrucoes
            imem_out   : in    std_logic_vector(31 downto 0);
            imem_add   : out   std_logic_vector(31 downto 0);
    
            -- Interface IF/ID
            IF_ID     : out   std_logic_vector(95 downto 0)
    
        );
    end component;
    
    component decode is 
    port(
        clk, reset: in std_logic;

        -- Interface IF/ID
        IF_ID: in   std_logic_vector(95 downto 0);
        
        -- Interface ID/IS
        ID_IS:  out std_logic_vector(152 downto 0);

        -- Entradas
        reg_write: in std_logic;
        rd_in: in std_logic_vector(4 downto 0);
        data_write: in std_logic_vector(31 downto 0)
    );

    end component;

    component issue is
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
        );
    end component;
    component execute is 
        port(
            -- input
            clock, reset: std_logic;

            -- interface IS/EX
            IS_EX: in std_logic_vector(431 downto 0);
            -- interface EX/COM

            EX_COM : out std_logic_vector(44 downto 0); 

            -- input (memory interface)
            data_read_in: in std_logic_vector(31 downto 0);

            -- output (memory interface)
            rw_out:         out std_logic;
            data_write:     out std_logic_vector(31 downto 0);
            address_out:    out std_logic_vector(31 downto 0);

            cdb_3:            out std_logic_vector(32 downto 0);
            cdb_2:            out std_logic_vector(32 downto 0);
            cdb_1:            out std_logic_vector(32 downto 0)
        );
    end component;
   
    component commit is 
        port(
            -- input
            clock, reset: std_logic;

            -- interface EX/COM
            EX_COM : in std_logic_vector(44 downto 0); 

            -- output 
            rd_out: out std_logic_vector(4 downto 0);
            w_val_out:     out std_logic_vector(31 downto 0);
            we:  out std_logic
        );
    end component;

    -- Sinais internos para memória
    signal m_rw: std_logic;
    signal m_imem_add, m_imem_out, m_dmem_add, m_dmem_out, m_dmem_in: std_logic_vector(31 downto 0);

    -- Sinais para registradores entre os estágios
    signal m_if_id_d, m_if_id_q : std_logic_vector(95 downto 0) := (others => '0');
    signal m_id_is_d, m_id_is_q : std_logic_vector(152 downto 0) := (others => '0');
    signal m_is_ex_d, m_is_ex_q : std_logic_vector(431 downto 0) := (others => '0');
    signal m_ex_com_d, m_ex_com_q : std_logic_vector(44 downto 0) := (others => '0');

    -- Sinais para comunicação com memória
    signal m_com_we: std_logic;
    signal m_com_val_out: std_logic_vector(31 downto 0);
    signal m_com_rd_out: std_logic_vector(4 downto 0);

    -- common data bus
    signal m_cdb_1, m_cdb_2, m_cdb_3: std_logic_vector(32 downto 0);

begin
IMEM: rom
    generic map(
        BE => 12,
        BP => 32,
        file_name => "t_five_pipeline/data/default_imem.txt",
        Tread => 5 ns
    )    
    port map( 
        reset => reset,
        ender => m_imem_add(13 downto 2),
        dado_out => m_imem_out
    );

DMEM: ram
    generic map(
        BE => 12,
        BP => 32,
        file_name => "t_five_pipeline/data/default_dmem.txt",
        Tz => 2 ns,
        Twrite => 5 ns,
        Tread => 5 ns
    )
    port map( 
        clk => clock,
        reset => reset,
        rw => m_rw,
        ender => m_dmem_add(13 downto 2),
        dado_in => m_dmem_in,
        dado_out => m_dmem_out
    );   

IF_ID: reg
    generic map(
        NB => 96,
        t_prop => 1 ns,
        t_hold => 0.25 ns,
        t_setup => 0.25 ns
    )

    port map(
        clk => clock,
        CE => '1',
        R => reset,
        S => '0',
        D => m_if_id_d,
        Q => m_if_id_q
    );

ID_IS: reg
    generic map(
        NB => 153,
        t_prop => 1 ns,
        t_hold => 0.25 ns,
        t_setup => 0.25 ns
    )

    port map(
        clk => clock,
        CE => '1',
        R => reset,
        S => '0',
        D => m_id_is_d,
        Q => m_id_is_q
    );

IS_EX: reg
    generic map(
        NB => 432,
        t_prop => 1 ns,
        t_hold => 0.25 ns,
        t_setup => 0.25 ns
    )

    port map(
        clk => clock,
        CE => '1',
        R => reset,
        S => '0',
        D => m_is_ex_d,
        Q => m_is_ex_q
    );

EX_COM: reg
    generic map(
        NB => 45,
        t_prop => 1 ns,
        t_hold => 0.25 ns,
        t_setup => 0.25 ns
    )

    port map(
        clk => clock,
        CE => '1',
        R => reset,
        S => '0',
        D => m_ex_com_d,
        Q => m_ex_com_q
    );

IF_STAGE: fetch 
    port map(
        clk => clock,
        reset => reset,
        pc_src => '0', --TODO
        NPCJ => (others=>'0'), --TODO
        imem_out => m_imem_out,
        imem_add => m_imem_add,
        IF_ID => m_if_id_d
    );

ID_STAGE: decode
    port map(
        clk => clock,
        reset => reset,

        -- Interface IF/ID
        IF_ID => m_if_id_q,

        -- Interface ID/IS
        ID_IS => m_id_is_d,

        -- Entradas
        reg_write => m_com_we, 
        rd_in => m_com_rd_out,
        data_write => m_com_val_out
    );

IS_STAGE: issue
    port map(
        clock => clock,
        reset => reset,

        -- interface ID/IS
        ID_IS => m_id_is_q,

        -- output
        IS_EX => m_is_ex_d,
        
        cdb_3 => m_cdb_3,
        cdb_2 => m_cdb_2,
        cdb_1 => m_cdb_1
        
    ) ;

EX_STAGE: execute
    port map(
        -- input
        clock => clock,
        reset => reset,

        IS_EX => m_is_ex_q,

        -- output

        EX_COM => m_ex_com_d,

        -- input (memory interface)
        data_read_in => m_dmem_out,

        -- output (memory interface)
        rw_out => m_rw,
        data_write => m_dmem_in,
        address_out => m_dmem_add,

        cdb_3 => m_cdb_3,
        cdb_2 => m_cdb_2,
        cdb_1 => m_cdb_1
    );

COM_STAGE: commit
    port map(
        -- input
        clock => clock,
        reset => reset,

        EX_COM => m_ex_com_q,
    
        -- output
        rd_out => m_com_rd_out,
        w_val_out => m_com_val_out,
        we => m_com_we
    );


end architecture structural ; 