-------------------------------------------------------------------------------
-- Title      : HULK Project
-- Project    : 
-------------------------------------------------------------------------------
-- File       : shiftreg_8x8.vhd
-- Author     : benj  <benj@ns1.digitaljunkies.ca>
-- Last update: 2002/03/26
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: 8 8-bit parallel shift registers
-------------------------------------------------------------------------------
-- Revisions  :
-- Date      Author         Description
-- 2002/03/26      benj         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity shiftreg_8x8 is
  generic (
    WIDTH    : positive := 64;
    IN_WIDTH : positive := 8);
  port (
--    data     : in  std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    clock    : in  std_logic;
    reset    : in  std_logic;
    enable   : in  std_logic;
    shiftin  : in  std_logic_vector(IN_WIDTH-1 downto 0);
    q        : out std_logic_vector(WIDTH-1 downto 0);
    shiftout : out std_logic_vector(IN_WIDTH-1 downto 0));

end entity shiftreg_8x8;

architecture structural of shiftreg_8x8 is

  component lpm_shiftreg
    generic (LPM_WIDTH     : POSITIVE;
             LPM_AVALUE    : STRING := "UNUSED";
             LPM_SVALUE    : STRING := "UNUSED";
             LPM_PVALUE    : STRING := "UNUSED";
             LPM_DIRECTION : STRING := "UNUSED";
             LPM_TYPE      : STRING := "LPM_SHIFTREG";
             LPM_HINT      : STRING := "UNUSED");

    port (data                         : in  std_logic_vector(LPM_WIDTH-1 downto 0) := (others => '0');
          clock                        : in  std_logic;
          enable, shiftin              : in  std_logic := '1';
          load, sclr, sset, aclr, aset : in  std_logic := '0';
          q                            : out std_logic_vector(LPM_WIDTH-1 downto 0);
          shiftout                     : out std_logic);
  end component;

  signal clear : std_logic;
  signal tangled_wires : std_logic_vector(WIDTH-1 downto 0);

begin  -- architecture structural

  clear <= not reset;

  parallel_shiftregs: for i in 0 to IN_WIDTH-1 generate
  begin  -- generate parallel_shiftregs

    shift_reg_inst : lpm_shiftreg
      generic map (
        LPM_WIDTH => 8)
      port map (
        clock    => clock,
        enable   => enable,
        shiftin  => shiftin(i),
        aclr     => clear,
        q        => tangled_wires((i+1)*IN_WIDTH-1 downto i*IN_WIDTH),
        shiftout => shiftout(i));
     
     q(i)    <= tangled_wires(i*8);
     q(i+8)  <= tangled_wires(i*8+1);
     q(i+16) <= tangled_wires(i*8+2);
     q(i+24) <= tangled_wires(i*8+3);
     q(i+32) <= tangled_wires(i*8+4);
     q(i+40) <= tangled_wires(i*8+5);
     q(i+48) <= tangled_wires(i*8+6);
     q(i+56) <= tangled_wires(i*8+7);

  end generate parallel_shiftregs;

  
end architecture structural;
