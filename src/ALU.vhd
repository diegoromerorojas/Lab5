----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
-- include components
component ripple_adder is
    Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
           B : in STD_LOGIC_VECTOR (7 downto 0);
           Cin : in STD_LOGIC;
           S : out STD_LOGIC_VECTOR (7 downto 0);
           Cout : out STD_LOGIC);
end component ripple_adder;

--declare signals
    signal w_sum         : std_logic_vector(7 downto 0);
	signal w_Cin, w_Cout : std_logic; -- might not need these
	
	-- ALU Control 00 & 01 signals
	signal w_b : std_logic_vector(7 downto 0);
	signal w_Bmux_o : std_logic_vector(7 downto 0);
	signal w_adder_result : std_logic_vector (7 downto 0);
	
	-- ALU Controller Signals
	signal w_result : std_logic_vector (7 downto 0);

begin
---------------Port Maps-------------------------
   ripple_adder_uut : ripple_adder port map (
	   A    => i_A,
	   B    => w_Bmux_o,
	   Cin  => i_op(0),
	   S    => w_adder_result,
	   Cout => w_Cout
	);
    


----------------Concurrent Statements------------


w_Bmux_o <= i_B when (i_op(0) = '0') else
            NOT i_B   when (i_op(0) = '1') else
            "00000000";
            
            
w_result <= w_adder_result  when (i_op = "000") else
            w_adder_result  when (i_op = "001") else
            (i_A AND i_B)       when (i_op = "010") else
            (i_A OR i_B)        when (i_op = "011") else
            "00000000";
            
o_result <= w_result;     

      
o_flags(3)  <=  '1' when (w_result(7)= '1') else
                '0';      --negative

o_flags(2)  <=  '1' when (w_result = "00000000" ) else
                '0';                -- zero
                
o_flags(1)  <= '1' when (i_op = "000" or i_op = "001") AND (w_Cout = '1') else
               '0';  -- carry out

o_flags(0)  <= '1' when (i_op = "000" or i_op = "001") 
                        AND (i_A(7) XOR w_adder_result(7)) = '1' 
                        AND ( ( (i_A(7) XNOR i_B(7)) AND ( NOT i_op(0)) ) or ( (i_A(7) XOR i_B(7)) AND i_op(0))) = '1' else
                '0';  -- overflow V
end Behavioral;
