-----------------------------------------------------------------------
-- Manticore: 3D Graphics Processor Core
-- http://icculus.org/manticore/
--
-- Portions of Manticore are freely available under the Design Science 
-- License. 
--
-- All source files with this header are distributed under the terms
-- of the Design Science License, which should have been packaged
-- with this source code. If it was not, a copy is available at
-- http://www.dsl.org/copyleft/dsl.txt
--
-- Source files without this header are not copyrighted by the 
-- Manticore project, and their use may be limited by their own
-- respective licenses.
--
-- Manticore is © 2002 Jeff Mrochuk and Benj Carson. Under the DSL, 
-- however, its source may be distributed, published or copied in its 
-- entirety provided the license is clearly published with all copies.
--
-- Jeff Mrochuk   jm@icculus.org
-- Benj Carson    benjcarson@digitaljunkies.ca
-----------------------------------------------------------------------

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
