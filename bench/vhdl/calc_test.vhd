-------------------------------------------------------------------------------
-- Title      : Frame buffer test file
-- Project    : HULK
-------------------------------------------------------------------------------
-- File       : frame_buffer_test.vhd
-- Author     : Benj Carson <benjcarson@digitaljunkies.ca>
-- Last update: 2002/03/31
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: Top level file for VGA out & SDRAM test
-------------------------------------------------------------------------------
-- Revisions  :
-- Date            Author       Description
-- 2002/03/11      benj         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.memory_defs.all;
use work.vgaout_defs.all;

entity calc_test is

  port (
      clock50    : in std_logic;
     
      reset : in  std_logic;
      tb_x0, tb_x1, tb_x2, tb_y0, tb_y1, tb_y2, tb_z0, tb_z1, tb_z2    : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);

      slope01_out     : out  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      slope12_out     : out  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      slope02_out     : out  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      x0_out, x1_out, x2_out, y0_out, y1_out, y2_out, z0_out, z1_out, z2_out,
      dz_dx01_out, dz_dx02_out, dz_dx12_out, z_slope01_out, z_slope12_out, z_slope02_out : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);

      color      : in  std_logic_vector(COLOR_DEPTH-1 downto 0);

      sc_Result_Out, sc_A_out, sc_B_out, sc_C_out, sc_D_out : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      
      -- Signals to write fifo
 --     W_Enable : out std_logic;
      address_to_write  : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      data_to_write     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      mask_to_write     : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
      fifo_level : in  std_logic_vector(3 downto 0);

      -- Control signals
      draw_start_out : out  std_logic;
      draw_done  : out std_logic

    );

end entity calc_test;


architecture structural of calc_test is

  component pll2x is                    -- altclocklock/boost megafunction
    port (
      inclock : IN  STD_LOGIC;
      clock0  : OUT STD_LOGIC;
      clock1  : OUT STD_LOGIC
      );
  end component pll2x;

  component sdram_control is
    generic(

      in_address_width   : positive := ADDRESS_WIDTH;
      rowsize 	: integer := ADDRESS_ROW_WIDTH;
      colsize 	: integer := ADDRESS_COLUMN_WIDTH;
      rowstart 	: integer := ADDRESS_COLUMN_WIDTH;
      colstart 	: integer := 0
    );

    port(
      clock, reset       : in  std_logic;
      R_enable, W_enable : in  std_logic;
      RW_address         : in  std_logic_vector(in_address_width-1 downto 0);
      ready              : out std_logic;
      tx_data, rx_data   : out std_logic;
      init_done          : out std_logic;
	  data_mask          : in  std_logic_vector(DATA_WIDTH/8*4 -1 downto 0);
      r_ack, w_ack       : out std_logic;	      
      -- to memory
      WEbar              : out std_logic;                  -- Write enable, Active Low
      CKE                : out std_logic_vector(1 downto 0);                    -- clock enable
      CSbar              : out std_logic; 
      CS2bar             : out std_logic;                 -- chip select, Active Low
      addr               : out std_logic_vector(12 downto 0);
      RASbar, CASbar     : out std_logic;
      DQM                : out std_logic_vector(7 downto 0);
      BA                 : out std_logic_vector (1 downto 0);
      chip_select        : in  std_logic
    );
  end component sdram_control;

  component vgaout is
   port(
        signal clock, reset : in  std_logic;
        -- Color outputs will be mulitple bits.  If only a single bit is used,
        -- the MSB can be connected to the RGB pins.  If multiple bits can be used,
        -- each of the bits can be fed into a D/A converter (i.e. three resistors)
        -- and then to the RGB pins.
        Red_Out     : out std_logic_vector(R_DEPTH-1 downto 0);
        Green_Out   : out std_logic_vector(G_DEPTH-1 downto 0);
        Blue_Out    : out std_logic_vector(B_DEPTH-1 downto 0);

        DataIn      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        Line_Number : out std_logic_vector(9 downto 0);
		Init_Done   : in std_logic;
		Blank_done  : in std_logic;
        Horiz_Sync, Vert_Sync : out std_logic;

        -- Fifo interface signals
        Read_Line      : out std_logic;  -- Tell fifo to begin buffering an entire line
        Read_Line_Warn : out std_logic;
        Read_Line_Ack  : in std_logic;
        Read_Req       : out std_logic;  -- Request read
        Fifo_Empty     : in  std_logic  -- Check if fifo has data

        );
                     
  end component vgaout;
  
  component vgafifo is                  -- lpm_fifo_dc megafunction
    port (
      data    : IN  STD_LOGIC_VECTOR (63 DOWNTO 0);
      wrreq   : IN  STD_LOGIC;
      rdreq   : IN  STD_LOGIC;
      rdclk   : IN  STD_LOGIC;
      wrclk   : IN  STD_LOGIC;
      aclr    : IN  STD_LOGIC := '0';
      q       : OUT STD_LOGIC_VECTOR (63 DOWNTO 0);
      rdempty : OUT STD_LOGIC;
      wrfull  : OUT STD_LOGIC;
      wrusedw : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
    );
  end component;

  -- Z FIFO
  component zfifo is                  -- lpm_fifo_dc megafunction
    port (
      data    : IN  STD_LOGIC_VECTOR (63 DOWNTO 0);
      wrreq   : IN  STD_LOGIC;
      rdreq   : IN  STD_LOGIC;
      rdclk   : IN  STD_LOGIC;
      wrclk   : IN  STD_LOGIC;
      aclr    : IN  STD_LOGIC := '0';
      q       : OUT STD_LOGIC_VECTOR (63 DOWNTO 0);
      rdempty : OUT STD_LOGIC;
      wrfull  : OUT STD_LOGIC;
      wrusedw : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
  end component;

  component vgafifo_ctrl is
    port (
      clock, reset : in  std_logic;
      -- VGA Signals
      Read_Line      : in  std_logic;       -- Read Line command from VGA out module
      Read_Line_Warn : in std_logic;
      Read_Line_Ack  : out std_logic;
      Line_Number    : in  std_logic_vector(9 downto 0);
      -- SDRAM Signals
      SDRAM_Ready  : in  std_logic;
      Data_Out     : inout std_logic_vector(DATA_WIDTH-1 downto 0);
      Rx_Data      : in  std_logic;
      Tx_Data      : in  std_logic;
      Init_Done    : in  std_logic;
      R_Enable     : out std_logic;
      W_Enable     : out std_logic;
      Address      : inout std_logic_vector(ADDRESS_WIDTH-1 downto 0);
	  data_mask    : out std_logic_vector(4*DATA_WIDTH/8 -1 downto 0);
      r_ack, w_ack	   : in std_logic;
      BufferPick   : in std_logic;  -- DEBUG
      -- Write Fifo signals

      Write_Fifo_Empty : in std_logic;
      Write_Fifo_Data_Pop   : out std_logic;
      Write_Fifo_Data_Enable : out std_logic;
      Write_Fifo_Addr_Enable : out std_logic;
      Write_Fifo_Addr_Pop : out std_logic;
      Write_FB         : out std_logic;
      -- Z_Fifo Signals

      Z_Fifo_Clear   : out std_logic;
      Z_Write_Req    : out std_logic;
      Z_Fifo_Level   : in  std_logic_vector(7 downto 0);
      Z_Fifo_Full    : in  std_logic;

      -- Z_Buffer Signals
      Z_Line_Number : in std_logic_vector(9 downto 0);
      Z_Col_Start   : in std_logic_vector(10 downto 0);
      Z_Col_End     : in std_logic_vector(10 downto 0);

      -- Fifo Signals
      Write_Req    : out std_logic;
      Fifo_Clear   : out std_logic;
      Fifo_Full    : in  std_logic;
      Fifo_Level   : in  std_logic_vector(6 downto 0);
	  Blank_Done   : out std_logic

    );
  end component;

  component write_fifo is
    port (
      clock, reset  : in  std_logic;
      Data_Mask_In  : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);       -- Mask for input 4 word burst
      Data_In       : in  std_logic_vector(DATA_WIDTH-1 downto 0);           -- Write data in
      Address_In    : in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);        -- Address for beginning of burst
      W_Enable      : in  std_logic;
      Send_Address  : in  std_logic;
      Addr_Out_Enable : in std_logic;
      Send_Data     : in  std_logic;
      Data_Out_Enable : in std_logic;
      Data_Mask_Out : out std_logic_vector(4*DATA_WIDTH/8-1 downto 0);
      Data_Out      : inout std_logic_vector(DATA_WIDTH-1 downto 0);
      Address_Out   : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      Fifo_Level    : out std_logic_vector(3 downto 0);
      Full          : out std_logic;
      Mostly_Empty  : out std_logic
    );
   end component;


 component rasterizer is

    port(
      clock, reset : in  std_logic;
      coord_x0   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_y0   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_x1   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_y1   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_x2   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_y2   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_z0   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_z1   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_z2   : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      slope01     : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      slope12     : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      slope02     : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      color      : in  std_logic_vector(COLOR_DEPTH-1 downto 0);
      z_slope01   : in  std_logic_vector(raster_datawidth-1 downto 0);
      z_slope12   : in  std_logic_vector(raster_datawidth-1 downto 0);
      z_slope02   : in  std_logic_vector(raster_datawidth-1 downto 0);
      dz_dx01, dz_dx12, dz_dx02     : in  std_logic_vector(raster_datawidth-1 downto 0);
      -- Signals to write fifo
      W_Enable : out std_logic;
      address  : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      data     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      mask     : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
      fifo_level : in  std_logic_vector(3 downto 0);

      -- Control signals
      draw_start : in  std_logic;
      draw_done  : out std_logic
      );
  end component rasterizer;

 component raster_vars_reg is

    port (
      reset, clock                       : in  std_logic;
      input                              : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      data_type                          : in  raster_var_type;
      W_Enable                           : in  std_logic;
      R_Enable                           : in  std_logic;
 
      Coord_R_Enable                     : in  std_logic;

      Full_Flag                          : out std_logic;
      Proj_Coord_Flag                    : out std_logic;
    
      coord_x0, coord_y0, coord_z0       : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_x1, coord_y1, coord_z1       : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      coord_x2, coord_y2, coord_z2       : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      slope01, slope12, slope02          : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      dz_dx01, dz_dx12, dz_dx02          : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      z_slope01, z_slope12, z_slope02    : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0)
      );
  end component;

  component slope_calc is
    generic (
      DIVIDER_PIPELINE         : integer := 17);
    port (
      clock, reset             : in  std_logic;
      num_add_sub, den_add_sub : in  std_logic;
      Enable                   : in  std_logic;
      a, b, c, d               : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      Data_Type_In             : in  raster_var_type;
      Data_Type_Out            : out raster_var_type;
      Result                   : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
      Remainder                : out std_logic_vector(9 downto 0);
      out_enable               : out std_logic
      );
  end component slope_calc;


 component raster_ctrl is
   port (
    reset, clock : in std_logic;

    -- Signals from triangle buffer
    Triangles_Ready : in std_logic;
    
    -- Rasterizer signals
    Draw_Start : out std_logic;
    Draw_Done  : in  std_logic;    
    R_Enable   : out std_logic;
    Coord_R_Enable : out  std_logic;

    -- Rasterizer variable register signals
    Full_Flag  : in  std_logic;
    Proj_Coord_Flag : in std_logic;

    -- Inputs to slope_calc engine
    Data_Type         : out raster_var_type;
    slope_calc_Enable : out std_logic;
    A, B, C, D        : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    Num_Add_Sub       : out std_logic;  -- + if = '1'
    Den_Add_Sub       : out std_logic;

    -- Inputs from triangle buffer
    x0, y0, z0, x1, y1, z1, x2, y2, z2 : in std_logic_vector(RASTER_DATAWIDTH-1 downto 0)   ;

    -- Projected coordinates for slope calculation
    x0_proj_in, y0_proj_in, z0_proj_in, 
    x1_proj_in, y1_proj_in, z1_proj_in, 
    x2_proj_in, y2_proj_in, z2_proj_in : in std_logic_vector(RASTER_DATAWIDTH-1 downto 0)    
    );
  end component raster_ctrl;    

  -- internal signals
  signal clear          : std_logic;
  signal Read_Req       : std_logic;
  signal Fifo_Data_Out  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Fifo_Clear     : std_logic;
  signal Fifo_Empty     : std_logic;
  signal Line_Number    : std_logic_vector(9 downto 0);
  signal Read_Line      : std_logic;
  signal Read_Line_Warn : std_logic;
  signal Read_Line_Ack  : std_logic;
  signal Write_Req      : std_logic;
  signal Fifo_Full      : std_logic;
--  signal Fifo_Level     : std_logic_vector(6 downto 0);
--  signal Data_Out       : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Data_Buf       : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Data_VGA_fifo  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Blank_Done	    : std_logic;
   

  signal R_Enable, W_Enable, Tx_Data, Rx_Data, r_ack, w_ack : std_logic;
  signal Init_Done                                          : std_logic;
  signal Address_Internal                                   : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal Data_mask                                          : std_logic_vector(DATA_WIDTH/8*4 -1 downto 0);

  signal Write_FB : std_logic;

    -- Z FIFO signals
  signal Z_Write_Req      : std_logic;
  signal Z_Fifo_Full      : std_logic;
  signal Z_Fifo_Level     : std_logic_vector(7 downto 0);
  signal Z_Read_Req       : std_logic;
  signal Z_Fifo_Data_Out  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Z_Data : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Z_Fifo_Clear     : std_logic;
  signal Z_Fifo_Empty     : std_logic;
  
  signal Z_Line_Number : std_logic_vector(9 downto 0);
  signal Z_Col_Start   : std_logic_vector(10 downto 0);
  signal Z_Col_End     : std_logic_vector(10 downto 0);



  -- Write FIFO signals
--  signal Data_to_write       : std_logic_vector(DATA_WIDTH-1 downto 0);
--  signal Mask_to_Write       : std_logic_vector(DATA_WIDTH/8-1 downto 0);
--  signal Address_to_write    : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal Write_Fifo_W_Enable : std_logic;
  signal Write_Fifo_Addr_Enable : std_logic;
  signal Write_Fifo_Data_Enable : std_logic;
  signal Addr_Pop            : std_logic;
  signal Data_Pop            : std_logic;
  signal Data_Mask_to_RAM    : std_logic_vector(DATA_WIDTH*4/8-1 downto 0);
  signal wf_Data_to_RAM      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal wf_Mask_to_RAM      : std_logic_vector(DATA_WIDTH*4/8-1 downto 0);
  signal wf_Address_to_RAM   : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal Write_Fifo_Level    : std_logic_vector(3 downto 0);
  signal Write_Fifo_Full     : std_logic;
  signal Write_Fifo_Empty    : std_logic;


-- Rasterizer signals:
  signal coord_x0 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal coord_y0 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal coord_z0 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);  
  signal coord_x1 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal coord_y1 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal coord_z1 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal coord_x2 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal coord_y2 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal coord_z2 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal slope01 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal slope12 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal slope02 :  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal dz_dx01, dz_dx02, dz_dx12, 
         z_slope01, z_slope12, z_slope02 : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal draw_signal : std_logic;
  signal rasterizer_done : std_logic;

-- Rasterizer buffer signals:
  signal rr_W_Enable, rr_R_Enable, rr_Full_Flag : std_logic;
  signal proj_coord_flag, coord_R_Enable : std_logic;
  
-- Slope engine signals
  signal sc_Num_Add_Sub, sc_Den_Add_Sub : std_logic;
  signal sc_Enable : std_logic;
  signal sc_A, sc_B, sc_C, sc_D : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal sc_Data_Type_In, sc_Data_Type_Out : raster_var_type;
  signal sc_Result : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal sc_Remainder : std_logic_vector(9 downto 0);
  signal sc_Out_Enable : std_logic;

--DEBUGGING SIGNAL:
signal tb_Buffer_Ready : std_logic;
signal counter : std_logic_vector(7 downto 0);

begin  -- architecture structural
  
  clear <= Fifo_Clear or not reset;
  
    
  
  rasterizer_inst : rasterizer
    port map (
      clock    => clock50,
      reset    => reset,
      coord_x0 => coord_x0,
      coord_y0 => coord_y0,
      coord_x1 => coord_x1,
      coord_y1 => coord_y1,
      coord_x2 => coord_x2,
      coord_y2 => coord_y2,

      coord_z0 => coord_z0,
      coord_z1 => coord_z1,
      coord_z2 => coord_z2,

      slope01   => slope01,
      slope12   => slope12,
      slope02   => slope02,

      z_slope01   => z_slope01,
      z_slope12   => z_slope12,
      z_slope02   => z_slope02,

      dz_dx01     => dz_dx01,
      dz_dx02     => dz_dx02,
      dz_dx12     => dz_dx12,

      color    => color,
      W_Enable => Write_Fifo_W_Enable,
      address  => Address_to_write,
      data     => Data_to_write,
      mask     => Mask_to_write,
      fifo_level => Write_Fifo_Level,
      draw_start => draw_signal,
      draw_done  => rasterizer_done
      );


  slope_calc_inst : slope_calc
    port map (
      clock         => clock50,
      reset         => reset,
      num_add_sub   => sc_Num_Add_Sub,
      den_add_sub   => sc_Den_Add_Sub,
      Enable        => sc_Enable,
      a             => sc_A,
      b             => sc_B,
      c             => sc_C,
      d             => sc_D,
      Data_Type_In  => sc_Data_Type_In,
      Data_Type_Out => sc_Data_Type_Out,
      Result        => sc_Result,
      Remainder     => sc_Remainder,
      out_enable    => rr_W_Enable
      );

  raster_vars_reg_inst : raster_vars_reg
   port map (
     reset     => reset,
     clock     => clock50,
     input     => sc_Result,
     data_type => sc_Data_Type_Out,
     W_Enable  => rr_W_Enable,
     R_Enable  => rr_R_Enable,
     Coord_R_Enable => coord_R_Enable,
     Full_Flag => rr_Full_Flag,
     Proj_Coord_Flag => proj_coord_flag,
     coord_x0  => coord_x0,
     coord_y0  => coord_y0,
     coord_z0  => coord_z0,
     coord_x1  => coord_x1,
     coord_y1  => coord_y1,
     coord_z1  => coord_z1,
     coord_x2  => coord_x2,
     coord_y2  => coord_y2,
     coord_z2  => coord_z2,

     slope01    => slope01,
     slope12    => slope12,
     slope02    => slope02,

     dz_dx01     => dz_dx01,
     dz_dx02     => dz_dx02,
     dz_dx12     => dz_dx12,

     z_slope01  => z_slope01,
     z_slope12  => z_slope12,
     z_slope02  => z_slope02
     );


  raster_ctrl_inst : raster_ctrl
    port map (
      reset             => reset,
      clock             => clock50,
      Triangles_Ready   => tb_Buffer_Ready,
      Draw_Start        => draw_signal,
      Draw_Done         => rasterizer_done,
      Data_Type         => sc_Data_Type_In,
      slope_calc_Enable => sc_Enable,
      R_Enable          => rr_R_Enable,
      Coord_R_Enable    => coord_R_Enable,
      Full_Flag         => rr_Full_Flag,
      Proj_Coord_Flag => proj_coord_flag,
      A                 => sc_A,
      B                 => sc_B,
      C                 => sc_C,
      D                 => sc_D,
      Num_Add_Sub       => sc_Num_Add_Sub,
      Den_Add_Sub       => sc_Den_Add_Sub,
      x0                => tb_x0,
      y0                => tb_y0,
      z0                => tb_z0,
      x1                => tb_x1,
      y1                => tb_y1,
      z1                => tb_z0,
      x2                => tb_x2,
      y2                => tb_y2,
      z2                => tb_z2,
      x0_proj_in           => coord_x0,
      y0_proj_in           => coord_y0,
      z0_proj_in           => coord_z0,
      x1_proj_in           => coord_x1,
      y1_proj_in           => coord_y1,
      z1_proj_in           => coord_z0,
      x2_proj_in           => coord_x2,
      y2_proj_in           => coord_y2,
      z2_proj_in           => coord_z2
            
);
  

  --rr_R_Enable <= '1';

  sc_A_Out <= sc_A;
  sc_B_Out <= sc_B;
  sc_C_Out <= sc_C;
  sc_D_Out <= sc_D;

  sc_Result_Out <= sc_Result;

  dz_dx01_out <= dz_dx01;
  dz_dx02_out <= dz_dx02;
  dz_dx12_out <= dz_dx12;

  z_slope01_out <= z_slope01;
  z_slope12_out <= z_slope12;
  z_slope02_out <= z_slope02;

  slope01_out <= slope01;
  slope12_out <= slope12;
  slope02_out <= slope02;

  x0_out <= coord_x0;
  x1_out <= coord_x1;
  x2_out <= coord_x2;
  y0_out <= coord_y0;
  y1_out <= coord_y1;
  y2_out <= coord_y2;
  z0_out <= coord_z0;
  z1_out <= coord_z1;
  z2_out <= coord_z2;
  
--Added By jeff for testing: (Values from Eric's waveforms)
        tb_Buffer_Ready <= '1';
--        tb_x0 <= "0011001000000000"; -- 50
--        tb_x1 <= "0001111000000000"; -- 30
--        tb_x2 <= "0011110000000000"; -- 60
--        tb_y0 <= "0011001000000000"; -- 50
--        tb_y1 <= "0100011000000000"; -- 70
--        tb_y2 <= "0101000000000000"; -- 80
--        slope01   <= "1111111110111111";
--        slope12   <= "0000000011000000";
--        slope02   <= "0000000000010101";

 
--Z buffer testing

	Z_Line_Number <= (others =>'0');
	Z_col_start <= (others => '0');
	Z_Col_End <= "00000000100";


--  write_to_fifo : process(clock50, reset) is

--   begin

--     if reset='0' then
--       Write_Fifo_W_Enable <= '0';
--       counter <= (others => '0');
--       Address_to_write <= (others => '0');
--       Mask_to_Write <= (others => '0');
--	   Data_to_Write <= (others => '0');
--
--     elsif clock50'event and clock50 = '1' then
--      if Write_Fifo_Level < "1011" and init_done ='1' then 
--        Write_Fifo_W_Enable <= '1';

--        if counter(1 downto 0) = "00" then
--          Address_to_write(17 downto 9) <= counter;
--        end if;

--        if counter < conv_std_logic_vector(255, 8) then
--           counter <= counter + '1';
--        else
--           counter <= (others => '0');
--        end if;

--    else
--       Write_Fifo_W_Enable <= '0';
--     end if;
 
--      Address_to_write(22 downto 19) <= "0000";
--      Address_to_write(18) <= '1';
--      Address_to_write(ADDRESS_COLUMN_WIDTH-1 downto 0) <= conv_std_logic_vector(30, ADDRESS_COLUMN_WIDTH);

--      Mask_to_Write <= "01010101";
--      Data_to_write <= "1110000011100000000111000001110000000011000000111111110011111100";
  --Data_to_write(8 downto 0) <= conv_std_logic_vector(counter, 9);
     
--   end if;
--   end process;  

    
  
  -- purpose: Latches data
  -- type   : sequential
  -- inputs : reset, clock50, Data_Out
  -- outputs: Data_Buf
--  data_latch : process (clock50, reset) is

--  begin  
    
--    if reset = '0' then
--      Data_Buf       <= (others => '0');
--    elsif clock50'event and clock50 ='1' then
--      Data_Buf       <= Data_Out;
--    end if; 

--  end process;

  -- purpose: Tristates data bus
  -- type   : combinational
  -- inputs : Tx_Data
  -- outputs: Data
--  tristate_data_bus : process (Tx_Data, Data_Buf) is

--  begin  -- process tristate_data_bus	
--    if Tx_Data = '1' then
--      Data <= Data_Buf;
--    else
--      Data <= (others => 'Z');
--    end if;

    
--  end process tristate_data_bus;

end architecture structural;
