-------------------------------------------------------------------------------
-- Title      : Top-level VGA output w/fifo & control logic
-- Project    : HULK
-------------------------------------------------------------------------------
-- File       : vgaout_top.vhd
-- Author     : Benj Carson <benjcarson@digitaljunkies.ca>
-- Last update: 2002/03/11
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: Structural design for top-level VGA output module.  Includes
-- full line FIFO, control logic and rudimentary memory interface.
-------------------------------------------------------------------------------
-- Revisions  :
-- Data         Author     Description
-- 2002/03/05   benj       Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.memory_defs.all;
use work.vgaout_defs.all;

entity vgaout_top is
  port (

    clock33, clock66      : in  std_logic;
    reset                 : in  std_logic;
    
    -- SDRAM Signals
    SDRAM_Ready           : in  std_logic;
    Rx_Data               : in  std_logic;
    Tx_Data               : in  std_logic;
	r_ack, w_ack	   : in std_logic;
    Init_Done             : in std_logic;
    R_Enable              : out std_logic;
    W_Enable              : out std_logic;
    Address               : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    Data                  : inout  std_logic_vector(DATA_WIDTH-1 downto 0);
	data_mask    		  : out std_logic_vector(DATA_WIDTH/8*4 -1 downto 0);

    -- VGA Signals
    Red                   : out std_logic_vector(R_DEPTH-1 downto 0);
    Green                 : out std_logic_vector(G_DEPTH-1 downto 0);
    Blue                  : out std_logic_vector(B_DEPTH-1 downto 0);
    Horiz_Sync, Vert_Sync : out std_logic;
	BufferPick   : in std_logic  -- DEBUG
    );
end entity vgaout_top;

architecture structural of vgaout_top is

  component vgaout is
   port(
        signal clock, reset : in  std_logic;
        -- Color outputs will be mulitple bits.  If only a single bit is used,
        -- the MSB can be connected to the RGB pins.  If multiple bits can be used,
        -- each of the bits can be fed into a D/A converter (i.e. three resistors)
        -- and then to the RGB pins.
        signal Red_Out     : out std_logic_vector(R_DEPTH-1 downto 0);
        signal Green_Out   : out std_logic_vector(G_DEPTH-1 downto 0);
        signal Blue_Out    : out std_logic_vector(B_DEPTH-1 downto 0);

        signal DataIn      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        signal Line_Number : out std_logic_vector(9 downto 0);
		signal Init_Done   : in std_logic;
		signal Blank_done  : in std_logic;
        signal Horiz_Sync, Vert_Sync : out std_logic;

        -- Fifo interface signals
        signal Read_Line  : out std_logic;  -- Tell fifo to begin buffering an entire line
        signal Read_Req   : out std_logic;  -- Request read
        signal Fifo_Empty : in  std_logic  -- Check if fifo has data

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

  component vgafifo_ctrl is
    port (
      clock, reset : in  std_logic;
      -- VGA Signals
      Read_Line    : in  std_logic;       -- Read Line command from VGA out module
      Line_Number  : in  std_logic_vector(9 downto 0);
      -- SDRAM Signals
      SDRAM_Ready  : in  std_logic;
      Data_Out     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      Rx_Data      : in  std_logic;
      Tx_Data      : in  std_logic;
      Init_Done    : in  std_logic;
      R_Enable     : out std_logic;
      W_Enable     : out std_logic;
      Address      : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
	  data_mask    : out std_logic_vector(4*DATA_WIDTH/8 -1 downto 0);
      r_ack, w_ack	   : in std_logic;
      BufferPick   : in std_logic;  -- DEBUG
      -- Fifo Signals
      Write_Req    : out std_logic;
      Fifo_Clear   : out std_logic;
      Fifo_Full    : in  std_logic;
      Fifo_Level   : in  std_logic_vector(6 downto 0);
	  Blank_Done   : out std_logic
    );
  end component;

  -- internal signals
  signal clear         : std_logic;
  signal Read_Req      : std_logic;
  signal Fifo_Data_Out : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Fifo_Clear    : std_logic;
  signal Fifo_Empty    : std_logic;
  signal Line_Number   : std_logic_vector(9 downto 0);
  signal Read_Line     : std_logic;
  signal Write_Req     : std_logic;
  signal Fifo_Full     : std_logic;
  signal Fifo_Level    : std_logic_vector(6 downto 0);
  signal Data_Out      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Data_Buf      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Data_VGA_fifo : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Blank_Done	   : std_logic;
  

--Testing:
signal Blue_Out : std_logic_vector(B_DEPTH-1 downto 0);
signal  R_Enable_Out : std_logic;

begin  -- architecture structural

  clear <= Fifo_Clear or not reset;


  vgafifo_inst : component vgafifo
    port map (
      data    => Data, --_VGA_fifo,
      wrreq   => Write_Req,
      rdreq   => Read_Req,
      rdclk   => clock33,
      wrclk   => clock66,
      aclr    => clear,
      q       => Fifo_Data_Out,
      rdempty => Fifo_Empty,
      wrfull  => Fifo_Full,
      wrusedw => Fifo_Level
      );

  vgaout_inst : component vgaout
    port map (
      clock       => clock33,
      reset       => reset,
      Red_Out     => Red,
      Green_Out   => Green,
      Blue_Out    => Blue,
      DataIn      => Fifo_Data_Out,
      Line_Number => Line_Number,
      Horiz_Sync  => Horiz_Sync,
      Vert_Sync   => Vert_Sync,
      Init_Done   => Init_Done,
      Read_Line   => Read_Line,
      Read_Req    => Read_Req,
      Fifo_Empty  => Fifo_Empty,
      blank_done  => blank_done
      );

  vgafifo_ctrl_inst : component vgafifo_ctrl
    port map (
      clock       => clock66,
      reset       => reset,
      Read_Line   => Read_Line,
      Line_Number => Line_Number,
      SDRAM_Ready => SDRAM_Ready,
      Data_Out    => Data_Out,
      Rx_Data     => Rx_Data,
      Tx_Data     => Tx_Data,
	  Init_Done   => Init_Done,
      R_Enable    => R_Enable,
      W_Enable    => W_Enable,
      Address     => Address,
      Write_Req   => Write_Req,
      Fifo_Clear  => Fifo_Clear,
      Fifo_Full   => Fifo_Full,
      Fifo_Level  => Fifo_Level,
	  data_mask   => data_mask,
	  r_ack 	  => r_ack,
	  w_ack       => w_ack,
	  blank_done  => blank_done,
      BufferPick  => BufferPick  -- DEBUG
      );
  
--R_Enable <= R_Enable_Out;
--Blue(1) <= R_Enable_Out and Blue_Out(1);
--Blue(0) <= R_Enable_Out and Blue_Out(0);


 
data_latch: process (clock66, reset) is

    begin  
    
      if reset = '0' then
		Data_Buf <= (others => '0');
      elsif clock66'event and clock66 ='1' then
		Data_Buf <= Data_Out;
	  end if; 

end process;

    -- purpose: Tristates data bus
    -- type   : combinational
    -- inputs : Tx_Data
    -- outputs: Data

   tristate_data_bus: process (Tx_Data) is

    begin  -- process tristate_data_bus	
        if Tx_Data = '1' then
            Data <= Data_Buf;
          else
            Data <= (others => 'Z');
        end if;

	
    end process tristate_data_bus;

end architecture structural;

------------------------------------------------------------------------------------------------------------------------
-- END VGAOUT_TOP
------------------------------------------------------------------------------------------------------------------------
