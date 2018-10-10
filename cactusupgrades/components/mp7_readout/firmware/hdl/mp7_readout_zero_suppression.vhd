-- mp7_readout zero supression
-- JRF August 2017
-- The new ZS block consists of three state machines, the main state machine handles the bulk of the work, transfering the header to the fifo2 and filling the fifo1 with the data blocks. 
-- the second state machine manages the transfer of the data blocks from fifo1 to fifo2 once a decision has been made to keep or reject the data. Data blocks are stored in fifo1 for the 
-- length of the block which can be any number of 32 bit words as indicated in the length field of the 6 word header. The third State machine handles the output of the data from the fifo2. 
--
-- The main state machine performs the following tasks:   
-- 1 IDLE.   N clocks: IDLE 
-- 2 HDR. 	6 clocks: write the remaining 5 headaer words into FIFO2 (5 x 32 bit words) then go to 3
-- 3 INIT.   N clocks: IDLE until the init arrives and store the word in init_word, then go to 4
-- 4 DATA. 	N clocks: reset the counter1 to N from the length in the block header word when it arrives 
--          (use STROBE to see arrival). Transfer data when strobe is high for each block then raise 
--          blk_done once each block is done to trigger the transfer state machien. 
--          At the same time another process is checking the data to see if it's all zero. Set a flag 
--          to keep keep_blk. Once all data is transfered on token, go to 5. Note that we idle in this
--          state once data is finished until the token arrives.
-- 5 DONE. 	N clocks. when transfer state machine is in IDLE, then go to 1. 
--	When counter1 = 1 set done_block high to trigger transfer state machine. 
-- 
--
-- The transfer state machine performs the following tasks:
-- 1 IDLE.	N clocks: IDLE until done_block high AND fifo1 not empty, 
-- 2.BLK_BLK_HEAD.  1 clock: handle writing of the block header from fifo1 into fifo2 along with overwritting the length
-- 3.BLK_BX_HEAD. 1 clock: write the BX Header in the cases we need one
-- 4.BLK_BX_DATA. N clocks: write out the data we want to keep in groups of 6 or 7 words depending on whether we are outputing ZS data or un-ZS data. 
--	we do this by retreieving the stored block lengh from the block length fifo and then grouping the transfer into a BX at a time. We loop around the state machine between Idle and BLK_bX_DATA until all Blocks have been transfered. 
--	        Note. set fifo2 write enable only if keep_bx = true
--          

-- The output state machine peroforms the following tasks:
-- 1 IDLE.   N Clocks: IDLE until main state machien is done then go to 2
-- 2 HDR.    1 clock:  overwrite the total_len in the stored HEADER and push onto the output_bus store total_len in counter3
-- 2 DATA.   counter3 Clocks: readout all data before going back to IDLE
--   

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
--use ieee.std_logic_arith.all;

-- JRF Feb 2016
-- Adding the folloing components to use block ram to buffer my ZS data
library unisim;
use unisim.VComponents.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;
use work.mp7_readout_decl.all;
use work.ipbus_decode_mp7_readout_zs.all;

entity mp7_readout_zero_suppression is
	port(
        clk: in std_logic;
        rst: in std_logic;
        ipb_in: in ipb_wbus;
        ipb_out: out ipb_rbus;
		clk_p: in std_logic; 
		rst_p: in std_logic;
		daq_bus_in: in daq_bus; 
		daq_bus_out: out daq_bus;
		done_in: in std_logic; --JRF feb 2016 added this to hijack the rob_last signal in readout
		done_out: out std_logic --JRF feb 2016 added this to output the hijacked signal to the rob
	);

end mp7_readout_zero_suppression;


architecture rtl of mp7_readout_zero_suppression is
	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
    signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);

-- V1 state machine
	signal dbus_plus_1clk, dbus_plus_2clk, dbus_plus_3clk, dbus_plus_4clk: daq_bus;
	type state_type is (ST_IDLE, ST_HDR, ST_DATA, ST_DONE);
	
-- V2 State machines	
	type main_state_type is (ST_IDLE, ST_HDR, ST_INIT, ST_DATA, ST_DONE);
	type fifo_transfer_state_type is (ST_IDLE, ST_BLK_BLK_HEAD, ST_BLK_BX_HEAD, ST_BLK_BX_DATA, ST_DONE); 
    type output_state_type is (ST_IDLE, ST_HDR, ST_DATA, ST_DONE);
	signal state_main, state_main_prev, state_main_prev2, state_main_prev3: main_state_type; -- JRF this state machine manages the bulk of the work, writing fifo1, writing header info to fifo2, calculating length and triggering the readout from fifo2
	signal state_fifo_transfer, state_fifo_transfer_prev, state_fifo_transfer_prev2,state_fifo_transfer_prev3,state_fifo_transfer_prev4,state_fifo_transfer_prev5: fifo_transfer_state_type; -- JRF this state machine manages the reading from fifo1 and transfering the blocks to fifo2. It also handles ignoring data that is all zero.
	signal state_data_out, state_data_out_plus_1clk, state_data_out_plus_2clk: output_state_type; -- JRF this state machine manages the output of the fifo2

-- Signals from V1 of ZS block
	signal ctr, ro_mask_ctr: unsigned(15 downto 0);
	signal strobe, fifo_transfer_done : std_logic;
	signal ro_mask, ro_mask_plus_1clk: std_logic_vector(31 downto 0) ;
	signal ro_mask_3: std_logic_vector(2 downto 0) ; -- dummy signal, not used.
	signal ctrl: ipb_reg_v(1 downto 0);
    signal stat: ipb_reg_v(1 downto 0);
    signal en, data_complement, rst_p_int: std_logic;


-- New Signals for V2
	signal first_header_word: daq_bus; -- JRF contains the first header word which contains the length to be overwritten at the end
	signal init_word: std_logic_vector(31 downto 0);
	signal total_length, total_length_plus_1clk, total_length_plus_2clk, counter_fifo2_read, init_length: unsigned(15 downto 0); 
	signal block_length, block_length_plus_1clk, block_length_plus_2clk, counter_keep_bx,  counter_keep_bx_plus_1clk, counter_keep_bx_plus_2clk, counter_keep_bx_plus_3clk, counter_keep_bx_plus_4clk, counter_keep_bx_plus_5clk, counter_keep_bx_plus_6clk, counter_keep_bx_plus_7clk, read_blk_ready, read_blk_ready_plus_1clk : unsigned(7 downto 0);
	signal token_latch, keep_blk, keep_blk_plus_1clk, keep_blk_plus_2clk, keep_blk_plus_3clk, keep_blk_plus_4clk, keep_blk_plus_5clk, keep_blk_plus_6clk, done_blk, done_blk_plus_1clk, done_blk_plus_2clk,done_blk_plus_3clk, done_blk_plus_4clk  : std_logic;
	signal fifo2_write_strobe, fifo2_write_strobe_plus_1clk, fifo2_write_strobe_plus_2clk, fifo2_write_strobe_plus_3clk, fifo2_write_strobe_plus_4clk : std_logic;
    signal counter_fifo1_write, counter_fifo1_read, counter_cap_id: unsigned(7 downto 0); --JRF TODO check if this is wide enough to handle all possible lengths
    signal counter_start_out: unsigned(3 downto 0);--JRF this counter delays the start of output state machine, 
    signal counter_bx_data: unsigned(2 downto 0); --JRF one counter to count the bx block of 6 words.
    
    signal zs_fifo1_blk_length_out, zs_fifo1_blk_length_out1:  std_logic_vector(11 downto 0);  
    signal zs_fifo1_keep_bx_out, zs_fifo1_keep_bx_in: std_logic_vector(1 downto 0);
    signal zs_fifo1_counter_keep_bx_out, zs_fifo1_counter_keep_bx_out1, zs_fifo1_counter_keep_bx_in:  std_logic_vector(7 downto 0);
    signal zs_fifo1_blk_length_in:  std_logic_vector(11 downto 0); 
    signal dbus_zs_fifo1_out,dbus_zs_fifo1_out_plus_1clk:  std_logic_vector(35 downto 0);   -- JRF data returned from the fifo to be shipped out might not need this. wire the fifo output directly.
    signal dbus_zs_fifo1_in: std_logic_vector(35 downto 0); -- JRF data to be sotred in the fifo during ZS
    signal dbus_zs_fifo2_out:  std_logic_vector(35 downto 0);   -- JRF data returned from the fifo to be shipped out might not need this. wire the fifo output directly.
    signal dbus_zs_fifo2_in, dbus_zs_fifo2_in_minus_1clk: std_logic_vector(35 downto 0); -- JRF data to be sotred in the fifo during ZS
    signal dbus_zs_fifo2_in_pre1: std_logic_vector(35 downto 0); -- JRF used to multiplex data into fifo2 from two processes
    signal dbus_zs_fifo2_in_pre2: std_logic_vector(35 downto 0); -- JRF used to multiplex data into fifo2 from two processes

    signal zs_fifo1_counter_keep_bx_wen, zs_fifo1_counter_keep_bx_ren, zs_fifo1_counter_keep_bx_full, zs_fifo1_counter_keep_bx_empty, zs_fifo1_counter_keep_bx_valid: std_logic;
    signal zs_fifo1_keep_bx_wen, zs_fifo1_keep_bx_ren, zs_fifo1_keep_bx_full, zs_fifo1_keep_bx_empty, zs_fifo1_keep_bx_valid, zs_fifo1_keep_bx_valid_plus_1clk,zs_fifo1_keep_bx_out_plus_1clk,zs_fifo1_keep_bx_out_plus_2clk,zs_fifo1_keep_bx_out_plus_3clk,zs_fifo1_keep_bx_out_plus_4clk,zs_fifo1_keep_bx_out_plus_5clk:  std_logic;
    signal zs_fifo1_blk_length_wen, zs_fifo1_blk_length_ren, zs_fifo1_blk_length_full, zs_fifo1_blk_length_empty, zs_fifo1_blk_length_valid:  std_logic;        
    signal zs_fifo1_wen, zs_fifo1_ren, zs_fifo1_full, zs_fifo1_empty, zs_fifo1_valid:  std_logic;
    signal zs_fifo2_wen, zs_fifo2_ren, zs_fifo2_full, zs_fifo2_empty, zs_fifo2_valid:  std_logic;
    signal zs_fifo2_wen_pre1, zs_fifo2_wen_pre2, zs_fifo2_wen_pre2_minus1clk, token_out, done_out_int, done_hdr_out:  std_logic;
        
    signal ro_mask_read_addr: std_logic_vector(6 downto 0); -- JRF contains the address based upon the capture id and which of the 6 words we are on from the block    
    signal ro_cap_id, ro_cap_id_plus_1clk, ro_cap_id_plus_2clk, ro_cap_id_plus_3clk : unsigned(3 downto 0); -- 4 bit capture id which will determin which mask to use from the mask ram, this is used when calculating the length of each block while writing to fifo1 and then stored in the same fifo as the length, to be used when deciding whether to keep BXs during transfer
    signal ro_mode_id, ro_val_mode_id: unsigned(7 downto 0); -- mode_id from header and required mode id to determin if this is a validation event
    signal cap_en: std_logic_vector(15 downto 0); -- 16 enable bits, one for each capid.
    signal ro_mask_en: std_logic;
    
    constant dummy_1 : std_logic := '1';
    constant dummy_0: std_logic := '0';
    constant dummy_0_vec_1 : std_logic_vector(0 downto 0) := (others => '0');
    constant dummy_1_vec_1 : std_logic_vector(0 downto 0) := (others => '1');
    constant dummy_0_vec_36: std_logic_vector(35 downto 0) := (others => '0');
    --constant ZS_ENABLED : std_logic := '0'; -- this is declared in top_decl.vhd for each project

begin 

-- JRF there are some things which are needed regardless of whether we build with ZS or not

    --JRF TODO replace this fifo with an 8 bit fifo of depth 256
    zs_fifo1_counter_keep_bx: entity work.zs_fifo_256_x_8b --JRF TODO, this should be a 1 bit fifo to save space.
        port map (
            clk =>clk_p, --: IN STD_LOGIC;
            srst =>rst_p_int, --: IN STD_LOGIC;
            din => zs_fifo1_counter_keep_bx_in, --keep_blk, -- & dbus_plus_3clk.data.data, -- JRF eventually we will do the folloiwing to this value unsigned(dbus_plus_3clk.data.data(23 downto 16)) + 1, --: IN STD_LOGIC_VECTOR(35 DOWNTO 0);
            wr_en => zs_fifo1_counter_keep_bx_wen, --: IN STD_LOGIC;
            rd_en => zs_fifo1_counter_keep_bx_ren, --: IN STD_LOGIC;
            dout => zs_fifo1_counter_keep_bx_out1, -- : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
            full => zs_fifo1_counter_keep_bx_full, --: OUT STD_LOGIC;
            empty => zs_fifo1_counter_keep_bx_empty, --: OUT STD_LOGIC;
            valid => zs_fifo1_counter_keep_bx_valid -- : OUT STD_LOGIC
        );      -- JRF add the entity for the zs output fifo1. 


--JRF we need a fifo to store the ZS decision for each BX as they come in.
--JRF 2 bit fifo of 256 deep. Note that it stores keep_bx bit plus the data_complement bit. 
    zs_fifo1_keep_bx: entity work.zs_fifo_256_x_2b --JRF TODO, this should be a 1 bit fifo to save space.
        port map (
            clk =>clk_p, --: IN STD_LOGIC;
            srst =>rst_p_int, --: IN STD_LOGIC;
            din => zs_fifo1_keep_bx_in, --keep_blk, -- & dbus_plus_3clk.data.data, -- JRF eventually we will do the folloiwing to this value unsigned(dbus_plus_3clk.data.data(23 downto 16)) + 1, --: IN STD_LOGIC_VECTOR(35 DOWNTO 0);
            wr_en => zs_fifo1_keep_bx_wen, --: IN STD_LOGIC;
            rd_en => zs_fifo1_keep_bx_ren, --: IN STD_LOGIC;
            dout => zs_fifo1_keep_bx_out, -- : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
            full => zs_fifo1_keep_bx_full, --: OUT STD_LOGIC;
            empty => zs_fifo1_keep_bx_empty, --: OUT STD_LOGIC;
            valid => zs_fifo1_keep_bx_valid -- : OUT STD_LOGIC
        );      -- JRF add the entity for the zs output fifo1. 


    -- JRF add the entity for the zs output fifo1. 
--JRF TODO replace this fifo with a 12 bit fifo, remember we need to store the length and the capid in this fifo, that's why we need 12 bits it can be 256 deep
    zs_fifo1_blk_length: entity work.zs_fifo_256_x_12b
        port map (
            clk =>clk_p, --: IN STD_LOGIC;
            srst =>rst_p_int, --: IN STD_LOGIC;
            din => zs_fifo1_blk_length_in, --“0000" & dbus_plus_3clk.data.data, -- JRF eventually we will do the folloiwing to this value unsigned(dbus_plus_3clk.data.data(23 downto 16)) + 1, --: IN STD_LOGIC_VECTOR(35 DOWNTO 0);
            wr_en => zs_fifo1_blk_length_wen, --: IN STD_LOGIC;
            rd_en => zs_fifo1_blk_length_ren, --: IN STD_LOGIC;
            dout => zs_fifo1_blk_length_out1, -- : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
            full => zs_fifo1_blk_length_full, --: OUT STD_LOGIC;
            empty => zs_fifo1_blk_length_empty, --: OUT STD_LOGIC;
            valid => zs_fifo1_blk_length_valid -- : OUT STD_LOGIC
        );	-- JRF add the entity for the zs output fifo1. 
        

    zs_fifo1: entity work.zs_fifo_16k_x_36b
        port map (
            clk =>clk_p, --: IN STD_LOGIC;
            srst =>rst_p_int, --: IN STD_LOGIC;
            din =>dbus_zs_fifo1_in, --: IN STD_LOGIC_VECTOR(35 DOWNTO 0);
            wr_en => zs_fifo1_wen, --: IN STD_LOGIC;
            rd_en => zs_fifo1_ren, --: IN STD_LOGIC;
            dout =>dbus_zs_fifo1_out, -- : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
            full => zs_fifo1_full, --: OUT STD_LOGIC;
            empty => zs_fifo1_empty, --: OUT STD_LOGIC;
            valid => zs_fifo1_valid -- : OUT STD_LOGIC
        );

-- JRF add the entity for the zs transfer fifo2.
    zs_fifo2: entity work.zs_fifo_16k_x_36b
        port map (
            clk =>clk_p, --: IN STD_LOGIC;
            srst =>rst_p_int, --: IN STD_LOGIC;
            din =>dbus_zs_fifo2_in, --: IN STD_LOGIC_VECTOR(35 DOWNTO 0);
            wr_en => zs_fifo2_wen, --: IN STD_LOGIC;
            rd_en => zs_fifo2_ren, --: IN STD_LOGIC;
            dout =>dbus_zs_fifo2_out, -- : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
            full => zs_fifo2_full, --: OUT STD_LOGIC;
            empty => zs_fifo2_empty, --: OUT STD_LOGIC;
            valid => zs_fifo2_valid -- : OUT STD_LOGIC
        );

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
    generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_mp7_readout_zs(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

		   
 csr: entity work.ipbus_ctrlreg_v
  generic map(
      N_CTRL => 2,
      N_STAT => 2
  )
  port map(
      clk => clk,
      reset => rst,
      ipbus_in => ipbw(N_SLV_CSR),
      ipbus_out => ipbr(N_SLV_CSR),
      d => stat,
      q => ctrl
  );
 
  zs_blk_mask_ram: entity work.ipbus_ported_dpram36
          generic map(
              ADDR_WIDTH => 7--LB_ADDR_WIDTH
          )
          port map(
              clk => clk,
              rst => rst,
              ipb_in => ipbw(N_SLV_RAM),
              ipb_out => ipbr(N_SLV_RAM),
              rclk => clk_p,
              we => '0',
              d => dummy_0_vec_36,
              q(31 downto 0) => ro_mask,
	      q(35) => data_complement,
              q(34 downto 32) => ro_mask_3,
              addr => ro_mask_read_addr
          );
--ro_mask(31 downto 0) <= ro_mask_36 ( 31 downto 0); -- pass the 36 wide ram data into the ro_mask 32 bit wide bus
  
ZS_DISABLE: if (ZS_ENABLED = false) generate

-- give all the unused inputs some value
-- ro_mask_en <= '0';
 --ctrl(0) <= (others => '0');
 --ctrl(1) <= (others => '0');
 stat(0) <= X"00000000";
 stat(1) <= X"00000000"; -- bit 24 - ZS Enabled, fifo 1 36 x 8, fifo 2 36 x 8, mask ram, 32 x 72 (0x48)
     
 ro_mask_read_addr <= (others => '0');
 ro_mask <= (others => '0');
 dbus_zs_fifo1_in <= (others => '0');
 zs_fifo1_wen <= '0';
 zs_fifo1_ren <= '0';
 dbus_zs_fifo2_in <= (others => '0');
 zs_fifo2_wen <= '0';
 zs_fifo2_ren <= '0';
 zs_fifo1_blk_length_in <= (others => '0');
 zs_fifo1_blk_length_wen <= '0';
 zs_fifo1_blk_length_ren <= '0';
 zs_fifo1_keep_bx_in <= (others => '0');
 zs_fifo1_keep_bx_wen <= '0';
 zs_fifo1_keep_bx_ren <= '0';
 zs_fifo1_counter_keep_bx_in <= (others => '0');
 zs_fifo1_counter_keep_bx_wen <= '0';
 zs_fifo1_counter_keep_bx_ren <= '0';
 
 
 process(clk_p) -- process to select which done signal to output, this depends if we are performing zero suppression or not
    begin
        if rising_edge(clk_p) then
            done_out <= done_in; -- in this case we have no ZS algo so we just pass through
        end if;
    end process;

 process(clk_p) -- process to output data to rob Note we use a 2clk delayed version of the output state machine to be sure we align the arrival of the data from the fifo
    begin
        if rising_edge(clk_p) then
             daq_bus_out <= daq_bus_in; -- passthrough do nothing
        end if;
    end process;

end generate;

    
ZS_ENABLE: if (ZS_ENABLED = true) generate

--JRF Debug Process, remove this when debugging complete
    process(clk_p) -- process to output data to rob Note we use a 2clk delayed version of the output state machine to be sure we align the arrival of the data from the fifo
    begin
        if rising_edge(clk_p) then
             if (daq_bus_in.data.start = '1' or (daq_bus_in.token ='0' and stat(0)(10) = '0' ) ) then
                stat(0)(10) <= '0';
             else
                stat(0)(10) <= '1';
             end if;
        end if;
    end process;

   -- stat(0)(10) <= '0' when ( daq_bus_in.data.start = '1' or (daq_bus_in.token ='0' and stat(0)(10) = '0' ) ) else '1'; 
		
-- set up the status registers
-- start with fifo flags
    stat(0)(0) <= zs_fifo1_full;
	stat(0)(1) <= zs_fifo1_empty;
	stat(0)(2) <= zs_fifo2_full;
	stat(0)(3) <= zs_fifo2_empty;
	stat(0)(4) <= zs_fifo1_counter_keep_bx_full;
	stat(0)(5) <= zs_fifo1_counter_keep_bx_empty;
	stat(0)(6) <= zs_fifo1_keep_bx_full;
	stat(0)(7) <= zs_fifo1_keep_bx_empty;
	stat(0)(8) <= zs_fifo1_blk_length_full;
	stat(0)(9) <= zs_fifo1_blk_length_empty;
	stat(0)(31 downto 11) <=   "00000000000000" --stat(0)(31 downto 10) <=   "000000000000000" 
	                        & std_logic_vector(to_unsigned(main_state_type'pos(state_main), 3))
	                        & std_logic_vector(to_unsigned(fifo_transfer_state_type'pos(state_fifo_transfer), 2)) 
	                        & std_logic_vector(to_unsigned(output_state_type'pos(state_data_out), 2)); -- [3]&[2]&[2]
	-- fifo sizes
	stat(1) <= X"01101060"; -- bit 24 - ZS Enabled, fifo 1 36 x 16, fifo 2 36 x 16,  mask ram, 36 x  96 (0x60)
	
			
   process(clk_p) -- process to select which done signal to output, this depends if we are performing zero suppression or not
   begin
       if rising_edge(clk_p) then
           if rst_p_int = '1' then
               done_out_int <= '0';
           else
               if en ='0' then
                   done_out_int <= done_in;
               elsif   en ='1' AND token_out = '1' then --  if we are in zs mode and we have finished writing the event to fifo
                   done_out_int <= '1';
               else
                   done_out_int <= '0'; 
               end if;
           end if;
       end if;
   end process;
   

-- JRF process to manage the token_latch 
    process(clk_p) 
    begin
        if rising_edge(clk_p) then
             if rst_p_int = '1' then 
                token_latch <= '0';
             elsif (state_main /= ST_IDLE and daq_bus_in.token = '1') 
                or ( token_latch = '1' and token_out = '0' ) then
                token_latch <= '1'; 
             else 
                token_latch <= '0';
             end if;
         end if;
    end process;    
    
    
-- JRF V2 State Machines
   
    process(clk_p) --JRF data_output state machine
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' then
                state_data_out <= ST_IDLE;
            else
                case state_data_out is
                when ST_IDLE => -- only leave this state once we are sure all data have been transfered to fifo2 and that the total_length is now correct
                    if state_fifo_transfer = ST_DONE and counter_start_out = 3 then--JRF TODO, check that we should not be looking at a delayed version of the state_fifo_transfer.
                        state_data_out <= ST_HDR;
                    end if;
                    
                when ST_HDR =>
                        state_data_out <= ST_DATA;
                    
                when ST_DATA =>
                    if counter_fifo2_read <= 1  then --JRF TODO check this note we added token latch
                    -- there are two cases, token comes before data are finished outputting, and token comes after data are finished, so we 
                    -- must wait for the token to latch before we complete
                        state_data_out <= ST_DONE;
                    end if;
                when ST_DONE =>
                    if token_latch = '1' then
                        state_data_out <= ST_IDLE;
                    end if;
                end case;
            end if;
        end if;
    end process;
   
    process(clk_p) -- Main State Machine. Note that all state tranitions occur one clock after the fact. So all data manipulation will have to be done from a pipelined data bus signal.
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' then
                state_main <= ST_IDLE;
            else
                case state_main is
                    when ST_IDLE => -- here we wait until the header arrives, when it arrives change state to HDR
                        if daq_bus_in.data.strobe = '1' and daq_bus_in.data.start = '1' then
                            state_main <= ST_HDR;
                        end if;
                    when ST_HDR => -- here we store the first header word in first_header_word and the remaining 5 header words in fifo2
                        if daq_bus_in.init = '1' and ctr >= to_unsigned(DAQ_N_HDR_WORDS - 1, 16) then --note that we stay in this state until init arrives, although we don't do anything in between
                            state_main <= ST_INIT;
                        end if;
                    when ST_INIT => -- here we store the init word and  wait for the data to arrive when the first word arrives we store the length 
                        if daq_bus_in.data.strobe = '1' then 
                            state_main <= ST_DATA;
                        end if;
                    when ST_DATA =>
                        if dbus_plus_1clk.token = '1' then -- we stay in this state until token, again, we don't do anythign when strobe is low.
                            -- Note that we take token from 1 clock later since it comes on the last word, not after the last word
                            state_main <= ST_DONE;
                        end if;
                    when ST_DONE =>
                        if state_fifo_transfer_prev3 = ST_IDLE and counter_fifo1_read = 0 and zs_fifo1_empty = '1' and fifo_transfer_done = '1' then -- JRF gonna try ST_DONE to speed up ... didn't work...  ST_IDLE then--JRF TODO, check that we don't need to use a delayed version of state_fifo_transfer here.
                            state_main <= ST_IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;


    process(clk_p) -- state machine to handle transfer of blocks from fifo1 to fifo2
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' then
                state_fifo_transfer <= ST_IDLE;
		        fifo_transfer_done <= '1';
            else
                case state_fifo_transfer is
                when ST_IDLE =>
		            if  state_main /= ST_DATA and counter_fifo1_read < 1 and zs_fifo1_empty = '1' and fifo_transfer_done = '0' then
                        state_fifo_transfer <= ST_DONE;

                    elsif read_blk_ready_plus_1clk > 0 and counter_fifo1_read = 0 then --JRF Note that although we use this signal to trigger the state machine to move into ST_BLK, we cannot rely on this signal to trigger the read of each block. JRF TODO, check that the timing of this signal is now ok, since we only start the transfer when we get the length from the length fifo. could be that this is ok, but we need to pipeline the state_Fifo_transfer... 
                        state_fifo_transfer <= ST_BLK_BLK_HEAD;
                    end if;

                when ST_BLK_BLK_HEAD =>
		            fifo_transfer_done <= '0';
		            state_fifo_transfer <= ST_BLK_BX_HEAD;

		        when ST_BLK_BX_HEAD =>
		            state_fifo_transfer <= ST_BLK_BX_DATA;

		        when ST_BLK_BX_DATA =>
                    if  ( counter_fifo1_read < 8  and counter_bx_data = 0 )  then 
                        state_fifo_transfer <= ST_IDLE;
		    --elsif  state_main /= ST_DATA and counter_fifo1_read < 1 and zs_fifo1_empty = '1' then 
                    -- JRF changed this to check for empty fifo 1 before finishing the 
                    -- block transfer, much simpler. Also we must not quit the transfer 
                    -- until the main state leaves DATA, just in case of big gaps between blocks
                    -- this happens when you enable channels that are far apart e.g. 0 and 4 is far enough
                    --    state_fifo_transfer <= ST_DONE;
		            elsif (counter_bx_data = 0) then -- JRF we count down from 5 to get 6 words for each block
			           state_fifo_transfer <= ST_BLK_BX_HEAD;
                    end if;
                when ST_DONE =>
		            fifo_transfer_done <= '1';
                    if counter_start_out = 6 then
                        state_fifo_transfer <= ST_IDLE;
                    end if;
                end case;
            end if;
        end if;
    end process;
   
   process(clk_p) -- process to manage the counter_bx_data which counts down from 5 to 0.
   begin
       if rising_edge(clk_p) then
           if rst_p_int = '1' then
               counter_bx_data <= (others => '0');
           else
               if ( state_fifo_transfer = ST_BLK_BX_HEAD ) then
		   counter_bx_data <= "101";
               elsif ( state_fifo_transfer = ST_BLK_BX_DATA and counter_bx_data > 0) then
                   counter_bx_data <= counter_bx_data - 1;
	       else 
		   counter_bx_data <= (others => '0');
               end if;
           end if;
       end if;
   
   end process;
 
    
    process(clk_p) -- process to output data to rob Note we use a 2clk delayed version of the output state machine to be sure we align the arrival of the data from the fifo
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' then
                daq_bus_out <=  daq_bus_in;
            else
                if en ='0' then
                     daq_bus_out <= daq_bus_in; -- passthrough do nothing
                else
                    if state_data_out_plus_2clk = ST_HDR then
                        -- we must handle the two cases for ODD and EVEN numbers of words
                        -- before we check we must add one more word for the header since...
                        -- The total length in the header appears to be total number of 64 bit words padded to 64 bit boundary. 
                        -- remember to first add one 32 bit word for the header that was never written to the fifo2.
                        if (total_length_plus_2clk+1 REM 2) = 0 then --EVEN CASE 
                            daq_bus_out.data.data <= first_header_word.data.data(31 downto 16) & std_logic_vector(((total_length_plus_2clk+1)/2) + 1); -- TODO check this. 
			else -- ODD CASE
			    daq_bus_out.data.data <= first_header_word.data.data(31 downto 16) & std_logic_vector(((total_length_plus_2clk+2)/2) + 1);
			end if;
                        daq_bus_out.data.valid <= first_header_word.data.valid;
                        daq_bus_out.data.start <= first_header_word.data.start;
                        daq_bus_out.init <= first_header_word.init;
                        daq_bus_out.token <= '0';
                        daq_bus_out.data.strobe <= first_header_word.data.strobe; 
                    elsif state_data_out_plus_2clk = ST_DATA then
                        daq_bus_out.data.data <= dbus_zs_fifo2_out(31 downto 0);
                        daq_bus_out.data.valid <= dbus_zs_fifo2_out(35);
                        daq_bus_out.data.start <= dbus_zs_fifo2_out(34);
                        daq_bus_out.init <= dbus_zs_fifo2_out(33);
                        daq_bus_out.token <= token_out;
                        daq_bus_out.data.strobe <= dbus_zs_fifo2_out(32); 
		            else
			            daq_bus_out.data.data <= (others => '0');
                        daq_bus_out.data.valid <= '0';
                        daq_bus_out.data.start <= '0';
                        daq_bus_out.init <= '0';
                        daq_bus_out.token <= token_out;
                        daq_bus_out.data.strobe <= '0';
			
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    process(clk_p) -- process to manage fifo2 read enable
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' or state_data_out = ST_IDLE  or state_data_out = ST_HDR then
               	zs_fifo2_ren <= '0';
            elsif state_data_out = ST_DATA then 
       		zs_fifo2_ren <= '1';     	
	    end if;
        end if;
    end process;
    
    process(clk_p) -- process to manage output counter
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' or state_data_out = ST_IDLE then
               counter_fifo2_read <= (others => '0');
            elsif state_data_out = ST_HDR then -- set the length for fifo read, and replace the total length in the header
               counter_fifo2_read <= total_length + init_length; -- we have to remember to readout the init words
            elsif state_data_out = ST_DATA and counter_fifo2_read > 0 then
               counter_fifo2_read <= counter_fifo2_read - 1;
            end if;
        end if;
    end process;

    process(clk_p) -- process to manage token_out
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' then
               	token_out <= '0';
            elsif state_data_out_plus_1clk = ST_IDLE and state_data_out_plus_2clk = ST_DONE then
               	token_out <= '1';
            else
		        token_out <= '0';
            end if;
        end if;
    end process;

    -- process to increment the header counter.
    process(clk_p) 
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' or state_main = ST_IDLE then
                ctr <= (others => '0');
            else
                if daq_bus_in.data.strobe = '1' and  state_main = ST_HDR  then -- note we only increment when strobe is high, this allows for data to arrive at any time.
                    ctr <= ctr + 1;
                end if;
            end if;
        end if;
    end process;
 
     -- process to increment the start out counter. This counter is used to delay the start of the readout
     -- to ensure that the total_length has completed counting before we use it
    process(clk_p) 
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' or state_fifo_transfer = ST_IDLE then--JRF TODO, check if we need to deplay this state signal to prev4...
                counter_start_out <= (others => '0');
            else
                if  state_fifo_transfer = ST_DONE then 
                    counter_start_out <= counter_start_out + 1;
                end if;
            end if;
        end if;
    end process;
   
-- JRF TODO reinclude the ro_mask from V1, use the capture id to select masks from a lookup of masks    
--    V1 process
--    process(clk_p)
--    begin
--        if rising_edge(clk_p) then
--            if rst_p_int = '1' then
--                ro_mask <= (others => '0');
--            elsif daq_bus_in.init = '1' then
--                ro_mask <= daq_bus_in.data.data(CLOCK_RATIO + 21 downto 22) & '0';
--            end if;
--        end if;
--    end process;
--    
--    process(clk_p)
--    begin
--       if rising_edge(clk_p) then
--           if (rst_p_int = '1') or (state = ST_IDLE) or (ro_mask_ctr = (CLOCK_RATIO)) then -- clock ratio -1
--               ro_mask_ctr <= (others => '0');
--           elsif state = ST_DATA and daq_bus_in.data.strobe = '1' then
--               ro_mask_ctr <= ro_mask_ctr + 1;
--           end if;
--       end if;
--    end process;
                        
--    strobe <= not ro_mask(to_integer(ro_mask_ctr)) when en = '1' else '1'; -- masks words being read out
    
    


-- JRF we require the following processes to pipeline various signals  
    process(clk_p)
    begin
        if rising_edge(clk_p) then
            dbus_plus_1clk.data.data <= daq_bus_in.data.data;
            dbus_plus_1clk.data.valid <= daq_bus_in.data.valid;
            dbus_plus_1clk.data.start <= daq_bus_in.data.start;
            dbus_plus_1clk.init <= daq_bus_in.init;
            dbus_plus_1clk.token <= daq_bus_in.token;
            dbus_plus_1clk.data.strobe <= daq_bus_in.data.strobe; 
            
            dbus_plus_2clk.data.data <= dbus_plus_1clk.data.data;
            dbus_plus_2clk.data.valid <= dbus_plus_1clk.data.valid;
            dbus_plus_2clk.data.start <= dbus_plus_1clk.data.start;
            dbus_plus_2clk.init <= dbus_plus_1clk.init;
            dbus_plus_2clk.token <= dbus_plus_1clk.token;
            dbus_plus_2clk.data.strobe <= dbus_plus_1clk.data.strobe;
 
            dbus_plus_3clk.data.data <= dbus_plus_2clk.data.data;
            dbus_plus_3clk.data.valid <= dbus_plus_2clk.data.valid;
            dbus_plus_3clk.data.start <= dbus_plus_2clk.data.start;
            dbus_plus_3clk.init <= dbus_plus_2clk.init;
            dbus_plus_3clk.token <= dbus_plus_2clk.token;
            dbus_plus_3clk.data.strobe <= dbus_plus_2clk.data.strobe;
 
            dbus_plus_4clk.data.data <= dbus_plus_3clk.data.data;
            dbus_plus_4clk.data.valid <= dbus_plus_3clk.data.valid;
            dbus_plus_4clk.data.start <= dbus_plus_3clk.data.start;
            dbus_plus_4clk.init <= dbus_plus_3clk.init;
            dbus_plus_4clk.token <= dbus_plus_3clk.token;
            dbus_plus_4clk.data.strobe <= dbus_plus_3clk.data.strobe;

            dbus_zs_fifo1_out_plus_1clk <= dbus_zs_fifo1_out;
                                               
            done_blk_plus_1clk <= done_blk;
            done_blk_plus_2clk <= done_blk_plus_1clk;
	    done_blk_plus_3clk <= done_blk_plus_2clk;
	    done_blk_plus_4clk <= done_blk_plus_3clk;
	    keep_blk_plus_1clk <= keep_blk;
            keep_blk_plus_2clk <= keep_blk_plus_1clk;
            keep_blk_plus_3clk <= keep_blk_plus_2clk;
            keep_blk_plus_4clk <= keep_blk_plus_3clk;
            keep_blk_plus_5clk <= keep_blk_plus_4clk;
	    keep_blk_plus_6clk <= keep_blk_plus_5clk;
            block_length_plus_1clk <= block_length;
            block_length_plus_2clk <= block_length_plus_1clk;
            zs_fifo1_keep_bx_out_plus_1clk <= zs_fifo1_keep_bx_out(0);
	    zs_fifo1_keep_bx_out_plus_2clk <= zs_fifo1_keep_bx_out_plus_1clk;
	    zs_fifo1_keep_bx_out_plus_3clk <= zs_fifo1_keep_bx_out_plus_2clk;
	    zs_fifo1_keep_bx_out_plus_4clk <= zs_fifo1_keep_bx_out_plus_3clk;
	    zs_fifo1_keep_bx_out_plus_5clk <= zs_fifo1_keep_bx_out_plus_4clk;
        zs_fifo1_blk_length_out <= zs_fifo1_blk_length_out1;
        zs_fifo1_counter_keep_bx_out <= zs_fifo1_counter_keep_bx_out1;
	    zs_fifo1_keep_bx_valid_plus_1clk <= zs_fifo1_keep_bx_valid;
            ro_mask_plus_1clk <= ro_mask;
            state_main_prev <= state_main;
            state_main_prev2 <= state_main_prev;
            state_main_prev3 <= state_main_prev2;
            state_fifo_transfer_prev <= state_fifo_transfer;
	    state_fifo_transfer_prev2 <= state_fifo_transfer_prev;
	    state_fifo_transfer_prev3 <= state_fifo_transfer_prev2;
	    state_fifo_transfer_prev4 <= state_fifo_transfer_prev3;
	    state_fifo_transfer_prev5 <= state_fifo_transfer_prev4;
	    state_data_out_plus_1clk <= state_data_out;
	    state_data_out_plus_2clk <= state_data_out_plus_1clk;
	    total_length_plus_1clk <=  total_length;
            total_length_plus_2clk <= total_length_plus_1clk;
            zs_fifo2_wen_pre2 <= zs_fifo2_wen_pre2_minus1clk;
            fifo2_write_strobe_plus_1clk <= fifo2_write_strobe;
            fifo2_write_strobe_plus_2clk <= fifo2_write_strobe_plus_1clk;
            fifo2_write_strobe_plus_3clk <= fifo2_write_strobe_plus_2clk;
            fifo2_write_strobe_plus_4clk <= fifo2_write_strobe_plus_3clk;
	    ro_cap_id_plus_1clk <= ro_cap_id;
	    ro_cap_id_plus_2clk <= ro_cap_id_plus_1clk;
 	    ro_cap_id_plus_3clk <= ro_cap_id_plus_2clk;
	    counter_keep_bx_plus_1clk <= counter_keep_bx;
	    read_blk_ready_plus_1clk <= read_blk_ready;
            done_out <= done_out_int;
        end if;
    end process;

    
    
    -- JRF some processes to manage counters and lengths fifo
    -- JRF note that we must store the block lengths in a fifo to handle reading of odd length blocks, we do that by controlling the fifo1_blk_length_write bit.
    process(clk_p)
    begin
       if rising_edge(clk_p) then
           if (rst_p_int = '1') or (state_main_prev2 = ST_IDLE)  then 
               counter_fifo1_write <= (others => '0');
               zs_fifo1_blk_length_wen <= '0';
               block_length <= (others => '0');
           elsif  dbus_plus_3clk.data.strobe = '1' -- don't do anything if there is no strobe
               and ( ( (state_main_prev2 = ST_DATA) and (state_main_prev3 = ST_INIT) and (counter_fifo1_write = 0) )
               or  ( (state_main_prev2 = ST_DATA) and (state_main_prev3 = ST_DATA) and (counter_fifo1_write = 1) ) ) then -- first data word
               -- set the counter from the length in the 3clock pipelined data. 
               -- we also store the captureid for later use during ZS of this block
               zs_fifo1_blk_length_wen <= '1';
               counter_fifo1_write <= unsigned(dbus_plus_3clk.data.data(23 downto 16)) + 1; --JRF replace this by the output of the fifo1_blk_length fifo.
               block_length <= unsigned(dbus_plus_3clk.data.data(23 downto 16)) + 1; --JRF replace this by the output of the fifo1_blk_length fifo. -- store the length to use for the transfer from fifo1 to fifo2 header contains N-1
               
           elsif state_main_prev2 = ST_DATA and dbus_plus_3clk.data.strobe = '1' then -- only decrement on strobe
               counter_fifo1_write <= counter_fifo1_write - 1;
               zs_fifo1_blk_length_wen <= '0';

           else 
               
               zs_fifo1_blk_length_wen <= '0';

           end if;
       end if;
    end process;    
    
    
    -- JRF process to manage capid and mask read address:
    process(clk_p)
    begin
       if rising_edge(clk_p) then
           if (rst_p_int = '1') or (state_main = ST_IDLE)  then 
               counter_cap_id <= (others => '0');
               ro_cap_id <= (others => '0');
               
               ro_mask_read_addr <= (others => '0');
           elsif  dbus_plus_1clk.data.strobe = '1' -- don't do anything if there is no strobe
               and ( ( (state_main = ST_DATA) and (state_main_prev = ST_INIT) and (counter_cap_id = 0) )
                   or  ( (state_main = ST_DATA) and (state_main_prev = ST_DATA) and (counter_cap_id = 1) ) ) then -- first data word
              
               ro_cap_id <=  unsigned(dbus_plus_1clk.data.data(11 downto 8)); -- note that cap id is 4 bits only, despite what it says in the manual
               counter_cap_id <= unsigned(dbus_plus_1clk.data.data(23 downto 16)) + 1;
               ro_mask_read_addr <=    std_logic_vector(  resize((unsigned(dbus_plus_1clk.data.data(11 downto 8)) + 1) * 6,ro_mask_read_addr'length) + resize(( 5 - ((counter_cap_id-2) mod 6)), ro_mask_read_addr'length  ) );
                            
           elsif state_main = ST_DATA and dbus_plus_1clk.data.strobe = '1' then -- only decrement on strobe
               counter_cap_id <= counter_cap_id - 1;
               ro_mask_read_addr <=    std_logic_vector(  resize(ro_cap_id * 6,ro_mask_read_addr'length) + resize(( 5 - ((counter_cap_id-2) mod 6)), ro_mask_read_addr'length  ) );
                              
           else 
               --do nothing
           end if;
       end if;
    end process;    
    
-- JRF process to manage the mask read address based upon capture id
--    process(clk_p)
--    begin
--        if rising_edge(clk_p) then
--            if (rst_p_int = '1')  then 
--                ro_mask_read_addr <= (others => '0');
--            else
--                ro_mask_read_addr <=    std_logic_vector(  resize(ro_cap_id * 6,ro_mask_read_addr'length) + resize(( 5 - ((counter_cap_id-2) mod 6)), ro_mask_read_addr'length  ) );
--            end if;
--        end if;
--    end process;
    

 -- JRF This is the new method to get counter fifo 1 read values from the fifo.
 -- JRF This process is used to get the block lengths from the zs_fifo_blk_length, not we need to get these as and when the previous read has finished.
--    process(clk_p)
--    begin
--       if rising_edge(clk_p) then
--           if (rst_p_int = '1') or (state_main_prev = ST_IDLE)  then
--		zs_fifo1_blk_length_ren <= '0'; 
--                read_blk_ready <= (others => '0'); 
--           elsif (  state_fifo_transfer_prev = ST_BLK_BLK_HEAD and read_blk_ready > 0 ) then 
--                -- set the counter from the length in the 1clock pipelined data. 
--	        if (done_blk_plus_1clk = '0') then
--			read_blk_ready <= read_blk_ready - 1;
--		end if;
--		zs_fifo1_blk_length_ren <= '1';
--           elsif (done_blk_plus_1clk = '1' and state_fifo_transfer_prev /= ST_BLK_BLK_HEAD) then
--		read_blk_ready <= read_blk_ready + 1;
--		zs_fifo1_blk_length_ren <= '0';	       
--           else 
--		zs_fifo1_blk_length_ren <= '0';
--	   end if;
--       end if;
--    end process;   

-- replaced the process above iwth this one, trying to set read enable 1clk earlier and then register the output of the fifo. 
    process(clk_p)
    begin
        if rising_edge(clk_p) then
           if (rst_p_int = '1') or (state_main = ST_IDLE)  then
                zs_fifo1_blk_length_ren <= '0'; 
                read_blk_ready <= (others => '0'); 
           elsif (  state_fifo_transfer = ST_BLK_BLK_HEAD and read_blk_ready > 0 ) then 
                -- set the counter from the length in the 1clock pipelined data. 
            if (done_blk = '0') then
                read_blk_ready <= read_blk_ready - 1;
            end if;
            zs_fifo1_blk_length_ren <= '1';
            elsif (done_blk = '1' and state_fifo_transfer /= ST_BLK_BLK_HEAD) then
                read_blk_ready <= read_blk_ready + 1;
                zs_fifo1_blk_length_ren <= '0';           
            else 
                zs_fifo1_blk_length_ren <= '0';
            end if;
        end if;
    end process;  
--JRF process to manage the zs_fifo1_blk_length_ren signal
-- process(clk_p)
--    begin
--       if rising_edge(clk_p) then
--           if (rst_p_int = '1') or (state_main_prev = ST_IDLE)  then
--               zs_fifo1_blk_length_ren <= '0';
--           elsif ( counter_fifo1_read = 0 and read_blk_ready > 0 ) then                                                      
--               -- set the counter from the length in the 1clock pipelined data. 
--               zs_fifo1_blk_length_ren <= '1';
--           else
--               zs_fifo1_blk_length_ren <= '0';
--           end if;
--       end if;
--    end process;

--JRF process to set the read enable for the counter_keep_blk fifo
--    process(clk_p)
--    begin
--       if rising_edge(clk_p) then
--           if (rst_p_int = '1') or (state_main_prev2 = ST_IDLE)  then
--               zs_fifo1_counter_keep_bx_ren <= '0';
               
--           elsif ( state_fifo_transfer_prev2 = ST_BLK_BLK_HEAD ) then 
--               zs_fifo1_counter_keep_bx_ren <= '1';
--           else
--               zs_fifo1_counter_keep_bx_ren <= '0';
--           end if;
--       end if;
--    end process;
    process(clk_p)
begin
   if rising_edge(clk_p) then
       if (rst_p_int = '1') or (state_main_prev = ST_IDLE)  then
           zs_fifo1_counter_keep_bx_ren <= '0';
           
       elsif ( state_fifo_transfer_prev = ST_BLK_BLK_HEAD ) then 
           zs_fifo1_counter_keep_bx_ren <= '1';
       else
           zs_fifo1_counter_keep_bx_ren <= '0';
       end if;
   end if;
end process;

    process(clk_p) -- JRF new method process to manage the counter_fifo1_Read
   begin
      if rising_edge(clk_p) then
           if (rst_p_int = '1') or (state_fifo_transfer_prev3 = ST_IDLE)  then 
               counter_fifo1_read <= (others => '0');
           else 
               if ( state_fifo_transfer_prev3 = ST_BLK_BLK_HEAD ) then -- JRF removing this cause it's now one clk too early. -- and zs_fifo1_blk_length_valid = '1' ) then --JRF Todo fix this, we might need another prev for state fifo transfer so that we don't miss the last word of data, we also need to use the correct state, should be ST_BLK_BLK_HEAD... I think.
                   counter_fifo1_read <= unsigned(zs_fifo1_blk_length_out(7 downto 0)) + 1;  
               elsif ( state_fifo_transfer_prev3 = ST_BLK_BX_DATA and counter_fifo1_read > 0 ) then 
                   counter_fifo1_read <= counter_fifo1_read - 1;--JRF NOTE: decrement only in BLK_BLK_HEAD and BLK_BX_DATA, not in BLK_BX_HEAD, since we are creating these words that don't exist in the fifo1
               end if; 
              
           end if;
      end if;
    end process;

--JRF process to capture and store the first header word
    process(clk_p)
    begin
        if rising_edge(clk_p) then
            if (rst_p_int = '1')  then
                first_header_word.data.data <= (others => '0');
                first_header_word.data.valid <= '0';
                first_header_word.data.start <= '0';
                first_header_word.init <= '0';
            	first_header_word.token <= '0';
            	first_header_word.data.strobe <= '0';
                ro_mode_id <= (others => '0'); -- we will grab the mode at the same time
           elsif state_main = ST_HDR and state_main_prev = ST_IDLE and daq_bus_in.data.strobe = '1' and daq_bus_in.data.start = '1' then -- JRF if this is the first word store the data for later
                first_header_word  <= dbus_plus_1clk; --daq_bus_in; 
		        -- this header word contains the length that we should replace with  total_length later before we push this out.
           elsif state_main_prev3 = ST_IDLE and state_main_prev2 = ST_HDR then
                ro_mode_id <= unsigned(daq_bus_in.data.data(7 downto 0));
           end if;
       end if;
    end process;

--JRF process to fire done_blk
    process(clk_p)
    begin
       if rising_edge(clk_p) then
           if (rst_p_int = '1') or (state_main_prev3 = ST_IDLE) then 
                done_blk <= '0';
           elsif state_main_prev3 = ST_DATA and dbus_plus_4clk.data.strobe = '1' and  counter_fifo1_write = 1 then -- JRF if this is the first word store the data for later
                done_blk <= '1'; 
		   else
		        done_blk <= '0';
           end if;
       end if;
    end process;

    --JRF TODO we will need to fix the total length to include the new BX HEADERS etc... unless it comes entirely from fifo2_wen. check that this is ok now. 
    process(clk_p) -- process to manage the total_length. This is incremented when we write into fifo2 only when not writing INIT words
    begin
       if rising_edge(clk_p) then
            if (rst_p_int = '1') or (state_main_prev2 = ST_IDLE) then
                total_length <= (others => '0'); -- we are starting a new event so we must reset the total event length count 
                init_length  <= (others => '0');                     
            elsif (zs_fifo2_wen = '1' ) then 
                if (state_main_prev2 = ST_INIT)  then -- TODO check this. do not increment for init words
                    init_length <= init_length + 1;
                else
                    total_length <= total_length + 1;
                end if;
            end if;
       end if;
    end process;
    
-- JRF process to write header and init words directly to fifo2.   This works in conjunction with two state_main.
    process(clk_p)
    begin
       if rising_edge(clk_p) then
            if (rst_p_int = '1') or (state_main = ST_IDLE) then -- JRF if this is the first word we don't need to put it in fifo2, we will add this later when we push data out. 
                    dbus_zs_fifo2_in_pre1 <= (others => '0');    
                    zs_fifo2_wen_pre1 <= '0'; -- no need to write to fifo2
                    
            elsif state_main = ST_HDR then -- JRF if this is the remaining 5 words of the header we store the header directly in fifo2
                if daq_bus_in.data.strobe = '1' then
                    dbus_zs_fifo2_in_pre1  <=   daq_bus_in.data.valid & 
                                                daq_bus_in.data.start &
                                                daq_bus_in.init &
                                                daq_bus_in.data.strobe &
                                                daq_bus_in.data.data; -- output the data
                    zs_fifo2_wen_pre1 <= '1'; -- enable  write to fifo
                else
                    zs_fifo2_wen_pre1 <= '0';
                end if;
            elsif state_main = ST_INIT then  
                if  dbus_plus_1clk.init = '1'  then -- in this state we have to store the stat word if the INIT bit is set only  
                    dbus_zs_fifo2_in_pre1  <=   dbus_plus_1clk.data.valid & 
                                                dbus_plus_1clk.data.start &
                                                dbus_plus_1clk.init &
                                                dbus_plus_1clk.data.strobe &
                                                dbus_plus_1clk.data.data; -- note that we don't need strobe for init to be valid
                    zs_fifo2_wen_pre1 <= '1'; -- enable  write to fifo2
                else 
                    zs_fifo2_wen_pre1 <= '0';
                end if;
            end if;
        end if;
    end process;
    
    --JRF process to count BXs to be kept. We do this by counting the keep_bx signal when writing to the fifo.Once we finish the block we store the value in the fifo for later use during the transfer
    process(clk_p)
    begin
	if rising_edge(clk_p) then
            if (rst_p_int = '1')  then-- and zs_fifo1_keep_bx_in(0) = '1') then -- JRF reset the counter at end of each block, we then need to pipeline the result for use in the transfer
	   	counter_keep_bx <= (others => '0'); 
		zs_fifo1_counter_keep_bx_wen <= '0';
		zs_fifo1_counter_keep_bx_in <= (others => '0');
	    elsif (done_blk_plus_1clk = '1' ) then
		counter_keep_bx <= (others => '0');
		zs_fifo1_counter_keep_bx_wen <= '1'; 
		zs_fifo1_counter_keep_bx_in <= std_logic_vector(counter_keep_bx);
	    elsif ( zs_fifo1_keep_bx_wen = '1') then -- JRF there are two cases:
		if ( std_logic(cap_en(to_integer(ro_cap_id_plus_3clk))) = '0' ) then --JRF Case 1: ZS disabled for cap ID, in this case we don't insert the BX headers so we only increment by 6
		    	counter_keep_bx <= counter_keep_bx + "00000110" ;
		elsif (zs_fifo1_keep_bx_in(0) = '1' or (ro_mode_id = ro_val_mode_id) ) then --JRF Case 2: ZS Enabled for cap ID AND keep bx is true, or we are in a validation event. We add 7 words for each BX
			counter_keep_bx <= counter_keep_bx + "00000111"; 
		end if;
		zs_fifo1_counter_keep_bx_wen <= '0';
		zs_fifo1_counter_keep_bx_in <= (others => '0');
	    else 
		zs_fifo1_counter_keep_bx_wen <= '0';
                zs_fifo1_counter_keep_bx_in <= (others => '0');
	    end if;
	end if;
    end process;

--JRF process to write data to fifo1 and work out if we want to suppress this block
--JRF  we must now make a decision to keep or not for each BX within the block, so we make a decision to keep or not on each 6 words. 
--JRF TODO, we also need a signal to trigger for each BX that is high one clock before the  
    process(clk_p)
    begin
       if rising_edge(clk_p) then
            if (rst_p_int = '1') or (state_main_prev3 /= ST_DATA) then -- reset
                zs_fifo1_wen <= '0'; 
                dbus_zs_fifo1_in  <= (others => '0');
                keep_blk <='0'; -- default is to discard blocks
                zs_fifo1_keep_bx_wen <= '0'; 
	  	zs_fifo1_keep_bx_in <= (others => '0'); 
            elsif (state_main_prev3 = ST_DATA) then
                if (dbus_plus_4clk.data.strobe = '1') then
                    zs_fifo1_wen <= '1'; 
                    dbus_zs_fifo1_in  <=    dbus_plus_4clk.data.valid & 
                                            dbus_plus_4clk.data.start &
                                            dbus_plus_4clk.init &
                                            dbus_plus_4clk.data.strobe &
                                            dbus_plus_4clk.data.data;
                    if (counter_fifo1_write < block_length) then -- skip the block header when deciding whether to keep block --JRF we must now send out the keep block for each BX. that means resetting it after each BX. 
                        if (((counter_fifo1_write-1) mod 6) = 0 ) then --JRF This case is to reset after each 6 words, we also take the opportunity to push the data into the fifo at the same time.
		    	    keep_blk <= '0'; --reset for each group of 6 words in the block (each BX)
			    if (data_complement = '1') then --JRF when complement is set we must invert the data before comparrison, note we don't invert the data when storing it later.
				zs_fifo1_keep_bx_in <= '1' & (keep_blk or (or_reduce( ( not dbus_plus_4clk.data.data ) and ro_mask_plus_1clk)) ); --JRF TODO check timing of the masks and change this when we change the fifo to 2 bits. bit 1 flags complement
			    else
				zs_fifo1_keep_bx_in <= '0' & (keep_blk or (or_reduce(dbus_plus_4clk.data.data and ro_mask_plus_1clk)) ); --JRF TODO check timing of the masks and change this when we change the fifo to a 1 bit fifo.
			    end if;
		 	    zs_fifo1_keep_bx_wen <= '1';
			else
		    	    if (data_complement = '1') then --JRF when complement is set we must invert the data before comparrison, note we don't invert the data when storing it later.
			        keep_blk <= keep_blk or (or_reduce( ( not dbus_plus_4clk.data.data ) and ro_mask_plus_1clk)); -- or all the bits in data keep if anything is non-zero
			    else
				keep_blk <= keep_blk or (or_reduce(dbus_plus_4clk.data.data and ro_mask_plus_1clk)); -- or all the bits in data keep if anything is non-zero
			    end if;
			    zs_fifo1_keep_bx_wen <= '0';
			end if;
		    else
                        --use this opportunity to clear the keep_blk
                        keep_blk <= '0';
			zs_fifo1_keep_bx_wen <= '0';
                    end if;
                    
                else
                    zs_fifo1_wen <= '0';
                    zs_fifo1_keep_bx_wen <= '0';
                end if;
            end if;
        end if;
    end process;
   
    --JRF NOTE: we must only read when we are in BLK_HEAD state and BX_DATA state, but not when we are creating the BX_HEAD.  
    process(clk_p) -- process to enable read from fifo 1 to go to fifo 2
    begin
        if rising_edge(clk_p) then
            if (rst_p_int = '1') or (state_fifo_transfer_prev2 = ST_IDLE) or (state_fifo_transfer_prev2 = ST_DONE) then
                zs_fifo1_ren <= '0';
                dbus_zs_fifo2_in_pre2 <= (others => '0');
            elsif ( state_fifo_transfer_prev2 = ST_BLK_BLK_HEAD ) then --JRF NOTE we only read the blk header once at the start, the counter is still 0 at this point it takes the start value in the next clock cycle
		zs_fifo1_ren <= '1';
	    elsif ( state_fifo_transfer_prev2 = ST_BLK_BX_DATA ) then --JRF TODO we don't want to read when writing bx headers. we should also be sure that the timing of the ren is correct.. should be ok.
                if (counter_fifo1_read > 0) then 
                    zs_fifo1_ren <= '1';
                else
                    zs_fifo1_ren <= '0';
                end if;
	    elsif (state_fifo_transfer_prev2 = ST_BLK_BX_HEAD ) then --JRF we pop off the keep bx result from the fifo1_keep_bx fifo. JRF TODO, we might want to add the check of the counter to be sure.
		zs_fifo1_ren <= '0';
            else
		zs_fifo1_ren <= '0';
	    end if;
            dbus_zs_fifo2_in_pre2 <= dbus_zs_fifo1_out; -- always pass the fifo1 out to the fifo2_in_pre.
           --JRF removing this --  zs_fifo2_wen_pre2_minus1clk <= zs_fifo1_ren; -- this simply assures that the read enable is always 1clock after the write enable. --JRF TODO, be aware that we also need to enable the wen for fifo2 when writing BX headers, this alone is not enough.
        end if;
    end process;  
              
    process(clk_p) -- process to read keep bx decision for this BX. need this early to decide.
    begin
        if rising_edge(clk_p) then
            if (rst_p_int = '1') or (state_fifo_transfer = ST_IDLE) or (state_fifo_transfer = ST_DONE) then
                zs_fifo1_keep_bx_ren <='0';
            elsif (state_fifo_transfer = ST_BLK_BX_HEAD ) then --JRF we pop off the keep bx result from the fifo1_keep_bx fifo. JRF TODO, we might want to add the check of the counter to be sure.
                zs_fifo1_keep_bx_ren <='1';
            else
                zs_fifo1_keep_bx_ren <='0';
            end if;
        end if;
    end process;
    
    process(clk_p) -- process to create the fifo2_write_strobe
    begin
        if rising_edge(clk_p) then
            if (rst_p_int = '1') or (state_fifo_transfer_prev2 = ST_IDLE) then --JRF TOOD, check if we need to use a prev value here.
                fifo2_write_strobe <= '0';
            elsif  (state_fifo_transfer_prev2 = ST_BLK_BX_HEAD 
		and ((zs_fifo1_keep_bx_valid = '1' and zs_fifo1_keep_bx_out(0) = '1') --JRF TODO, check if this is enough 
                or ( zs_fifo1_keep_bx_valid = '1' and ( (ro_mode_id = ro_val_mode_id) or ( cap_en(to_integer(unsigned(zs_fifo1_blk_length_out (11 downto 8)))) = '0') ) ) ) )-- we only trigger strobe in this case for validation events and if the capid_en is 0 for that capture_id. keep_bx is 0, but we want to keep data and tag it
                or ( fifo2_write_strobe = '1' and counter_fifo1_read > 1 and zs_fifo1_keep_bx_valid = '0') then --JRF TODO might need to change the counter fifo1 read check to make sure we end at the right moment. --note we are latching on the write strobe for each block of 6 words so keep blk need only be high for 1 clock to trigger
                fifo2_write_strobe <= '1';
            else
                fifo2_write_strobe <= '0';
            end if;
        end if;
    end process;
   

    process(clk_p) -- process merge data and write enable bit for fifo2
    begin
        if rising_edge(clk_p) then
             if (rst_p_int = '1') or (state_main = ST_IDLE) then
                   dbus_zs_fifo2_in <= (others => '0');
                   zs_fifo2_wen <= '0';
             else
                if (state_main /= ST_HDR and state_main /= ST_INIT and state_fifo_transfer_prev5 = ST_BLK_BLK_HEAD and zs_fifo1_counter_keep_bx_out(7 downto 0) /= "00000000") then --JRF NOTE we only write BLK HEaders for those blocks which have some BXs to keep
			         --JRF NOTE we always write the block header, we must overwrite the length in here from our counter_keep_bx value
		            zs_fifo2_wen <= '1';
		            dbus_zs_fifo2_in <=  dbus_zs_fifo2_in_pre2(35 downto 24)  
					                   & std_logic_vector( zs_fifo1_counter_keep_bx_out(7 downto 0) ) --JRF this is the calculated length of the block not including the block header, so it's just the number of BXs * 2 + 1 (plus one BX header ) unless cap id is disabled in which case it's only Bx * 2.
					                   & dbus_zs_fifo2_in_pre2(15 downto 2) 
					                   & std_logic(cap_en(to_integer(unsigned(zs_fifo1_blk_length_out (11 downto 8))))) 
					                   & ( std_logic(cap_en(to_integer(unsigned(zs_fifo1_blk_length_out (11 downto 8))))) and zs_fifo1_keep_bx_out(1))  ;--JRF set bit 0 to 1 for capids with data_complement bit set
		             --JRF block header with new length. NOTE that we only set bit 1 to true for those cap ids which have ZS enabled.

		        elsif (state_main /= ST_HDR and state_main /= ST_INIT and state_fifo_transfer_prev5 = ST_BLK_BX_HEAD 
			            and cap_en(to_integer(unsigned(zs_fifo1_blk_length_out (11 downto 8)))) = '1' --JRF NOTE we only add BX headers for cap ids which are ZS enabled 
                        and zs_fifo1_keep_bx_out_plus_2clk = '0' -- JRF TODO, confirm this delay is correct when we have a keepBX signal to test. -- and keep_blk_plus_5clk = '0'
                        and fifo2_write_strobe_plus_2clk = '1') then -- JRF NOTE, this is the case where we want to write the data because they are either validation or from a capid which has ZS disabled
		            dbus_zs_fifo2_in <=  "1001" & std_logic_vector((unsigned(zs_fifo1_blk_length_out (7 downto 0)) - (counter_fifo1_read ))) & std_logic_vector(unsigned(zs_fifo1_blk_length_out (7 downto 0))) & "000000000000000" & std_logic(cap_en(to_integer(unsigned(zs_fifo1_blk_length_out (11 downto 8)))));--JRF Note we stored the cap_id in the upper 4 bits 
                    zs_fifo2_wen <= '1';
                elsif (state_main /= ST_HDR and state_main /= ST_INIT and state_fifo_transfer_prev5 = ST_BLK_BX_HEAD) 
			             and cap_en(to_integer(unsigned(zs_fifo1_blk_length_out (11 downto 8)))) = '1' --JRF NOTE we only add BX headers for cap ids which are ZS enabled 
			             and zs_fifo1_keep_bx_out_plus_2clk = '1' -- JRF, Note we keep these blocks if the decision to keep them was taken and we write them in with no validation bit
                         and fifo2_write_strobe_plus_2clk = '1' then
                    dbus_zs_fifo2_in <=  "1001" & std_logic_vector((unsigned(zs_fifo1_blk_length_out (7 downto 0)) -( counter_fifo1_read))) & std_logic_vector(unsigned(zs_fifo1_blk_length_out (7 downto 0))) & "0000000000000000"; --JRF TODO, add the other flags
		            zs_fifo2_wen <= '1';
	 	        elsif (state_main /= ST_HDR and state_main /= ST_INIT and state_fifo_transfer_prev5 = ST_BLK_BX_DATA and fifo2_write_strobe_plus_2clk = '1') then -- only transfer data if needed
                    dbus_zs_fifo2_in <= dbus_zs_fifo2_in_pre2;--JRF TODO, check the timing of the data from the fifo1 output, so that we get the right words in time.
                    zs_fifo2_wen <= '1'; --JRF just overriding the old value for now -- zs_fifo2_wen_pre2;
                elsif ( state_main = ST_HDR or state_main = ST_INIT ) then
                    dbus_zs_fifo2_in <= dbus_zs_fifo2_in_pre1;
                    zs_fifo2_wen <= zs_fifo2_wen_pre1;
                else
                    zs_fifo2_wen <= '0';
                end if;
             end if;
        end if;
    end process;

--JRF TODO, may not need this -- Added this process to break up the big combinatorial in the process above into smaller steps
--    process(clk_p) -- process merge data and write enable bit for fifo2
--    begin
--        if rising_edge(clk_p) then
--            if (rst_p_int = '1') or (state_main = ST_IDLE) then
--	    
--		else
--		
--	    end if;
--	end if;
--    end process;
--
end generate;

    zs_fifo1_blk_length_in <= std_logic_vector(ro_cap_id) & dbus_plus_4clk.data.data(23 downto 16);
    en <= ctrl(0)(0); -- ZS enable or disable
    ro_val_mode_id <= unsigned(ctrl(0)(27 downto 20)); -- mode ID on which to output validation events
    cap_en <= ctrl(0)(19 downto 4); -- 16 enable bits one for each capid
--JRF replaced this iwth a bit in the mask ram --    data_complement <=  ctrl(0)(1); -- invert data before masking to look for hits, note we revert the complement before outputting the data.

    process(clk_p)
    begin
        if rising_edge(clk_p) then
            rst_p_int <= rst_p; -- we have added this to try to help meet timing.
        end if;
    end process;


end rtl;
