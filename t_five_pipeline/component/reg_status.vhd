
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_status is
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
end reg_status;

architecture reg_status of reg_status is
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

---- Architecture declarations -----
type reg_status_t is array (0 to 2**NBadd - 1)
        of std_logic_vector (NBfu - 1 downto 0);

signal regs: reg_status_t := (others => (others => '0'));


type reg_file_t is array (0 to 2**NBadd - 1)
          of std_logic_vector (NBfu - 1 downto 0);

signal DOUT: reg_file_t := (others => (others => '0'));
signal CE: std_logic_vector(2**NBadd - 1 downto 0) := (others=>'0');

begin

---- Processes ----

UpdateCE:
process (reg_write_add)

begin
     CE <= (others => '0');
     CE(to_integer(unsigned(reg_write_add))) <= '1';
end process;


GEN_REG:
for I in 0 to 2**NBadd - 1 generate
     REGX : reg 
     generic map (
               NB => NBfu,
               t_prop => 1 ns,
               t_hold => 0.25 ns,
               t_setup => 0.25 ns
     )
     port map(
          clk => clk, 
          R => reset, 
          CE => CE(I),
          S => '0',
          D => reg_write_in,
          Q => DOUT(I)
     );
end generate;


---- User Signal Assignments ----
status_out_a <= DOUT(to_integer(unsigned (reg_read_a))) after t_read;
status_out_b <= DOUT(to_integer(unsigned (reg_read_B))) after t_read;

end reg_status;
