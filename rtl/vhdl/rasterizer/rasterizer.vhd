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

-- EE552 Project 'The Hulk' 3D Video Accelerator
-- Triangle Rasterizer Component
-- Inputs need are the three vertices, and the three slopes that the set of vertices make up.  Assumes
-- the vertices are sorted starting wih the lowest y-value then going counterclockwise.  Output is the
-- x and y coordinates that make up the triangle.  The algorithm used is one that splits up the triangle
-- into two: a top half and a bottom half.  

-- All values are 16 bit fixed point numbers: 10 digit integer part, 6 digit
-- decimal part.
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

library work;
use work.memory_defs.all;
use work.vgaout_defs.all;

entity rasterizer is

    port(
      clock, reset : in std_logic;
      coord_x0     : in std_logic_vector(raster_datawidth-1 downto 0);
      coord_y0     : in std_logic_vector(raster_datawidth-1 downto 0);
      coord_x1     : in std_logic_vector(raster_datawidth-1 downto 0);
      coord_y1     : in std_logic_vector(raster_datawidth-1 downto 0);
      coord_x2     : in std_logic_vector(raster_datawidth-1 downto 0);
      coord_y2     : in std_logic_vector(raster_datawidth-1 downto 0);
      coord_z0     : in std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_z1     : in std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_z2     : in std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      slope01      : in std_logic_vector(raster_datawidth-1 downto 0);
      slope12      : in std_logic_vector(raster_datawidth-1 downto 0);
      slope02      : in std_logic_vector(raster_datawidth-1 downto 0);
      z_slope01    : in std_logic_vector(raster_datawidth-1 downto 0);
      z_slope12    : in std_logic_vector(raster_datawidth-1 downto 0);
      z_slope02    : in std_logic_vector(raster_datawidth-1 downto 0);
      dz_dx01      : in std_logic_vector(raster_datawidth-1 downto 0);
      dz_dx12      : in std_logic_vector(raster_datawidth-1 downto 0);
      dz_dx02      : in std_logic_vector(raster_datawidth-1 downto 0);

      color : in std_logic_vector(COLOR_DEPTH-1 downto 0);

      -- Signals to write fifo
      W_Enable   : out std_logic;
      address    : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      data       : out std_logic_vector(DATA_WIDTH-1 downto 0);
      mask       : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
      fifo_level : in  std_logic_vector(3 downto 0);

      -- Control signals
      draw_start : in  std_logic;
      draw_done  : out std_logic
      );

end rasterizer;


architecture behavioural of rasterizer is

  component lpm_shiftreg is
    generic (LPM_WIDTH     : POSITIVE;
             LPM_AVALUE    : STRING := "UNUSED";
             LPM_SVALUE    : STRING := "UNUSED";
             LPM_PVALUE    : STRING := "UNUSED";
             LPM_DIRECTION : STRING := "UNUSED";
             LPM_TYPE      : STRING := "LPM_SHIFTREG";
             LPM_HINT      : STRING := "UNUSED");

    port (data                         : in  std_logic_vector(LPM_WIDTH-1 downto 0) := (others => '0');
          clock                        : in  std_logic;
          enable, shiftin              : in  std_logic := '1';
          load, sclr, sset, aclr, aset : in  std_logic := '0';
          q                            : out std_logic_vector(LPM_WIDTH-1 downto 0);
          shiftout                     : out std_logic);
  end component;

  component shiftreg_8x8 is
      generic (
    WIDTH    : positive := 64;
    IN_WIDTH : positive := 8);
  port (
--    data     : in  std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    clock    : in  std_logic;
    reset    : in  std_logic;
    enable   : in  std_logic;
    shiftin  : in  std_logic_vector(IN_WIDTH-1 downto 0);
    q        : out std_logic_vector(WIDTH-1 downto 0);
    shiftout : out std_logic_vector(IN_WIDTH-1 downto 0));
  end component shiftreg_8x8;
  

  COMPONENT lpm_ff
   GENERIC (LPM_WIDTH: POSITIVE;
      LPM_AVALUE: STRING := "UNUSED";
      LPM_SVALUE: STRING := "UNUSED";
      LPM_PVALUE: STRING := "UNUSED";
      LPM_FFTYPE: STRING := "DFF";
      LPM_TYPE: STRING := "LPM_FF";
      LPM_HINT: STRING := "UNUSED");
   PORT (data: IN STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0);
      clock: IN STD_LOGIC;
      enable: IN STD_LOGIC := '1';
      sload, sclr, sset, aload, aclr, aset: IN STD_LOGIC := '0';
      q: OUT STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0));
  END COMPONENT;


  component dff is
    port (
      d    : in  std_logic;
      clk  : in  std_logic;
      clrn : in  std_logic := '1';
      prn  : in  std_logic := '1';
      q    : out std_logic);
  end component dff;

  COMPONENT DFFEA
   PORT (d   : IN STD_LOGIC;
      clk 	: IN STD_LOGIC;
      clrn	: IN STD_LOGIC := '1';
      prn 	: IN STD_LOGIC := '1';
      ena 	: IN STD_LOGIC := '1';
      adata	: IN STD_LOGIC := '1';
      aload	: IN STD_LOGIC;	  	  
      q   	: OUT STD_LOGIC );
  END COMPONENT;


  component lpm_compare is
    generic (LPM_WIDTH          : POSITIVE;
             LPM_REPRESENTATION : STRING  := "UNSIGNED";
             LPM_PIPELINE       : INTEGER := 0;
             LPM_TYPE           : STRING  := "LPM_COMPARE";
             LPM_HINT           : STRING  := "UNUSED");

    port (dataa, datab                    : in  std_logic_vector(LPM_WIDTH-1 downto 0);
          aclr, clock                     : in  std_logic := '0';
          clken                           : in  std_logic := '1';
          agb, ageb, aeb, aneb, alb, aleb : out std_logic);

  end component;  

  component lpm_add_sub is
    generic (LPM_WIDTH: POSITIVE;
             LPM_REPRESENTATION: STRING := "SIGNED";
             LPM_DIRECTION: STRING := "UNUSED";
             LPM_PIPELINE: INTEGER := 0;
             LPM_TYPE: STRING := "LPM_ADD_SUB";
             LPM_HINT: STRING := "UNUSED");

    port (dataa, datab     : in  STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);
          aclr, clock, cin : in  STD_LOGIC := '0';
          add_sub          : in  STD_LOGIC := '1';
          clken            : in  STD_LOGIC := '1';
          result           : out STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);

          cout, overflow: out STD_LOGIC);
  end component;

  -- Vertex sorter signals 
  signal y0_lt_y1, y0_lt_y2, y1_lt_y2, y0_eq_y1, y0_eq_y2, y1_eq_y2,
         x0_lt_x1, x0_lt_x2, x1_lt_x2, x0_eq_x1, x0_eq_x2, x1_eq_x2 : std_logic;

  signal x_vector : std_logic_vector(2 downto 0);

  -- LPM Data/Enable Delay signals
  signal shift_reg_enable_stg1,  shift_reg_enable_stg2,
         shift_reg_enable_stg3,  shift_reg_enable_stg4  : std_logic;
  signal data_to_shift_reg_stg1, data_to_shift_reg_stg2,
         data_to_shift_reg_stg3, data_to_shift_reg_stg4 : std_logic_vector(COLOR_DEPTH-1 downto 0);
  signal mask_to_shift_reg_stg1, mask_to_shift_reg_stg2,
         mask_to_shift_reg_stg3, mask_to_shift_reg_stg4 : std_logic;

  signal start_x, end_x, count_x, count_y                         : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal x01, x02, x01_delta, x02_delta, next_x, next_slope       : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal count_z, z01, z01_delta, dz_dx,  next_z_slope : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal y_min, y_max, y_max2                                     : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);

  signal done                      : std_logic;

  signal data_to_shift_reg : std_logic_vector(COLOR_DEPTH-1 downto 0);
  signal mask_to_shift_reg : std_logic;
  signal shift_reg_enable  : std_logic;

  signal clear : std_logic;
  signal reg_reset : std_logic;

  -- Address resolver pipeline signals
  signal fifo_level_stg1    : std_logic_vector(3 downto 0);
  signal done_stg1, not_done_stg1, not_done_stg2, not_done_stg3,
    fifo_ne_max_stg1, fifo_ne_max_stg2,
    count_x_gt_start_x_stg1, count_x_gt_start_x_stg2,
    count_y_gt_y0_stg1, count_y_gt_y0_stg2,
    count_y_gt_y_min_stg1, count_y_gt_y_min_stg2,
    count_y_ne_y_max_stg1, count_y_ne_y_max_stg2,
    count_y_ge_y_max2_stg1, count_y_ge_y_max2_stg2,
    A, B, C, D, E, F,
    Draw_Enable_stg2, Draw_Enable_stg3,
    W_Enable_compare, W_Enable_stg3, Addr_eq_8, Addr_Enable: std_logic;
  signal count_x_stg1, count_x_stg2, count_x_stg3, count_x_stg4,
    start_x_stg1,
    count_y_stg1, count_y_stg2, count_y_stg3, count_y_stg4,
    y_min_stg1,
    y_max_stg1, y_max2_stg1 : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);



  signal Address_stg3 : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal fifo_max  : std_logic_vector(3 downto 0);
  signal three_Ohs : std_logic_vector(2 downto 0);
  signal one       : std_logic_vector(1 downto 0);
  signal one_7_bit : std_logic_vector(6 downto 0);

-----------------------
-- Shading constants --
-----------------------

constant shadelevel0: std_logic_vector(COLOR_DEPTH-1 downto 0)  := "11111111";
constant shadelevel1: std_logic_vector(COLOR_DEPTH-1 downto 0)  := "11011011";
constant shadelevel2: std_logic_vector(COLOR_DEPTH-1 downto 0)  := "10110110";
constant shadelevel3: std_logic_vector(COLOR_DEPTH-1 downto 0)  := "10010010";
constant shadelevel4: std_logic_vector(COLOR_DEPTH-1 downto 0)  := "01101101";
constant shadelevel5: std_logic_vector(COLOR_DEPTH-1 downto 0)  := "01001001";
constant shadelevel6: std_logic_vector(COLOR_DEPTH-1 downto 0)  := "00100101";
constant shadelevel7: std_logic_vector(COLOR_DEPTH-1 downto 0)  := "00100100";


constant shadedepth1: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0001100000000000"; -- 96
constant shadedepth2: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0001110000000000"; -- 112
constant shadedepth3: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0010000000000000"; -- 128
constant shadedepth4: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0010010000000000"; -- 144
constant shadedepth5: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0010100000000000"; -- 160
constant shadedepth6: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0010110000000000"; -- 176
constant shadedepth7: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0011000000000000"; -- 192
constant shadedepth8: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0011010000000000"; -- 208

----------------------
-- Shading signals  --
----------------------

signal shademask: std_logic_vector(COLOR_DEPTH-1 downto 0);


begin

  clear <= (not reset); -- done or 
  draw_done <= done;
  reg_reset <= reset; --(not done) and reset;

  fifo_max <= "1111";
  three_Ohs <= "000";
  one       <= "01";
  one_7_bit <= "0000001";

  -----------------------------------------------------------------------------
  -- Generate signals necessary for sorting vertices
  -----------------------------------------------------------------------------

  y0_y1_comp : lpm_compare
    generic map (
      LPM_WIDTH          => 10,
      LPM_REPRESENTATION => "SIGNED")
    port map (
      dataa => coord_y0(15 downto 6),
      datab => coord_y1(15 downto 6),
      aeb   => y0_eq_y1,
      alb   => y0_lt_y1
      );
  
  y0_y2_comp : lpm_compare
  generic map (
      LPM_WIDTH          => 10,
      LPM_REPRESENTATION => "SIGNED")
    port map (
      dataa => coord_y0(15 downto 6),
      datab => coord_y2(15 downto 6),
      aeb   => y0_eq_y2,
      alb   => y0_lt_y2
      );

  y1_y2_comp : lpm_compare
  generic map (
      LPM_WIDTH          => 10,
      LPM_REPRESENTATION => "SIGNED")
    port map (
      dataa => coord_y1(15 downto 6),
      datab => coord_y2(15 downto 6),
      aeb   => y1_eq_y2,
      alb   => y1_lt_y2
      );

   x0_x1_comp : lpm_compare
     generic map (
       LPM_WIDTH          => 10,
       LPM_REPRESENTATION => "SIGNED")
     port map (
       dataa => coord_x0(15 downto 6),
       datab => coord_x1(15 downto 6),
       aeb   => x0_eq_x1,
       alb   => x0_lt_x1
       );
 
   x0_x2_comp : lpm_compare
   generic map (
       LPM_WIDTH          => 10,
       LPM_REPRESENTATION => "SIGNED")
     port map (
       dataa => coord_x0(15 downto 6),
       datab => coord_x2(15 downto 6),
       aeb   => x0_eq_x2,
       alb   => x0_lt_x2
       );

   x1_x2_comp : lpm_compare
   generic map (
       LPM_WIDTH          => 10,
       LPM_REPRESENTATION => "SIGNED")
     port map (
       dataa => coord_x1(15 downto 6),
       datab => coord_x2(15 downto 6),
       aeb   => x1_eq_x2,
       alb   => x1_lt_x2
       );
  
  -----------------------------------------------------------------------------
  --
  --   x_vector   order
  --     000      2-1-0
  --     001      1-2-0
  --     011      1-0-2
  --     100      2-0-1
  --     110      0-2-1
  --     111      0-1-2                
  --
  -----------------------------------------------------------------------------

  x_vector(2) <= x0_lt_x1;
  x_vector(1) <= x0_lt_x2;
  x_vector(0) <= x1_lt_x2;
  
  calculate: process(clock,reset) is

  begin
    if reset='0' then
      start_x   <= (others => '0');
      end_x     <= (others => '0');
      x01       <= (others => '0');
      x02       <= (others => '0');
      x01_delta <= (others => '0');
      x02_delta <= (others => '0');
      count_x   <= (others => '0');
      count_y   <= (others => '0');

      y_min     <= (others => '0');
      y_max     <= (others => '0');
      y_max2    <= (others => '0');

      data_to_shift_reg <= (others => '0');
      mask_to_shift_reg <= '1';
      shift_reg_enable  <= '0';

      done <= '1';

      count_z   <= (others => '0');

      dz_dx <= (others => '0');

      z01       <= (others => '0');
      z01_delta <= (others => '0');

      next_slope   <= (others => '0');
      next_x       <= (others => '0');
      next_z_slope <= (others => '0');
 

    elsif clock'event and clock = '1' then    

      if draw_start = '1' and done = '1' then -- Load new values if we're not doing anything

        data_to_shift_reg <= (others => '0');
        mask_to_shift_reg <= '1';
        shift_reg_enable  <= '0';

        done <= '0';

        -- Since addresses can only be specified in multiples of 4 *words*, we take the
        -- nearest multiple of four words (32 pixels) less than the leftmost
        -- vertex as the starting point.  We end up scanning a rectangle and
        -- deterimining  which points are within the triangle.

        -- x01 is the coordinate on the current scan line along one edge of
        -- the triangle, and x02 is the other.  x01_delta and x02_delta
        -- are the dx/dy values for the edges.

        -- z01 walks the left edge of the triangle in z.  z01_delta the dz/dy
        -- for the left edge, and dz_dx is the change in z across one scan line.
        
        ---------------------
        --
        -- or 1        0                 
        --    0--------1    
        --     \      /     
        --      \    /      
        --       \  /       
        --        \/        
        --         2        
        --                 
        ---------------------        
        if y0_eq_y1 = '1' and y0_lt_y2 = '1' then
  
          x01 <= coord_x0;
          x02 <= coord_x1;
          x01_delta <= slope02;
          x02_delta <= slope12;

          count_y <= coord_y0;
          y_min   <= coord_y0;
          y_max   <= coord_y2;
          y_max2  <= coord_y2;


          dz_dx     <= dz_dx01;
          
          if x0_lt_x1 = '1' then
            count_z   <= coord_z0;
            z01       <= coord_z0;
            z01_delta <= z_slope02;

          else
            count_z <= coord_z1;
            z01     <= coord_z1;
            z01_delta <= z_slope12;
          end if;          
        
        ---------------------
        --
        --    2        1                 
        -- or 1--------2    
        --     \      /     
        --      \    /      
        --       \  /       
        --        \/        
        --         0        
        --                 
        ---------------------        
        elsif y1_eq_y2 = '1' and y0_lt_y1 = '0' then

          x01 <= coord_x1;
          x02 <= coord_x2;
          x01_delta <= slope01;
          x02_delta <= slope12;

          count_y <= coord_y1;
          y_min   <= coord_y1;
          y_max   <= coord_y0;
          y_max2  <= coord_y0;

          dz_dx <= dz_dx12;

          if x1_lt_x2 = '1' then
            count_z   <= coord_z1;
            z01       <= coord_z1;
            z01_delta <= z_slope01;
          else
            count_z <= coord_z2;
            z01     <= coord_z2;
            z01_delta <= z_slope02;
          end if;

        
        ---------------------
        --
        --    2        0                 
        -- or 0--------2    
        --     \      /     
        --      \    /      
        --       \  /       
        --        \/        
        --         1        
        --                 
        ---------------------        
        elsif y0_eq_y2 = '1' and y0_lt_y1 = '1' then

          x01 <= coord_x0;
          x02 <= coord_x2;
          x01_delta <= slope01;
          x02_delta <= slope12;

          count_y <= coord_y0;
          y_min   <= coord_y0;
          y_max   <= coord_y1;
          y_max2  <= coord_y1;

          dz_dx <= dz_dx02;

          if x0_lt_x2 = '1' then
            count_z   <= coord_z0;
            z01       <= coord_z0;
            z01_delta <= z_slope01;
          else
            count_z <= coord_z2;
            z01     <= coord_z2;
            z01_delta <= z_slope12;
          end if;

        
        ---------------------
        --                 
        --        0
        --        /\ 
        --       /  \
        --      /    \
        --     /      \
        --    1--------2
        -- or 2        1                
        ---------------------        
        elsif y0_lt_y1 = '1' and y0_lt_y2 = '1' then
          
          x01 <= coord_x0;
          x02 <= coord_x0;
          x01_delta <= slope01;
          x02_delta <= slope02;
          next_slope <= slope12;
          
          count_y <= coord_y0;
          y_min   <= coord_y0;

          z01     <= coord_z0;
          count_z <= coord_z0;

          dz_dx <= dz_dx12;

          if x1_lt_x2 = '1' then
            z01_delta    <= z_slope01;
            next_z_slope <= z_slope12;

          else
            z01_delta    <= z_slope02;
            next_z_slope <= z_slope12;

          end if;

          if y1_lt_y2 = '1' then
            y_max  <= coord_y1;
            y_max2 <= coord_y2;
            next_x <= coord_x1;
          else
            y_max  <= coord_y2;
            y_max2 <= coord_y1;
            next_x <= coord_x2;
          end if;

        ---------------------
        --                  
        --        1
        --        /\ 
        --       /  \
        --      /    \
        --     /      \
        --    0--------2
        -- or 2        0          
        ---------------------        
        elsif y1_lt_y2 = '1' then
          
          x01 <= coord_x1;
          x02 <= coord_x1;
          x01_delta <= slope01;
          x02_delta <= slope12;
          next_slope <= slope02;

          count_y <= coord_y1;
          y_min   <= coord_y1;

          z01     <= coord_z1;
          count_z <= coord_z1;

          dz_dx <= dz_dx02;
          
          if x0_lt_x2 = '1'  then
            z01_delta    <= z_slope01;
            next_z_slope <= z_slope02;

          else
            z01_delta    <= z_slope12;
            next_z_slope <= z_slope02;

          end if;

          if y0_lt_y2 = '1' then
            y_max  <= coord_y0;
            y_max2 <= coord_y2;
            next_x <= coord_x0;
          else
            y_max  <= coord_y2;
            y_max2 <= coord_y0;
            next_x <= coord_x2;
          end if;

        ---------------------
        --                 
        --       2
        --       /\ 
        --      /  \
        --     /    \
        --    /      \
        --   1--------0
        --   0        1     
        ---------------------        
        else
          
          x01 <= coord_x2;
          x02 <= coord_x2;
          x01_delta <= slope02;
          x02_delta <= slope12;
          next_slope <= slope01;

          count_y <= coord_y2;
          y_min   <= coord_y2;

          z01     <= coord_z2;
          count_z <= coord_z2;

          dz_dx <= dz_dx01;

          if x0_lt_x1 = '1' then
            z01_delta    <= z_slope02;
            next_z_slope <= z_slope01;

          else
            z01_delta    <= z_slope12;
            next_z_slope <= z_slope01;

          end if;

          if y0_lt_y1 = '1' then
            y_max  <= coord_y0;
            y_max2 <= coord_y1;
            next_x <= coord_x0;
          else
            y_max  <= coord_y1;
            y_max2 <= coord_y0;
            next_x <= coord_x1;
          end if;

        end if;

        -----------------------------------------------------------------------------
        --
        --   x_vector   order
        --     000      2-1-0
        --     001      1-2-0
        --     011      1-0-2
        --     100      2-0-1
        --     110      0-2-1
        --     111      0-1-2                
        --
        -----------------------------------------------------------------------------
        case x_vector is
          when "111" =>                 -- x-order = 0-1-2
            start_x <= coord_x0(15 downto 11) & "00000000000";
            count_x <= coord_x0(15 downto 11) & "00000000000";
            end_x   <= coord_x2(15 downto 11) & "11111000000";

          when "110" =>                 -- x-order = 0-2-1
            start_x <= coord_x0(15 downto 11) & "00000000000";
            count_x <= coord_x0(15 downto 11) & "00000000000";
            end_x   <= coord_x1(15 downto 11) & "11111000000";

          when "011" =>                 -- x-order = 1-0-2

            start_x <= coord_x1(15 downto 11) & "00000000000";
            count_x <= coord_x1(15 downto 11) & "00000000000";
            end_x   <= coord_x2(15 downto 11) & "11111000000";

          when "001" =>                 -- x-order = 1-2-0
            start_x <= coord_x1(15 downto 11) & "00000000000";
            count_x <= coord_x1(15 downto 11) & "00000000000";
            end_x   <= coord_x0(15 downto 11) & "11111000000";

          when "100" =>                 -- x-order = 2-0-1
            start_x <= coord_x2(15 downto 11) & "00000000000";
            count_x <= coord_x2(15 downto 11) & "00000000000";
            end_x   <= coord_x1(15 downto 11) & "11111000000";

          when "000" =>                 -- x-order = 2-1-0
            start_x <= coord_x2(15 downto 11) & "00000000000";
            count_x <= coord_x2(15 downto 11) & "00000000000";
            end_x   <= coord_x0(15 downto 11) & "11111000000";
            
          when others => null;
        end case;

      -- Start (or continue) drawing the triangle if we're not finished and if
      -- the write fifo still has room.
      elsif (done = '0' and fifo_level /= "1111") then

        if count_y(15 downto 6) < y_max(15 downto 6) then
          
          -- count_x is to the left of the triangle
          if count_x(15 downto 6) < x01(15 downto 6) and count_x(15 downto 6) < x02(15 downto 6) then

            count_x(15 downto 6) <= count_x(15 downto 6) + "000000001";

            data_to_shift_reg <= (others => '0');
            mask_to_shift_reg <= '1';
            shift_reg_enable  <= '1';

            -- count_x is inside the triangle:
          elsif count_x(15 downto 6) <= x01(15 downto 6) or count_x(15 downto 6) <= x02(15 downto 6) then 
            
            count_x(15 downto 6) <= count_x(15 downto 6) + "0000000001";
            count_z <= count_z + dz_dx;

            data_to_shift_reg <= color AND shademask;
            mask_to_shift_reg <= '0';
            shift_reg_enable  <= '1';

            
            -- count_x is past the right edge of the triangle
          elsif count_x(15 downto 6) < end_x(15 downto 6) then

            count_x(15 downto 6) <= count_x(15 downto 6) + "0000000001";

            data_to_shift_reg <= (others => '0');
            mask_to_shift_reg <= '1';
            shift_reg_enable  <= '1';
            
            -- count_x is at the end of the line
          else
            
            x01 <= x01 + x01_delta;
            x02 <= x02 + x02_delta;
            
            shift_reg_enable <= '0';

            count_x <= start_x;

            count_y(15 downto 6) <= count_y(15 downto 6) + "0000000001";
            z01 <= z01 + z01_delta;
            count_z <= z01 + z01_delta;

          end if;

        -- One pixel past the very end aaaannnd, we're done!
        elsif count_y(15 downto 6) >= y_max2(15 downto 6) and count_x(15 downto 6) > start_x(15 downto 6) then
          done <= '1';        
          shift_reg_enable  <= '0';
        -- Not quite done.  We need to draw one past the end to ensure that all the data is
        -- sent to the write fifo correctly.
        elsif count_y(15 downto 6) >= y_max2(15 downto 6) then
          count_x(15 downto 6) <= count_x(15 downto 6) + "0000000001";
          shift_reg_enable  <= '0';

        -- Render the bottom half of the triangle:
        else 
          y_max <= y_max2;
          shift_reg_enable  <= '0';

          -- Update slopes if we've hit a corner (for the bottom half of the triangle)
          if (x01(15 downto 6) < x02(15 downto 6) and x01(15 downto 6) = next_x(15 downto 6)) or 
             (x02(15 downto 6) < x01(15 downto 6) and x02(15 downto 6) = next_x(15 downto 6)) then
            z01_delta <= next_z_slope;
          end if;
          
          if x01(15 downto 6) = next_x(15 downto 6) then 
            x01_delta <= next_slope;
          else
            x02_delta <= next_slope;
          end if;
          
        end if;
      end if;
    end if;
  end process calculate;

     

 ------------------------------------------------------------------------------
 -- Shading Process
 ------------------------------------------------------------------------------

  shader: process(count_z) is
  
	begin
	
    if count_z > shadedepth8 then    -- > 208
	    shademask <= shadelevel7;
    elsif count_z > shadedepth7 then -- > 192
	    shademask <= shadelevel6;
    elsif count_z > shadedepth6 then -- > 176
	    shademask <= shadelevel5;
    elsif count_z > shadedepth5 then -- > 160
	    shademask <= shadelevel4;
	elsif count_z > shadedepth4 then -- > 144
	    shademask <= shadelevel3;
	elsif count_z > shadedepth3 then -- > 128
	    shademask <= shadelevel2;
	elsif count_z > shadedepth2 then -- > 112
	    shademask <= shadelevel1;
	elsif count_z > shadedepth1 then -- > 96
	    shademask <= shadelevel0;
	else
	    shademask <= shadelevel0;
    end if;

  end process shader;
   


  -----------------------------------------------------------------------------
  -- Pipeline Input Stage
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- Here's the function we're about to pipeline:
  -- Draw_Enable <= (( done = '0' and fifo_level /= "1111") and
  -- (( count_x > start_x or (count_y > y_min and count_y /= y_max))
  -- or (count_y >= y_max2)))
  -----------------------------------------------------------------------------

  -- Mask, Data & Shift_Reg signals
  
  dff_reg_enable_level_1 : dff
    port map(
      d    => shift_reg_enable,                    
      clk  => clock,                      
      clrn => reset,
      q    => shift_reg_enable_stg1                                            
      );  


  dff_reg_mask_level_1: dff
    port map(
      d    => mask_to_shift_reg,
      clk  => clock,
      prn  => reset,
      q    => mask_to_shift_reg_stg1
      );

  
  lpm_reg_data_level_1: lpm_ff
    generic map( LPM_WIDTH => COLOR_DEPTH  )
    port map(
      data   => data_to_shift_reg,                    
      clock  => clock,                      
      aclr   => clear,
      q      => data_to_shift_reg_stg1                                            
      );

  -- Address resolver signals
  done_ff_stg1 : dff
    port map (
      clk  => clock,      
      d    => done,
      q    => done_stg1,
      clrn => reset);

  fifo_level_ff_stg1 : lpm_ff
    generic map (
      LPM_WIDTH => 4)
    port map (
      data  => fifo_level,
      aclr  => clear,
      clock => clock,
      q     => fifo_level_stg1);

  count_x_ff_stg1 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => count_x,
      aset  => clear,
      clock => clock,
      q     => count_x_stg1
      );

  start_x_ff_stg1 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => start_x,
      aclr  => clear,
      clock => clock,
      q     => start_x_stg1
      );

  count_y_ff_stg1 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => count_y,
      aclr  => clear,
      clock => clock,
      q     => count_y_stg1
      );

  y_min_ff_stg1 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => y_min,
      aclr  => clear,
      clock => clock,
      q     => y_min_stg1
      );

  y_max_ff_stg1 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => y_max,
      aclr  => clear,
      clock => clock,
      q     => y_max_stg1
      );

  y_max2_ff_stg1 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => y_max2,
      aclr  => clear,
      clock => clock,
      q     => y_max2_stg1
      );
  

  -----------------------------------------------------------------------------
  -- Pipeline stage 1
  -----------------------------------------------------------------------------

  -- Mask, Data & Shift_Reg signals

  dff_reg_enable_level_2 : dff
    port map(
      d    => shift_reg_enable_stg1,                    
      clk  => clock,                      
      clrn => reset,
      q    => shift_reg_enable_stg2                                            
      );

  dff_reg_mask_level_2   : dff
    port map(
      d    => mask_to_shift_reg_stg1,                    
      clk  => clock,                      
      prn  => reset,
      q    => mask_to_shift_reg_stg2                                            
      );


  lpm_reg_data_level_2: lpm_ff
    generic map( LPM_WIDTH => COLOR_DEPTH  )
    port map(
      data   => data_to_shift_reg_stg1,                    
      clock  => clock,                      
      aclr   => clear,
      q      => data_to_shift_reg_stg2                                            
      );

  -- Address resolver signals


  count_x_ff_stg2 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => count_x_stg1,
      clock => clock,
      aset  => clear,
      q     => count_x_stg2
      );

  count_y_ff_stg2 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => count_y_stg1,
      clock => clock,
      aclr  => clear,
      q     => count_y_stg2
      );

  fifo_ne_max_comp : component lpm_compare
    generic map (
      LPM_WIDTH          => 4,
      LPM_REPRESENTATION => "UNSIGNED"
      )
    port map (
      dataa => fifo_level_stg1,
      datab => fifo_max,
      aneb  => fifo_ne_max_stg1);
  

  count_x_gt_start_x_comp : lpm_compare
    generic map (
      LPM_WIDTH => 10,
      LPM_REPRESENTATION => "UNSIGNED"
      )
    port map (
      dataa => count_x_stg1(15 downto 6),
      datab => start_x_stg1(15 downto 6),
      agb   => count_x_gt_start_x_stg1
      );

  count_y_gt_y_min_comp : lpm_compare
    generic map (
      LPM_WIDTH          => 10,
      LPM_REPRESENTATION => "UNSIGNED"
      )
    port map (
      dataa => count_y_stg1(15 downto 6),
      datab => y_min_stg1(15 downto 6),
      agb   => count_y_gt_y_min_stg1
      );

  count_y_ne_y_max_comp : lpm_compare
    generic map (
      LPM_WIDTH          => 10,
      LPM_REPRESENTATION => "UNSIGNED"
      )
    port map (
      dataa  => count_y_stg1(15 downto 6),
      datab  => y_max_stg1(15 downto 6),
      aneb   => count_y_ne_y_max_stg1
      );

  count_y_ge_y_max2 : lpm_compare
    generic map (
      LPM_WIDTH          => 10,
      LPM_REPRESENTATION => "UNSIGNED" 
      )
    port map (
      dataa => count_y_stg1(15 downto 6),
      datab => y_max2(15 downto 6),
      ageb  => count_y_ge_y_max2_stg1
      );

  not_done_stg1 <= not done_stg1;

  not_done_ff_stg : dff
    port map (
      clk     => clock,
      d       => not_done_stg1,
      q       => not_done_stg2,
      clrn    => reset
    );

  dff2_stg2 : dff
    port map (
      clk  => clock,
      d    => fifo_ne_max_stg1,
      q    => fifo_ne_max_stg2,
      clrn => reset
      );

  dff3_stg2 : dff
    port map (
      clk  => clock,
      d    => count_x_gt_start_x_stg1,
      q    => count_x_gt_start_x_stg2,
      clrn => reset
      );

  dff4_stg2 : dff
    port map (
      clk  => clock,
      d    => count_y_gt_y_min_stg1,
      q    => count_y_gt_y_min_stg2,
      clrn => reset
      );

  dff5_stg2 : dff
    port map (
      clk  => clock,
      d    => count_y_ne_y_max_stg1,
      q    => count_y_ne_y_max_stg2,
      clrn => reset
      );

  dff6_stg2 : dff
    port map (
      clk  => clock,
      d    => count_y_ge_y_max2_stg1,
      q    => count_y_ge_y_max2_stg2,
      clrn => reset
      );

  -----------------------------------------------------------------------------
  -- Pipeline stage 2
  -----------------------------------------------------------------------------

  -- Mask, Data & Shift_Reg signals
  dff_reg_enable_level_3 : dff
    port map(
      d    => shift_reg_enable_stg2,                    
      clk  => clock,                      
      clrn => reset,
      q    => shift_reg_enable_stg3                                            
      );

  dff_reg_mask_level_3   : dff
    port map(
      d    => mask_to_shift_reg_stg2,                
      clk  => clock,                      
      prn  => reset,
      q    => mask_to_shift_reg_stg3                                         
      );
  
  lpm_reg_data_level_3: lpm_ff
    generic map( LPM_WIDTH => COLOR_DEPTH  )
    port map(
      data   => data_to_shift_reg_stg2,  
      clock  => clock,                      
      aclr   => clear,
      q      => data_to_shift_reg_stg3                                           
      );

  -- This is what we're trying to accomplish:
  -- Draw_Enable <= (( done = '0' and fifo_level /= "1111") and
  -- (( count_x > start_x or (count_y > y_min and count_y /= y_max))
  -- or (count_y >= y_max2)))
  --
  -- This is what the variables are called:
  -- Draw_Enable <=  A and ((B or C) or D)
  -- Draw_Enable <=  A and ( E or D)
  -- Draw_Enable <=  A and F
  
  A <= not_done_stg2 and fifo_ne_max_stg2;
  B <= count_x_gt_start_x_stg2;
  C <= count_y_gt_y_min_stg2 and count_y_ne_y_max_stg2;
  D <= count_y_ge_y_max2_stg2;
  E <= B or C;
  F <= E or D;
  Draw_Enable_stg2 <= A and F;

  Draw_Enable_ff_stg3 : dff
    port map (
      clk  => clock,
      d    => Draw_Enable_stg2,
      q    => Draw_Enable_stg3,
      clrn => reset
      );
  

  -- Address resolver signals
  count_x_ff_stg3 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => count_x_stg2,
      clock => clock,
      aset  => clear,
      q     => count_x_stg3
      );

  count_y_ff_stg4 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => count_y_stg2,
      clock => clock,
      aclr  => clear,
      q     => count_y_stg3
      );

  -----------------------------------------------------------------------------
  -- Final address resolution (stage 3)
  -----------------------------------------------------------------------------

  -- Mask, Data & Shift_Reg signals
  dff_reg_enable_level_4 : dff
    port map(
      d    => shift_reg_enable_stg3,
      clk  => clock,                      
      clrn  => reset,
      q    => shift_reg_enable_stg4                                           
      );

  dff_reg_mask_level_4   : dff
    port map(
      d    => mask_to_shift_reg_stg3,                
      clk  => clock,                      
      prn => reset,
      q    => mask_to_shift_reg_stg4                                         
      );
  
  lpm_reg_data_level_4: lpm_ff
    generic map( LPM_WIDTH => COLOR_DEPTH  )
    port map(
      data   => data_to_shift_reg_stg3,  
      clock  => clock,                      
      aclr   => clear,
      q      => data_to_shift_reg_stg4                                           
      );


  -- Address resolver signals
  count_x_lo_comp_stg3 : lpm_compare
    generic map (
      LPM_WIDTH          => 3,
      LPM_REPRESENTATION => "UNSIGNED")
    port map (
      dataa  => count_x_stg3(8 downto 6),
      datab  => three_Ohs,
      aeb    => W_Enable_compare
      );

  count_x_mid_comp_stg3 : lpm_compare
    generic map (
      LPM_WIDTH          => 2,
      LPM_REPRESENTATION => "UNSIGNED")
    port map (
      dataa => count_x_stg3(10 downto 9),
      datab => one,
      aeb   => Addr_eq_8
      );
  
  W_Enable_stg3 <= Draw_Enable_stg3 and W_Enable_compare;

  Addr_Enable <= W_Enable_stg3 and Addr_eq_8;
  
  W_Enable_reg_stg3 : dff
    port map (
      d    => W_Enable_stg3,
      clk  => clock,
      clrn => reset,
      q    => W_Enable

      );

  -- Address slicing:
  --
  --   Bank                Row                         Column
  -- |<- ->|<-                            ->|<-                      ->|
  -- |21 20|19 18 17 16 15 14 13 12 11 10  9| 8  7  6  5  4  3  2  1  0|
  -- 
  -- |     |<-           count_y          ->|<-        count_x       ->|
  -- | x  x| x 15 14 13 12 11 10  9  8  7  6| x  x 15 14 13 12 11 10  9|
  --
  -- The column address is in words of 64 bits.  Each word is 8 pixels.
  -- The column address corresponding to an eight pixel block is the 9th
  -- and higher bits in count_x.

  Address_stg3(22 downto 19) <= "0000";

 -- address_stg3(18 downto 9)  <= count_y_stg3(15 downto 6) ;
    Address_stg3(18) <= count_y_stg3(15);
    Address_stg3(17 downto 13) <= count_y_stg3(14 downto 10);-- + "01111";
    Address_stg3(12 downto 9)  <= count_y_stg3(9 downto 6);
    address_stg3(8 downto 7)   <= "00";

  address_add_sub : lpm_add_sub
    generic map (
      LPM_WIDTH          => 7,
      LPM_REPRESENTATION => "UNSIGNED",
      LPM_DIRECTION      => "SUB")
    port map (
      dataa  => count_x_stg3(15 downto 9),
      datab  => one_7_bit,
      result => address_stg3(6 downto 0)
      );
  
  address_reg : lpm_ff
    generic map (
      LPM_WIDTH => ADDRESS_WIDTH)
    port map (
      enable => Addr_Enable,
      data   => Address_stg3,
      clock  => clock,
      aclr   => clear,
      q      => address
      );
  

  
-- Shift Registers
  
  data_shift_reg_inst : shiftreg_8x8
    port map (
      clock   => clock,
      enable  => shift_reg_enable_stg4,
      shiftin => data_to_shift_reg_stg4,
      reset   => reg_reset,
      q       => data);

  mask_shift_reg_inst : lpm_shiftreg
    generic map (
      LPM_WIDTH     => DATA_WIDTH/8,
      LPM_DIRECTION => "LEFT")
    port map (
      clock   => clock,
      enable  => shift_reg_enable_stg4,
      shiftin => mask_to_shift_reg_stg4,
      aclr    => clear,
      q       => mask);


  -- purpose: Sends contents of shift registers to write fifo
  -- type   : sequential
  -- inputs : clock, reset, count_x, line_done
  -- outputs: W_Enable 
--    output_control: process (clock, reset) is
--    begin  -- process output_control
--      if reset = '0' then                 -- asynchronous reset (active low)

--        W_Enable                <= '0';
--        address                 <= (others => '0');      
--        done_stg1               <= '0';
--        count_x_stg1            <= (others => '0');
--        fifo_level_stg1         <= (others => '0');
--        start_x_stg1            <= (others => '0');
--        count_y_stg1            <= (others => '0');
--        coord_y0_stg1           <= (others => '0');
--        y_max_stg1              <= (others => '0');
--        y_max2_stg1             <= (others => '0');

--        done_stg2               <= '0';
--        fifo_stg2               <= '0';
--        count_x_gt_start_x_stg2 <= '0';
--        count_y_gt_y0_stg2      <= '0';
--        count_y_ne_y_max        <= '0';
--        count_y_gt_y_max2       <= '0';
--        Draw_Enable             <= '0';

--        count_x_stg3            <= (others => '0');
--        count_y_stg3            <= (others => '0');

--      elsif clock'event and clock = '1' then  -- rising clock edge
--        -- Pipeline ugly comparison:
--        done_stg1        <= done;
--        fifo_level_stg1  <= fifo_level;
--        count_x_stg1     <= count_x(15 downto 6);
--        start_x_stg1     <= start_x(15 downto 6);
--        count_y_stg1     <= count_y(15 downto 6);
--        coord_y0_stg1    <= coord_y0(15 downto 6);
--        y_max_stg1       <= y_max(15 downto 6);
--        y_max2_stg1      <= y_max2;

--        -- First combinational block:
--        done_stg2 <= not done_stg1;

--        if fifo_level_stg1 /= "1111" then
--          fifo_stg2 <= '1';
--        else
--          fifo_stg2 <= '0';
--        end if;

--        if count_x_stg1 > start_x_stg1 then 
--           count_x_gt_start_x_stg2 <= '1';
--        else
--           count_x_gt_start_x_stg2 <= '0';
--        end if;

--        if count_y_stg1 > coord_y0_stg1 then 
--           count_y_gt_y0_stg2 <= '1';
--        else
--           count_y_gt_y0_stg2 <= '0';
--        end if;
       
--        if count_y_stg1 /= y_max_stg1 then
--           count_y_ne_y_max <= '1';
--        else
--           count_y_ne_y_max <= '0';      
--        end if;

--        if count_y_stg1 >= y_max2 then
--           count_y_gt_y_max2 <= '1';
--        else
--           count_y_gt_y_max2 <= '0';
--        end if;

--        -- Second combinational block: (blech!)
--        Draw_Enable <= (done_stg2 and fifo_stg2) and ((count_y_gt_y0_stg2 and count_y_ne_y_max)  or count_x_gt_start_x_stg2 or count_y_gt_y_max2);
 
--        count_x_stg2 <= count_x_stg1;
--        count_x_stg3 <= count_x_stg2;

--        count_y_stg2 <= count_y_stg1;
--        count_y_stg3 <= count_y_stg2;

-- --       if ( ( done = '0' and fifo_level /="1111" )         
-- --            and 
-- --            ( ( count_x(15 downto 6) > start_x(15 downto 6)
-- --                or (
-- --                  count_y(15 downto 6) > coord_y0(15 downto 6) and count_y(15 downto 6) /= y_max(15 downto 6)
-- --                  ) 
-- --               )
-- --               or ( count_y >= y_max2 ) -- Very last write:                              
-- --             )
-- --           ) 
-- --          then
--        if Draw_Enable = '1' then   
--          if ( count_x_stg3(4 downto 0) = "01000") then

--             W_Enable <= '1';

--             address(21 downto 19) <= "000";
--             address(18 downto 9)  <= count_y_stg3;
--             address(8 downto 7)   <= "00";
--             address(6 downto 0)   <= count_x_stg3(9 downto 3) - "0000001";   


--           elsif (count_x_stg3(2 downto 0) = "000") then

--             W_Enable <= '1';

--           else

--             W_Enable <= '0';

--           end if;

--       else
--           W_Enable <= '0';
--       end if;

--      end if;

--    end process output_control;

  
end behavioural;

