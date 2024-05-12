----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2024 13:12:00
-- Design Name: 
-- Module Name: conta_generic - Behavioral
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

entity conta_generic is
    generic (fin_conta: natural := 10**7; -- frecuencia inicial es 100MHz y queremos la f de 1 decima de segundo, la nueva frecuencia será de 10*10e6
            n_bits: natural := 24; -- la menos potencia de 2 superior a 10e6 es 24 -->2^3<10e6<2^4
            max: unsigned:="1001");
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           enable : in std_logic; -- señal del contador anterior
           up_down: in std_logic; -- interruptor de cuenta ascendente/descendente SW OFF = ASCENDENTE, SW ON= DESCENDENTE
           sconta : out STD_LOGIC; --emitirá una señal/pulso cada periodo, si es s1dec, emirtira un pulso cada decima de segundo, si es s1seg emitira un un pulso cada segundo.. 
           vconta : out unsigned (n_bits-1 downto 0)); -- tendrá los bits necesarios para contar hasta el valor deseado y mostrarlo luego en los displays. se realiza a partir de la señal s-conta. 
end conta_generic;

architecture Behavioral of conta_generic is
-- señales intermedias
    signal contador: unsigned (n_bits-1 downto 0); -- señal que lleva la cuenta, debe tener un rango potencia de 2. 
    signal s_conta : std_logic;
   
 
begin
-- descripcion del contador
P_contageneric: process (clk, rst)
begin
    if rst ='1' then
        contador <= (others=>'0');
    elsif clk'event and clk='1' then
        if enable='1' then 
            if up_down ='0' then   
                if s_conta='1' then
                contador<=(others=>'0');
                else
                contador<=contador + 1;
                end if;
            else -- si up_down esta en 1 
                if s_conta='1' then
                contador<=max;
                else
                contador<=contador-1;
                end if;
            end if;
        end if;
    end if;
end process;
s_conta<='1' when contador = fin_conta-1 and enable ='1' and up_down='0' else
          '1' when contador = 0 and enable ='1' and up_down ='1' else '0';  
sconta<=s_conta;
vconta<=contador;
end Behavioral;
