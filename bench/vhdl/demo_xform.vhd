-------------------------------------------------------------------------------
-- Title      : Demonstration Transform Engine
-- Project    : 
-------------------------------------------------------------------------------
-- File       : demo_xform.vhd
-- Author     : benj  <benj@ns1.digitaljunkies.ca>
-- Last update: 2002/04/05
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: Handles rotation about x,y and z by a constant amount
-------------------------------------------------------------------------------
-- Revisions  :
-- Date            Author       Description
-- 2002/04/05      benj         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

library work;
use work.memory_defs.all;

package xform_constants is
 -- sin(4) (all decimal digits)
 constant SIN : std_logic_vector(9 downto 0) := "0001000111"; --011011";
 -- cos(4) (all decimal digits)
 constant COS : std_logic_vector(9 downto 0) := "1111111101"; --100000";

 constant MULT_PIPELINE_DEPTH : integer := 4;
 -- If you change the value below, you must enable the clock to the
 -- add_sub components below.
 constant ADD_PIPELINE_DEPTH  : integer := 3;
 constant PIPELINE_DEPTH : positive := MULT_PIPELINE_DEPTH + ADD_PIPELINE_DEPTH;
 
end package xform_constants;


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

library work;
use work.memory_defs.all;
use work.xform_constants.all;

entity demo_xform is
    
  port (
    clock, reset        : in  std_logic;
    enable              : in  std_logic;
    x_in, y_in, z_in    : in  std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    x_out, y_out, z_out : out std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
    data_valid          : out std_logic;
    axis                : in  std_logic_vector(1 downto 0)
    );

end entity demo_xform;

architecture behavioural of demo_xform is

  component lpm_mult
    generic (
      LPM_WIDTHA         : POSITIVE;
      LPM_WIDTHB         : POSITIVE;
      LPM_WIDTHS         : NATURAL := 0;
      LPM_WIDTHP         : POSITIVE;
      LPM_REPRESENTATION : STRING  := "UNSIGNED";
      LPM_PIPELINE       : INTEGER := 0;
      LPM_TYPE           : STRING  := "LPM_MULT";
      LPM_HINT           : STRING  := "UNUSED");

    port (
      dataa       : in  STD_LOGIC_VECTOR(LPM_WIDTHA-1 downto 0);
      datab       : in  STD_LOGIC_VECTOR(LPM_WIDTHB-1 downto 0);
      aclr, clock : in  STD_LOGIC := '0';
      clken       : in  STD_LOGIC := '1';
      sum         : in  STD_LOGIC_VECTOR(LPM_WIDTHS-1 downto 0) := (others => '0');
      result      : out STD_LOGIC_VECTOR(LPM_WIDTHP-1 downto 0));
  end component lpm_mult;

  component lpm_add_sub
    generic (LPM_WIDTH          : POSITIVE;
             LPM_REPRESENTATION : STRING  := "SIGNED";
             LPM_DIRECTION      : STRING  := "UNUSED";
             LPM_PIPELINE       : INTEGER := 0;
             LPM_TYPE           : STRING  := "LPM_ADD_SUB";
             LPM_HINT           : STRING  := "UNUSED");

    port (dataa, datab     : in  STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);
          aclr, clock, cin : in  STD_LOGIC := '0';
          add_sub          : in  STD_LOGIC := '1';
          clken            : in  STD_LOGIC := '1';
          result           : out STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);
          cout, overflow   : out STD_LOGIC);
  end component lpm_add_sub;

  signal A, C : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal B, D : std_logic_vector(9 downto 0);
  signal E, G : std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  signal F, H : std_logic_vector(9 downto 0);

  signal AB_out, CD_out, EF_out, GH_out : std_logic_vector(25 downto 0);
  signal ABCD_out, EFGH_out : std_logic_vector(RASTER_DATAWIDTH downto 0);

  type std_logic_2D is array (PIPELINE_DEPTH-1 downto 0) of std_logic_vector(RASTER_DATAWIDTH-1 downto 0);
  type axis_2D is array (PIPELINE_DEPTH-1 downto 0) of std_logic_vector(1 downto 0);

  signal data_stg       : std_logic_2D;
  signal axis_stg       : axis_2D;
  signal data_valid_stg : std_logic_vector(PIPELINE_DEPTH-1 downto 0);

  signal ABCD_add_sub, EFGH_add_sub : std_logic;
  signal clear : std_logic;
  
begin  -- architecture behavioural

  clear <= not reset;

  -----------------------------------------------------------------------------
  -- Calculates AB +/- CD and EF +/- GH and places result in x, y & z
  -----------------------------------------------------------------------------
  
  
  -- purpose: Registers input and output signals
  -- type   : sequential
  -- inputs : clock, reset, x_in, y_in, z_in
  -- outputs: x_out, y_out, z_out
  register_signals: process (clock, reset) is
  begin  -- process register_signals
    if reset = '0' then                 -- asynchronous reset (active low)

      A <= (others => '0');
      B <= (others => '0');
      C <= (others => '0');
      D <= (others => '0');

      for i in 0 to PIPELINE_DEPTH-1 loop
        data_stg(i)       <= (others => '0');
        axis_stg(i)       <= (others => '0');
      end loop;  -- i      

      data_valid_stg <= (others => '0');
      
    elsif clock'event and clock = '1' then  -- rising clock edge

      if enable = '1' then
        data_valid_stg(0) <= '1';
        axis_stg(0) <= axis;
        
        case axis is
          when "00" =>                    -- x-axis
            A <= y_in;
            B <= SIN;
            C <= z_in;
            D <= COS;
            ABCD_add_sub <= '1';
            
            E <= z_in;
            F <= COS;
            G <= y_in;
            H <= SIN;
            EFGH_add_sub <= '0';            

            data_stg(0) <= x_in;
            
          when "01" =>                    -- y-axis
            A <= x_in;
            B <= COS;
            C <= z_in;
            D <= SIN;
            ABCD_add_sub <= '0';
            
            E <= x_in;
            F <= SIN;
            G <= z_in;
            H <= COS;
            EFGH_add_sub <= '1';            

            data_stg(0) <= y_in;
            
          when "10" =>                    -- z-axis
            A <= x_in;
            B <= COS;
            C <= y_in;
            D <= SIN;
            ABCD_add_sub <= '1';
            
            E <= y_in;
            F <= COS;
            G <= x_in;
            H <= SIN;
            EFGH_add_sub <= '0';

            data_stg(0) <= z_in;
            
          when others => null;
        end case;
      else
        data_valid_stg(0) <= '0';
        axis_stg(0) <="11";
      end if;

      -- Advance pipeline
      for i in 1 to PIPELINE_DEPTH-1 loop
        data_stg(i)       <= data_stg(i-1);
        axis_stg(i)       <= axis_stg(i-1);
        data_valid_stg(i) <= data_valid_stg(i-1);
      end loop;  -- i      

      if data_valid_stg(PIPELINE_DEPTH-1) = '1' then
        data_valid <= '1';

        case axis_stg(PIPELINE_DEPTH-1) is
          when "00" =>
            x_out <= data_stg(PIPELINE_DEPTH-1);
            y_out <= ABCD_out(RASTER_DATAWIDTH downto 1);
            z_out <= EFGH_out(RASTER_DATAWIDTH downto 1);
          when "01" =>
            x_out <= ABCD_out(RASTER_DATAWIDTH downto 1);
            y_out <= data_stg(PIPELINE_DEPTH-1);
            z_out <= EFGH_out(RASTER_DATAWIDTH downto 1);
          when "10" =>
            x_out <= ABCD_out(RASTER_DATAWIDTH downto 1);
            y_out <= EFGH_out(RASTER_DATAWIDTH downto 1);
            z_out <= data_stg(PIPELINE_DEPTH-1);
          when others => null;
        end case;

      end if;

    end if;
    
  end process register_signals;

  -----------------------------------------------------------------------------
  -- A * B and C * D
  -----------------------------------------------------------------------------
  AB_mult : lpm_mult
    generic map (
      LPM_WIDTHA         => RASTER_DATAWIDTH,
      LPM_WIDTHB         => 10,
      LPM_WIDTHS         => 8,
      LPM_WIDTHP         => 26,
      LPM_REPRESENTATION => "SIGNED",
      LPM_PIPELINE       => MULT_PIPELINE_DEPTH)
    port map (
      dataa  => A,
      datab  => B,
      aclr   => clear,
      clock  => clock,
      result => AB_out);

  CD_mult : lpm_mult
    generic map (
      LPM_WIDTHA         => RASTER_DATAWIDTH,
      LPM_WIDTHB         => 10,
      LPM_WIDTHS         => 8,
      LPM_WIDTHP         => 26,
      LPM_REPRESENTATION => "SIGNED",
      LPM_PIPELINE       => MULT_PIPELINE_DEPTH)
    port map (
      dataa  => C,
      datab  => D,
      aclr   => clear,
      clock  => clock,
      result => CD_out);

  -- The number of fractional (i.e. decimal) digits
  -- in the product of two fixed point values is the sum of
  -- the number of fractional digits in the muliplier and
  -- multiplicand.  Since the SIN & COS values are 0.10 and
  -- the coordinates are 10.6, the results are 10.16.  Luckily
  -- the points are aligned, so we can add them.
  
  ABCD_add_sub_inst : lpm_add_sub
    generic map (
      LPM_WIDTH          => RASTER_DATAWIDTH+1,
      LPM_REPRESENTATION => "SIGNED",
      -- Uncomment the following line if the adder is pipelined
      LPM_PIPELINE       => ADD_PIPELINE_DEPTH
      )
    port map (
      dataa   => AB_out(25 downto 9),
      datab   => CD_out(25 downto 9),
      -- Uncomment the following line if the adder is pipelined
      aclr    => clear,
      clock   => clock,
      add_sub => ABCD_add_sub,
      result  => ABCD_out
      );

  -----------------------------------------------------------------------------
  -- E * F and G * H
  -----------------------------------------------------------------------------
  EF_mult : lpm_mult
    generic map (
      LPM_WIDTHA         => RASTER_DATAWIDTH,
      LPM_WIDTHB         => 10,
      LPM_WIDTHS         => 8,
      LPM_WIDTHP         => 26,
      LPM_REPRESENTATION => "SIGNED",
      LPM_PIPELINE       => MULT_PIPELINE_DEPTH)
    port map (
      dataa  => E,
      datab  => F,
      aclr   => clear,
      clock  => clock,
      result => EF_out);

  GH_mult : lpm_mult
    generic map (
      LPM_WIDTHA         => RASTER_DATAWIDTH,
      LPM_WIDTHB         => 10,
      LPM_WIDTHS         => 8,
      LPM_WIDTHP         => 26,
      LPM_REPRESENTATION => "SIGNED",
      LPM_PIPELINE       => MULT_PIPELINE_DEPTH)
    port map (
      dataa  => G,
      datab  => H,
      aclr   => clear,
      clock  => clock,
      result => GH_out);

  EFGH_add_sub_inst : lpm_add_sub
    generic map (
      LPM_WIDTH          => RASTER_DATAWIDTH+1,
      LPM_REPRESENTATION => "SIGNED",
      -- Uncomment the following line if the adder is pipelined
      LPM_PIPELINE       => ADD_PIPELINE_DEPTH
      )
    port map (
      dataa   => EF_out(25 downto 9),
      datab   => GH_out(25 downto 9),
      -- Uncomment the following line if the adder is pipelined
      aclr    => clear,
      clock   => clock,
      add_sub => EFGH_add_sub,
      result  => EFGH_out);
    
end architecture behavioural;
