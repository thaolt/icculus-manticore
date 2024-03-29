-- megafunction wizard: %LPM_FIFO+%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: scfifo 

-- ============================================================
-- File Name: write_fifo_address.vhd
-- Megafunction Name(s):
-- 			scfifo
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
-- ************************************************************


--Copyright (C) 1991-2001 Altera Corporation
--Any megafunction design, and related net list (encrypted or decrypted),
--support information, device programming or simulation file, and any other
--associated documentation or information provided by Altera or a partner
--under Altera's Megafunction Partnership Program may be used only to
--program PLD devices (but not masked PLD devices) from Altera.  Any other
--use of such megafunction design, net list, support information, device
--programming or simulation file, or any other related documentation or
--information is prohibited for any other purpose, including, but not
--limited to modification, reverse engineering, de-compiling, or use with
--any other silicon devices, unless such use is explicitly licensed under
--a separate agreement with Altera or a megafunction partner.  Title to
--the intellectual property, including patents, copyrights, trademarks,
--trade secrets, or maskworks, embodied in any such megafunction design,
--net list, support information, device programming or simulation file, or
--any other related documentation or information provided by Altera or a
--megafunction partner, remains with Altera, the megafunction partner, or
--their respective licensors.  No other licenses, including any licenses
--needed under any third party's intellectual property, are provided herein.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY write_fifo_address IS
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (22 DOWNTO 0);
		wrreq		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		aclr		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (22 DOWNTO 0);
		full		: OUT STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		usedw		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
	);
END write_fifo_address;


ARCHITECTURE SYN OF write_fifo_address IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (3 DOWNTO 0);
	SIGNAL sub_wire1	: STD_LOGIC ;
	SIGNAL sub_wire2	: STD_LOGIC_VECTOR (22 DOWNTO 0);
	SIGNAL sub_wire3	: STD_LOGIC ;



	COMPONENT scfifo
	GENERIC (
		lpm_width		: NATURAL;
		lpm_numwords		: NATURAL;
		lpm_showahead		: STRING;
		lpm_hint		: STRING
	);
	PORT (
			usedw	: OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
			rdreq	: IN STD_LOGIC ;
			empty	: OUT STD_LOGIC ;
			aclr	: IN STD_LOGIC ;
			clock	: IN STD_LOGIC ;
			q	: OUT STD_LOGIC_VECTOR (22 DOWNTO 0);
			wrreq	: IN STD_LOGIC ;
			data	: IN STD_LOGIC_VECTOR (22 DOWNTO 0);
			full	: OUT STD_LOGIC 
	);
	END COMPONENT;

BEGIN
	usedw    <= sub_wire0(3 DOWNTO 0);
	empty    <= sub_wire1;
	q    <= sub_wire2(22 DOWNTO 0);
	full    <= sub_wire3;

	scfifo_component : scfifo
	GENERIC MAP (
		lpm_width => 23,
		lpm_numwords => 16,
		lpm_showahead => "OFF",
		lpm_hint => "USE_EAB=ON"
	)
	PORT MAP (
		rdreq => rdreq,
		aclr => aclr,
		clock => clock,
		wrreq => wrreq,
		data => data,
		usedw => sub_wire0,
		empty => sub_wire1,
		q => sub_wire2,
		full => sub_wire3
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: Width NUMERIC "23"
-- Retrieval info: PRIVATE: Depth NUMERIC "16"
-- Retrieval info: PRIVATE: Clock NUMERIC "0"
-- Retrieval info: PRIVATE: Full NUMERIC "1"
-- Retrieval info: PRIVATE: Empty NUMERIC "1"
-- Retrieval info: PRIVATE: UsedW NUMERIC "1"
-- Retrieval info: PRIVATE: AlmostFull NUMERIC "0"
-- Retrieval info: PRIVATE: AlmostEmpty NUMERIC "0"
-- Retrieval info: PRIVATE: AlmostFullThr NUMERIC "-1"
-- Retrieval info: PRIVATE: AlmostEmptyThr NUMERIC "-1"
-- Retrieval info: PRIVATE: sc_aclr NUMERIC "1"
-- Retrieval info: PRIVATE: sc_sclr NUMERIC "0"
-- Retrieval info: PRIVATE: rsFull NUMERIC "0"
-- Retrieval info: PRIVATE: rsEmpty NUMERIC "1"
-- Retrieval info: PRIVATE: rsUsedW NUMERIC "0"
-- Retrieval info: PRIVATE: wsFull NUMERIC "1"
-- Retrieval info: PRIVATE: wsEmpty NUMERIC "0"
-- Retrieval info: PRIVATE: wsUsedW NUMERIC "0"
-- Retrieval info: PRIVATE: dc_aclr NUMERIC "0"
-- Retrieval info: PRIVATE: LegacyRREQ NUMERIC "1"
-- Retrieval info: PRIVATE: LE_BasedFIFO NUMERIC "0"
-- Retrieval info: PRIVATE: Optimize NUMERIC "0"
-- Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "23"
-- Retrieval info: CONSTANT: LPM_NUMWORDS NUMERIC "16"
-- Retrieval info: CONSTANT: LPM_SHOWAHEAD STRING "OFF"
-- Retrieval info: CONSTANT: LPM_HINT STRING "USE_EAB=ON"
-- Retrieval info: USED_PORT: data 0 0 23 0 INPUT NODEFVAL data[22..0]
-- Retrieval info: USED_PORT: q 0 0 23 0 OUTPUT NODEFVAL q[22..0]
-- Retrieval info: USED_PORT: wrreq 0 0 0 0 INPUT NODEFVAL wrreq
-- Retrieval info: USED_PORT: rdreq 0 0 0 0 INPUT NODEFVAL rdreq
-- Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
-- Retrieval info: USED_PORT: full 0 0 0 0 OUTPUT NODEFVAL full
-- Retrieval info: USED_PORT: empty 0 0 0 0 OUTPUT NODEFVAL empty
-- Retrieval info: USED_PORT: usedw 0 0 4 0 OUTPUT NODEFVAL usedw[3..0]
-- Retrieval info: USED_PORT: aclr 0 0 0 0 INPUT NODEFVAL aclr
-- Retrieval info: CONNECT: @data 0 0 23 0 data 0 0 23 0
-- Retrieval info: CONNECT: q 0 0 23 0 @q 0 0 23 0
-- Retrieval info: CONNECT: @wrreq 0 0 0 0 wrreq 0 0 0 0
-- Retrieval info: CONNECT: @rdreq 0 0 0 0 rdreq 0 0 0 0
-- Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
-- Retrieval info: CONNECT: full 0 0 0 0 @full 0 0 0 0
-- Retrieval info: CONNECT: empty 0 0 0 0 @empty 0 0 0 0
-- Retrieval info: CONNECT: usedw 0 0 4 0 @usedw 0 0 4 0
-- Retrieval info: CONNECT: @aclr 0 0 0 0 aclr 0 0 0 0
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
