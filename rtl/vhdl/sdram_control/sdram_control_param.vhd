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
-- File       : memory_manager.vhd
-- Author     : Jeff Mrochuk <jmrochuk@ieee.org>
-- Last update: 2002-05-30
-- Platform   : Altera APEX20K200
-------------------------------------------------------------------------------
-- Description: Sends necessary signals to operate PC100 SDRAM at 66MHz
-- 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Author  Description
-- 2002/02/01   Jeff	Created
-- 2002/02/18   Benj    Hole dug, refilled
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package memory_constants is

  -- Number of cycles for various delays (66MHz)
  -- NOTE: These are all 1 less than the number needed because the counter
  --		 starts at 0;
	         		  -- Spec val (actual)
									
  -- From JEDEC PC100/133 standard (www.jedec.org)
  --
  -- tRC   >= 70ns (RAS Cycle time)
  -- tRRD  >= 20ns (RAS to RAS Bank activate delay)
  -- tRCD  >= 20ns (Activate to command delay - RAS to CAS delay)
  -- tRAS  >= 50ns (RAS Active time)
  -- tRP   >= 20ns (RAS Precharge time)
  -- tMRD  >= 3 tCK
  -- tREF  <= 64ms (Refresh period for 4096 rows, so 64ms/4096 = 15.625us per row)
  -- tRFC  <= 80ns (Row refresh cycle time)
  
  constant CLOCK_PERIOD : positive := 20; -- Clock period in ns.  Designed for 50 MHz (20ns)

  -- Timing constants in ns:
  constant tRC  : positive := 70;
  constant tRRD : positive := 20;
  constant tRCD : positive := 20;
  constant tRAS : positive := 50;
  constant tRP  : positive := 20;
  constant tREF : positive := 15440;       -- Spec is 15625ns, but is reduced here because it worked better with our RAM
  constant tRFC : positive := 90;          -- This value was also massaged.
  constant tSTARTUP_NOP : positive := 200000;
  
  -- Timing constants in cycles
  constant tRC_CYCLES  : positive := tRC  / CLOCK_PERIOD;
  constant tRRD_CYCLES : positive := tRRD / CLOCK_PERIOD;
  constant tRCD_CYCLES : positive := tRCD / CLOCK_PERIOD;
  constant tRAS_CYCLES : positive := tRAS / CLOCK_PERIOD;
  constant tRP_CYCLES  : positive := tRP  / CLOCK_PERIOD + 1;
  constant tMRD_CYCLES : positive := 3;
  constant tREF_CYCLES : positive := tREF / CLOCK_PERIOD;
  constant tRFC_CYCLES : positive := tRFC / CLOCK_PERIOD;

  constant tSTARTUP_NOP_CYCLES : positive := tSTARTUP_NOP / CLOCK_PERIOD;
   
  constant CASWIDTH : integer := 3;    -- width of CAS mode for MRS

  constant CAS_LATENCY : positive := 2;

  constant B1_START : integer := 31;    -- Mask start for burst 1
  constant B1_END   : integer := 24;    -- Mask End for burst 1
  constant B2_START : integer := 23;    -- Mask start for burst 2
  constant B2_END   : integer := 16;    -- Mask End for burst 2
  constant B3_START : integer := 15;    -- Mask start for burst 3
  constant B3_END   : integer := 8;     -- Mask End for burst 3
  constant B4_START : integer := 7;     -- Mask start for burst 4
  constant B4_END   : integer := 0;     -- Mask End for burst 4
  
end memory_constants;

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
library work;
use work.memory_constants.all;

entity sdram_control_param is
  generic(

    -- Input Address format:
    --
    --   Bank       Row            Column 
    --  |<->|<-              ->|<-        ->|
    --  -------------------------------------
    --  22  21                 9            0
    --
    IN_ADDRESS_WIDTH    : positive := 23;
    BANKSIZE            : integer := 2;
    ROWSIZE             : integer := 12;
    COLSIZE             : integer := 9;
    BANKSTART           : integer := 21;
    ROWSTART            : integer := 9;
    COLSTART            : integer := 0;
    DATAWIDTH           : integer := 64;
    INTERLEAVED         : std_logic := '0';  -- Sequential if '0'
    BURST_MODE_n        : std_logic := '0';  -- enabled if '0'
    BURST_LENGTH        : integer := 8;
    NO_OF_CHIPS         : integer := 2
    );

  port(
    CLK_I               : in std_logic;
    RST_I               : in  std_logic;
    R_enable_I          : in  std_logic;
    W_enable_I          : in  std_logic;
    RW_address_I        : in  std_logic_vector(IN_ADDRESS_WIDTH-1 downto 0);
    ready_O             : out std_logic;
    tx_data_O           : out std_logic;
    rx_data_O           : out std_logic;
    r_ack_O             : out std_logic;
    w_ack_O             : out std_logic;
    init_done_O         : out std_logic;
    data_mask_I         : in  std_logic_vector(DATAWIDTH/8*BURST_LENGTH -1 downto 0);

    -- to memory
    CKE_O          : out std_logic_vector(1 downto 0);  -- clock enable
    CS_n_O         : out std_logic_vector(NO_OF_CHIPS-1 downto 0);
    
    addr_O         : out std_logic_vector(12 downto 0);
    WE_n_O         : out std_logic;     -- Write enable, Active Low
    RAS_n_O        : out std_logic;
    CAS_n_O        : out std_logic;
    DQM_O          : out std_logic_vector(datawidth/8-1 downto 0);
    BA_O           : out std_logic_vector (1 downto 0)

    );
end sdram_control_param;

architecture behav of sdram_control_param is

  
  type state_type is (sdram_startup, sdram_activ, sdram_read, sdram_write, sdram_tRP_delay, sdram_MRS, sdram_precharge, sdram_auto_refresh, sdram_NOP);
  
  signal state            : state_type;
  signal startup_flg      : std_logic;  -- Asserted when startup sequence finsihed

  -- Command signals
  type command_type is (startup, read, write, refresh, NOP);
  signal command : command_type;        -- Designates current command being executed  

  -- Refresh signals & flags
  signal refresh_req      : std_logic;  -- Refresh request signals
  signal refresh_done_flg : std_logic;
  
  -- Address signals:
  signal bankaddr : std_logic_vector(BANKSIZE-1 downto 0);
  signal rowaddr  : std_logic_vector(ROWSIZE-1 downto 0);
  signal coladdr  : std_logic_vector(COLSIZE-1 downto 0);

  -- Timing signals:
  signal delaycount    : integer range 0 to 15;             -- Multipurpose long interval counter
  signal count         : integer range 0 to 10;             -- Multipurpose short interval counter
  signal refresh_timer : integer range 0 to tREF_CYCLES+1;  -- Refresh timer
  signal warmup_timer  : integer range 0 to tSTARTUP_NOP_CYCLES;

  signal mask1, mask2, mask3, mask4 : std_logic_vector(7 downto 0);
  signal mask5, mask6, mask7, mask8 : std_logic_vector(7 downto 0);
  
begin  -- architecture behav

  bankaddr <= RW_address_I(bankstart + banksize- 1 downto bankstart);
  rowaddr  <= RW_address_I(rowstart + rowsize - 1 downto rowstart);    
  coladdr  <= RW_address_I(colstart + colsize - 1 downto colstart);  

  -- purpose: Send outputs to RAM based on command input
  -- type   : sequential
  -- inputs : clock, RST_I, refresh_req, read_req, write_req
  -- outputs: All memory signals, init_done_O
  command_engine: process (CLK_I, RST_I) is
  begin  -- process command_engine

    ---------------------------------------------------------------------------
    --  ASYNCHRONOUS RESET
    ---------------------------------------------------------------------------

    if RST_I = '0' then

      state        <= sdram_startup;
      command      <= startup;
      warmup_timer <= 0;

      delaycount    <= 0;
      count         <= 0;
      refresh_timer <= 0;
      refresh_done_flg <= '0';
      
      mask1       <= (others => '0');
      mask2       <= (others => '0');
      mask3       <= (others => '0');
      mask4       <= (others => '0');
      mask5       <= (others => '0');
      mask6       <= (others => '0');
      mask7       <= (others => '0');
      mask8       <= (others => '0');
      
      ready_O       <= '0';
      r_ack_O       <= '0';
      w_ack_O       <= '0';
      tx_data_O     <= '0';
      rx_data_O     <= '0';
      WE_n_O        <= '0';
      CKE_O         <= (others => '0');
      CS_n_O(0)     <= '0';
      CS_n_O(1)     <= '1';
      addr_O        <= (others => '0');
      RAS_n_O       <= '0';
      CAS_n_O       <= '0';
      DQM_O         <= (others => '1');
      BA_O          <= (others => '0');
      init_done_O   <= '0';

    elsif CLK_I'event and CLK_I = '1' then  -- rising clock edge
      
      ---------------------------------------------------------------------
      -- CONSTANT SIGNALS
      ---------------------------------------------------------------------     
      CKE_O <= "11";                    -- Clock enable

      
      case state is

        -----------------------------------------------------------------------
        -- Startup
        -----------------------------------------------------------------------

        when sdram_startup   =>
          DQM_O     <= (others => '1');   -- Set high during init routine
          command <= startup;
          state   <= sdram_NOP;
          r_ack_O <= '0';
          w_ack_O <= '0';
          
        -----------------------------------------------------------------------
        -- Mode Register Set
        -----------------------------------------------------------------------
        when sdram_MRS =>
          RAS_n_O <= '0';
          CAS_n_O <= '0';
          WE_n_O  <= '0';
          r_ack_O <= '0';
          w_ack_O <= '0';
          
          addr_O(12 downto 10) <= "000";
          addr_O(9)            <= BURST_MODE_n;   -- Burst read and write
          addr_O(8 downto 7)   <= "00";
          addr_O(6 downto 4)   <= conv_std_logic_vector(cas_latency, CASWIDTH);                                          -- CAS latency 2
          addr_O(3)            <= INTERLEAVED;  -- Sequential mode not interleave
          addr_O(2 downto 0)   <= "010";        --burst length of 4

          if delaycount < tMRD_CYCLES then
            delaycount <= delaycount + 1;
            state      <= sdram_MRS;
          else        
            delaycount <= 0;
            
            case command is
              when startup => 
                init_done_O   <= '1';
                command     <= NOP;
                state       <= sdram_NOP;
              -- We shouldn't be in this state if we aren't in the startup
              -- sequence, so head to NOP. 
              when read =>
                command <= NOP;
                state <= sdram_NOP;
              when write =>
                command <= NOP;
                state <= sdram_NOP;
              when refresh =>
                command <= NOP;
                state <= sdram_NOP;
              when NOP =>
                state <= sdram_NOP;
              when others => null;

            end case;
            
          end if;

        -----------------------------------------------------------------------
        -- Precharge
        -----------------------------------------------------------------------  
        when sdram_precharge =>

          RAS_n_O <= '0';
          CAS_n_O <= '1';
          WE_n_O  <= '0';
          r_ack_O <= '0';
          w_ack_O <= '0';         
          addr_O(12 downto 11) <= "00";
          addr_O(10) <= '1';                    -- Precharge all banks
          addr_O(9 downto 0)   <= "0000000000";

          if delaycount < tRP_CYCLES then
            delaycount <= delaycount + 1;
            state <= sdram_precharge;
          else
            delaycount <= 0;

            case command is
              
              when startup => 
                state <= sdram_auto_refresh;
              when refresh =>
                state <= sdram_auto_refresh;
              when read =>
                state <= sdram_activ;
              when write =>
                state <= sdram_activ;
              when NOP =>
                state <= sdram_NOP;
              when others => null;

            end case;
            
          end if;

        -----------------------------------------------------------------------
        -- Auto refresh
        -----------------------------------------------------------------------  
        when sdram_auto_refresh =>

          -- Not sure why this has to be high, but it works better
          
          DQM_O <= (others => '1');
          r_ack_O <= '0';
          w_ack_O <= '0';
			
          if delaycount = 0 then
            
            RAS_n_O <= '0';
            CAS_n_O <= '0';
            WE_n_O  <= '1';
            delaycount <= delaycount + 1; 
            state <= sdram_auto_refresh;
            
          elsif delaycount < tRFC_CYCLES then
            
            CS_n_O(0) <= '1'; -- Disable SDRAM
            delaycount <= delaycount + 1;
            state <= sdram_auto_refresh;
            
          else
            
            CS_n_O(0) <= '1';
            delaycount <= 0;
                       
            case command is
              when startup =>
                if count < 8 then     -- Send 8 refresh commands
                  count <= count + 1;
                  state <= sdram_auto_refresh;
                else
                  count <= 0;
                  state <= sdram_MRS;
                end if;
                CS_n_O(0) <= '0'; -- Enable SDRAM
		
              when read =>
                command <= NOP;
                state <= sdram_NOP;

              when write =>
                command <= NOP;
                state <= sdram_NOP;

              when refresh =>
                command <= NOP;
                state <= sdram_NOP;

              when NOP =>
                state <= sdram_NOP;

              when others => null;
            end case;

          end if;

        ---------------------------------------------------------------------
        -- Activate
        ---------------------------------------------------------------------
        when sdram_activ =>
            
          ready_O <= '0';

          -- Load DQM mask
          mask1 <= data_mask_I(B1_START downto B1_END);
          mask2 <= data_mask_I(B2_START downto B2_END);
          mask3 <= data_mask_I(B3_START downto B3_END);
          mask4 <= data_mask_I(B4_START downto B4_END);
          DQM_O <= (others => '0');

          if delaycount = 0 then 
            --Row Activate
            RAS_n_O <= '0';
            CAS_n_O <= '1';
            WE_n_O  <= '1';
            CS_n_O(0)  <= '0';	                    

            -- Send row address
            addr_O(12) <= '0';
            addr_O(11 downto 0) <= rowaddr;
  
            delaycount <= delaycount + 1;
            state <= sdram_activ;

          elsif delaycount < tRCD_CYCLES then

	    CS_n_O(0) <= '1'; -- Disable SDRAM          
            delaycount <= delaycount + 1;
            state <= sdram_activ;

          else
      
            CS_n_O(0) <= '1'; -- Disable SDRAM          
            delaycount <= 0;
            count <= 0;

            case command is
              when read =>
                state <= sdram_read;
                addr_O(12 downto 11) <= "00";   -- HARDCODED: send bank
                addr_O(10) <= '1';              -- Auto precharge
                addr_O(9)  <= '0';
                addr_O(8 downto 0) <= coladdr;


              when write =>
                state <= sdram_write;
                addr_O(12 downto 11) <= "00";   -- HARDCODED: send bank
                addr_O(10) <= '1';              -- Auto precharge
                addr_O(9)  <= '0';
                addr_O(8 downto 0) <= coladdr;
                tx_data_O <= '1';
                
              when refresh =>

                command <= NOP;
                state <= sdram_NOP;
                
              when startup =>

                command <= NOP;
                state <= sdram_NOP;
                
              when NOP =>
                state <= sdram_NOP;

              when others => null;
            end case;

          end if;
          

        -----------------------------------------------------------------------
        -- Read with auto precharge        
        -----------------------------------------------------------------------
        when sdram_read =>
          
          CS_n_O(0) <= '0'; -- Enable SDRAM
          DQM_O <= (others => '0');
          r_ack_O <= '0';
          
          case count is
            when 0 =>
              -- READA Command
              RAS_n_O <= '1';
              CAS_n_O <= '0';
              WE_n_O  <= '1';

              rx_data_O <= '1';
              count <= count + 1;

            when 1 => -- CAS_LATENCY - 1=>
              -- NOP
              -- RAS_n_O <= '1';
              -- CAS_n_O <= '1';
              -- WE_n_O  <= '1';
              CS_n_O(0) <= '1';
              
              rx_data_O <= '1';
              count <= count + 1;
              
            when 2 => -- CAS_LATENCY =>             
              rx_data_O <= '1';
              count <= count + 1;
              
            when 3 => --CAS_LATENCY + 1 =>              
              if BURST_LENGTH-1 = 3 then
                state <= sdram_tRP_delay;  -- Delay for tRP until next operation    
              else
                count <= count + 1; 
              end if;

            when 4 => -- CAS_LATENCY =>             
              rx_data_O <= '1';
              count <= count + 1;
            when 5 => -- CAS_LATENCY =>             
              rx_data_O <= '1';
              count <= count + 1;
            when 6 => -- CAS_LATENCY =>             
              rx_data_O <= '1';
              count <= count + 1;
            when 7 => -- CAS_LATENCY =>             
              rx_data_O <= '1';
              state <= sdram_tRP_delay;
              
            when others => null;
              
          end case;

        -----------------------------------------------------------------------
        -- Write
        -----------------------------------------------------------------------  
        when sdram_write =>
          CS_n_O(0) <= '0'; -- Enable SDRAM

          case count is
            when 0 =>
              -- WRITEA Command --
              RAS_n_O <= '1';
              CAS_n_O <= '0';
              WE_n_O  <= '0';
              --------------------
              
              w_ack_O <= '0';            
              count <= count + 1;              
              DQM_O <= mask1;
              tx_data_O <= '1';

            when 1 =>
          --  NOP
          --  RAS_n_O <= '1';
          --  CAS_n_O <= '1';
          --  WE_n_O  <= '1';
              CS_n_O(0) <= '1';              
              count <= count + 1;
              DQM_O <= mask2;
              tx_data_O <= '1';
              
            when 2 =>
              count <= count + 1;
              DQM_O <= mask3;
              tx_data_O <= '1';

            when 3 =>
              count <= count + 1;
              DQM_O <= mask4;
              tx_data_O <= '1';

            when 4 =>
              
              tx_data_O <= '1';
              if BURST_LENGTH = 4 then
                state <= sdram_tRP_delay;
              else
                count <= count + 1;
                DQM_O <= mask5;
              end if;

            when 5 =>
              count <= count + 1;
              DQM_O <= mask6;
              tx_data_O <= '1';

            when 6 =>
              count <= count + 1;
              DQM_O <= mask7;
              tx_data_O <= '1';

            when 7 =>
              count <= count + 1;
              DQM_O <= mask8;
              tx_data_O <= '1';

            when 8 =>
              count <= count + 1;
              tx_data_O <= '1';
              state <= sdram_tRP_delay;
              
            when others => null;

          end case;

        -----------------------------------------------------------------------
        -- Delay for tRP
        -----------------------------------------------------------------------
        when sdram_tRP_delay =>
          DQM_O <= (others => '0');
          rx_data_O <= '0';
          tx_data_O <= '0';
          count <= 0;    
          CS_n_O(0) <= '1'; -- Disable SDRAM
		
          if delaycount < tRP_CYCLES then
            delaycount <= delaycount + 1;
            state <= sdram_tRP_delay;
          else
            delaycount <= 0;
            CS_n_O(0) <= '0'; -- Enable SDRAM
            state <= sdram_NOP;
            Command <= NOP;
          end if;
          
        -----------------------------------------------------------------------
        -- NOP
        -----------------------------------------------------------------------  
        when sdram_NOP =>
          RAS_n_O <= '1';
          CAS_n_O <= '1';
          WE_n_O  <= '1';
          CS_n_O(0) <= '0'; -- Enable SDRAM          
          
          if command = startup then     -- Check if we're in the startup sequence
            r_ack_O <= '0';
            w_ack_O <= '0';
            DQM_O <= (others => '1'); 
            ready_O <= '0';

            if warmup_timer < tSTARTUP_NOP_CYCLES then
              warmup_timer <= warmup_timer + 1;
              state <= sdram_NOP;
            else
              state <= sdram_precharge;
            end if;            
            
          elsif (refresh_req = '1' or command = refresh) then            
            refresh_done_flg <= '1';   
            DQM_O <= (others => '0');
            ready_O <= '0';            
      --    command <= refresh;
            state <= sdram_auto_refresh;
            r_ack_O <= '0';
            w_ack_O <= '0';
            
          elsif (W_Enable_I = '1' or command = write) then
            refresh_done_flg <= '0';
            DQM_O <= (others => '0');
            ready_O <= '0';            
     
            -- Send row address
            addr_O(12) <= '0';
            addr_O(11 downto 0) <= rowaddr;
    
            command <= write;
            state <= sdram_activ;
            w_ack_O <= '1';
            r_ack_O <= '0';

          elsif (R_enable_I = '1' or command = read) then
            refresh_done_flg <= '0';
            DQM_O <= (others => '0');
            ready_O <= '0';

            -- Send row address
            addr_O(12) <= '0';
            addr_O(11 downto 0) <= rowaddr;

            command <= read;
            state <= sdram_activ;
            r_ack_O <= '1';
            w_ack_O <= '0';       
  
          else
            
            refresh_done_flg <= '0';
            DQM_O <= (others => '0');
            ready_O <= '1';
            command <= NOP;
            state <= sdram_NOP;
            r_ack_O <= '0';
            w_ack_O <= '0';
            
          end if;                     

        when others => null;

      end case;
      
    end if;
  end process command_engine;  

-------------------------------------------------------------------------------
-- REFRESH EVERY 15.6us
-------------------------------------------------------------------------------

  -- purpose: Generates refresh request every 15.6us
  -- type   : sequential
  -- inputs : clock, RST_I
  -- outputs: refresh_req

refresh_process: process (CLK_I, RST_I) is
  begin  -- process refresh
    if RST_I = '0' then                 -- asynchronous reset (active low)

      refresh_timer <= 0;
      refresh_req <= '0';

    elsif CLK_I'event and CLK_I = '1' then  -- rising clock edge

      if refresh_timer < tREF_CYCLES then

        refresh_req <= '0';
        refresh_timer <= refresh_timer + 1;

      elsif refresh_done_flg = '1' then

        refresh_req <= '0';
        refresh_timer <= 0;

      else

        refresh_req <= '1';

      end if;
      
    end if;
  end process refresh_process;

end architecture behav;

