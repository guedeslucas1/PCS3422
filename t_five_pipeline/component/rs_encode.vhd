library IEEE;
use IEEE.std_logic_1164.all;

entity rs_encode is
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
end rs_encode;

architecture rs_encode of rs_encode is


begin
    
    Vj  <= rs1_value when rs1_status = "00" else (others => '0');
    Vk  <= rs2_value when rs2_status = "00" else (others => '0');
    Qj  <= rs1_status;
    Qk  <= rs2_status;

    rd_new_status <= (others =>'0') when (op /= "0000011") else 
                    "01" when fu_id = "001" else
                    "10" when fu_id = "010" else
                    "11" when fu_id = "100" else
                    (others =>'0');
                    
    we_out <= '1' when op = "0000011" else '0'; 

end rs_encode ; -- rs_encode