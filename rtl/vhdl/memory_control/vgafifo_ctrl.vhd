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

------------------------------------------------------------------------------
-- Title      : VGA FIFO Control Section
-- Project    : HULK
-------------------------------------------------------------------------------
-- File       : vgafifo_ctrl.vhd
-- Author     : Benj Carson <benjcarson@digitaljunkies.ca>
-- Last update: 2002-06-13
-- Platform   : Altera APEX20K200E
-------------------------------------------------------------------------------
-- Description: Generates control signals for fifo & SDRAM
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Author     Description
-- 2002/03/04   benj       Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.memory_defs.all;


entity vgafifo_ctrl is

  port (
    clock, reset : in  std_logic;
    -- VGA Signals
    Read_Line      : in  std_logic;       -- Read Line command from VGA out module
    Read_Line_Warn : in  std_logic;
    Read_Line_Ack  : out std_logic;
    Line_Number    : in  std_logic_vector(9 downto 0);
    Blank_Done     : out std_logic;
 
    -- SDRAM Signals
    Data_Out     : inout std_logic_vector(DATA_WIDTH-1 downto 0);
    SDRAM_Ready  : in  std_logic;
    Tx_Data      : in  std_logic;
    Rx_Data      : in  std_logic;
    Init_Done    : in  std_logic;
    R_Enable     : out std_logic;
    W_Enable     : out std_logic;
    Address      : inout std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    data_mask    : out std_logic_vector(DATA_WIDTH/8*4 -1 downto 0);
    r_ack, w_ack :  in std_logic;	
    BufferPick   : in std_logic;  -- DEBUG
    -- Fifo Signals
    Fifo_Clear   : out std_logic;
    Write_Req    : out std_logic;
    Fifo_Full    : in  std_logic;
    Fifo_Level   : in  std_logic_vector(6 downto 0);

      Blank_Now    : in std_logic;
      Blank_Ack    : out std_logic;

    -- Z_Fifo Signals
 --   Z_Fifo_Clear   : out std_logic;
 --   Z_Write_Req    : out std_logic;
 --   Z_Fifo_Level   : in  std_logic_vector(7 downto 0);
 --   Z_Fifo_Full    : in  std_logic;

    -- Z_Buffer Signals
--    Z_Line_Number : in std_logic_vector(9 downto 0);
--    Z_Col_Start   : in std_logic_vector(10 downto 0);
--    Z_Col_End     : in std_logic_vector(10 downto 0);

--Write Fifo Signals
    Write_Fifo_Empty : in std_logic;
    Write_Fifo_Data_Pop   : out std_logic;
    Write_Fifo_Data_Enable : out std_logic;
    Write_Fifo_Addr_Enable : out std_logic;
    Write_Fifo_Addr_Pop : out std_logic;
    Write_FB         : out std_logic

    );

end vgafifo_ctrl;

architecture behavioural of vgafifo_ctrl is

  type state_type is (memory_wait, blank_ready_wait, memory_blank, idle, ready_wait, R_send,  
  get_data, flush_writes_wait, flush_writes,
  z_blank_wait, z_blank, z_read_wait, z_read ); --,draw_ready_wait, send_data, error_state);
                      
  signal state       : state_type;
  signal Word_Count  : integer range 0 to 84; -- Tally of words written to buffer
  signal blank_Word_Count  : integer range 0 to 84; -- Tally of words written to buffer
  signal Burst_Count : integer range 0 to 7;                   -- Tally of words received in a burst cycle
  signal Row_Number	 : integer range 0 to 485;
  signal Read_FB : std_logic;           -- The active read frame bufffer

  --
  signal Data_Internal: std_logic_vector(DATA_WIDTH-1 downto 0);
  signal Data_Enable: std_logic;
  signal Address_Internal :  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal Address_Enable: std_logic;
--  signal Blank_Half: std_logic;
begin  -- behavioural


  -- purpose: Retrieves an entire line of 640 pixels (80x64 bit words)
  -- type : sequential
  -- inputs : clock, reset, Fifo_Full, Fifo_Level, Read_Line,
  -- Line_Number, SDRAM_Ready, Tx_Data, Rx_Data
  -- outputs: R_Enable, W_Enable, Address_Internal, Write_Req, Data_Internal, Fifo_Clear

  getline : process (clock, reset)

  begin  -- process getline

    if reset = '0' then                 -- asynchronous reset (active low)
      R_Enable  <= '0';
      W_Enable  <= '0';
      Address_Internal   <= (others => '0');
      Write_Req <= '0';
      Fifo_Clear <= '0';
      Data_Internal <= (others => '0');
      state    <= memory_wait;
      Blank_Done <= '0';  
      Word_Count <= 0;
      blank_word_count <= 0;
      Burst_Count <= 0;
      Row_Number <= 0;
      data_mask <= ( others => '0');
      Read_FB <= '0';
      Read_Line_Ack <= '0';
      Data_Enable <= '0';
      Address_Enable <= '0';
--	  Blank_half <= '0';
      Write_Fifo_Data_Pop    <= '0';
      Write_Fifo_Data_Enable <= '0';
      Write_Fifo_Addr_Enable <= '0';
      Write_Fifo_Addr_Pop    <= '0';
      Write_FB               <= '0';

    elsif clock'event and clock = '1' then  -- rising clock edge

      case state is

        when memory_wait =>
          
          Data_Enable <= '0';
          Blank_Done <= '0'; 
          R_Enable <= '0';
          W_Enable <= '0';
          Address_Internal  <= (others => '0');
          Data_Internal <= (others => '0');
          Write_Req <= '0';
          Fifo_Clear <= '0';
          Word_Count <= 0;
          blank_word_count <= 0;
          Burst_Count <= 0;
          Row_Number <= 0;
          data_mask <= ( others => '0');

          --         Blank_Half <= '1';  -- Whole thing first

          if Init_Done ='0' then
            state <= memory_wait;
          else
            state <= blank_ready_wait;
--            state <= draw_ready_wait;
--          state <= idle; 
          end if;

------------------------------------------------------------------------------------
-- Blank State
------------------------------------------------------------------------------------			
        when blank_ready_wait =>

          R_Enable   <= '0';
          Address_Enable <= '1';
          Data_Enable <= '1';
          Address_Internal(ADDRESS_COLUMN_WIDTH+ADDRESS_ROW_WIDTH-1 downto ADDRESS_COLUMN_WIDTH+ADDRESS_ROW_WIDTH-3) <= "000";
          Address_Internal(18) <= '0';
          Address_Internal(17 downto ADDRESS_COLUMN_WIDTH)  <= conv_std_logic_vector(Row_Number, 9);
          Address_Internal(ADDRESS_COLUMN_WIDTH-1 downto 0) 
            <= conv_std_logic_vector(blank_Word_Count, ADDRESS_COLUMN_WIDTH);

          Write_Req  <= '0';
          Fifo_Clear <= '0';
          Burst_count <= 0;
         -- Data_Internal   <= (others => '0');

-- Stupid green Fade
	if row_number < 60 then
            Data_Internal   <= (others => '1');
	elsif row_number < 120 then
            Data_Internal <= "1101101111011011110110111101101111011011110110111101101111011011";

		
	elsif row_number < 180 then

            Data_Internal <= "1011011110110111101101111011011110110111101101111011011110110111";

		
	elsif row_number < 240 then
	
             Data_Internal <= "1001001110010011100100111001001110010011100100111001001110010011"; 

		
	elsif row_number < 300 then
	
              Data_Internal <= "0110111101101111011011110110111101101111011011110110111101101111";

		
	elsif row_number < 360 then
	
            Data_Internal <= "0100101101001011010010110100101101001011010010110100101101001011";

	
	elsif row_number < 420 then

            Data_Internal <= "0010011100100111001001110010011100100111001001110010011100100111";
		
	elsif row_number < 480 then
	

            Data_Internal <= "0000001100000011000000110000001100000011000000110000001100000011";
		
	end if;

          data_mask <= (others => '0');

          if Read_Line_Warn = '1'  then
      	      state <= idle;
              W_Enable <= '0'; 
              word_count <= 0;
            
          elsif row_number > 479 then

            state <= idle;
            word_count <= 0;
            row_number <= 0;
            W_Enable <= '0';       			
            Read_FB <= '0';

          elsif blank_Word_count > 80 then
            row_number <= row_number + 1;
            blank_Word_Count <= 0;
            W_Enable <= '0';

          elsif (SDRAM_Ready = '1') then
            W_Enable <= '1';
       	    state <= memory_blank;

          else
            state <= blank_ready_wait;
            W_Enable <= '0';
          end if;

        when memory_blank =>

          Blank_Ack <= '0';
          R_Enable <= '0';
          --data_mask <= ( others => '0');

          case burst_count is 
            when 0 =>
              if tx_data = '1' then
                Address_Enable <= '0';
                burst_count <= 1;
                W_Enable   <= '0';
              else
                Data_Enable <= '1';
                burst_count <= 0;
              end if; 

            when 1 =>
              burst_count <= 2;
              W_Enable   <= '0';
            when 2 => 
              burst_count <= 3;
            when 3 =>
              burst_count <= 0;
			  Data_Enable <= '1';
             -- word_count <= word_count + 4;
              blank_word_count <= blank_word_count + 4;
              state <= blank_ready_wait;

            when others => null;	

          end case;

------------------------------------------------------------------------------------
-- Idle state
------------------------------------------------------------------------------------		

        when idle =>
          R_Enable <= '0';
          W_Enable <= '0';
          Blank_Done <= '1'; 
          Write_Req <= '0';
          Address_Enable <= '0';
	      Data_Enable <= '0';

          Write_Fifo_Data_Enable <= '0';
          Write_Fifo_Addr_Enable <= '0';
          Write_Fifo_Data_Pop <= '0';
          Write_Fifo_Addr_Pop <= '0';

          Read_FB <= '0';

          if Read_line = '1'  then
            Word_Count <= 0;
            state <= ready_wait; 		
            Fifo_Clear <= '1';
            Read_Line_Ack <= '1'; 
            Blank_Ack <= '0';

          elsif Blank_Now = '1' and Read_Line_Warn = '0'  then
            state <= blank_ready_wait;
            Word_Count <= 0;
            Read_Line_Ack <= '0';
            Burst_Count <= 0;
            Blank_Ack <= '1';

--           if Blank_half= '0' then
--              row_number <= 0;
--           else
--              row_number <= 239;
--           end if;
              
 --         Row_Number <= 0;

          elsif Write_Fifo_Empty = '0' and Read_Line_Warn = '0' then
            state <= flush_writes_wait;
            Word_Count <= 0;
            Fifo_Clear <= '0';
            Read_Line_Ack <= '0';
            Blank_Ack <= '0';


          else
            Word_Count <= 0;
            state <= idle;
            Fifo_Clear <= '0';
            Read_Line_Ack <= '0';
            Blank_Ack <= '0';

          end if;
          
------------------------------------------------------------------------------------
-- READ CYCLE
------------------------------------------------------------------------------------


        when ready_wait =>

          Address_Internal(22 downto 19) <= "0000";
          Address_Internal(18) <= '0'; --Read_FB;
          Address_Internal(17 downto ADDRESS_COLUMN_WIDTH) <= Line_Number (8 downto 0);
          Address_Internal(ADDRESS_COLUMN_WIDTH-1 downto 0) <= conv_std_logic_vector(Word_Count, ADDRESS_COLUMN_WIDTH);
          Address_Enable <= '1';

          W_Enable    <= '0';          
          Write_Req   <= '0';
          Fifo_Clear  <= '0';
          Burst_count <= 0;          

          Write_Fifo_Data_Enable <= '0';          
          Write_Fifo_Addr_Enable <= '0';

          if Word_Count > 80 then 
            Read_Line_Ack <= '0';		   
            state <= idle; --z_read_wait; 
 --           row_number <= 0;
            Word_Count <= 0; --conv_integer(Z_Col_Start);
            R_Enable <= '0';
--            Z_Fifo_Clear <= '1';

          elsif (SDRAM_Ready = '1') and (Fifo_Level < conv_std_logic_vector(76,7)) then            
            R_Enable <= '1';
            state <= get_data;

          else
            state <= ready_wait;
            R_Enable   <= '0';
          end if;

        when get_data =>

          W_Enable   <= '0';
          data_mask  <= (others => '0');
          Data_Internal   <= (others => '0');
          Fifo_Clear <= '0';
          Read_Line_Ack <= '0';

          case burst_count is 
            when 0 =>
            
              if rx_data = '1' then
                burst_count <= 1;
                Write_Req <= '1';
                R_Enable <= '0';  	              
              else
                Write_Req <= '0';
                burst_count <= 0;
--			    R_Enable <= '1';
              end if;
					
            when 1 =>
              Address_Enable <= '0';
              burst_count <= 2;
              Write_Req <= '1';
              R_Enable <= '0';
            when 2 => 
              burst_count <= 3;
              Write_Req <= '1';
            when 3 =>
              word_count <= word_count + 4;		
              write_req <= '1';	
              state <= ready_wait;  
              burst_count <= 0;  

				    --R_Enable <= '0';  
            when others => null;
				
          end case;


------------------------------------------------------------------------------------
-- DRAW CYCLE
------------------------------------------------------------------------------------
         
--        when draw_ready_wait =>

--         Address_Internal(ADDRESS_COLUMN_WIDTH+ADDRESS_ROW_WIDTH-1 downto ADDRESS_COLUMN_WIDTH+ADDRESS_ROW_WIDTH-3) <= "00";
--         Address_Internal(18) <= Read_FB;
--         Address_Internal(17 downto ADDRESS_COLUMN_WIDTH)  <= conv_std_logic_vector(Row_Number, 9);
--         Address_Internal(ADDRESS_COLUMN_WIDTH-1 downto 0) 
--    				<= conv_std_logic_vector(Word_Count, ADDRESS_COLUMN_WIDTH);

--         Address_Enable <= '1';

--         Data_Internal <= (others => '0');
--        data_mask <= "01111111011111110111111101111110";
--        data_mask <= "10111111111111111111111111111110";
--          data_mask <= "00000000000110000011110011111111";
--        data_mask <= (others => '0');
--         R_Enable   <= '0';

--          Write_Req  <= '0';
--          Fifo_Clear <= '0';
--          Burst_count <= 0 ;


--	   if row_number > 210  then
		
--             state <= idle;		
--             word_count <= 0;
--             W_Enable <= '0';       
--             row_number <= 0;
						
--          elsif Word_count > 36 then
--            Word_count <= 32;
--            W_Enable   <= '0';
--	        row_number <= row_number + 1;

--          elsif (SDRAM_Ready = '1') then
--            W_Enable <= '1';
--            state <= send_data;
--
--          else
--            W_Enable   <= '0';          
--            state <= draw_ready_wait;
--          end if;
--
--        when send_data =>
--
--          Write_Req  <= '0';
--         Fifo_Clear <= '0';
--          
--	case burst_count is 
--          when 0 =>
--            
--            if w_ack = '1' then        
--              burst_count <= burst_count + 1;
--              W_Enable   <= '0';
--            else
--              burst_count <= 0;
--              W_Enable   <= '1';
--			  Data_Enable <= '1';
--              
--            end if;
--
--          when 1 =>
--                  Address_Enable <= '0';   
--                  burst_count <= burst_count + 1;
--                  Data_Internal <= "1111110011111100111111001111110011111100111111001111110011111100";
--          when 2 => 
--                  Data_Internal <= "1110000011100000111000001110000011100000111000001110000011100000";
--                  burst_count <= burst_count + 1;
--          when 3 =>				
--                  burst_count <= burst_count + 1;
--                  Data_Internal <= "0001110000011100000111000001110000011100000111000001110000011100";
--          when 4 =>
--			      Data_Enable <= '0';
--                  Data_Internal <= "0000001100000011000000110000001100000011000000110000001100000011";
--                  state <= draw_ready_wait;	
--                  word_count <= word_count + 4;		    	
--          when others => null;	
--
--        end case;   

-------------------------------------------------------------------------------
-- Arbitrary Write
-------------------------------------------------------------------------------

-- Wait for ready
          
          when flush_writes_wait =>
            Write_Fifo_Data_Enable <= '1'; -- Tristate enable
            Write_Fifo_Addr_Enable <= '1';  
            burst_count <= 0;
            Write_FB <= not Read_FB;

            if (SDRAM_Ready = '1') then
              W_Enable <= '1';
              state <= flush_writes;
              Write_Fifo_Addr_Pop <= '1';
            -- Last chance for read line:
            elsif Read_line = '1' then
              Word_Count <= 0;              
              state <= ready_wait; 		
              Fifo_Clear <= '1';
              Read_Line_Ack <= '1';
            else
              W_Enable <= '0';
              state <= flush_writes_wait;
            end if;

-- Now Write
          
        when flush_writes =>
          
          case burst_count is 
             when 0 =>
               Write_Fifo_Addr_Pop <= '0';
               if w_ack = '1' then
                 Write_Fifo_Data_Pop <= '1';
                 burst_count <=  1;
                 W_Enable   <= '0';
               else
                 burst_count <= 0;
                 W_Enable   <= '1';
               end if;

             when 1 =>
               burst_count <= 2;
             when 2 => 
               burst_count <= 3;
             when 3 =>				
               burst_count <= 4;
             when 4 =>
               Write_Fifo_Data_Pop <= '0';
               burst_count <= 0;                              
               state <= idle;	
       when others => null;	

        end case;   

-----------------------------------------------------------------------------------
-- Z-Buffer States
-----------------------------------------------------------------------------------

--Z_Blank_Wait--------------------------------------------------

--     when z_blank_wait =>

--          R_Enable   <= '0';
--          Address_Enable <= '1';

          -- 01 is for ZB

--          Address_Internal(22 downto 19) <= "0001";

--          Address_Internal(18) <= '0';  --Frame buffer not relevant

--          Address_Internal(17 downto ADDRESS_COLUMN_WIDTH)  <= conv_std_logic_vector(Row_Number, 9);

--          Address_Internal(ADDRESS_COLUMN_WIDTH-1 downto 0) 
--            <= conv_std_logic_vector(Word_Count, ADDRESS_COLUMN_WIDTH);

--          Write_Req  <= '0';
--          Fifo_Clear <= '0';
--          Burst_count <= 0;

--          data_mask <= (others => '0');

          -- Maximum  Z value
--	      data_internal <= "0111111111111111011111111111111101111111111111110111111111111111";
			
--          if row_number > 479 then
            
--            state <= idle;
--            word_count <= 0;
--            row_number <= 0;
--            W_Enable <= '0';       			
--            Read_FB <= '0';

--          elsif Word_count > 160 then
--            row_number <= row_number + 1;
--            Word_Count <= 0;
--            W_Enable <= '0';

--          elsif (SDRAM_Ready = '1') then
--            W_Enable <= '1';
--       	    state <= z_blank;

--          else
--            state <= z_blank_wait;
--            W_Enable <= '0';
--          end if;

--Z_Blank-------------------------------------------------------

--        when z_blank =>

--          R_Enable <= '0';

--          case burst_count is 
--            when 0 =>
--              if tx_data = '1' then
--                Address_Enable <= '0';
--                burst_count <= 1;
--                W_Enable   <= '0';
--              else
--		Data_Enable <= '1';
--                burst_count <= 0;
--              end if; 

--            when 1 =>
--              burst_count <= 2;
--              W_Enable   <= '0';

--            when 2 => 
--              burst_count <= 3;

--            when 3 =>
--              burst_count <= 0;
--	      Data_Enable <= '1';
--              word_count <= word_count + 4;
--              state <= z_blank_wait;

--            when others => null;	

--          end case;

--Z_Read_Wait------------------------------------------------------

--    when z_read_wait =>

--          Address_Internal(22 downto 19) <= "0001"; -- Z_Buffer top address

--          Address_Internal(18) <= '0';
          
--          Address_Internal(17 downto ADDRESS_COLUMN_WIDTH) <= Z_Line_Number(8 downto 0);

--          Address_Internal(ADDRESS_COLUMN_WIDTH-1 downto 0) <= conv_std_logic_vector(Word_Count, ADDRESS_COLUMN_WIDTH);
--          Address_Enable <= '1';

--          W_Enable    <= '0';          
--          Z_Write_Req   <= '0';
--          Z_Fifo_Clear  <= '0';
--          Burst_count <= 0;          
          
--          if Word_Count > conv_integer(Z_Col_End) then 
		   
--            state <= idle; 
--            row_number <= 0;
--            Word_Count <= 0;
--            R_Enable <= '0';

--          elsif (SDRAM_Ready = '1')  and (Z_Fifo_Level < conv_std_logic_vector(154,8)) then
          
--            R_Enable <= '1';
--            state <= z_read;

--          else
--            state <= z_read_wait;
--            R_Enable   <= '0';
--          end if;

--Z_Read-----------------------------------------------------------

--        when z_read =>

--          data_mask  <= (others => '0');
--          Data_Internal   <= (others => '0');
--          Z_Fifo_Clear <= '0';

--          case burst_count is 
--            when 0 =>
            
--              if rx_data = '1' then
--                burst_count <= 1;
--                Z_Write_Req <= '1';
--                R_Enable <= '0';  	              
--              else
--                Z_Write_Req <= '0';
--                burst_count <= 0;
--              end if;
					
--            when 1 =>
--              Address_Enable <= '0';
--              burst_count <= 2;
--              Z_Write_Req <= '1';
--              R_Enable <= '0';
--            when 2 => 
--              burst_count <= 3;
--              Z_Write_Req <= '1';
--            when 3 =>
--              word_count <= word_count + 4;		
--              Z_write_req <= '1';	
--              state <= Z_read_wait;  
--              burst_count <= 0;
              
--            when others => null;
				
--          end case;
          
-------------------------------------------------------------------------------
-- Others
-------------------------------------------------------------------------------

          
        when others => null;


          end case;

    end if;
  end process getline;


-------------------------------------------------------------------------------
-- Tristate
-------------------------------------------------------------------------------


  -- purpose: Tristates data bus
  -- type   : combinational
  -- inputs : Tx_Data
  -- outputs: Data
  tristate_data_bus : process (Data_Enable) is


  begin  -- process tristate_data_bus	
    if Data_Enable = '1' then
      Data_Out <= Data_Internal;
    else
      Data_Out <= (others => 'Z');
    end if;

    
  end process tristate_data_bus;

  tristate_address_bus : process (Address_Enable) is


  begin  -- process tristate_address
    if (Address_Enable = '1') then
      Address <= Address_Internal;
    else
      Address <= (others => 'Z');
    end if;

    
  end process tristate_address_bus;


end behavioural;
------------------------------------------------------------------------------------------------------------------------
-- END VGA FIFO CONTROL
------------------------------------------------------------------------------------------------------------------------
