-- Design unit header --
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity execute_mem2 is 
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
end entity;

architecture execute_arch of execute_mem2 is

    begin

        data_read_out <= data_read_in;

        rw_out <= rw_in;
        data_write <= w_value;
        address_out <= address_in;

        PC_out <= PC_in;
        rd_out <= rd_in;
        op_out <= op_in;
        data_ready_out <= data_ready_in;
end architecture execute_arch ; 
