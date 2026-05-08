----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is
 -- declare type
 	type sm_state is (s_state1, s_state2, s_state3, s_state4);
 
 -- declare signals
    signal f_Q, f_Q_next: sm_state := s_state1;
    
begin

    -- Next State Logic
            f_Q_next <= s_state2 when (i_adv = '1' AND f_Q = s_state1) else
                        
                        s_state3 when (i_adv = '1' AND f_Q = s_state2) else
                        
                        s_state4 when (i_adv = '1' AND f_Q = s_state3) else
                        
                        s_state1 when (i_adv = '1' AND f_Q = s_state4) else
                        
                        f_Q      when (i_adv = '0') else
                        
                        s_state1; -- default case
	-- Output logic
        with f_Q select
            o_cycle <=  "0001" when s_state1,
                        "0010" when s_state2,
                        "0100" when s_state3,
                        "1000" when s_state4,
                        "0010" when others; -- default is state 1

	-- PROCESSES ------------------------------------------------------------------------------------------	
	
	-- State register ------------
	state_register : process(i_adv, i_reset)
	begin
           if i_reset = '1' then
               f_Q <= s_state1;
           end if;
           
           if rising_edge(i_adv) then
               f_Q <= f_Q_next;            
            end if;
            
	end process state_register;
	
	
	
	-------------------------------------------------------------------------------------------------------

end FSM;
