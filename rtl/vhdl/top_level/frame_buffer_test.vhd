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
-- Title      : Frame buffer test file
-- Project    : HULK
-------------------------------------------------------------------------------
-- File       : frame_buffer_test.vhd
-- Author     : Benj Carson <benjcarson@digitaljunkies.ca>
-- Last update: 2002-05-29
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

entity frame_buffer_test is

  port (
    inclock               : in  std_logic;
    reset                 : in  std_logic;
    outclock              : out std_logic;
    -- VGA Output signals
    Red                   : out std_logic_vector(R_DEPTH-1 downto 0);
    Green                 : out std_logic_vector(G_DEPTH-1 downto 0);
    Blue                  : out std_logic_vector(B_DEPTH-1 downto 0);
    Horiz_Sync            : out std_logic;
    Vert_Sync             : out std_logic;
    BufferPick            : in std_logic;  -- DEBUG
    -- Memory signals
    WE_n_O                : out   std_logic;  -- Write enable, Active Low
    CKE_O                 : out   std_logic_vector(1 downto 0); -- clock enable
    CS_n_O                : out   std_logic_vector(1 downto 0);
    Address_To_Ram        : out   std_logic_vector(12 downto 0);
    Data                  : inout std_logic_vector(DATA_WIDTH-1 downto 0);
    RAS_n_O               : out   std_logic;
    CAS_n_O               : out   std_logic;
    DQM_O                 : out   std_logic_vector(7 downto 0);
    BA_O                  : out   std_logic_vector(1 downto 0);

    SW1                   : in std_logic;
    SW2                   : in std_logic
    );

end entity frame_buffer_test;


architecture structural of frame_buffer_test is

  component pll2x is                    -- altclocklock/boost megafunction
    port (
      inclock : IN  STD_LOGIC;
      clock0  : OUT STD_LOGIC;
      clock1  : OUT STD_LOGIC
      );
  end component pll2x;
-------------------------------------------------------------------------------
-- sdram_control
-------------------------------------------------------------------------------
  component sdram_control is
    generic(
    -- Input Address format:
    --
    --   Bank       Row            Column 
    --  |<->|<-              ->|<-        ->|
    --  -------------------------------------
    --  22  21                 9            0
    --
    IN_ADDRESS_WIDTH    : positive := 23;
    BANKSIZE            : integer := 2;
    ROWSIZE             : integer := 12;
    COLSIZE             : integer := 9;
    BANKSTART           : integer := 21;
    ROWSTART            : integer := 9;
    COLSTART            : integer := 0;
    DATAWIDTH           : integer := 64;
    INTERLEAVED         : std_logic := '0';  -- Sequential if '0'
    BURST_MODE_n        : std_logic := '0';  -- enabled if '0'
    BURST_LENGTH        : integer := 4;
    NO_OF_CHIPS         : integer := 2

    );

    port(
    CLK_I               : in std_logic;
    RST_I               : in  std_logic;
    R_enable_I          : in  std_logic;
    W_enable_I          : in  std_logic;
    RW_address_I        : in  std_logic_vector(IN_ADDRESS_WIDTH-1 downto 0);
    ready_O             : out std_logic;
    tx_data_O           : out std_logic;
    rx_data_O           : out std_logic;
    r_ack_O             : out std_logic;
    w_ack_O             : out std_logic;
    init_done_O         : out std_logic;
    data_mask_I         : in  std_logic_vector(DATAWIDTH/8*BURST_LENGTH -1 downto 0);

    -- to memory
    CKE_O          : out std_logic_vector(1 downto 0);  -- clock enable
    CS_n_O         : out std_logic_vector(NO_OF_CHIPS-1 downto 0);
    
    addr_O         : out std_logic_vector(12 downto 0);
    WE_n_O         : out std_logic;     -- Write enable, Active Low
    RAS_n_O        : out std_logic;
    CAS_n_O        : out std_logic;
    DQM_O          : out std_logic_vector(datawidth/8-1 downto 0);
    BA_O           : out std_logic_vector (1 downto 0)
    );
  end component sdram_control;
-------------------------------------------------------------------------------
-- vgaout
-------------------------------------------------------------------------------
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

        Blank_Now    : out std_logic;
        Blank_Ack    : in std_logic;

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

      Blank_Now    : in std_logic;
      Blank_Ack    : out std_logic;

      Write_Fifo_Empty : in std_logic;
      Write_Fifo_Data_Pop   : out std_logic;
      Write_Fifo_Data_Enable : out std_logic;
      Write_Fifo_Addr_Enable : out std_logic;
      Write_Fifo_Addr_Pop : out std_logic;
      Write_FB         : out std_logic;
      -- Z_Fifo Signals

--      Z_Fifo_Clear   : out std_logic;
--      Z_Write_Req    : out std_logic;
--      Z_Fifo_Level   : in  std_logic_vector(7 downto 0);
--      Z_Fifo_Full    : in  std_logic;

      -- Z_Buffer Signals
--      Z_Line_Number : in std_logic_vector(9 downto 0);
--      Z_Col_Start   : in std_logic_vector(10 downto 0);
--      Z_Col_End     : in std_logic_vector(10 downto 0);

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
      dz_dx01     : in  std_logic_vector(raster_datawidth-1 downto 0);
      dz_dx12     : in  std_logic_vector(raster_datawidth-1 downto 0);
      dz_dx02     : in  std_logic_vector(raster_datawidth-1 downto 0);
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
  signal Fifo_Level     : std_logic_vector(6 downto 0);
  signal Data_Out       : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Data_Buf       : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Data_VGA_fifo  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Blank_Done	    : std_logic;

  signal Blank_Now	    : std_logic;
  signal Blank_Ack	    : std_logic;

  signal clock33, clock50, SDRAM_Ready                      : std_logic;
  signal R_Enable, W_Enable, Tx_Data, Rx_Data, r_ack, w_ack : std_logic;
  signal Init_Done                                          : std_logic;
  signal Address_Internal                                   : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal Data_mask                                          : std_logic_vector(DATA_WIDTH/8*4 -1 downto 0);

  signal Write_FB : std_logic;
  signal triangle_case : std_logic_vector(1 downto 0);

    -- Z FIFO signals
--  signal Z_Write_Req      : std_logic;
--  signal Z_Fifo_Full      : std_logic;
--  signal Z_Fifo_Level     : std_logic_vector(7 downto 0);
--  signal Z_Read_Req       : std_logic;
--  signal Z_Fifo_Data_Out  : std_logic_vector(DATA_WIDTH-1 downto 0);
--  signal Z_Data : std_logic_vector(DATA_WIDTH-1 downto 0);
--  signal Z_Fifo_Clear     : std_logic;
--  signal Z_Fifo_Empty     : std_logic;
  
--  signal Z_Line_Number : std_logic_vector(9 downto 0);
--  signal Z_Col_Start   : std_logic_vector(10 downto 0);
--  signal Z_Col_End     : std_logic_vector(10 downto 0);



  -- Write FIFO signals
  signal Data_to_write       : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Mask_to_Write       : std_logic_vector(DATA_WIDTH/8-1 downto 0);
  signal Address_to_write    : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
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
  signal dz_dx01, dz_dx12, dz_dx02, z_slope01, z_slope12, z_slope02 : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal color : std_logic_vector(COLOR_DEPTH-1 downto 0);
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

-- Triangle Buffer Signals
  signal tb_x0, tb_y0, tb_z0, tb_x1, tb_y1, tb_z1, tb_x2, tb_y2, tb_z2 : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal tb_Buffer_Ready : std_logic;

--DEBUGGING SIGNAL:
signal counter : std_logic_vector(7 downto 0);

begin  -- architecture structural
  
  clear <= Fifo_Clear or not reset;
  
  pll2x_inst : pll2x
    port map (
      inclock => inclock,
      clock0  => clock33,
      clock1 => clock50
      );

  outclock <= clock50;
    
  sdram_control_inst : sdram_control
    port map (
      CLK_I             => clock50,
      RST_I             => reset,
      R_Enable_I        => R_Enable,
      W_Enable_I        => W_Enable,
      RW_address_I      => Address_Internal,
      ready_O           => SDRAM_Ready,
      tx_data_O         => Tx_Data,
      rx_data_O         => Rx_Data,
      init_done_O       => Init_Done,
      WE_n_O            => WE_n_O,
      CKE_O             => CKE_O,
      CS_n_O            => CS_n_O,
      addr_O            => Address_To_Ram,
      RAS_n_O           => RAS_n_O,
      CAS_n_O           => CAS_n_O,
      DQM_O             => DQM_O,
      BA_O              => BA_O,
      Data_mask_I       => wf_Mask_to_Ram,
--    chip_select => chip_select,
      r_ack_O           => r_ack,
      w_ack_O           => w_ack
      );
  
  vgafifo_inst : component vgafifo
    port map (
      data    => Data, --_VGA_fifo,
      wrreq   => Write_Req,
      rdreq   => Read_Req,
      rdclk   => clock33,
      wrclk   => clock50,
      aclr    => clear,
      q       => Fifo_Data_Out,
      rdempty => Fifo_Empty,
      wrfull  => Fifo_Full,
      wrusedw => Fifo_Level
      );

--  zfifo_inst : component zfifo
--    port map (
--      data    => Z_Data, --_VGA_fifo,
--      wrreq   => Z_Write_Req,
--      rdreq   => Z_Read_Req,
--      rdclk   => clock50,
--      wrclk   => clock50,
--      aclr    => Z_Fifo_clear,
--      q       => Z_Fifo_Data_Out,
--      rdempty => Z_Fifo_Empty,
--      wrfull  => Z_Fifo_Full,
--      wrusedw => Z_Fifo_Level
--      );

  vgaout_inst : component vgaout
    port map (
      clock          => clock33,
      reset          => reset,
      Red_Out        => Red,
      Green_Out      => Green,
      Blue_Out       => Blue,
      DataIn         => Fifo_Data_Out,
      Line_Number    => Line_Number,
      Horiz_Sync     => Horiz_Sync,
      Vert_Sync      => Vert_Sync,
      Init_Done      => Init_Done,
      Read_Line      => Read_Line,
      Read_Line_Warn => Read_Line_Warn,
      Read_Line_Ack  => Read_Line_Ack,
      Read_Req       => Read_Req,
      Fifo_Empty     => Fifo_Empty,
      Blank_Now      => Blank_Now,
      Blank_Ack      => Blank_Ack,
      blank_done     => blank_done
      );

  vgafifo_ctrl_inst  : component vgafifo_ctrl
    port map (
      clock                 => clock50,
      reset                 => reset,
      Read_Line             => Read_Line,
      Read_Line_Warn        => Read_Line_Warn,
      Read_Line_Ack         => Read_Line_Ack,
      Line_Number           => Line_Number,
      SDRAM_Ready           => SDRAM_Ready,
      Data_Out              => Data_Out,
      Rx_Data               => Rx_Data,
      Tx_Data               => Tx_Data,
      Init_Done             => Init_Done,
      R_Enable              => R_Enable,
      W_Enable              => W_Enable,
      Address               => Address_Internal,
      Write_Req             => Write_Req,
      Fifo_Clear            => Fifo_Clear,
      Fifo_Full             => Fifo_Full,
      Fifo_Level            => Fifo_Level,
      --Z
--    Z_Fifo_Clear          => Z_Fifo_Clear,
--    Z_Write_Req           => Z_Write_Req,
--    Z_Fifo_Level          => Z_Fifo_Level,
--    Z_Fifo_Full           => Z_Fifo_Full,     

--    Z_Line_Number         => Z_Line_Number, 
--    Z_Col_Start           => Z_Col_Start,
--    Z_Col_End             => Z_Col_End,

      --Z
      Write_Fifo_Empty      => Write_Fifo_Empty,
      Write_Fifo_Data_Pop   => Data_Pop,
      Write_Fifo_Data_Enable => Write_Fifo_Data_Enable,
      Write_Fifo_Addr_Pop   => Addr_Pop,
      Write_Fifo_Addr_Enable => Write_Fifo_Addr_Enable,
      Write_FB              => Write_FB,
      data_mask             => data_mask,
      r_ack                 => r_ack,
      w_ack                 => w_ack,
      blank_done            => blank_done,

      Blank_Now      => Blank_Now,
      Blank_Ack      => Blank_Ack,

      BufferPick            => BufferPick  -- DEBUG
      );


  write_fifo_inst  : write_fifo
    port map (
      clock               => clock50,
      reset               => reset,
      Data_Mask_In        => Mask_to_write,
      Data_In             => Data_to_write,
      Address_In          => Address_to_write,
      W_Enable            => Write_Fifo_W_Enable,
      Send_Address        => Addr_Pop,
      Addr_Out_Enable     => Write_Fifo_Addr_Enable,
      Send_Data           => Data_Pop,
      Data_Out_Enable     => Write_Fifo_Data_Enable,
      Data_Mask_Out       => wf_Mask_to_RAM,
      Data_Out            => Data_Out, --wf_Data_to_RAM,
      Address_Out         => Address_Internal,  --wf_Address_to_RAM,
      Fifo_Level          => Write_Fifo_Level,
      Full                => Write_Fifo_Full,
      Mostly_Empty        => Write_Fifo_Empty
      );
  
 
  rasterizer_inst : rasterizer
    port map (
      clock    => clock50,
      reset    => reset,

      coord_x0 => coord_x0,
      coord_y0 => coord_y0,
      coord_z0 => coord_z0,

      coord_x1 => coord_x1,
      coord_y1 => coord_y1,
      coord_z1 => coord_z1,

      coord_x2 => coord_x2,
      coord_y2 => coord_y2,
      coord_z2 => coord_z2,

      slope01   => slope01,
      slope12   => slope12,
      slope02   => slope02,

      z_slope01   => z_slope01,
      z_slope12   => z_slope12,
      z_slope02   => z_slope02,

      dz_dx01     => dz_dx01,
      dz_dx12     => dz_dx12,
      dz_dx02     => dz_dx02,

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
     dz_dx12     => dz_dx12,
     dz_dx02     => dz_dx02,

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
      z1                => tb_z1,

      x2                => tb_x2,
      y2                => tb_y2,
      z2                => tb_z2,

      x0_proj_in           => coord_x0,
      y0_proj_in           => coord_y0,
      z0_proj_in           => coord_z0,

      x1_proj_in           => coord_x1,
      y1_proj_in           => coord_y1,
      z1_proj_in           => coord_z1,

      x2_proj_in           => coord_x2,
      y2_proj_in           => coord_y2,
      z2_proj_in           => coord_z2
            
);
  
--Added By jeff for testing: (Values from Eric's waveforms)
        tb_Buffer_Ready <= '1';
        --tb_x0 <= "0000110010" & "000000"; -- (-220) 100
        --tb_x1 <= "0000011110" & "000000"; -- (-200) 120
        --tb_x2 <= "0000111100" & "000000"; -- (-80)  240
        --tb_y0 <= "0000110010" & "000000"; -- (-40)  200
        --tb_y1 <= "0001000110" & "000000"; -- (40)   280
        --tb_y2 <= "0001010000" & "000000"; -- (80)   320
        --tb_z0 <= (others => '0');
        --tb_z1 <= (others => '0');
        --tb_z2 <= (others => '0');
        --tb_x0 <= "1111001110" & "000000"; -- -50
        --tb_x1 <= "1110011100" & "000000"; -- -100
        --tb_x2 <= "0000111100" & "000000"; -- 60
        --tb_y0 <= "1110110000" & "000000"; -- -80
        --tb_y1 <= "0001011010" & "000000"; -- 90
        --tb_y2 <= "0001000110" & "000000"; -- 70
        --tb_z0 <= (others => '0');
        --tb_z1 <= (others => '0');
        --tb_z2 <= (others => '0');

        --tb_x0 <= "1111100111" & "000000"; -- -25 (projected = 270)
		--tb_y0 <= "1110110000" & "000000"; -- -80 (projected = 400)
        --tb_z0 <= "0001100000" & "000000"; -- 96

        --tb_x1 <= "1111001110" & "000000"; -- -50 (projected = 270)
        --tb_y1 <= "0000101101" & "000000"; -- 45   (projected = 195)
        --tb_z1 <= "0010000000" & "000000"; -- 128

        --tb_x2 <= "0010011110" & "000000"; -- 188  (projected = 414)
        --tb_y2 <= "0000100011" & "000000"; -- 70   (projected = 205)
        --tb_z2 <= "0011000000" & "000000"; -- 192



        ---------------------------------------------
        -- NOTE: z values must be greater than 64  --
        -- since that is our focal length          --
        ---------------------------------------------



--        tb_z2 <= "0010000000" & "000000"; -- 128
--        slope01   <= "1111111110111111";
--        slope12   <= "0000000011000000";
--        slope02   <= "0000000000010101";

 
--Z buffer testing

--	Z_Line_Number <= (others =>'0');
--	Z_col_start <= (others => '0');
--	Z_Col_End <= "00000000100";

--draw_signal <= init_done;
  draw : process (clock50, reset) is

  begin
 
    if reset = '0' then
--      draw_signal <= '0';
      color    <= "00000000";
    elsif clock50'event and clock50 ='1' then
--      if init_done = '1' and rasterizer_done = '1' then
--        draw_signal <= '1';
--     else
--        draw_signal <= '0';
--      end if;

 --     if BufferPick = '1' then
 --       color    <= "11100000";
 --       tb_x0 <= conv_std_logic_vector(150, 10)  & "000000";
--      else
 --       color    <= "00011100";
--        tb_x0 <= conv_std_logic_vector(100, 10)  & "000000";
--      end if;


triangle_case <= sw1 & sw2;

case triangle_case is

     when "00" => 
        color    <= "11100000";
        tb_x0 <= conv_std_logic_vector(-150, 10)  & "000000";
        tb_y0 <= conv_std_logic_vector(-100, 10)  & "000000";
        tb_z0 <= conv_std_logic_vector(64, 10)  & "000000";

        tb_x1 <= conv_std_logic_vector(-100, 10)  & "000000";
        tb_y1 <= conv_std_logic_vector(-100, 10)  & "000000";
        tb_z1 <= conv_std_logic_vector(0, 10) & "000000";

        tb_x2 <= conv_std_logic_vector(-20, 10) & "000000";
        tb_y2 <= conv_std_logic_vector(-60, 10)  & "000000";
        tb_z2 <= conv_std_logic_vector(-32, 10) & "000000";

       when "01" => 
        color    <= "11111100";
        tb_x0 <= conv_std_logic_vector(150, 10)  & "000000";
        tb_y0 <= conv_std_logic_vector(-100, 10)  & "000000";
        tb_z0 <= conv_std_logic_vector(-32, 10)  & "000000";

        tb_x1 <= conv_std_logic_vector(100, 10)  & "000000";
        tb_y1 <= conv_std_logic_vector(-100, 10)  & "000000";
        tb_z1 <= conv_std_logic_vector(0, 10) & "000000";

        tb_x2 <= conv_std_logic_vector(20, 10) & "000000";
        tb_y2 <= conv_std_logic_vector(-30, 10)  & "000000";
        tb_z2 <= conv_std_logic_vector(60, 10) & "000000";

     when "10" => 
        color    <= "11000011";
        tb_x0 <= conv_std_logic_vector(10, 10)  & "000000";
        tb_y0 <= conv_std_logic_vector(100, 10)  & "000000";
        tb_z0 <= conv_std_logic_vector(64, 10)  & "000000";

        tb_x1 <= conv_std_logic_vector(100, 10)  & "000000";
        tb_y1 <= conv_std_logic_vector(100, 10)  & "000000";
        tb_z1 <= conv_std_logic_vector(50, 10) & "000000";

        tb_x2 <= conv_std_logic_vector(30, 10) & "000000";
        tb_y2 <= conv_std_logic_vector(0, 10)  & "000000";
        tb_z2 <= conv_std_logic_vector(10, 10) & "000000";

     when "11" => 
        color    <= "00011100";
        tb_x0 <= conv_std_logic_vector(-50, 10)  & "000000";
        tb_y0 <= conv_std_logic_vector(100, 10)  & "000000";
        tb_z0 <= conv_std_logic_vector(32, 10)  & "000000";

        tb_x1 <= conv_std_logic_vector(-100, 10)  & "000000";
        tb_y1 <= conv_std_logic_vector(100, 10)  & "000000";
        tb_z1 <= conv_std_logic_vector(0, 10) & "000000";

        tb_x2 <= conv_std_logic_vector(-20, 10) & "000000";
        tb_y2 <= conv_std_logic_vector(0, 10)  & "000000";
        tb_z2 <= conv_std_logic_vector(64, 10) & "000000";
     when others => null;

     end case;

    end if;

  end process;

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
  data_latch : process (clock50, reset) is

  begin  
    
    if reset = '0' then
      Data_Buf       <= (others => '0');
    elsif clock50'event and clock50 ='1' then
      Data_Buf       <= Data_Out;
    end if; 

  end process;

  -- purpose: Tristates data bus
  -- type   : combinational
  -- inputs : Tx_Data
  -- outputs: Data
  tristate_data_bus : process (Tx_Data, Data_Buf) is

  begin  -- process tristate_data_bus	
    if Tx_Data = '1' then
      Data <= Data_Buf;
    else
      Data <= (others => 'Z');
    end if;

  end process tristate_data_bus;

end architecture structural;
