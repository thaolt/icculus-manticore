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
-- Last update: 2002/06/05
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

package manticore_fifo is
generic (
  FIFO_WIDTH : unsigned:=8;                -- width
  FIFO_DEPTH : unsigned:=32             --depth
  );               

  port (
  
  CLK_I   : in  std_logic;              -- clock
  RST_I   : in  std_logic;              -- asych reset
  data_I  : in  std_logic_vector(FIFO_WIDTH-1 downto 0);  -- Input data
  data_O  : out std_logic_vector(FIFO_WIDTH-1 downto 0);  -- Output data
  full_O  : out std_logic;              -- high if fifo is full
  empty_O : out std_logic;              -- high if fifo is empty
  clear_I : in  std_logic;              -- empties the fifo
  w_req_I : in  std_logic;              -- write request
  r_req_I : in  std_logic;              -- read request
  );

end manticore_fifo;

architecture behavioral of manticore_fifo is


  type data_block_type is array (DATA_DEPTH-1 downto 0) of
       std_logic_vector(DATA_WIDTH-1 downto 0);

  
begin  -- behavioral

  -- purpose: performs the fifo storage
  -- type   : sequential
  -- inputs : CLK_I, RST_I, Data_I
  -- outputs: Data_O
  
  signal depth : unsigned;                -- depth gauge
  signal data : data_block_type;          -- storage
  signal start_pointer : unsigned;        -- start pointer
  signal end_pointer : unsigned;        -- end pointer

  storage: process (CLK_I, RST_I, data_I, clear_I, w_req_I, r_req_I)
  begin  -- process storage
    if RST_I = '0' then                 -- asynchronous reset (active low)

      data_O <= (others => '0');
      full_O <= '0';
      empty_O <= '1';
      depth <= 0;
      start_pointer <= 0;
      end_pointer <= DATA_DEPTH;
      
    elsif CLK'event and CLK = '1' then  -- rising clock edge

      if depth = 0 then
        empty_O <= 1;
      else
        empty_O <= 0;
      end if;
      
      if depth = DATA_DEPTH then
        full_O <= 1;
      else
        full_O <= 0;
      end if;
      
      if clear = '1' then               -- Clear

        depth <= 0;
        start_pointer <= 0;
        end_pointer <= 1;
        data_O  <= (others => '0');
        
      elsif w_req_I = '1' then          -- Write Request

        data_block(end_pointer) <= data_I;
        depth <= depth + 1;
        
        if end_pointer = DATA_DEPTH-1 then
          end_pointer <= 0;
        else
          end_pointer <= end_pointer + 1;
        end if;
        
      elsif r_req_I = '1' then          -- Read Request

        data_O <= data_block(start_pointer);

        depth  <= depth - 1;
        
        if start_pointer = DATA_DEPTH-1 then
          start_pointer <= 0;
        else
          start_pointer <= start_pointer + 1;
        end if;
        
      end if;
      
    end if;
  end process storage;

end behavioral;
