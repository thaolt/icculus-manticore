-------------------------------------------------------------------------------
-- Title      : Write Fifo
-- Project    : HULK
-------------------------------------------------------------------------------
-- File       : write_fifo.vhd
-- Author     : Benj Carson <benjcarson@digitaljunkies.ca>
-- Last update: 2002/03/26
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: Buffers SDRAM memory write requests so that they can be queued
--              and sent to memory.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date            Author       Description
-- 2002/03/17      benj         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.memory_defs.all;

entity write_fifo is

  port (
    clock, reset  : in  std_logic;
    Data_Mask_In  : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);       -- Mask for input 4 word burst
    Data_In       : inout  std_logic_vector(DATA_WIDTH-1 downto 0);           -- Write data in
    Address_In    : in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);        -- Address for beginning of burst
    W_Enable      : in  std_logic;
    Send_Address  : in  std_logic;
    Addr_Out_Enable : in std_logic;
    Send_Data     : in  std_logic;
    Data_Out_Enable : in std_logic;
    Data_Mask_Out : out std_logic_vector(4*DATA_WIDTH/8-1 downto 0);
    Data_Out      : inout std_logic_vector(DATA_WIDTH-1 downto 0);
    Address_Out   : inout std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    Fifo_Level    : out std_logic_vector(3 downto 0);
    Full          : out std_logic;
    Mostly_Empty  : out std_logic
    );

end entity write_fifo;

architecture mixed of write_fifo is


  component write_fifo_data is
    port (
        data  : in  std_logic_vector (63 downto 0);
        wrreq : in  std_logic;
        rdreq : in  std_logic;
        clock : in  std_logic;
        aclr  : in  std_logic;
        q     : out std_logic_vector (63 downto 0);
        full  : out std_logic;
        empty : out std_logic;
        usedw : out STD_LOGIC_VECTOR (5 DOWNTO 0)
    );
  end component write_fifo_data;

  component write_fifo_mask is
    port (
        data  : in  std_logic_vector (31 downto 0);
        wrreq : in  std_logic;
        rdreq : in  std_logic;
        clock : in  std_logic;
        aclr  : in  std_logic;
        q     : out std_logic_vector (31 downto 0);
        full  : out std_logic;
        empty : out std_logic
    );
  end component write_fifo_mask;

  component write_fifo_address is
    port (
        data  : in  std_logic_vector (22 downto 0);
        wrreq : in  std_logic;
        rdreq : in  std_logic;
        clock : in  std_logic;
        aclr  : in  std_logic;
        q     : out std_logic_vector (22 downto 0);
        full  : out std_logic;
        empty : out std_logic;
        usedw : out STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
  end component write_fifo_address;

  signal data_write_req, mask_write_req, addr_write_req : std_logic;
  signal data_write_en, mask_write_en, addr_write_en    : std_logic;
  signal data_full, mask_full, addr_full                : std_logic;

  signal W_Enable_data                                  : std_logic;

  signal data_empty, mask_empty, addr_empty             : std_logic;
  signal data_level : std_logic_vector(5 downto 0);

  signal clear : std_logic;
  
  -- Inputs to FIFOs:
  signal data_to_mask : std_logic_vector(4*DATA_WIDTH/8-1 downto 0);

  -- Write state machine:
  type write_state_type is (w_idle, write1, write2, write3, full_state);
  
  signal w_state : write_state_type;

  -- Tri-State Signals
  signal Data_Internal : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal Address_Internal : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
 

  -- Mask constants:
  constant B1_START : integer := 31;    -- Mask start for burst 1
  constant B1_END   : integer := 24;    -- Mask End for burst 1
  constant B2_START : integer := 23;    -- Mask start for burst 2
  constant B2_END   : integer := 16;    -- Mask End for burst 2
  constant B3_START : integer := 15;    -- Mask start for burst 3
  constant B3_END   : integer := 8;     -- Mask End for burst 3
  constant B4_START : integer := 7;     -- Mask start for burst 4
  constant B4_END   : integer := 0;     -- Mask End for burst 4

begin  -- architecture mixed
  

  clear <= not reset;

  data_fifo_inst : write_fifo_data
    port map (
      data  => Data_In,
      wrreq => W_Enable,
      rdreq => Send_Data,
      clock => clock,
      aclr  => clear,
      q     => Data_Internal,
      full  => data_full,
      empty => data_empty,
      usedw => data_level);

  mask_fifo_inst : write_fifo_mask
    port map (
      data  => data_to_mask,
      wrreq => mask_write_en,
      rdreq => Send_Address,
      clock => clock,
      aclr  => clear,
      q     => Data_Mask_Out,
      full  => mask_full,
      empty => mask_empty);

  addr_fifo_inst : write_fifo_address
    port map (
      data  => Address_In,
      wrreq => addr_write_en,
      rdreq => Send_Address,
      clock => clock,
      aclr  => clear,
      q     => Address_Internal,
      full  => addr_full,
      empty => addr_empty,
      usedw => Fifo_Level
  );

  Mostly_Empty <= mask_empty;
 
  Full  <= data_full or mask_full or addr_full;
  data_write_en <= W_Enable and data_write_req;
  addr_write_en <= W_Enable and addr_write_req;

  -- purpose: Handle write requests to the fifo
  -- type   : sequential
  -- inputs : clock, reset, W_Enable, R_Enable
  -- outputs: data_write_req, mask_write_req, addr_write_req, Full
  control_write: process (clock, reset) is
  begin  -- process control_write
    if reset = '0' then              -- asynchronous reset (active low)
      w_state <= w_idle;

      data_write_req <= '0';
      mask_write_req <= '0';
      addr_write_req <= '0';
      --Mostly_Empty <= '1';
      
    elsif clock'event and clock = '1' then  -- rising clock edge

      --if data_level < conv_std_logic_vector(3,6) then  -- Mostly_empty goes low when we have enough data for a burst
      --  Mostly_Empty <= '1';
      --else

--      end if;
  
      case w_state is

        when w_idle =>

          -- Since the write_req signals are ANDed with W_Enable, we 
          -- use them as a mask in each state to permit address or 
          -- data write operations.  We will let all three happen in idle:
          data_write_req <= '1';
          addr_write_req <= '1';
          
          mask_write_en <= '0';      
          if data_full = '1' then
 
            w_state <= full_state;

          elsif W_Enable = '1' then

            -- Every write must be a total of 4 words long (due to burst
            -- mode setting).  When W_Enable is high, the input to this
            -- module is stored in the fifos, otherwise if W_Enable is
            -- only high momentarily, the burst is completed with fully
            -- masked values (all 1's).  Since the address is only sent
            -- at the beginning of the burst it is only stored once.
            w_state <= write1;
            data_to_mask(B1_START downto B1_END) <= Data_Mask_In; 
            
          else
            w_state <= w_idle;
            
          end if;

        when write1 => 
          addr_write_req <= '0';
          data_write_req <= '1';
         
          if W_Enable = '1' then
            w_state <= write2;
            data_to_mask(B2_START downto B2_END) <= Data_Mask_In;
            
          else
            w_state <= write1;
            
          end if;

        when write2 =>
          addr_write_req <= '0';
          data_write_req <= '1';

          if W_Enable ='1' then
            w_state <= write3;
            data_to_mask(B3_START downto B3_END) <= Data_Mask_In;

          else
            w_state <= write2;
            
          end if;

        when write3 =>
          addr_write_req <= '0';
          data_write_req <= '1';

          if W_Enable ='1' then
            mask_write_en <= '1';
            data_to_mask(B4_START downto B4_END) <= Data_Mask_In;            
            w_state <= w_idle;
          else

            mask_write_en <= '0';
            w_state <= write3;            
            
          end if;

        when full_state =>

          if data_full = '0' then
            w_state <= w_idle;
          else
            w_state <= full_state;
          end if;
          
        when others =>
          null;
          
      end case;  -- w_state
      
      
    end if;

  end process control_write;
  
  -- purpose: Handle fifo read requests
  -- type   : sequential
  -- inputs : clock, reset, Send_Address, Send_Data
  -- outputs:  data_read_req, mask_read_req, addr_read_req
--  control_read: process (clock, reset) is
--  begin  -- process control_read
--    if reset = '0' then                 -- asynchronous reset (active low)
--      r_state <= r_idle;
--      
--      data_read_req <= '0';
--      mask_read_req <= '0';
--      addr_read_req <= '0';

--      Empty <=  '0';
      
--    elsif clock'event and clock = '1' then  -- rising clock edge

--      case r_state is
--        when r_idle  =>

--          if data_empty = '1'  then
--            addr_read_req <= '0';
--            data_read_req <= '0';
--            mask_read_req <= '0';            

--            Empty <= '1';
--            r_state <= empty_state;

--          elsif Send_Address = '1' then
--            r_state <= send_addr; 
--            addr_read_req <= '1';
--            data_read_req <= '0';
--            mask_read_req <= '1';            

--            Empty <=  '0';
--          else
--            addr_read_req <= '0';
--            data_read_req <= '0';
--            mask_read_req <= '0';            

--            r_state <= r_idle;
--            Empty <= '0';
            
--          end if;
          
--        when send_addr =>

--          addr_read_req <= '0';
--          data_read_req <= '0';
--          mask_read_req <= '0';            

--          if Send_Data = '0' then
--            r_state <= send_addr;
--          else
--            r_state <= send_data1;
            
--          end if;

--        when send_data1 =>
--            r_state <= send_data2;
--            addr_read_req <= '0';
--            data_read_req <= '1';
--            mask_read_req <= '0';           

--        when send_data2 =>
--            r_state <= send_data3;
--            addr_read_req <= '0';
--            data_read_req <= '1';
--            mask_read_req <= '0';           

--        when send_data3 =>
--            r_state <= send_data4;
--            addr_read_req <= '0';
--            data_read_req <= '1';
--            mask_read_req <= '0';

--        when send_data4 =>
--            r_state <= r_idle;
--            addr_read_req <= '0';
--            data_read_req <= '1';
--            mask_read_req <= '0';

--        when empty_state =>

--          if data_empty = '0' then
--            r_state <= r_idle;
--            Empty <= '0';
--          else
--            r_state <= empty_state;
--            Empty <= '1';          
--          end if;
          
--        when others => null;
--      end case;
      
--    end if;
--  end process control_read;
-------------------------------------------------------------------------------
-- Tristate
-------------------------------------------------------------------------------


  -- purpose: Tristates data bus
  -- type   : combinational
  -- inputs : Send_Data
  -- outputs: Data
  tristate_data_bus : process ( Data_Out_Enable) is


  begin  -- process tristate_data_bus	
    if  Data_Out_Enable = '1' then
      Data_Out <= Data_Internal;
    else
      Data_Out <= (others => 'Z');
    end if;

    
  end process tristate_data_bus;

  -- purpose: Tristates Address bus
  -- type   : combinational
  -- inputs : Addr_Out_Enable
  -- outputs: Address
  tristate_address_bus : process (Addr_Out_Enable) is


  begin  -- process tristate_data_bus	
    if Addr_Out_Enable = '1' then
      Address_Out <= Address_Internal;
    else
      Address_Out <= (others => 'Z');
    end if;

    
  end process tristate_address_bus;
  
end architecture mixed;
