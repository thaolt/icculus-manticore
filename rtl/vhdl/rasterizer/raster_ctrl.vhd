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
-- Title      : Rasterizer Control Engine
-- Project    : 
-------------------------------------------------------------------------------
-- File       : raster_ctrl.vhd
-- Author     : benj  <benj@ns1.digitaljunkies.ca>
-- Last update: 2002/04/07
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: Controls rasterizer, slope_calc engine and triangle buffer.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date      Author         Description
-- 2002/03/31      benj         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

library work;
use work.memory_defs.all;

entity raster_ctrl is
  
  port (
    reset, clock : in std_logic;

    -- Signals from triangle buffer
    Triangles_Ready : in std_logic;
    
    -- Rasterizer signals
    Draw_Start : out std_logic;
    Draw_Done  : in  std_logic;    
    R_Enable   : out std_logic;
    Coord_R_Enable : out std_logic;

    -- Rasterizer variable register signal
    Full_Flag  : in  std_logic;
    Proj_Coord_Flag : in std_logic;
 
    -- Outputs to slope_calc engine
    Data_Type         : out raster_var_type;
    slope_calc_Enable : out std_logic;
    A, B, C, D        : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    Num_Add_Sub       : out std_logic;  -- + if = '1'
    Den_Add_Sub       : out std_logic;

    -- Outputs to xform engine
--    axis              : out std_logic_vector(1 downto 0);
--    x_form_enable     : out std_logic;

    -- Inputs from triangle buffer
    x0, y0, z0, x1, y1, z1, x2, y2, z2 : in std_logic_vector(RASTER_DATAWIDTH-1 downto 0);


    -- Projected coordinates for slope calculation
    x0_proj_in, y0_proj_in, z0_proj_in, 
    x1_proj_in, y1_proj_in, z1_proj_in, 
    x2_proj_in, y2_proj_in, z2_proj_in : in std_logic_vector(RASTER_DATAWIDTH-1 downto 0)
    );
  
end entity raster_ctrl;


architecture behav of raster_ctrl is

  type state_type is (idle, xform_x, wait_x,
                      xform_y, wait_y, 
                      x_form_z, wait_z,
                      send_x0, send_x1, send_x2,
                      send_y0, send_y1, send_y2,
                      send_z0, send_z1, send_z2, wait_proj,
                      send_slope01, send_slope12, send_slope02,
                      send_z_slope01, send_z_slope12, send_z_slope02,
                      send_dz_dx01, send_dz_dx12, send_dz_dx02,
                      full_wait, load_coords, done_wait, load_wait);
  signal state : state_type;

  signal proj_ready : std_logic;
  signal x0_proj, y0_proj, z0_proj, 
         x1_proj, y1_proj, z1_proj, 
         x2_proj, y2_proj, z2_proj  : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);

begin  -- architecture behav
               

  -- purpose: Feeds slope_calc the correct data
  -- type   : sequential
  -- inputs : clock, reset, *_flg, Draw_Done
  -- outputs: Draw_Start, A, B, C, D, R_Enable, Coord_R_Enable, slope_calc_
  -- Enable, Draw_Start, Num/Den_Add_Sub 
  feed_data : process (clock, reset) is
  begin  -- process feed_data
    if reset = '0' then                 -- asynchronous reset (active low)
      Draw_Start  <= '0';
      A           <= (others => '0');
      B           <= (others => '0');
      C           <= (others => '0');
      D           <= (others => '0');
      Num_Add_Sub <= '0';
      Den_Add_Sub <= '0';

      R_Enable          <= '0';
      Coord_R_Enable    <= '0';
      slope_calc_Enable <= '0';
      state             <= idle;

    elsif clock'event and clock = '1' then  -- rising clock edge
      case state is
        when idle =>

          Draw_Start <= '0';
          A          <= (others => '0');
          B          <= (others => '0');
          C          <= (others => '0');
          D          <= (others => '0');

          R_Enable          <= '0';
          Coord_R_Enable    <= '0';
          slope_calc_Enable <= '0';

          if Triangles_Ready = '1' then
            state <= send_x0;
          else
            state <= idle;
          end if;

        when send_x0 =>
          A           <= (others => '0') ;
          B           <= x0;--"0101000000" & "000000";  -- 320
          Num_Add_Sub <= '0';                      -- Subtract A & B

          C           <= "0000000001" & "000000";  -- 1
          D           <= "000000" & (z0(15 downto 6)+ conv_std_logic_vector(128,10)); -- Divide z0 by lambda (which we've decided is 64)
          Den_Add_Sub <= '0';                      -- Subtract C & D

          slope_calc_Enable <= '1';
          data_type         <= t_coord_x0;

          state <= send_x1;

        when send_x1 =>
          A           <= (others => '0'); --x1;
          B           <= x1;-- "0101000000" & "000000";  -- 320
          Num_Add_Sub <= '0';                      -- Subtract A & B

          C           <= "0000000001" & "000000";  -- 1
          D           <= "000000" & (z1(15 downto 6)+ conv_std_logic_vector(128,10)); -- Divide z0 by lambda (which we've decided is 64)
          Den_Add_Sub <= '0';                      -- Subtract C & D

          slope_calc_Enable <= '1';
          data_type         <= t_coord_x1;

          state <= send_x2;

        when send_x2 =>
          A           <= (others => '0'); --x2;
          B           <= x2; --"0101000000" & "000000";  -- 320
          Num_Add_Sub <= '0';                      -- Subtract A & B

          C           <= "0000000001" & "000000";  -- 1
          D           <= "000000" & (z2(15 downto 6)+ conv_std_logic_vector(128,10)); -- Divide z0 by lambda (which we've decided is 64)
          Den_Add_Sub <= '0';                      -- Subtract C & D

          slope_calc_Enable <= '1';
          data_type         <= t_coord_x2;

          state <= send_y0;

        when send_y0 =>
          A           <= y0;
          B           <= (others => '0');-- "0011110000" & "000000";  -- 240
          Num_Add_Sub <= '0';                      -- Subtract A & B

          C <= "0000000001" & "000000";  -- 1
          D <= "000000" & (z0(15 downto 6) + conv_std_logic_vector(128,10)); -- Divide z0 by lambda (which we've decided is 64)

          Den_Add_Sub       <= '0';     -- Subtract C & D
          slope_calc_Enable <= '1';
          data_type         <= t_coord_y0;

          state <= send_y1;

        when send_y1 =>
          A           <= y1;
          B           <= (others => '0'); --"0011110000" & "000000";  -- 240
          Num_Add_Sub <= '0';                      -- Subtract A & B

          C           <= "0000000001" & "000000";  -- 1
          D <= "0000000" & (z1(15 downto 6) + conv_std_logic_vector(128,10)); -- Divide z0 by lambda (which we've decided is 64)
          Den_Add_Sub <= '0';                      -- Subtract C & D

          slope_calc_Enable <= '1';
          data_type         <= t_coord_y1;

          state <= send_y2;

        when send_y2 =>
          A           <= y2;
          B           <= (others => '0'); --"0011110000" & "000000";  -- 240
          Num_Add_Sub <= '0';                      -- Subtract A & B

          C           <= "0000000001" & "000000";  -- 1
          D <= "000000" & (z2(15 downto 6) + conv_std_logic_vector(128,10)); -- Divide z0 by lambda (which we've decided is 64)
          Den_Add_Sub <= '0';                      -- Subtract C & D

          slope_calc_Enable <= '1';
          data_type         <= t_coord_y2;

          state <= send_z0;

        when send_z0 =>
          A           <= z0 ;
          B           <= (others => '0');     -- 480
          Num_Add_Sub <= '0';                 -- Subtract A & B

          C           <= "0000000001" & "000000";  -- 1
          D           <= (others => '0');     --z0;
          Den_Add_Sub <= '0';                 -- Subtract C & D

          slope_calc_Enable <= '1';
          data_type         <= t_coord_z0;

          state <= send_z1;

        when send_z1 =>
          A           <= z1 ;
          B           <= (others => '0');  -- 480
          Num_Add_Sub <= '0';                 -- Subtract A & B

          C           <= "0000000001" & "000000";  -- 1
          D           <= (others => '0');
          Den_Add_Sub <= '0';                 -- Subtract C & D

          slope_calc_Enable <= '1';
          data_type         <= t_coord_z1;

          state <= send_z2;

        when send_z2 =>
          A           <= z2;
          B           <= (others => '0');  -- 480
          Num_Add_Sub <= '0';                 -- Subtract A & B

          C           <= "0000000001" & "000000";  -- 1
          D           <= (others => '0');
          Den_Add_Sub <= '0';                 -- Subtract C & D

          slope_calc_Enable <= '1';
          data_type         <= t_coord_z2;

          state <= send_z_slope01;
    
        when send_z_slope01 =>
          A <= z1;
          B <= z0;
          Num_Add_Sub <= '0';
          C <= y1;
          D <= y0;
          Den_Add_Sub <= '0';

          slope_calc_Enable <= '1';
          data_type <= t_z_slope01;

          state <= send_z_slope12;

        when send_z_slope12 =>
          A <= z2;
          B <= z1;
          Num_Add_Sub <= '0';
          C <= y2;
          D <= y1;
          Den_Add_Sub <= '0';

          slope_calc_Enable <= '1';
          data_type <= t_z_slope12;

          state <= send_z_slope02;

        when send_z_slope02 =>
          A <= z2;
          B <= z0;
          Num_Add_Sub <= '0';
          C <= y2;
          D <= y0;
          Den_Add_Sub <= '0';

          slope_calc_Enable <= '1';
          data_type <= t_z_slope02;

          state <= send_dz_dx01;

        when send_dz_dx01 =>
          A <= z1;
          B <= z0;
          Num_Add_Sub <= '0';
          C <= x1;
          D <= x0;
          Den_Add_Sub <= '0';

          slope_calc_Enable <= '1';
          data_type <= t_dz_dx01;

          state <= send_dz_dx12;

       when send_dz_dx12 =>
         A <= z2;
         B <= z1;
         Num_Add_Sub <= '0';
         C <= x2;
         D <= x1;
         Den_Add_Sub <= '0';

         slope_calc_Enable <= '1';
         data_type <= t_dz_dx12;

         state <= send_dz_dx02;

       when send_dz_dx02 =>
         A <= z2;
         B <= z0;
         Num_Add_Sub <= '0';
         C <= x2;
         D <= x0;
         Den_Add_Sub <= '0';

         slope_calc_Enable <= '1';
         data_type <= t_dz_dx02;

         state <= wait_proj;

        when wait_proj =>

          slope_calc_Enable <= '0';
          Coord_R_Enable <= '1';
            
          if Proj_Coord_Flag = '1' then         

            state <= load_coords;
            
          else
            state <= wait_proj;
          
          end if;

        when load_coords =>
          x0_proj <= x0_proj_in;
          x1_proj <= x1_proj_in;
          x2_proj <= x2_proj_in;
          y0_proj <= y0_proj_in;
          y1_proj <= y1_proj_in;
          y2_proj <= y2_proj_in;
          z0_proj <= z0_proj_in;
          z1_proj <= z1_proj_in;
          z2_proj <= z2_proj_in;

          state <= send_slope01;

        when send_slope01 =>
          Coord_R_Enable <= '0';

          A <= x1_proj;
          B <= x0_proj;
          Num_Add_Sub <= '0';
          C <= y1_proj;
          D <= y0_proj;
          Den_Add_Sub <= '0';

          slope_calc_Enable <= '1';
          data_type <= t_slope01;

          state <= send_slope12;

        when send_slope12 =>
          A <= x2_proj;
          B <= x1_proj;
          Num_Add_Sub <= '0';
          C <= y2_proj;
          D <= y1_proj;
          Den_Add_Sub <= '0';

          slope_calc_Enable <= '1';
          data_type <= t_slope12;

          state <= send_slope02;

        when send_slope02 =>
          A <= x2_proj;
          B <= x0_proj;
          Num_Add_Sub <= '0';
          C <= y2_proj;
          D <= y0_proj;
          Den_Add_Sub <= '0';

          slope_calc_Enable <= '1';
          data_type <= t_slope02;

          state <= full_wait;

        when full_wait =>
          slope_calc_Enable <= '0';
          -- Wait for all values to make it out of the dy/dx engine
          if Full_Flag = '1' then
            state <= done_wait;
          else
            state <= full_wait;
          end if;
  
        when done_wait =>
          -- Put the new values on the wire
          R_Enable   <= '1';

          if Draw_Done = '1' then       -- If the rasterizer is ready, let 'er rip
            state      <= Load_Wait;
            Draw_Start <= '1';
          else
            Draw_Start <= '0';
            state      <= Done_Wait;
          end if;

        when load_wait =>
          Draw_Start <= '0';

          if Draw_Done = '0' then
            state <= idle;
          else
            state <= Load_Wait;
          end if;
        when others => null;

      end case;
    end if;
  end process feed_data;

end architecture behav;
