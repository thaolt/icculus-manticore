-------------------------------------------------------------------------------
-- Title      : sdram_control
-- Project    : HULK
-------------------------------------------------------------------------------
-- File       : memory_manager.vhd
-- Author     : Jeff Mrochuk <jmrochuk@ieee.org>
-- Last update: 2002/03/20
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
  -- tRRD  >= 20ns (RAS to RAS Banck activate delay)
  -- tRCD  >= 20ns (Activate to command delay - RAS to CAS delay)
  -- tRAS  >= 50ns (RAS Active time)
  -- tRP   >= 20ns (RAS Precharge time)
  -- tMRD  >= 3 tCK
  -- tREF  <= 64ms (Refresh period for 4096 rows, so 64ms/4096 = 15.625us per row)
  -- tRFC  <= 80ns (Row refresh cycle time)
  
  constant CLOCK_PERIOD : positive := 20;--15;  -- Clock period in ns.  Designed for 66.67 MHz (15ns)

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
  --constant t_startupNOP_cycles: integer := 13334; --200us (200.01)
   
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

entity sdram_control is
  generic(

    -- Input Address format:
    --
    --   Bank       Row            Column 
    --  |<->|<-              ->|<-        ->|
    --  -------------------------------------
    --  22  21                 9            0
    --
    in_address_width   : positive := 23;
    banksize    : integer := 2;
	rowsize 	: integer := 12;
	colsize 	: integer := 9;
    bankstart   : integer := 21;
	rowstart 	: integer := 9;
	colstart 	: integer := 0;
    datawidth       : integer := 64;
    INTERLEAVED     : std_logic := '0';  -- Sequential if '0'
    BURST_MODE      : std_logic := '0';   -- enabled if '0'
    BURST_LENGTH    : integer := 4
    );

  port(
    clock, reset       : in  std_logic;
    R_enable, W_enable : in  std_logic;
    RW_address         : in  std_logic_vector(in_address_width-1 downto 0);
    ready              : out std_logic;
    tx_data, rx_data   : out std_logic;
	r_ack, w_ack	   : out std_logic;
    init_done          : out std_logic;
    data_mask          : in  std_logic_vector(datawidth/8*BURST_LENGTH -1 downto 0);
 --   chip_select        : in  std_logic;

    -- to memory
    WEbar          : out std_logic;     -- Write enable, Active Low
    CKE            : out std_logic_vector(1 downto 0);  -- clock enable
    CSbar          : out std_logic;
    CS2bar         : out std_logic;     -- chip select, Active Low
    addr           : out std_logic_vector(12 downto 0);
    RASbar, CASbar : out std_logic;
    DQM            : out std_logic_vector(datawidth/8-1 downto 0);
    BA             : out std_logic_vector (1 downto 0)

    );
end sdram_control;

architecture behav of sdram_control is

  
  type state_type is (sdram_startup, sdram_activ, sdram_read, sdram_write, sdram_tRP_delay,
                      sdram_MRS, sdram_precharge, sdram_auto_refresh, sdram_NOP);
  
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

begin  -- architecture behav

  bankaddr <= RW_address(bankstart + banksize- 1 downto bankstart);
  rowaddr  <= RW_address(rowstart + rowsize - 1 downto rowstart);    
  coladdr  <= RW_address(colstart + colsize - 1 downto colstart);  


  -- purpose: Send outputs to RAM based on command input
  -- type   : sequential
  -- inputs : clock, reset, refresh_req, read_req, write_req
  -- outputs: All memory signals, init_done
  command_engine: process (clock, reset) is
  begin  -- process command_engine

    ---------------------------------------------------------------------------
    --  ASYNCHRONOUS RESET
    ---------------------------------------------------------------------------

    if reset = '0' then

      state        <= sdram_startup;
      command      <= startup;
      warmup_timer <= 0;

      delaycount    <= 0;
      count         <= 0;
      refresh_timer <= 0;

      refresh_done_flg <= '0';
      mask1       <= "00000000";
      mask2       <= "00000000";
      mask3       <= "00000000";
      mask4       <= "00000000";
      ready       <= '0';
      r_ack       <= '0';
      w_ack       <= '0';
      tx_data     <= '0';
      rx_data     <= '0';
      WEbar       <= '0';
      CKE         <= (others => '0');
      CSbar       <= '0';
      CS2bar      <= '1';
      addr        <= (others => '0');
      RASbar      <= '0';
      CASbar      <= '0';
      DQM         <= (others => '1');
      BA          <= (others => '0');
      init_done   <= '0';

    elsif clock'event and clock = '1' then  -- rising clock edge
      ---------------------------------------------------------------------
      -- CONSTANT SIGNALS
      ---------------------------------------------------------------------     
      CKE <= "11";  

      
      case state is

        -----------------------------------------------------------------------
        -- Startup
        -----------------------------------------------------------------------

        when sdram_startup   =>
          DQM     <= (others => '1');   -- Set high during init routine
          command <= startup;
          state   <= sdram_NOP;
			r_ack <= '0';
			w_ack <= '0';
        -----------------------------------------------------------------------
        -- Mode Register Set
        -----------------------------------------------------------------------
        when sdram_MRS =>
          RASbar <= '0';
          CASbar <= '0';
          WEbar  <= '0';
         	r_ack <= '0';
			w_ack <= '0';
          addr(12 downto 10) <= "000";
          addr(9)            <= BURST_MODE;   -- Burst read and write
          addr(8 downto 7)   <= "00";
          addr(6 downto 4)   <= conv_std_logic_vector(cas_latency, CASWIDTH);
                                            -- CAS latency 2
          addr(3)            <= INTERLEAVED;  -- Sequential mode not interleave
          addr(2 downto 0)   <= "010";        --burst length of 4

          if delaycount < tMRD_CYCLES then
            delaycount <= delaycount + 1;
            state      <= sdram_MRS;
          else        
            delaycount <= 0;
            case command is
              when startup => 

                init_done   <= '1';
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
          RASbar <= '0';
          CASbar <= '1';
          WEbar  <= '0';
 			r_ack <= '0';
			w_ack <= '0';         
          addr(12 downto 11) <= "00";
          addr(10) <= '1';                    -- Precharge all banks
          addr(9 downto 0)   <= "0000000000";

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
          DQM <= (others => '1');
     		r_ack <= '0';
			w_ack <= '0';
			
	      if delaycount = 0 then
            RASbar <= '0';
            CASbar <= '0';
            WEbar  <= '1';
            delaycount <= delaycount + 1; 
            state <= sdram_auto_refresh;       
          elsif delaycount < tRFC_CYCLES then
		    CSbar <= '1'; -- Disable SDRAM
			-- NOP
		--	RASbar <= '1';
		--	CASbar <= '1';
		--	WEbar  <= '1';
            delaycount <= delaycount + 1;
            state <= sdram_auto_refresh;
          else
            CSbar <= '1'; -- Disable SDRAM
			-- NOP
	    --	RASbar <= '1';
		--	CASbar <= '1';
		--	WEbar  <= '1';
      
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
		        CSbar <= '0'; -- Enable SDRAM
		
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
            
          ready <= '0';

          -- Load DQM mask
          mask1 <= data_mask(B1_START downto B1_END);
          mask2 <= data_mask(B2_START downto B2_END);
          mask3 <= data_mask(B3_START downto B3_END);
          mask4 <= data_mask(B4_START downto B4_END);
          DQM <= (others => '0');

          if delaycount = 0 then 
            --Row Activate
            RASbar <= '0';
            CASbar <= '1';
            WEbar  <= '1';
            CSbar  <= '0';	                    

            -- Send row address
            addr(12) <= '0';
            addr(11 downto 0) <= rowaddr;
  
            delaycount <= delaycount + 1;
            state <= sdram_activ;

          elsif delaycount < tRCD_CYCLES then
            -- NOP
          --  RASbar <= '1';
          --  CASbar <= '1';
          --  WEbar  <= '1';
		    CSbar <= '1'; -- Disable SDRAM          
            delaycount <= delaycount + 1;
            state <= sdram_activ;

          else
            -- NOP
            --RASbar <= '1';
            --CASbar <= '1';
            --WEbar  <= '1';          
		    CSbar <= '1'; -- Disable SDRAM          
       
            delaycount <= 0;
            count <= 0;
            case command is
              when read =>
                state <= sdram_read;
                addr(12 downto 11) <= "00";   -- HARDCODED: send bank
                addr(10) <= '1';              -- Auto precharge
                addr(9)  <= '0';
                addr(8 downto 0) <= coladdr;


              when write =>
                state <= sdram_write;
                addr(12 downto 11) <= "00";   -- HARDCODED: send bank
                addr(10) <= '1';              -- Auto precharge
                addr(9)  <= '0';
                addr(8 downto 0) <= coladdr;

              tx_data <= '1';
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
		  CSbar <= '0'; -- Enable SDRAM
          DQM <= (others => '0');
          r_ack <= '0';
          
          case count is
            when 0 =>
              -- READA Command
              RASbar <= '1';
              CASbar <= '0';
              WEbar  <= '1';

              rx_data <= '1';
              count <= count + 1;

            when 1 => -- CAS_LATENCY - 1=>
              -- NOP
              RASbar <= '1';
              CASbar <= '1';
              WEbar  <= '1';
          
              rx_data <= '1';
              count <= count + 1;
              
            when 2 => -- CAS_LATENCY =>             
              rx_data <= '1';
              count <= count + 1;
              
            when 3 => --CAS_LATENCY + 1 =>              
  --            rx_data <= '1';
              state <= sdram_tRP_delay;  -- Delay for tRP until next operation

            when others => null;
              
          end case;

        -----------------------------------------------------------------------
        -- Write
        -----------------------------------------------------------------------  
        when sdram_write =>
		  CSbar <= '0'; -- Enable SDRAM

          case count is
            when 0 =>
              -- WRITEA Command
              RASbar <= '1';
              CASbar <= '0';
              WEbar  <= '0';
              w_ack <= '0';            
              count <= count + 1;              
              DQM <= mask1;
              tx_data <= '1';


            when 1 =>
              -- NOP
              RASbar <= '1';
              CASbar <= '1';
              WEbar  <= '1';
     
              count <= count + 1;
              DQM <= mask2;
              tx_data <= '1';
              
            when 2 =>
              count <= count + 1;
              DQM <= mask3;
              tx_data <= '1';

            when 3 =>
              count <= count + 1;
              DQM <= mask4;
              tx_data <= '1';


            when 4 =>
           --   DQM <= mask4;          
              tx_data <= '1';
              state <= sdram_tRP_delay;              

            when others => null;

          end case;

        -----------------------------------------------------------------------
        -- Delay for tRP
        -----------------------------------------------------------------------
        when sdram_tRP_delay =>
          DQM <= (others => '0');
          rx_data <= '0';
          tx_data <= '0';
          count <= 0;    
		  CSbar <= '1'; -- Disable SDRAM
		
          if delaycount < tRP_CYCLES then
            delaycount <= delaycount + 1;
            state <= sdram_tRP_delay;
          else
            delaycount <= 0;

 		   CSbar <= '0'; -- Enable SDRAM
           state <= sdram_NOP;
           command <= NOP;
          end if;
          
        -----------------------------------------------------------------------
        -- NOP
        -----------------------------------------------------------------------  
        when sdram_NOP =>
          RASbar <= '1';
          CASbar <= '1';
          WEbar  <= '1';
		  CSbar <= '0'; -- Enable SDRAM          

          if command = startup then     -- Check if we're in the startup sequence
			r_ack <= '0';
			w_ack <= '0';
            DQM <= (others => '1'); 
            ready <= '0';
            if warmup_timer < tSTARTUP_NOP_CYCLES then
              warmup_timer <= warmup_timer + 1;
              state <= sdram_NOP;
            else
              state <= sdram_precharge;
            end if;            
            
          elsif (refresh_req = '1' or command = refresh) then            
            refresh_done_flg <= '1';   
            DQM <= (others => '0');
            ready <= '0';            
            command <= refresh;
            state <= sdram_auto_refresh;
			r_ack <= '0';
			w_ack <= '0';
            
          elsif (W_Enable = '1' or command = write) then
            refresh_done_flg <= '0';
            DQM <= (others => '0');
            ready <= '0';            
     
            -- Send row address
            addr(12) <= '0';
            addr(11 downto 0) <= rowaddr;
    
            command <= write;
            state <= sdram_activ;
            w_ack <= '1';
            r_ack <= '0';

          elsif (R_Enable = '1' or command = read) then
            refresh_done_flg <= '0';
            DQM <= (others => '0');
            ready <= '1';

            -- Send row address
            addr(12) <= '0';
            addr(11 downto 0) <= rowaddr;

            command <= read;
            state <= sdram_activ;
			r_ack <= '1';
            w_ack <= '0';       
  
          else
            refresh_done_flg <= '0';
            DQM <= (others => '0');
            ready <= '1';
            command <= NOP;
            state <= sdram_NOP;
			r_ack <= '0';
			w_ack <= '0';
          end if;                     

        when others => null;

      end case;
      
    end if;
  end process command_engine;  

-- purpose: Latch and acknowledge commands
-- type : sequential
-- inputs : clock, reset, ready, R_Enable, W_enable
-- outputs: read_req, write_req, ready
--command_latch : process (clock, reset) is
--begin  -- process command_latch
--  if reset = '0' then                   -- asynchronous reset (active low)

--    write_req <= '0';
--    read_req  <= '0';

--  elsif clock'event and clock = '1' then  -- rising clock edge

--    if command_done_flg = '0' then
--      ready <= '0';
--      if R_Enable = '1' or read_req = '1' then
--        read_req <= '1';

--      elsif W_Enable = '1' or write_req = '1'  then
--        write_req <= '1';
--      end if;
    
--    else
--      ready <= '1';
--      read_req <= '0';
--      write_req <= '0';
--   end if;
    
    
--  end if;
--end process command_latch;

-------------------------------------------------------------------------------
-- REFRESH EVERY 15.6us
-------------------------------------------------------------------------------

  -- purpose: Generates refresh request every 15.6us
  -- type   : sequential
  -- inputs : clock, reset
  -- outputs: refresh_req

refresh_process: process (clock, reset) is
  begin  -- process refresh
    if reset = '0' then                 -- asynchronous reset (active low)

      refresh_timer <= 0;
      refresh_req <= '0';

    elsif clock'event and clock = '1' then  -- rising clock edge

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
