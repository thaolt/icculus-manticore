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
-- Last update: 2002-06-12
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
  r_full_O  : out std_logic;              -- high if fifo is full
  w_full_O  : out std_logic;              -- high if fifo is full
  r_empty_O : out std_logic;              -- high if fifo is empty
  w_empty_O : out std_logic;              -- high if fifo is empty 
  w_req_I : in  std_logic;              -- write request
  r_req_I : in  std_logic;              -- read request
  r_level_O : out std_logic_vector(ADDR_WIDTH-1 downto 0);
  w_level_O : out std_logic_vector(ADDR_WIDTH-1 downto 0)
  );

end manticore_fifo;

architecture struct of manticore_fifo is

component LPM_FIFO_DC
		generic (LPM_WIDTH : positive ;
				 LPM_WIDTHU : positive := 1;
				 LPM_NUMWORDS : positive;
				 LPM_SHOWAHEAD : string := "OFF";
				 LPM_TYPE : string := L_FIFO_DC;
				 LPM_HINT : string := "UNUSED");
		port (DATA : in std_logic_vector(LPM_WIDTH-1 downto 0);
			  WRCLOCK : in std_logic;
			  RDCLOCK : in std_logic;
			  WRREQ : in std_logic;
			  RDREQ : in std_logic;
			  ACLR : in std_logic := '0';
			  Q : out std_logic_vector(LPM_WIDTH-1 downto 0);
			  WRUSEDW : out std_logic_vector(LPM_WIDTHU-1 downto 0);
			  RDUSEDW : out std_logic_vector(LPM_WIDTHU-1 downto 0);
			  WRFULL : out std_logic;
			  RDFULL : out std_logic;
			  WREMPTY : out std_logic;
			  RDEMPTY : out std_logic);
end component;

signal clear : std_logic;               -- Asynch clear, active high

begin

  clear <= not rst_I;

  lpm_fifo_dc_inst: LPM_FIFO_DC
    generic map (
      LPM_WIDTH    => DATA_WIDTH,
      LPM_WIDTHU   => ADDR_WIDTH,
      LPM_NUMWORDS => DATA_DEPTH)
    port map (
      DATA    => DATA_I,
      WRCLOCK => W_CLK_I,
      RDCLOCK => R_CLK_I,
      WRREQ   => W_REQ_I,
      RDREQ   => R_REQ_I,
      ACLR    => clear,
      Q       => DATA_O,
      WRUSEDW => w_level_O,
      RDUSEDW => r_level_O,
      WRFULL  => w_full_O,
      RDFULL  => r_full_O,
      WREMPTY => w_empty_O,
      RDEMPTY => r_empty_O
      );

end struct;


