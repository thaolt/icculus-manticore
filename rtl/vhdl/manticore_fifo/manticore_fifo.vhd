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
-- Last update: 2002/06/06
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



entity manticore_fifo is

generic (
  DATA_WIDTH : positive:= 8;                -- width
  DATA_DEPTH : positive := 32;             --depth
  ADDR_WIDTH : positive := 3
  );               

  port (
  
  CLK_I   : in  std_logic;              -- clock
  RST_I   : in  std_logic;              -- asych reset
  data_I  : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- Input data
  data_O  : out std_logic_vector(DATA_WIDTH-1 downto 0);  -- Output data
  full_O  : out std_logic;              -- high if fifo is full
  empty_O : out std_logic;              -- high if fifo is empty
  clear_I : in  std_logic;              -- empties the fifo
  w_req_I : in  std_logic;              -- write request
  r_req_I : in  std_logic              -- read request
  );

end manticore_fifo;

architecture mixed of manticore_fifo is


--  type data_block_type is array (DATA_DEPTH-1 downto 0) of
--       std_logic_vector(DATA_WIDTH-1 downto 0);
  
  signal depth : positive range 0 to DATA_DEPTH+1;                -- depth gauge
--  signal data_block : data_block_type;          -- storage

  signal start_pointer : positive range 0 to DATA_DEPTH+1;        -- start pointer
  signal end_pointer : positive range 0 to DATA_DEPTH+1;        -- end pointer

  
begin  -- behavioral

  -- purpose: performs the fifo storage
  -- type   : sequential
  -- inputs : CLK_I, RST_I, Data_I
  -- outputs: Data_O

  storage: process (CLK_I, RST_I, data_I, clear_I, w_req_I, r_req_I)
  begin  -- process storage
    if RST_I = '0' then                 -- asynchronous reset (active low)

      data_O <= (others => '0');
      full_O <= '0';
      empty_O <= '1';
      depth <= 0;
      start_pointer <= 0;
      end_pointer <= DATA_DEPTH;
      
    elsif CLK_I'event and CLK_I = '1' then  -- rising clock edge
      
      
      if clear_I = '1' then               -- Clear

        depth <= 0;
        start_pointer <= 0;
        end_pointer <= 1;
        data_O  <= (others => '0');
        
      elsif w_req_I = '1' then          -- Write Request

        if depth /= DATA_DEPTH then
          
          full_O <= '0';
 --         data_block(end_pointer) <= data_I;
          depth <= depth + 1;    
        
          if end_pointer = DATA_DEPTH-1 then
            end_pointer <= 0;
          else
            end_pointer <= end_pointer + 1;
          end if;
          
        else
          
          full_O <= '1';
          
        end if;
        
      elsif r_req_I = '1' then          -- Read Request

        if depth /= 0 then

          empty_O <= '0';
          
    --      data_O <= data_block(start_pointer);

          depth  <= depth - 1;
        
          if start_pointer = DATA_DEPTH-1 then
            start_pointer <= 0;
          else
            start_pointer <= start_pointer + 1;
          end if;
          
        else
          
          empty_O <= '1';
          
        end if;                         -- depth
        
      end if;                           -- r_req
      
    end if;                             -- clock
  end process storage;

  -- purpose: connects to LPM_RAM 
  -- type   : combinational
  -- inputs : w_req_I
  -- outputs: 
  ram_connect: process (w_req_I, r_req_I, start_pointer, end_pointer, data_I)
  begin  -- process ram_connect
 
    lpm_ram_inst: component lpm_ram_dp
      generic map (
        LPM_WIDTH    => DATA_WIDTH,
        LPM_WIDTHad  => ADDR_WIDTH,
        LPM_NUMWORDS => DATA_DEPTH)
      
      port map (
        RDCLOCK   => CLK_I,
        RDADDRESS => conv_std_logic_vector(start_pointer, ADDR_WIDTH),
        RDEN      => r_req_I,
        DATA      => DATA_I,
        WRADDRESS => conv_std_logic_vector(end_pointer, ADDR_WIDTH),
        WRCLOCK   => CLK_I,
        Q         => DATA_O);

      
  end process ram_connect;

end mixed;
