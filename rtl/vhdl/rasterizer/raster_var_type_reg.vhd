-------------------------------------------------------------------------------
-- Title      : Register for rasterizer type variables
-- Project    : the HULK
-------------------------------------------------------------------------------
-- File       : raster_var_type_reg.vhd
-- Author     : benj  <benj@ns1.digitaljunkies.ca>
-- Last update: 2002/03/31
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date      Author         Description
-- 2002/03/31      benj         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.memory_defs.all;

entity raster_var_type_reg is
  
  port (
    clock, reset : in  std_logic;
    d            : in  raster_var_type;
    q            : out raster_var_type);

end entity raster_var_type_reg;

architecture behavioural of raster_var_type_reg is

begin  -- architecture behavioural

  register_data: process (clock, reset) is
  begin  -- process register
    if reset = '0' then                 -- asynchronous reset (active low)
      q <= t_coord_x0;      
    elsif clock'event and clock = '1' then  -- rising clock edge
      q <= d;
    end if;
  end process register_data;

end architecture behavioural;
