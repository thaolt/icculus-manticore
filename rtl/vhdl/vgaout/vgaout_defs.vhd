-------------------------------------------------------------------------------
-- Title      : VGA Output Definitions
-- Project    : HULK
-------------------------------------------------------------------------------
-- File       : vgaout_top.vhd
-- Author     : Benj Carson <benjcarson@digitaljunkies.ca>
-- Last update: 2002/03/05
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: Constant definitions for VGA output
-------------------------------------------------------------------------------
-- Revisions  :
-- Data         Author     Description
-- 2002/03/05   benj       Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package vgaout_defs is

  constant BUF_DEPTH   : integer := 3;      -- Depth of FIFO pixel buffer
  constant R_DEPTH     : integer := 3;      -- Number of bits used for red information
  constant G_DEPTH     : integer := 3;      -- Number of bits used for green information
  constant B_DEPTH     : integer := 2;      -- Number of bits used for blue information
  constant COLOR_DEPTH : integer := R_DEPTH + G_DEPTH + B_DEPTH;  -- Full colour depth

-- VGA timing constants for a 33324 kHz pixel clock:
  
-- Resolution:     640x480
-- Pixel Clock:      33324 kHz
--
-- Horizontal rate:     39 kHz
--  Front porch:        24 pixels (720.201ns)
--  Sync:                3 pixels ( 90.025ns)
--  Back porch:        136 pixels (  4.0811us)
--  Full line:         803 pixels ( 24.0967us)
--
-- Vertical rate:       76 Hz
--  Front porch:         9 lines (216.8708us)
--  Sync:                3 lines ( 72.2903us)
--  Back porch:         30 lines (722.9025us)
--
-- All horizontal values in pixels
  constant H_ACTIVE : integer := 639;
  constant H_FPORCH : integer := 43; --24;
  constant H_SYNC   : integer := 46; --3;
  constant H_BPORCH : integer := 87; --136;
  constant H_MAX    : integer := H_ACTIVE + H_FPORCH + H_SYNC + H_BPORCH;

-- All vertical values in lines
  constant V_ACTIVE : integer := 479;
  constant V_FPORCH : integer := 9;
  constant V_SYNC   : integer := 3;
  constant V_BPORCH : integer := 30;
  constant V_MAX    : integer := V_ACTIVE + V_FPORCH + V_SYNC + V_BPORCH;

  constant PIX_MAX  : integer := H_ACTIVE*V_ACTIVE;
  
end vgaout_defs;

------------------------------------------------------------------------------------------------------------------------
-- END VGAOUT_DEFS
------------------------------------------------------------------------------------------------------------------------
