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
-- Title      : VGA out
-- Project    : HULK
-------------------------------------------------------------------------------
-- File       : vgaout.vhd
-- Author     : Benj Carson <benjcarson@digitaljunkies.ca>
-- Last update: 2002/03/06
-- Platform   : Altera APEX20KE200
-------------------------------------------------------------------------------
-- Description: 
-- 
-- Based on razzle.vhd by
-- Jim Hamblen, Georgia Tech School of ECE
--
-- Notes:
--
-- Using a 25.175MHz clock:
-- Single row is sent to monitor within 25.17us
-- HSync drops low a minimum of 0.94us after last pixel in row
-- HSync stays low 3.77us
-- New line of pixels can begin a minimum of 1.89us after end of hsync
-- Therefore a single line occupies 25.17us of a 31.77us interval
--
-- Full frame is sent within 15.25ms
-- VSync drops low a minimum of 0.45ms after last row
-- VSync stays low for 64us
-- New frame can begin minimum of 1.02ms after end of vsync
-- Single frame occupies 15.25ms of 16.784ms
--
-- Things change when a 33.3MHz clock is used.  The following settings
-- were determined to work using a Matrox G400 video card and a 17" Daytek
-- monitor:
--
-- Resolution:     640x480
-- Pixel Clock:      33324 kHz
--
-- Horizontal rate:     39 kHz
--  Front porch:        24 pixels
--  Sync:                3 pixels
--  Back porch:        136 pixels
--
-- Vertical rate:       76 Hz
--  Front porch:         9 lines
--  Sync:                3 lines
--  Back porch:         30 lines
--
-- These values are defined in vgaout_defs.vhd.

library IEEE;
use  IEEE.std_logic_1164.all;
use  IEEE.std_logic_arith.all;
use  IEEE.std_logic_unsigned.all;

library work;
use work.memory_defs.all;
use work.vgaout_defs.all;

entity vgaout is

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

        signal Horiz_Sync, Vert_Sync : out std_logic;

        signal Init_Done   : in  std_logic;  -- Flags when memory is finished intializing
        signal Blank_Done  : in  std_logic;  -- Flags when screen blank is done

        signal Blank_Now    : out std_logic;
        signal Blank_Ack    : in std_logic;

        -- Fifo interface signals
        signal Read_Line      : out std_logic;  -- Tell fifo to begin buffering an entire line
        signal Read_Line_Ack  : in std_logic;   -- Acknowledge read line request
        signal Read_Line_Warn : out std_logic; 
        signal Read_Req       : out std_logic;  -- Request read
        signal Fifo_Empty     : in  std_logic   -- Check if fifo has data

        );

end vgaout;

architecture behavior of vgaout is

-- Video Display Signals

signal sHCount                        : std_logic_vector(9 Downto 0);
signal sVCount                        : std_logic_vector(9 Downto 0);
signal sVideoOn, sVideoOnH, sVideoOnV : std_logic;
signal Read_ReqA, Read_ReqB           : std_logic;  -- Two halves of read request signal

signal Red   : std_logic_vector(R_DEPTH-1 downto 0);
signal Green : std_logic_vector(G_DEPTH-1 downto 0);
signal Blue  : std_logic_vector(B_DEPTH-1 downto 0);

begin           

-- purpose: Get data from frame buffer to and display it on screen
-- type   : combinational
-- inputs : clock, reset, sHCount, DataIn, sVideoOn, Fifo_Empty
-- outputs: Red, Green, Blue, Read_ReqA
GetData: process (reset, sHCount, sVideoOn, Fifo_Empty)
begin  -- process GetData
  if reset = '0' then                   -- asynchronous reset (active low)

    Read_ReqA      <= '0';
    Red            <= conv_std_logic_vector(0, R_DEPTH);
    Green          <= conv_std_logic_vector(0, G_DEPTH);
    Blue           <= conv_std_logic_vector(0, B_DEPTH);

    elsif (sVideoOn = '1') and (Fifo_Empty = '0') then

      -- Colors for pixel data on video signal:
      -- If the color depth is 8bpp then a typical 3-3-2 breakdown is:
      --
      --          MSB           LSB
      --           7 6 5 4 3 2 1 0
      --           |---| |---| |-|
      --             R     G    B
      --
      -- Since DataIn is 64 bits wide, we need to extract 8 pixels from
      -- each input word.  We do this by examining the 3 least significant
      -- bits of sHCount and slicing DataIn differently.  Coulda used a shift
      -- register, but there's no point moving data around needlessly when
      -- we're not all that pressed for space.
      case sHCount(2 downto 0) is
        when "111" => 
          Red   <= DataIn(COLOR_DEPTH-1       downto (G_DEPTH+B_DEPTH));
          Green <= DataIn((G_DEPTH+B_DEPTH-1) downto B_DEPTH);
          Blue  <= DataIn((B_DEPTH-1)         downto 0);

          -- Request another data word from the fifo
          Read_ReqA <= '1';

        when "110" =>
          Red   <= DataIn(COLOR_DEPTH-1 + DATA_WIDTH/8         downto (G_DEPTH + B_DEPTH + DATA_WIDTH/8));
          Green <= DataIn((G_DEPTH+B_DEPTH-1 + DATA_WIDTH/8)   downto B_DEPTH + DATA_WIDTH/8);
          Blue  <= DataIn((B_DEPTH-1 + DATA_WIDTH/8)           downto DATA_WIDTH/8);
          Read_ReqA <= '0';
        when "101" =>
          Red   <= DataIn(COLOR_DEPTH-1 + DATA_WIDTH/4         downto (G_DEPTH+B_DEPTH + DATA_WIDTH/4));
          Green <= DataIn((G_DEPTH+B_DEPTH-1 + DATA_WIDTH/4)   downto B_DEPTH + DATA_WIDTH/4);
          Blue  <= DataIn((B_DEPTH-1 + DATA_WIDTH/4)           downto DATA_WIDTH/4);
          Read_ReqA <= '0';
        when "100" =>
          Red   <= DataIn(COLOR_DEPTH-1 + 3*DATA_WIDTH/8       downto (G_DEPTH+B_DEPTH + 3*DATA_WIDTH/8));
          Green <= DataIn((G_DEPTH+B_DEPTH-1 + 3*DATA_WIDTH/8) downto B_DEPTH + 3*DATA_WIDTH/8);
          Blue  <= DataIn((B_DEPTH-1 + 3*DATA_WIDTH/8)         downto 3*DATA_WIDTH/8);
          Read_ReqA <= '0';
        when "011" =>
          Red   <= DataIn(COLOR_DEPTH-1 + DATA_WIDTH/2         downto (G_DEPTH+B_DEPTH + DATA_WIDTH/2));
          Green <= DataIn((G_DEPTH+B_DEPTH-1 + DATA_WIDTH/2)   downto B_DEPTH + DATA_WIDTH/2);
          Blue  <= DataIn((B_DEPTH-1 + DATA_WIDTH/2)           downto DATA_WIDTH/2);
          Read_ReqA <= '0';
        when "010" =>
          Red   <= DataIn(COLOR_DEPTH-1 + 5*DATA_WIDTH/8       downto (G_DEPTH+B_DEPTH + 5*DATA_WIDTH/8));
          Green <= DataIn((G_DEPTH+B_DEPTH-1 + 5*DATA_WIDTH/8) downto B_DEPTH + 5*DATA_WIDTH/8);
          Blue  <= DataIn((B_DEPTH-1 + 5*DATA_WIDTH/8)         downto 5*DATA_WIDTH/8);
          Read_ReqA <= '0';
        when "001" =>
          Red   <= DataIn(COLOR_DEPTH-1 + 3*DATA_WIDTH/4       downto (G_DEPTH + B_DEPTH + 3*DATA_WIDTH/4));
          Green <= DataIn((G_DEPTH+B_DEPTH-1 + 3*DATA_WIDTH/4) downto B_DEPTH + 3*DATA_WIDTH/4);
          Blue  <= DataIn((B_DEPTH-1 + 3*DATA_WIDTH/4)         downto 3*DATA_WIDTH/4);
          Read_ReqA <= '0';
        when "000" =>
          Red   <= DataIn(COLOR_DEPTH-1 + 7*DATA_WIDTH/8       downto (G_DEPTH + B_DEPTH + 7*DATA_WIDTH/8));
          Green <= DataIn((G_DEPTH+B_DEPTH-1 + 7*DATA_WIDTH/8) downto B_DEPTH + 7*DATA_WIDTH/8);
          Blue  <= DataIn((B_DEPTH-1 + 7*DATA_WIDTH/8)         downto 7*DATA_WIDTH/8);
          Read_ReqA <= '0';

        when others => null;
                       
      end case;
      
    elsif Fifo_Empty = '1' and sVideoOn = '1' then 
      -- We're not drawing anything on the screen or the buffer is empty (bad)
      Read_ReqA <= '0';

      Red       <= "111"; --conv_std_logic_vector(0, R_DEPTH);
      Green     <= conv_std_logic_vector(0, G_DEPTH);
      Blue      <= conv_std_logic_vector(0, B_DEPTH);
    else
      -- We're not drawing anything on the screen or the buffer is empty (bad)
      Read_ReqA <= '0';

      Red       <= conv_std_logic_vector(0, R_DEPTH);
      Green     <= conv_std_logic_vector(0, G_DEPTH);
      Blue      <= conv_std_logic_vector(0, B_DEPTH);

    end if;
    
end process GetData;

-- purpose: Register RGB outputs
-- type : sequential
-- inputs : clock, reset, Red, Green, Blue
-- outputs: Red_Out, Green_Out, Blue_Out
register_rgb : process (clock, reset) is
begin  -- process register_rgb

  if reset = '0' then                     -- asynchronous reset (active low)
    Red_Out   <= conv_std_logic_vector(0, R_DEPTH);
    Green_Out <= conv_std_logic_vector(0, G_DEPTH);
    Blue_Out  <= conv_std_logic_vector(0, B_DEPTH);
  elsif clock'event and clock = '1' then  -- rising clock edge
    Red_Out   <= Red;
    Green_Out <= Green;
    Blue_Out  <= Blue;
  end if;

end process register_rgb;
 
-- purpose: Generate horizontal and vertical blanking signals  &
-- send address & commands to the fifo
-- type   : sequential
-- inputs : clock, reset
-- outputs: sHCount, sVCount, sVideoOnH, sVideoOnV, sVideoOn,
-- Line_Number, Read_Line, Read_ReqB
GenerateVideoSignals: process (clock, reset)
begin  -- process GenerateVideoSignals
  if reset = '0' then                   -- asynchronous reset (active low)

    Line_Number <= (others => '0');
    Read_Line   <= '0';
    Read_ReqB   <= '0';
    sHCount     <= conv_std_logic_vector(0, 10);
    sVCount     <= conv_std_logic_vector(0, 10);
    sVideoOnH   <= '0';
    sVideoOnV   <= '0';
    Vert_Sync   <= '0';
    Horiz_Sync  <= '0';
    Blank_Now   <= '0';
    Read_Line_Warn <= '0';


  elsif clock'event and clock = '1' then
    if Init_Done = '1' and Blank_Done = '1' then  -- rising clock edge
  
    -- sHCount counts pixels (640 + extra time for sync signals)
    --
    --  NON-STANDARD video timing (using 33.324MHz pixel clock):
    --
    --                                        Front    Sync    Back            
    --   |<-         Video active       ->|<- Porch ->|<-->|<- Porch ->|  
    --   ----------------------------------------------____-------------
    --   0                               639         663  666         802
    --
    If (sHCount = conv_std_logic_vector(H_MAX,10)) then
      sHCount  <= conv_std_logic_vector(0,10);
    else
      sHCount  <= sHCount + conv_std_logic_vector(1,10);
    end if;

    -- Assert Read_Req at beginning of new line
    if sHCount = conv_std_logic_vector(H_MAX-1, 10) then
      Read_ReqB <= '1';
    else
      Read_ReqB <= '0';
    end if;
    
    --Generate Horizontal Sync Signal (since we latch the rgb outputs
    --and delay them by one cycle, we can compensate here by bumping the
    --sync back by one cycle.    
    If (sHCount >= conv_std_logic_vector(H_ACTIVE+H_FPORCH+1,10)) and
       (sHCount < conv_std_logic_vector(H_ACTIVE+H_FPORCH+H_SYNC+1,10)) then
      Horiz_Sync <= '0';
    else
      Horiz_Sync <= '1';
    end if;
    --
    --
    -- sVCount counts rows of pixels (480 + extra time for sync signals)
    --
    --  NON-STANDARD video timing (using 33.324MHz pixel clock):
    --
    --                                        Front    Sync    Back            
    --   |<-         Video active       ->|<- Porch ->|<-->|<- Porch ->|  
    --   ----------------------------------------------____-------------
    --   0                               480         489  492         522
    --

    If (sVCount = conv_std_logic_vector(V_MAX,10)) and
       (sHCount >= conv_std_logic_vector(H_ACTIVE,10)) then

      sVCount <= conv_std_logic_vector(0,10);

    elsif (sHCount = conv_std_logic_vector(H_ACTIVE,10)) Then

      sVCount <= sVCount + conv_std_logic_vector(1,10);

    end if;

    -- Generate Vertical Sync Signal
    If (sVCount >= conv_std_logic_vector(V_ACTIVE+V_FPORCH, 10)) and
       (sVCount <  conv_std_logic_vector(V_ACTIVE+V_FPORCH+V_SYNC,10)) then
      Vert_Sync <= '0';
    else
      Vert_Sync <= '1';
    end if;
  
    -- Generate Video on Screen Signals for Pixel Data
    If (sHCount < conv_std_logic_vector(H_ACTIVE,10)) or
       (sHCount = conv_std_logic_vector(H_MAX,10)) Then
      sVideoOnH <= '1';
    else
      sVideoOnH <= '0';
    end if;


    if (sVCount < conv_std_logic_vector(V_ACTIVE,10)) Then

      -- Each line of pixels corresponds to a full column of memory addresses.
      sVideoOnV <= '1';

    else
      sVideoOnV <= '0';
    end if;

    -- We want the fifo to start requesting data well before we need it.
    -- Since it is running at 66MHz, and we're running at 33MHz, it can
    -- fill up twice as quickly as we can empty it.  The fifo can store
    -- an entire line of pixels (64 bits x 80 words).  Start buffering so that
    -- one quarter of the line is buffered by the time we need it.  (Note
    -- each read returns 8 bytes/clock + overhead so that it doesn't take long).
    -- The fifo will automagically buffer 640 pixels for us.  
 
    if (sHCount = conv_std_logic_vector(H_ACTIVE+1, 10)) and 
       (sVCount < conv_std_logic_vector(V_ACTIVE, 10)) then

      Read_Line <= '1';
      Line_Number <= sVCount;

    elsif (sHCount = conv_std_logic_vector(H_ACTIVE+1, 10)) and 
        (sVCount = conv_std_logic_vector(V_MAX, 10)) then

      Read_Line <= '1';
      Line_Number <= (others => '0');

    elsif Read_Line_Ack = '1' then

      Read_Line <= '0';

    end if;
           
    if (sHCount = conv_std_logic_vector(H_ACTIVE-10, 10)) and 
       ((sVCount < conv_std_logic_vector(V_ACTIVE, 10)) or 
         (sVCount = conv_std_logic_vector(V_MAX, 10))) then

      Read_Line_Warn <= '1';

    elsif Read_Line_Ack = '1' then

      Read_Line_Warn <= '0';

    end if;



    if  sVCount = conv_std_logic_vector(V_ACTIVE+2, 10) then

      Blank_Now <= '1';

    elsif Blank_Ack = '1'  then

      Blank_Now <= '0';

    end if;
    
  end if;  
end if;


end process GenerateVideoSignals;

-- sVideoOn turns off pixel data when not in the view area
sVideoOn <= sVideoOnH and sVideoOnV;

-- Read_Req is asserted every 8 pixels or just prior to the beginning of
-- a new line
Read_Req <= Read_ReqA or Read_ReqB;

end behavior;

------------------------------------------------------------------------------------------------------------------------
-- END VGA OUT
------------------------------------------------------------------------------------------------------------------------
