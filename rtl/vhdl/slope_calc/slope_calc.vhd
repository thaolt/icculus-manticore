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
-- Title      : Slope Calculator
-- Project    : HULK
-------------------------------------------------------------------------------
-- File       : slope_calc.vhd
-- Author     : Benj Carson <benjcarson@digitaljunkies.ca>
-- Last update: 2002-06-21
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: Calculates equations of the form (a +/- b)/(c +/- d)
-------------------------------------------------------------------------------
-- Revisions  :
-- Date            Author       Description
-- 2002/03/14      benj         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

library work;
use work.memory_defs.all;

entity slope_calc is
  generic (
    DIVIDER_PIPELINE         : integer := 22);
  port (
    clock, reset             : in  std_logic;
    num_add_sub, den_add_sub : in  std_logic;
    Enable                   : in  std_logic;
    a, b, c, d               : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    Data_Type_In             : in  raster_var_type;
    Data_Type_Out            : out raster_var_type;
    Result                   : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    Remainder                : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    out_enable               : out std_logic
    );

end entity slope_calc;

architecture structural of slope_calc is

  component lpm_add_sub is

    generic (LPM_WIDTH          : POSITIVE;
             LPM_DIRECTION      : STRING  := "UNUSED";
             LPM_REPRESENTATION : STRING  := "SIGNED";
             LPM_PIPELINE       : INTEGER := 0;
             LPM_TYPE           : STRING  := "LPM_ADD_SUB";
             LPM_HINT           : STRING  := "UNUSED");

    port (dataa, datab     : in  std_logic_vector(LPM_WIDTH-1 downto 0);
          aclr, clock, cin : in  std_logic := '0';
          clken, add_sub   : in  std_logic := '1';
          result           : out std_logic_vector(LPM_WIDTH-1 downto 0);
          cout, overflow   : out std_logic);
    
  end component lpm_add_sub;

  component lpm_divide is

       generic ( LPM_WIDTHN: POSITIVE;
                 LPM_WIDTHD: POSITIVE;
                 LPM_NREPRESENTATION: STRING := "SIGNED";
                 LPM_DREPRESENTATION: STRING := "SIGNED";
                 LPM_PIPELINE: INTEGER := 0;
                 LPM_TYPE: STRING := "LPM_DIVIDE";
                 LPM_HINT: STRING := "UNUSED");

       port ( numer       : in  std_logic_vector(LPM_WIDTHN-1 downto 0);
              denom       : in  std_logic_vector(LPM_WIDTHD-1 downto 0);
              clock, aclr : in  std_logic := '0';
              clken       : in  std_logic := '1';
              quotient    : out std_logic_vector(LPM_WIDTHN-1 downto 0);
              remain      : out std_logic_vector(LPM_WIDTHD-1 downto 0));
       
  end component lpm_divide;

  COMPONENT lpm_compare is
    GENERIC (LPM_WIDTH: POSITIVE;
             LPM_REPRESENTATION: STRING := "UNSIGNED";
             LPM_PIPELINE: INTEGER := 0;
             LPM_TYPE: STRING := "LPM_COMPARE";
             LPM_HINT: STRING := "UNUSED");
    PORT (dataa, datab: IN STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0);
          aclr, clock: IN STD_LOGIC := '0';
	  clken: IN STD_LOGIC := '1';
          agb, ageb, aeb, aneb, alb, aleb: OUT STD_LOGIC);
  END COMPONENT lpm_compare;

  component lpm_ff is
    generic (LPM_WIDTH: POSITIVE;
             LPM_AVALUE: STRING := "UNUSED";
             LPM_SVALUE: STRING := "UNUSED";
             LPM_PVALUE: STRING := "UNUSED";
             LPM_FFTYPE: STRING := "DFF";
             LPM_TYPE: STRING := "LPM_FF";
             LPM_HINT: STRING := "UNUSED");
    port (data                                 : in  STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);
          clock                                : in  STD_LOGIC;
          enable                               : in  STD_LOGIC := '1';
          sload, sclr, sset, aload, aclr, aset : in  STD_LOGIC := '0';
          q                                    : out STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0)
          );
  end component lpm_ff;

  component dff
    port (
      d    : in  std_logic;
      clk  : in  std_logic;
      clrn : in  std_logic;
      prn  : in  std_logic := '1';
      q    : out std_logic);
  end component dff;

  component raster_var_type_reg
      port (
        clock, reset : in  std_logic;
        d            : in  raster_var_type;
        q            : out raster_var_type);
  end component raster_var_type_reg;
  
  signal clear : std_logic;


  -- Stage 1 signals:
  signal a_stg1, b_stg1, c_stg1, d_stg1       : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);  -- Stage 1 wires
  signal num_add_sub_stg1, den_add_sub_stg1   : std_logic;
  signal num_carry, den_carry                 : std_logic;
  signal num_stg1                             : std_logic_vector(RASTER_DATAWIDTH+5 downto 0);
  signal den_stg1                             : std_logic_vector(RASTER_DATAWIDTH-1 downto 0); --(RASTER_DATAWIDTH downto 0);
  signal num_overflow_stg1, den_overflow_stg1 : std_logic;
  signal data_valid_stg1                      : std_logic;
  signal data_type_stg1                       : raster_var_type;

  -- Stage 2 signals:
  signal num_stg2                             : std_logic_vector(RASTER_DATAWIDTH+5 downto 0); --(RASTER_DATAWIDTH downto 0);
  signal den_stg2                             : std_logic_vector(RASTER_DATAWIDTH-1 downto 0); --(RASTER_DATAWIDTH downto 0);
  signal num_overflow_stg2, den_overflow_stg2 : std_logic;
  signal Quotient                             : std_logic_vector(RASTER_DATAWIDTH+5 downto 0); --(RASTER_DATAWIDTH downto 0);
  signal Remainder_Int                        : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal data_valid_stg2                      : std_logic;
  signal data_type_stg2                       : raster_var_type;

  signal denom_zero : std_logic;
  signal num_neg    : std_logic;
  signal zero : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  
  signal one, num_stg2_hack : std_logic_vector(1 downto 0);
  
  signal num_stg3, den_stg3 : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);

  -- Divider pipeline stage signals
  --  signal data_valid_div_stg1, data_valid_div_stg2, data_valid_div_stg3 : std_logic;    
  --  signal data_valid_div_stg4, data_valid_div_stg5, data_valid_div_stg6 : std_logic;    
  --  signal data_valid_div_stg7, data_valid_div_stg8 : std_logic;    
  signal data_valid_div                       : std_logic_vector(DIVIDER_PIPELINE-1 downto 0);
  type data_type_array is array (DIVIDER_PIPELINE-1 downto 0) of raster_var_type;
  signal data_type_div : data_type_array;
  
begin  -- architecture structural

  clear <= not reset;
  one <= "01";
  
  ----------------------------------------------------------------------------------------------------------------------
  -- Pipeline Stage 1
  ----------------------------------------------------------------------------------------------------------------------
  a_input_reg : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data    => a,
      clock   => clock,
      aclr    => clear,
      enable  => Enable,
      q       => a_stg1
      );

  b_input_reg : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data    => b,
      clock   => clock,
      aclr    => clear,
      enable  => Enable,
      q       => b_stg1
      );

  c_input_reg : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data    => c,
      clock   => clock,
      aclr    => clear,
      enable  => Enable,
      q       => c_stg1
      );

  d_input_reg : lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data    => d,
      clock   => clock,
      aclr    => clear,
      enable  => Enable,
      q       => d_stg1
      );

  num_add_sub_stg1_reg : component dff
    port map (
      d    => num_add_sub,
      clk  => clock,
      clrn => reset,
      q    => num_add_sub_stg1
      );

  den_add_sub_stg1_reg : component dff
    port map (
      d    => den_add_sub,
      clk  => clock,
      clrn => reset,
      q    => den_add_sub_stg1
      );

  num_add_sub_1 : component lpm_add_sub
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      dataa     => a_stg1,
      datab     => b_stg1,
      aclr      => clear,
--      clock => clock,
      add_sub   => num_add_sub_stg1,
      cout      => num_carry,
      overflow  => num_overflow_stg1,
      result    => num_stg1(RASTER_DATAWIDTH+5 downto 6) -- Add 6 decimal digits
      );
  num_stg1(5 downto 0) <= "000000";

  den_add_sub_1 : component lpm_add_sub
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      dataa     => c_stg1,
      datab     => d_stg1,
      aclr      => clear,
--      clock => clock,
      add_sub   => den_add_sub_stg1,
      cout      => den_carry,
      overflow  => den_overflow_stg1,
      result    => den_stg1(RASTER_DATAWIDTH-1 downto 0)
      );
  --den_stg1(RASTER_DATAWIDTH) <= den_carry;

  data_valid_stg1_reg : component dff
    port map (
      d    => Enable,
      clk  => clock,
      clrn => reset,
      q    => data_valid_stg1
      );

  data_type_reg_stg1 : raster_var_type_reg
    port map (
      clock => clock,
      reset => reset,
      d     => Data_Type_In,
      q     => data_type_stg1
      );
  
  num_stg1_reg_inst : component lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH+6) 
    port map (
      data   => num_stg1,
      clock  => clock,
      aclr   => clear,
      enable => data_valid_stg1,
      q      => num_stg2
      );

  den_stg1_reg_inst : component lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH) --+1)
    port map (
      data   => den_stg1,
      clock  => clock,
      aclr   => clear,
      enable => data_valid_stg1,
      q      => den_stg2
      );
    
  ----------------------------------------------------------------------------------------------------------------------
  -- Pipeline Stage 2
  ----------------------------------------------------------------------------------------------------------------------
  num_stg2_hack <= '0' & num_stg2(RASTER_DATAWIDTH-1);
  zero <= (others => '0');
  
  stg2_numer_check : component lpm_compare
    generic map (
       LPM_WIDTH          => 2,
      LPM_REPRESENTATION => "UNSIGNED")
    port map (
      dataa => one,
      datab => num_stg2_hack,
      aclr  => clear,
      aeb   => num_neg);

  stg2_denom_check : component lpm_compare
    generic map (
      LPM_WIDTH          => RASTER_DATAWIDTH,
      LPM_REPRESENTATION => "SIGNED")
    port map (
      dataa => zero,
      datab => den_stg2,
      aclr  => clear,
      clken => data_valid_stg1,
      aeb   => denom_zero);

  -- purpose: Set the numerator and denominator if the denominator is zero.
  -- type   : combinational
  -- inputs : denom_zero, num_stg2, num_neg
  -- outputs: num_stg3, den_stg3
  normalize: process (denom_zero, num_stg2, num_neg) is
  begin  -- process normalize
    if (denom_zero = '1' and num_neg = '1') then
      den_stg3 <= "0000000001" & "000000";
      num_stg3 <= "1000000000" & "000001000000";
    elsif (denom_zero = '1' and num_neg = '0') then
      den_stg3 <= "0000000001" & "000000";
      num_stg3 <= "0111111111" & "111111111111";
    else
      den_stg3 <= den_stg2;
      num_stg3 <= num_stg2;
    end if;
  end process normalize;
  
  stg2_div_inst : component lpm_divide
    generic map (
      LPM_WIDTHN   => RASTER_DATAWIDTH+6,
      LPM_WIDTHD   => RASTER_DATAWIDTH,
      LPM_PIPELINE => DIVIDER_PIPELINE)
    port map (
      numer    => num_stg2,
      denom    => den_stg2,
      clock    => clock,
      aclr     => clear,
      quotient => Quotient,
      remain   => Remainder_Int);
  
  data_valid_div_stg1_reg : component dff
    port map (
      d    => data_valid_stg1,
      clk  => clock,
      clrn => reset,
      q    => data_valid_div(0));

  
  data_type_reg_div_stg1 : raster_var_type_reg
    port map (
      clock => clock,
      reset => reset,
      d     => data_type_stg1,
      q     => data_type_div(0)
      );
  
  -- Data valid registers to sync with divider pipeline
  data_valid_div_stg_reg : for i in 0 to DIVIDER_PIPELINE-2 generate 
    reg : component dff
      port map (
        d    => data_valid_div(i),
        clk  => clock,
        clrn => reset,
        q    => data_valid_div(i+1)
        );

  data_type_reg_div : raster_var_type_reg
    port map (
      clock => clock,
      reset => reset,
      d     => data_type_div(i),
      q     => data_type_div(i+1)
      );
  end generate;

  data_valid_stg2_reg : component dff
    port map (
      d    => data_valid_div(DIVIDER_PIPELINE-1),
      clk  => clock,
      clrn => reset,
      q    => data_valid_stg2);

  data_type_reg_div_stg2 : raster_var_type_reg
    port map (
      clock => clock,
      reset => reset,
      d     => data_type_div(DIVIDER_PIPELINE-1),
      q     => data_type_stg2
      );


  result_reg_inst : component lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH) --+1)
    port map (
      data   => Quotient(RASTER_DATAWIDTH-1 downto 0),  -- FIXME: NO BOUNDS CHECKING!!  TRUNCATING 6 HIGH BITS
      clock  => clock,
      aclr   => clear,
      enable => data_valid_stg2,
      q      => Result);

  remain_reg_inst : component lpm_ff
    generic map (
      LPM_WIDTH => RASTER_DATAWIDTH)
    port map (
      data   => Remainder_Int,
      clock  => clock,
      aclr   => clear,
      enable => data_valid_stg2,
      q      => Remainder);


  data_valid_output_reg : component dff
    port map (
      d    => data_valid_stg2,
      clk  => clock,
      clrn => reset,
      q    => out_enable);
        

  data_type_reg_stg2 : raster_var_type_reg
    port map (
      clock => clock,
      reset => reset,
      d     => data_type_stg2,
      q     => Data_Type_Out
      );

  
end architecture structural;
