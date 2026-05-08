--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
    -- signal declarations
    signal w_clk : std_logic;
    signal w_action: std_logic;
    signal w_cycle : std_logic_vector (3 downto 0);
    
    --mux 1
    signal w_result : std_logic_vector (7 downto 0);
    signal w_muxresult : std_logic_vector (7 downto 0);
    
    --registers
    signal w_register1 : std_logic_vector (7 downto 0):= "00000001";    
    signal w_register2 : std_logic_vector (7 downto 0):= "00000000";  
    
    --twos comp
    signal w_sign : std_logic;
    signal w_hund : std_logic_vector (3 downto 0);
    signal w_tens : std_logic_vector (3 downto 0);
    signal w_ones : std_logic_vector (3 downto 0);
    
    -- TDM
    signal w_data : std_logic_vector (3 downto 0);
    signal w_sel : std_logic_vector (3 downto 0);
    
    -- seven seg
    signal w_seg : std_logic_vector (6 downto 0);
  
    -- mux 2
    signal w_mux2result : std_logic_vector(6 downto 0);
      
	-- component declarations
    component clock_divider is
       generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
											   -- Effectively, you divide the clk double this 
											   -- number (e.g., k_DIV := 2 --> clock divider of 4)
	   port ( 	i_clk    : in std_logic;
			i_reset  : in std_logic;		   -- asynchronous
			o_clk    : out std_logic		   -- divided (slow) clock
	);
    end component clock_divider;
    
    component controller_fsm is
    
        Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
           
    end component controller_fsm;
    
    component ALU is
    
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
    
    end component ALU;
    
    component twos_comp is
    
    port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
    
    end component twos_comp;
    
    component TDM4 is
    
    generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
    
    end component TDM4;
    
    component sevenseg_decoder is
    
    Port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0):= (others=> '0');
           o_seg_n : out STD_LOGIC_VECTOR (6 downto 0):= (others=> '0'));
    
    end component sevenseg_decoder;
    
    component button_debounce is
    
    Port(	clk: in  STD_LOGIC;
			reset : in  STD_LOGIC;
			button: in STD_LOGIC;
			action: out STD_LOGIC);
			
    end component button_debounce;
begin
	-- PORT MAPS ----------------------------------------
    button_debounce_inst : button_debounce
	port map(
	--inputs
	reset    =>  btnU,
	button   =>  btnC,
	clk      =>  clk,
	--outputs
    action   =>  w_action
	);
	
	controller_fsm_inst : controller_fsm
	port map(
	--inputs
	i_reset    =>  btnU,
	i_adv      =>  w_action,
	--outputs
	o_cycle    =>  w_cycle
	);
	
	clock_divider_inst : clock_divider
	generic map (k_DIV => 200000)
	port map(
	-- inputs
	i_clk      =>  clk,
	i_reset    =>  btnU,
	-- outputs
	o_clk      =>  w_clk
	);
	
	ALU_inst : ALU
	port map(
	-- inputs
	i_A    =>  w_register1, 
	i_B    =>  w_register2,
	i_op   =>  sw(2 downto 0),
	-- outputs
	o_flags    =>  led(15 downto 12),
	o_result   =>  w_result
	);
	
	-----------------implement mux 1 here------------------------
	
	twos_comp_inst : twos_comp
	port map(
	-- inputs
	i_bin  =>  w_muxresult,
	-- outputs
	o_sign =>  w_sign,
	o_hund =>  w_hund,
	o_tens =>  w_tens,
	o_ones =>  w_ones
	);
	
	--implement TDM4
	TDM4_inst : TDM4
	port map(
	---inputs
	i_clk  =>  w_clk,
	i_reset => btnU,
	i_D3(0)   =>   w_sign,
	i_D3(1)   =>   '0',
	i_D3(2)   =>   '0',
	i_D3(3)   =>   '0',
	i_D2   =>  w_hund,
	i_D1   =>  w_tens,
	i_D0   =>  w_ones,
	---outputs
	o_data =>  w_data,
	o_sel  =>  w_sel
	);
	
	sevenseg_decoder_inst : sevenseg_decoder
	port map(
	---inputs
	i_hex      =>  w_data,
	---outputs
	o_seg_n    =>  w_seg
	);
	
	
	-- CONCURRENT STATEMENTS ----------------------------
	led(3 downto 0)    <=  w_cycle;
	an(2 downto 0)     <=  "111" when (w_cycle = "0001") else
	                        w_sel(2 downto 0); --- add logic to turn off displays when state = 0001
	an(3)              <=  '0'   when(w_cycle = "1000") else
	                       '1';
	
	----mux1
	--- deciding what to output based on current controller fsm state
	w_muxresult <= w_result         when (w_cycle = "1000") else
                   w_register1      when (w_cycle = "0010") else
                   w_register2      when (w_cycle = "0100") else
                   "00000000";

                   
    ------mux2
    seg             <= "0111111"      when (w_seg(0) = '1' AND w_sel = "0111") else
                        w_seg;
    
	-- PROCESSES ------------------------------------------------------------------------------------------	
	
	-- State register ------------
	
	-- state memory w/ synchronous reset ---------------
	register_proc1 : process (w_action, w_cycle)
	begin
	   if      (w_cycle(0) = '1' and rising_edge (w_action) )then
	               w_register1 <= sw(7 downto 0);
	  	           end if;
	end process register_proc1;
	
	register_proc2 : process (w_action, w_cycle)
	begin
	   if      (w_cycle(1) = '1' and rising_edge (w_action) )then
	               w_register2 <= sw(7 downto 0);
	               end if;		 
	             
	end process register_proc2;
	-------------------------------------------------------------------------------------------------------

end top_basys3_arch;
