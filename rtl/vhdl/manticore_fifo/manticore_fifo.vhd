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
-- Title      : sdram_control
-- Project    : HULK
-------------------------------------------------------------------------------
-- File       : manticore_fifo.vhd
-- Author     : Jeff Mrochuk <jmrochuk@ieee.org>
-- Last update: 2002-06-11
-- Platform   : Altera APEX20K200
-------------------------------------------------------------------------------
-- Description: A generic FIFO for the manticore project
-- 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Author  Description
-- 2002/06/05   Jeff	Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

library lpm;
use lpm.lpm_components.all;

entity manticore_fifo is

generic (
  DATA_WIDTH : positive:= 8;                -- width
  DATA_DEPTH : positive := 640;             --depth
  ADDR_WIDTH : positive := 10
  );            

  port (
  
  W_CLK_I   : in  std_logic;              -- clock
  R_CLK_I   : in  std_logic;              -- clock
  RST_I   : in  std_logic;              -- asych reset
  data_I  : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- Input data
  data_O  : out std_logic_vector(DATA_WIDTH-1 downto 0);  -- Output data
  full_O  : out std_logic;              -- high if fifo is full
  empty_O : out std_logic;              -- high if fifo is empty
  clear_I : in  std_logic;              -- empties the fifo
  w_req_I : in  std_logic;              -- write request
  r_req_I : in  std_logic;              -- read request
  level_O : out std_logic_vector(ADDR_WIDTH-1 downto 0)
  );

end manticore_fifo;

architecture mixed of manticore_fifo is

component LPM_RAM_DP
  generic (LPM_WIDTH : positive;
           LPM_WIDTHAD : positive;
           LPM_NUMWORDS : natural := 0;
           LPM_INDATA : string := "REGISTERED";
           LPM_OUTDATA : string := "REGISTERED";
           LPM_RDADDRESS_CONTROL : string := "REGISTERED";
           LPM_WRADDRESS_CONTROL : string := "REGISTERED";
           LPM_FILE : string := "UNUSED";
           LPM_TYPE : string := L_RAM_DP;
           LPM_HINT : string := "UNUSED");

  port (RDCLOCK : in std_logic := '0';
        RDCLKEN : in std_logic := '1';
        RDADDRESS : in std_logic_vector(LPM_WIDTHad-1 downto 0);
        RDEN : in std_logic := '1';
        DATA : in std_logic_vector(LPM_WIDTH-1 downto 0);
        WRADDRESS : in std_logic_vector(LPM_WIDTHad-1 downto 0);
        WREN : in std_logic;
        WRCLOCK : in std_logic := '0';
        WRCLKEN : in std_logic := '1';
        Q : out std_logic_vector(LPM_WIDTH-1 downto 0));
end component;

--  type data_block_type is array (DATA_DEPTH-1 downto 0) of
--  std_logic_vector(DATA_WIDTH-1 downto 0);
--  signal data_block : data_block_type;              -- storage 

-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------

  signal depth : positive range 0 to DATA_DEPTH+1;                -- depth gauge
  signal start_pointer : std_logic_vector(ADDR_WIDTH-1 downto 0);        -- start pointer
  signal end_pointer : std_logic_vector(ADDR_WIDTH-1 downto 0);        -- end pointer
  signal wren, rden, full_int, empty_int : std_logic;  -- write enable and read enable


begin  -- behavioral

------------------------------------------------------------------------------
-- Depth Meter
------------------------------------------------------------------------------

  depth_control: process (R_CLK_I, W_CLK_I, RST_I, wren, rden, depth)
  begin

    if RST_I = '0' then                 -- asynchronous reset (active low)
      depth <= 0;
      empty_int <= '1';
      full_int <= '0';
      
    elsif (W_CLK_I'event and W_CLK_I = '1') then
      
      if wren = '1' and rden = '1' then
        null;
      elsif wren = '1' and ( depth < DATA_DEPTH-1 ) then
        depth <= depth+1;
      elsif rden='1' and ( depth > 0 ) then
        depth <= depth-1;
      end if;
      
      if depth=0 then
        empty_int <= '1';
       else
        empty_int <= '0';
       end if;
        
       if depth=DATA_DEPTH-1 then
         full_int <= '1';
       else
         full_int <= '0';
       end if;
          
  end if;
end process depth_control;
         
-------------------------------------------------------------------------------
-- Read Address Controller
-------------------------------------------------------------------------------
  
  read_address: process (R_CLK_I, RST_I, clear_I, R_REQ_I, depth, start_pointer)
  begin  -- process storage
    if RST_I = '0' then                 -- asynchronous reset (active low)

      start_pointer <= (others => '0');
      
    elsif R_CLK_I'event and R_CLK_I = '1' then  -- rising clock edge
 

      if clear_I = '1' then               -- Clear

        start_pointer <= (others => '0');
        
      elsif r_req_I = '1' then          -- Read Request

        if depth > 0 then

          if start_pointer = conv_std_logic_vector(DATA_DEPTH-1, ADDR_WIDTH) then
           start_pointer <= (others => '0');
          else
            start_pointer <= start_pointer + '1';
          end if;                       -- pointer
          
        end if;                         -- depth
        
        else
          
          null;
          
      end if; -- r_req_I
    end if;
  end process read_address;
  
-------------------------------------------------------------------------------
-- Write Address Controller
-------------------------------------------------------------------------------

  write_address: process (W_CLK_I, RST_I, clear_I, W_REQ_I, depth, end_pointer)
  begin  -- process storage

      if RST_I = '0' then
        
        end_pointer <= (others => '0');
        
      elsif  W_CLK_I'event and W_CLK_I = '1' then  -- rising clock edge
       
       if clear_I = '1' then               -- Clear

         end_pointer <= (others => '0');
         
       elsif w_req_I = '1' then -- Write Request
         
         if depth < DATA_DEPTH-1 then
          
          if end_pointer = conv_std_logic_vector(DATA_DEPTH-1, ADDR_WIDTH) then
            end_pointer <= (others => '0');
          else
            end_pointer <= end_pointer + '1';
          end if;                       -- pointer
          
         end if;
         
        end if;                         -- depth
  end if;
  end process write_address;

-------------------------------------------------------------------------------
-- Enable Controller
-------------------------------------------------------------------------------
  
  write_read_enable: process(w_req_I, r_req_I, full_int, empty_int, depth)
   begin
 
     wren <= w_req_I;
     rden <= r_req_I;

     level_O <= conv_std_logic_vector(depth, ADDR_WIDTH);
     full_O <= full_int;
     empty_O <= empty_int;
     
   end process write_read_enable;

-------------------------------------------------------------------------------
-- Wiring to LPM_RAM
-------------------------------------------------------------------------------
    
    lpm_ram_inst: lpm_ram_dp
      generic map (
        LPM_WIDTH    => DATA_WIDTH,
        LPM_WIDTHad  => ADDR_WIDTH,
        LPM_NUMWORDS => DATA_DEPTH)
      
      port map (
        RDCLOCK   => R_CLK_I,
        RDADDRESS => start_pointer,
        RDEN      => rden,
        DATA      => DATA_I,
        WREN      => wren,
        WRADDRESS => end_pointer, 
        WRCLOCK   => W_CLK_I,
        Q         => DATA_O);

end mixed;

-------------------------------------------------------------------------------
-- EOF
-------------------------------------------------------------------------------
