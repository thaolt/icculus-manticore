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
      clock, reset : in  std_logic;
      coord_x0   : in  std_logic_vector(raster_datawidth-1 downto 0);
      coord_y0   : in  std_logic_vector(raster_datawidth-1 downto 0);
      coord_x1   : in  std_logic_vector(raster_datawidth-1 downto 0);
      coord_y1   : in  std_logic_vector(raster_datawidth-1 downto 0);
      coord_x2   : in  std_logic_vector(raster_datawidth-1 downto 0);
      coord_y2   : in  std_logic_vector(raster_datawidth-1 downto 0);
      coord_z0   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_z1   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_z2   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      slope01     : in  std_logic_vector(raster_datawidth-1 downto 0);
      slope12     : in  std_logic_vector(raster_datawidth-1 downto 0);
      slope02     : in  std_logic_vector(raster_datawidth-1 downto 0);
      z_slope01   : in  std_logic_vector(raster_datawidth-1 downto 0);
      z_slope12   : in  std_logic_vector(raster_datawidth-1 downto 0);
      z_slope02   : in  std_logic_vector(raster_datawidth-1 downto 0);
      dz_dx     : in  std_logic_vector(raster_datawidth-1 downto 0);

      color      : in  std_logic_vector(COLOR_DEPTH-1 downto 0);
     
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
    data     : in  std_logic_vector(WIDTH-1 downto 0) := (others => '0');
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

    port (dataa, datab: in STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);
          aclr, clock, cin: in STD_LOGIC := '0';
          add_sub: in STD_LOGIC := '1';
          clken: in STD_LOGIC := '1';
          result: out STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);

          cout, overflow: out STD_LOGIC);
  end component;
  
  -- LPM Data/Enable Delay signals
  signal shift_reg_enable_stg1, shift_reg_enable_stg2, shift_reg_enable_stg3, shift_reg_enable_stg4 : std_logic;
  signal data_to_shift_reg_stg1, data_to_shift_reg_stg2, data_to_shift_reg_stg3, data_to_shift_reg_stg4: std_logic_vector(COLOR_DEPTH-1 downto 0);
  signal mask_to_shift_reg_stg1, mask_to_shift_reg_stg2, mask_to_shift_reg_stg3,mask_to_shift_reg_stg4: std_logic;


  signal x_start, x_end, count_x, count_y : std_logic_vector(15 downto 0);
  signal x01, x02, x01_delta, x02_delta   : std_logic_vector(15 downto 0);
  signal z01, z01_delta, dz_dx_reg   : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal y_max, y_max2                    : std_logic_vector(15 downto 0);

  type switch_type is (one_lt_two, one_gt_two, one_eq_two);

  signal slope_switch                     : switch_type;
  signal done                      : std_logic;

  signal data_to_shift_reg : std_logic_vector(COLOR_DEPTH-1 downto 0);
 -- signal data_shifted      : std_logic_vector(8*COLOR_DEPTH-1 downto 0);
 -- signal mask_shifted      : std_logic_vector(COLOR_DEPTH-1 downto 0);
  signal mask_to_shift_reg : std_logic;
  signal shift_reg_enable  : std_logic;
 -- signal W_Enable_Internal : std_logic;
  signal clear : std_logic;
  signal reg_reset : std_logic;
  
  signal enable : std_logic;

  -- Address resolver pipeline signals
  signal fifo_level_stg1    : std_logic_vector(3 downto 0);
  signal done_stg1, not_done_stg1, not_done_stg2, not_done_stg3,
    fifo_ne_max_stg1, fifo_ne_max_stg2,
    count_x_gt_x_start_stg1, count_x_gt_x_start_stg2,
    count_y_gt_y0_stg1, count_y_gt_y0_stg2,
    count_y_gt_coord_y0_stg1, count_y_gt_coord_y0_stg2,
    count_y_ne_y_max_stg1, count_y_ne_y_max_stg2,
    count_y_ge_y_max2_stg1, count_y_ge_y_max2_stg2,
    A, B, C, D, E, F,
    Draw_Enable_stg2, Draw_Enable_stg3,
    W_Enable_compare, W_Enable_stg3, Addr_eq_8, Addr_Enable: std_logic;
  signal count_x_stg1, count_x_stg2, count_x_stg3, count_x_stg4,
    x_start_stg1,
    count_y_stg1, count_y_stg2, count_y_stg3, count_y_stg4,
    coord_y0_stg1,
    y_max_stg1, y_max2_stg1,
    z_value : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);



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

constant shadedepth0: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0000000000000000";
constant shadedepth1: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0000010000000000";
constant shadedepth2: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0010000000000000";
constant shadedepth3: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0011000000000000";
constant shadedepth4: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0100000000000000";
constant shadedepth5: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0101000000000000";
constant shadedepth6: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0110000000000000";
constant shadedepth7: std_logic_vector(RASTER_DATAWIDTH-1 downto 0)  := "0111000000000000";

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

  calculate: process(clock,reset) is
                                  -- flags that determine if the calculation for the top and bottom triangles have been initialized.

  begin
    if reset='0' then
      x_start   <= (others => '0');
      x_end     <= (others => '0');
      x01       <= (others => '0');
      x02       <= (others => '0');
      x01_delta <= (others => '0');
      x02_delta <= (others => '0');
      count_x   <= (others => '0');
      count_y   <= (others => '0');

      y_max     <= (others => '0');
      y_max2    <= (others => '0');

      data_to_shift_reg <= (others => '0');
      mask_to_shift_reg <= '0';
      shift_reg_enable  <= '0';

      done <= '1';
     
      slope_switch <= one_lt_two;

      z_value   <= (others => '0');
      dz_dx_reg <= (others => '0');
      z01       <= (others => '0');
      z01_delta <= (others => '0');


    elsif clock'event and clock = '1' then    

      if draw_start = '1' and done = '1' then -- Load new values if we're not doing anything

        data_to_shift_reg <= (others => '0');
        mask_to_shift_reg <= '0';
        shift_reg_enable  <= '0';

        done <= '0';

        -- incremental change in x for the top half triangle
        x01_delta <= slope01;
        x02_delta <= slope02;

        -- x01 is the x value of the left edge of the triangle on the
        -- current scan line
        x01 <= coord_x0;

        -- x02 is the x value of the right edge of the triangle on the
        -- current scan line
        x02 <= coord_x0;

        z01 <= coord_z0;
        z_value <= coord_z0;

        z01_delta <= z_slope01;
        dz_dx_reg <= dz_dx;

        -- Since the vertices are sorted, coord_x1 is the smallest.  Since
        -- addresses can only be specified in multiples of 4 *words*, we take the
        -- nearest multiple of four words (32 pixels) less than the leftmost vertex.  We end
        -- up scanning a rectangle and deterimining which points are
        -- within the triangle.
        x_start(15 downto 11) <= coord_x1(15 downto 11);
        x_start(10 downto 0)  <= "00000000000";

        -- Right edge of rectangle (max x value rounded up to nearest multiple
        -- of four).
        if coord_x0(15 downto 11) > coord_x2(15 downto 11) then
          x_end(15 downto 11) <= coord_x0(15 downto 11);
        else
          x_end(15 downto 11) <= coord_x2(15 downto 11);
        end if;
        x_end(10 downto 0) <= "11111000000";

        -- count_x is the current x value we are rasterizing
        count_x(15 downto 11) <= coord_x1(15 downto 11);
        count_x(10 downto 0)  <= "00000000000";
        count_y               <= coord_y0;


        -- We want to draw up to the end of the first edge, so we set y_max to the lower of 
        -- coord_y1 or coord_y2.
        if coord_y1 < coord_y2 then
          y_max  <= coord_y1;
          y_max2 <= coord_y2;
          slope_switch <= one_lt_two;
        elsif coord_y1 > coord_y2 then
          y_max  <= coord_y2;
          y_max2 <= coord_y1;
          slope_switch <= one_gt_two;
        else
          y_max  <= coord_y1;
          y_max2 <= coord_y1;
          slope_switch <= one_eq_two;
        end if;

      elsif (done = '0' and fifo_level /= "1111") then


        if count_y < y_max then
          
          -- count_x is to the left of the triangle
          if count_x < x01 then

            count_x(15 downto 6) <= count_x(15 downto 6) + "000000001";
            z_value <= z_value + dz_dx_reg;

            data_to_shift_reg <= (others => '0');
            mask_to_shift_reg <= '1';
            shift_reg_enable  <= '1';

            -- count_x is inside the triangle:
          elsif count_x <= x02 then 
            
            count_x(15 downto 6) <= count_x(15 downto 6) + "0000000001";
            z_value <= z_value + dz_dx_reg;

            data_to_shift_reg <= color AND shademask;
            mask_to_shift_reg <= '0';
            shift_reg_enable  <= '1';

            
            -- count_x is past the right edge of the triangle
          elsif count_x < x_end then

            count_x(15 downto 6) <= count_x(15 downto 6) + "0000000001";
            z_value <= z_value + dz_dx_reg;

            data_to_shift_reg <= (others => '0');
            mask_to_shift_reg <= '1';
            shift_reg_enable  <= '1';
            
            -- count_x is at the end of the line
          else
            
            x01 <= x01 + x01_delta;
            x02 <= x02 + x02_delta;
            
            shift_reg_enable <= '0';

            count_x <= x_start;
            count_y(15 downto 6) <= count_y(15 downto 6) + "0000000001";
            z01 <= z01 + z01_delta;
            z_value <= z01 + z01_delta;

          end if;

        elsif count_y >= y_max2 and count_x(15 downto 6) > x_start(15 downto 6) then
          done <= '1';        
        elsif count_y >= y_max2 then
          count_x(15 downto 6) <= count_x(15 downto 6) + "0000000001";
          shift_reg_enable  <= '0';
        elsif slope_switch = one_lt_two then
          y_max <= y_max2;
          x01_delta <= slope12;
          x02_delta <= slope02;
          z01_delta <= z_slope12;

        elsif slope_switch = one_gt_two then
          y_max <= y_max2;
          x01_delta <= slope01;
          x02_delta <= slope12;
          z01_delta <= z_slope01;

        end if;
      end if;
    end if;
  end process calculate;

     

 ------------------------------------------------------------------------------
 -- Shading Process
 ------------------------------------------------------------------------------

  shader: process(z_value) is
  
	begin
	
    if z_value > shadedepth7 then
	    shademask <= shadelevel7;
    elsif z_value > shadedepth6 then
	    shademask <= shadelevel6;
    elsif z_value > shadedepth5 then
	    shademask <= shadelevel5;
	elsif z_value > shadedepth4 then
	    shademask <= shadelevel4;
	elsif z_value > shadedepth3 then
	    shademask <= shadelevel3;
	elsif z_value > shadedepth2 then
	    shademask <= shadelevel2;
	elsif z_value > shadedepth1 then
	    shademask <= shadelevel1;
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
  -- (( count_x > x_start or (count_y > coord_y0 and count_y /= y_max))
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

  x_start_ff_stg1 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => x_start,
      aclr  => clear,
      clock => clock,
      q     => x_start_stg1
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

  coord_y0_ff_stg1 : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data  => coord_y0,
      aclr  => clear,
      clock => clock,
      q     => coord_y0_stg1
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
  

  count_x_gt_x_start_comp : lpm_compare
    generic map (
      LPM_WIDTH => 10,
      LPM_REPRESENTATION => "UNSIGNED"
      )
    port map (
      dataa => count_x_stg1(15 downto 6),
      datab => x_start_stg1(15 downto 6),
      agb   => count_x_gt_x_start_stg1
      );

  count_y_gt_coord_y0_comp : lpm_compare
    generic map (
      LPM_WIDTH          => 10,
      LPM_REPRESENTATION => "UNSIGNED"
      )
    port map (
      dataa => count_y_stg1(15 downto 6),
      datab => coord_y0_stg1(15 downto 6),
      agb   => count_y_gt_coord_y0_stg1
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
      d    => count_x_gt_x_start_stg1,
      q    => count_x_gt_x_start_stg2,
      clrn => reset
      );

  dff4_stg2 : dff
    port map (
      clk  => clock,
      d    => count_y_gt_coord_y0_stg1,
      q    => count_y_gt_coord_y0_stg2,
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
  -- (( count_x > x_start or (count_y > coord_y0 and count_y /= y_max))
  -- or (count_y >= y_max2)))
  --
  -- This is what the variables are called:
  -- Draw_Enable <=  A and ((B or C) or D)
  -- Draw_Enable <=  A and ( E or D)
  -- Draw_Enable <=  A and F
  
  A <= not_done_stg2 and fifo_ne_max_stg2;
  B <= count_x_gt_x_start_stg2;
  C <= count_y_gt_coord_y0_stg2 and count_y_ne_y_max_stg2;
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

  Address_stg3(21 downto 19) <= "000";
  address_stg3(18 downto 9)  <= count_y_stg3(15 downto 6);
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
--        x_start_stg1            <= (others => '0');
--        count_y_stg1            <= (others => '0');
--        coord_y0_stg1           <= (others => '0');
--        y_max_stg1              <= (others => '0');
--        y_max2_stg1             <= (others => '0');

--        done_stg2               <= '0';
--        fifo_stg2               <= '0';
--        count_x_gt_x_start_stg2 <= '0';
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
--        x_start_stg1     <= x_start(15 downto 6);
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

--        if count_x_stg1 > x_start_stg1 then 
--           count_x_gt_x_start_stg2 <= '1';
--        else
--           count_x_gt_x_start_stg2 <= '0';
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
--        Draw_Enable <= (done_stg2 and fifo_stg2) and ((count_y_gt_y0_stg2 and count_y_ne_y_max)  or count_x_gt_x_start_stg2 or count_y_gt_y_max2);
 
--        count_x_stg2 <= count_x_stg1;
--        count_x_stg3 <= count_x_stg2;

--        count_y_stg2 <= count_y_stg1;
--        count_y_stg3 <= count_y_stg2;

-- --       if ( ( done = '0' and fifo_level /="1111" )         
-- --            and 
-- --            ( ( count_x(15 downto 6) > x_start(15 downto 6)
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

