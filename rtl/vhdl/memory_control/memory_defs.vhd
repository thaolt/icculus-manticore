-------------------------------------------------------------------------------
-- Title      : Memory Constant Definitions
-- Project    : HULK
-------------------------------------------------------------------------------
-- File       : vgaout_top.vhd
-- Author     : Benj Carson <benjcarson@digitaljunkies.ca>
-- Last update: 2002/04/07
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: Memory Constant Definitions
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Author        Description
-- 2002/03/05   benj          Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package memory_defs is

  constant ADDRESS_BANK_WIDTH   : integer := 2;   -- SDRAM bank select width
  constant ADDRESS_ROW_WIDTH    : integer := 12;  -- SDRAM row address width
  constant ADDRESS_COLUMN_WIDTH : integer := 9;   -- SDRAM column address width
  constant COLUMN_START         : integer := 0;
  constant COLUMN_END           : integer := COLUMN_START + ADDRESS_COLUMN_WIDTH;
  constant ROW_START            : integer := 9;
  constant ROW_END              : integer := ROW_START + ADDRESS_ROW_WIDTH;

  constant ADDRESS_WIDTH        : integer := ADDRESS_BANK_WIDTH + ADDRESS_ROW_WIDTH + ADDRESS_COLUMN_WIDTH;  -- Address width to SDRAM

  constant DATA_WIDTH           : integer := 64;  -- SDRAM Data width
  constant ADDRESS_WIDTH_INT    : integer := 4;
                                        -- Address width for internal module
  constant VGA_ADDRESS_INT      : std_logic_vector(ADDRESS_WIDTH_INT-1 downto 0) := "0001";  --conv_std_logic_vector(1,ADDRESS_WIDTH_INT);
                                        -- Internal address of the VGA output module
  constant RASTER_ADDRESS_INT   : std_logic_vector(ADDRESS_WIDTH_INT-1 downto 0) := "0010";  --conv_std_logic_vector(2,ADDRESS_WIDTH_INT);
                                        -- Internal address of the rasterizer
  constant Z_BUFFER_ADDRESS_INT : std_logic_vector(ADDRESS_WIDTH_INT-1 downto 0) := "0011";  --conv_std_logic_vector(3,ADDRESS_WIDTH_INT);  
                                        -- Internal address of the z-buffer
  constant VERTEX_ADDRESS_INT   : std_logic_vector(ADDRESS_WIDTH_INT-1 downto 0) := "0100";  --conv_std_logic_vector(4,ADDRESS_WIDTH_INT);  
                                        -- Internal address of the vertex buffer
  constant X_FORM_ADDRESS_INT   : std_logic_vector(ADDRESS_WIDTH_INT-1 downto 0) := "0101";  --conv_std_logic_vector(5, ADDRESS_WIDTH_INT);  
                                        -- Internal address of transform unit
  constant RASTER_DATAWIDTH     : integer := 16;
  constant WRITE_FIFO_DEPTH     : integer := 15;

  type raster_var_type is (t_coord_x0, t_coord_y0, t_coord_z0,
                           t_coord_x1, t_coord_y1, t_coord_z1,
                           t_coord_x2, t_coord_y2, t_coord_z2,
                           t_slope01, t_slope12, t_slope02,
                           t_z_slope01, t_z_slope12, t_z_slope02,
                           t_dz_dx01, t_dz_dx12, t_dz_dx02);
end memory_defs;

------------------------------------------------------------------------------------------------------------------------
-- END MEMORY DEFS
------------------------------------------------------------------------------------------------------------------------
