-------------------------------------------------------------------------------
-- Title      : Rasterizer variable registers
-- Project    : The HULK
-------------------------------------------------------------------------------
-- File       : raster_vars_reg.vhd
-- Author     : benj  <benj@ns1.digitaljunkies.ca>
-- Last update: 2002/04/07
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: Buffers x,y,z and slope information until the rasterizer is
-- ready.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date      Author         Description
-- 2002/03/30      benj         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.memory_defs.all;

entity raster_vars_reg is

  port (
    reset, clock                       : in  std_logic;
    input                              : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    data_type                          : in  raster_var_type;
    W_Enable                           : in  std_logic;
    R_Enable                           : in  std_logic;

    Coord_R_Enable                     : in  std_logic;

    Full_Flag                          : out std_logic;
    Proj_Coord_Flag                    : out std_logic;

    coord_x0, coord_y0, coord_z0    : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    coord_x1, coord_y1, coord_z1    : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    coord_x2, coord_y2, coord_z2    : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    slope01, slope12, slope02       : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    dz_dx01, dz_dx02, dz_dx12       : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    z_slope01, z_slope12, z_slope02 : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0)
    );

end entity raster_vars_reg;

architecture behavioural of raster_vars_reg is

  component lpm_ram_dp is
    generic ( LPM_WIDTH              :     POSITIVE;
              LPM_WIDTHAD            :     POSITIVE;
              LPM_NUMWORDS           :     NATURAL   := 0;
              LPM_TYPE               :     STRING    := "LPM_RAM_DP";
              LPM_INDATA             :     STRING    := "REGISTERED";
              LPM_OUTDATA            :     STRING    := "REGISTERED";
              LPM_RDADDRESS_CONTROL  :     STRING    := "REGISTERED";
              LPM_WRADDRESS_CONTROL  :     STRING    := "REGISTERED";
              LPM_FILE               :     STRING    := "UNUSED";
              LPM_HINT               :     STRING    := "UNUSED");
    port    ( rdaddress, wraddress   : in  STD_LOGIC_VECTOR(LPM_WIDTHAD-1 downto 0);
              rdclock, wrclock       : in  STD_LOGIC := '0';
              rden, rdclken, wrclken : in  STD_LOGIC := '1';
              wren                   : in  STD_LOGIC;
              data                   : in  STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);
              q                      : out STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0));
  end COMPONENT;

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

  signal data_plus_320, data_plus_240, data_plus_128 : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal s_320 : std_logic_vector(3 downto 0);
  signal s_240 : std_logic_vector(5 downto 0);
  signal s_128 : std_logic_vector(2 downto 0);

  signal zero : std_logic_vector(0 downto 0);

  signal data_reg : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);

  signal coord_x0_wren, coord_y0_wren, coord_z0_wren    : std_logic;
  signal coord_x1_wren, coord_y1_wren, coord_z1_wren    : std_logic;
  signal coord_x2_wren, coord_y2_wren, coord_z2_wren    : std_logic;
  signal slope01_wren, slope12_wren, slope02_wren       : std_logic;
  signal z_slope01_wren, z_slope12_wren, z_slope02_wren : std_logic;
  signal dz_dx01_wren, dz_dx12_wren, dz_dx02_wren       : std_logic;

  signal coord_x0_flg, coord_x1_flg, coord_x2_flg    : std_logic;
  signal coord_y0_flg, coord_y1_flg, coord_y2_flg    : std_logic;
  signal coord_z0_flg, coord_z1_flg, coord_z2_flg    : std_logic;
  signal slope01_flg, slope12_flg, slope02_flg       : std_logic;
  signal dz_dx01_flg, dz_dx12_flg, dz_dx02_flg       : std_logic;
  signal z_slope01_flg, z_slope12_flg, z_slope02_flg : std_logic;

  signal clear                : std_logic;
  signal Proj_coords_R_Enable : std_logic;

begin  -- architecture behavioural

  zero <= "0";
  clear <= not reset;  
  proj_coords_R_Enable <= R_Enable or Coord_R_Enable;

  s_240 <= "001111";
  s_320 <= "0101";
  s_128 <= "001";

  Full_Flag <= (((coord_x0_flg and coord_x1_flg) and (coord_x2_flg and coord_y0_flg)) and
               ((coord_y1_flg and coord_y2_flg) and (coord_z0_flg and coord_z1_flg))) and
               (((coord_z2_flg and slope01_flg) and (slope12_flg and slope02_flg))) and
               (((z_slope01_flg and z_slope12_flg) and (z_slope02_flg and dz_dx01_flg))) and 
               (dz_dx12_flg and dz_dx02_flg);

  Proj_Coord_Flag <= (((coord_x0_flg and coord_y0_flg) and (coord_z0_flg and coord_x1_flg)) and 
                 ((coord_y1_flg and coord_z1_flg) and (coord_x2_flg and coord_y2_flg))) and coord_z2_flg;
 
      

  data_reg_inst : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data   => input,
      clock  => clock,
      aclr   => clear,
      q      => data_reg
      );

  -- We need to shift all x coordinates to the center of the screen by adding 320
  x_shifter : lpm_add_sub
    generic map (
      LPM_WIDTH => 4,
      LPM_REPRESENTATION => "SIGNED")
    port map (
      dataa => data_reg(15 downto 12),
      datab => s_320,
      result => data_plus_320(15 downto 12)
      );
  data_plus_320(11 downto 0) <= data_reg(11 downto 0);

  y_shifter : lpm_add_sub
    generic map (
      LPM_WIDTH => 6,
      LPM_REPRESENTATION => "SIGNED")
    port map (
      dataa => data_reg(15 downto 10),
      datab => s_240,
      result => data_plus_240(15 downto 10)
      );

  data_plus_240(9 downto 0) <= data_reg(9 downto 0);
  
 z_shifter : lpm_add_sub
    generic map (
      LPM_WIDTH => 3,
      LPM_REPRESENTATION => "SIGNED")
    port map (
      dataa => data_reg(15 downto 13),
      datab => s_128,
      result => data_plus_128(15 downto 13)
      );

  data_plus_128(12 downto 0) <= data_reg(12 downto 0);

  coord_x0_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => proj_coords_R_Enable,
      wren      => coord_x0_wren,
      data      => data_plus_320,
      q         => coord_x0);

  coord_y0_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => proj_coords_R_Enable,
      wren      => coord_y0_wren,
      data      => data_plus_240,
      q         => coord_y0);

  coord_z0_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => proj_coords_R_Enable,
      wren      => coord_z0_wren,
      data      => data_plus_128,
      q         => coord_z0);

  coord_x1_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => proj_coords_R_Enable,
      wren      => coord_x1_wren,
      data      => data_plus_320,
      q         => coord_x1);

  coord_y1_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => proj_coords_R_Enable,
      wren      => coord_y1_wren,
      data      => data_plus_240,
      q         => coord_y1);

  coord_z1_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => proj_coords_R_Enable,
      wren      => coord_z1_wren,
      data      => data_plus_128,
      q         => coord_z1);

  coord_x2_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => proj_coords_R_Enable,
      wren      => coord_x2_wren,
      data      => data_plus_320,
      q         => coord_x2);

  coord_y2_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => proj_coords_R_Enable,
      wren      => coord_y2_wren,
      data      => data_plus_240,
      q         => coord_y2);
  
  coord_z2_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => proj_coords_R_Enable,
      wren      => coord_z2_wren,
      data      => data_plus_128,
      q         => coord_z2);
  
  slope01_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => R_Enable,
      wren      => slope01_wren,
      data      => data_reg,
      q         => slope01);
  
  slope12_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => R_Enable,
      wren      => slope12_wren,
      data      => data_reg,
      q         => slope12);

  slope02_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => R_Enable,
      wren      => slope02_wren,
      data      => data_reg,
      q         => slope02);

  z_slope01_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => R_Enable,
      wren      => z_slope01_wren,
      data      => data_reg,
      q         => z_slope01);
  
  z_slope12_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => R_Enable,
      wren      => z_slope12_wren,
      data      => data_reg,
      q         => z_slope12);

  z_slope02_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => R_Enable,
      wren      => z_slope02_wren,
      data      => data_reg,
      q         => z_slope02);

  dz_dx01_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => R_Enable,
      wren      => dz_dx01_wren,
      data      => data_reg,
      q         => dz_dx01);

  dz_dx12_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => R_Enable,
      wren      => dz_dx12_wren,
      data      => data_reg,
      q         => dz_dx12);

  dz_dx02_ram : lpm_ram_dp
    generic map (
      LPM_WIDTHAD  => 1,
      LPM_WIDTH    => RASTER_DATAWIDTH
      )
    port map (
      rdaddress => zero,
      wraddress => zero,
      rdclock   => clock,
      wrclock   => clock,
      rden      => R_Enable,
      wren      => dz_dx02_wren,
      data      => data_reg,
      q         => dz_dx02);
  

  -- purpose: Determine which register should be written to.  Simply asserts
  -- the appropriate write enable signal and sets the correct flag.
  -- type   : sequential
  -- inputs : clock, reset, data_type, W_Enable
  -- outputs: *_wren
  write_decode: process (clock, reset) is
  begin  -- process write_decode
    if reset = '0' then                 -- asynchronous reset (active low)
      coord_x0_wren <= '0';
      coord_y0_wren <= '0';
      coord_z0_wren <= '0';
      coord_x1_wren <= '0';
      coord_y1_wren <= '0';
      coord_z1_wren <= '0';
      coord_x2_wren <= '0';
      coord_y2_wren <= '0';
      coord_z2_wren <= '0';

      slope01_wren <= '0';
      slope12_wren <= '0';
      slope02_wren <= '0';

      dz_dx01_wren <= '0';
      dz_dx12_wren <= '0';
      dz_dx02_wren <= '0';
      
      z_slope01_wren <= '0';
      z_slope12_wren <= '0';
      z_slope02_wren <= '0';
        
      coord_x0_flg <= '0';
      coord_y0_flg <= '0';
      coord_z0_flg <= '0';
      coord_x1_flg <= '0';
      coord_y1_flg <= '0';
      coord_z1_flg <= '0';
      coord_x2_flg <= '0';
      coord_y2_flg <= '0';
      coord_z2_flg <= '0';

      slope01_flg <= '0';
      slope12_flg <= '0';
      slope02_flg <= '0';

      dz_dx01_flg <= '0';
      dz_dx12_flg <= '0';
      dz_dx02_flg <= '0';

      z_slope01_flg <= '0';
      z_slope12_flg <= '0';
      z_slope02_flg <= '0';
            
    elsif clock'event and clock = '1' then  -- rising clock edge

      if W_Enable = '1' then
        case data_type is
          when t_coord_x0 =>
            coord_x0_wren <= '1';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';            
            
            coord_x0_flg <= '1';
            
          when t_coord_y0 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '1';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';
            
            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';

            coord_y0_flg <= '1';
            
          when t_coord_z0 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '1';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
            
            coord_z0_flg <= '1';
            
          when t_coord_x1 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '1';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';

            coord_x1_flg <= '1';
            
          when t_coord_y1 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '1';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';

            coord_y1_flg <= '1';
            
          when t_coord_z1 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '1';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
            
            coord_z1_flg <= '1';
            
          when t_coord_x2 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '1';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
            
            coord_x2_flg <= '1';
            
          when t_coord_y2 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '1';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
   
            coord_y2_flg <= '1';
            
          when t_coord_z2 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '1';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
   
            coord_z2_flg <= '1';
            
          when t_slope01 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '1';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
   
            slope01_flg <= '1';
            
          when t_slope12 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '1';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
           
            slope12_flg <= '1';
            
          when t_slope02 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '1';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
    
            slope02_flg <= '1';
            
          when t_z_slope01 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '1';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
            
            z_slope01_flg <= '1';
            
          when t_z_slope12 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '1';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
   
            z_slope12_flg <= '1';
            
          when t_z_slope02 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '1';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
           
            z_slope02_flg <= '1';

          when t_dz_dx01 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '1';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '0';
            
            dz_dx01_flg <= '1';

          when t_dz_dx12 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '1';
            dz_dx02_wren <= '0';
            
            dz_dx12_flg <= '1';

          when t_dz_dx02 =>
            coord_x0_wren <= '0';
            coord_y0_wren <= '0';
            coord_z0_wren <= '0';
            coord_x1_wren <= '0';
            coord_y1_wren <= '0';
            coord_z1_wren <= '0';
            coord_x2_wren <= '0';
            coord_y2_wren <= '0';
            coord_z2_wren <= '0';

            slope01_wren <= '0';
            slope12_wren <= '0';
            slope02_wren <= '0';

            z_slope01_wren <= '0';
            z_slope12_wren <= '0';
            z_slope02_wren <= '0';

            dz_dx01_wren <= '0';
            dz_dx12_wren <= '0';
            dz_dx02_wren <= '1';
            
            dz_dx02_flg <= '1';
            
          when others => null;
        end case;

      elsif R_Enable = '1' then

        coord_x0_wren <= '0';
        coord_y0_wren <= '0';
        coord_z0_wren <= '0';
        coord_x1_wren <= '0';
        coord_y1_wren <= '0';
        coord_z1_wren <= '0';
        coord_x2_wren <= '0';
        coord_y2_wren <= '0';
        coord_z2_wren <= '0';

        slope01_wren <= '0';
        slope12_wren <= '0';
        slope02_wren <= '0';

        dz_dx01_wren <= '0';
        dz_dx12_wren <= '0';
        dz_dx02_wren <= '0';

        z_slope01_wren <= '0';
        z_slope12_wren <= '0';
        z_slope02_wren <= '0';
        
        coord_x0_flg <= '0';
        coord_y0_flg <= '0';
        coord_z0_flg <= '0';
        coord_x1_flg <= '0';
        coord_y1_flg <= '0';
        coord_z1_flg <= '0';
        coord_x2_flg <= '0';
        coord_y2_flg <= '0';
        coord_z2_flg <= '0';

        slope01_flg <= '0';
        slope12_flg <= '0';
        slope02_flg <= '0';

        dz_dx01_flg <= '0';
        dz_dx12_flg <= '0';
        dz_dx02_flg <= '0';

        z_slope01_flg <= '0';
        z_slope12_flg <= '0';
        z_slope02_flg <= '0';        
        
      else 

        coord_x0_wren <= '0';
        coord_y0_wren <= '0';
        coord_z0_wren <= '0';
        coord_x1_wren <= '0';
        coord_y1_wren <= '0';
        coord_z1_wren <= '0';
        coord_x2_wren <= '0';
        coord_y2_wren <= '0';
        coord_z2_wren <= '0';

        slope01_wren <= '0';
        slope12_wren <= '0';
        slope02_wren <= '0';

        dz_dx01_wren <= '0';
        dz_dx12_wren <= '0';
        dz_dx02_wren <= '0';

        z_slope01_wren <= '0';
        z_slope12_wren <= '0';
        z_slope02_wren <= '0';
        
      end if;
    end if;
  end process write_decode;

end architecture behavioural;
