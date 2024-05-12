----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.04.2024 10:30:55
-- Design Name: 
-- Module Name: sincro_vga - Behavioral
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
library WORK;
use WORK.VGA_PKG.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sincro_vga is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           col : out unsigned (9 downto 0);
           fila : out unsigned (9 downto 0);
           visible : out STD_LOGIC;
           hsinc : out STD_LOGIC;
           vsinc : out STD_LOGIC);
end sincro_vga;

architecture Behavioral of sincro_vga is

-- COMPONENTE CONTADOR
component conta_generic 
        generic (fin_conta: natural := 10**6; 
            n_bits: natural := 24;
            max: unsigned:="1001");
        Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           enable : in std_logic; -- señal del contador anterior
           up_down: in std_logic; -- señal de cuenta ascendente/descendente SW OFF = ASCENDENTE, SW ON= DESCENDENTE
           sconta : out STD_LOGIC; --emitirá una señal/pulso cada periodo, si es s1dec, emirtira un pulso cada decima de segundo, si es s1seg emitira un un pulso cada segundo.. 
           vconta : out unsigned (n_bits-1 downto 0)); -- tendrá los bits necesarios para contar hasta el valor deseado y mostrarlo luego en los displays. se realiza a partir de la señal s-conta. Será de 4 bits porque las cuentas serán de 0 a 9 como maximo
    end component;

--SEÑALES INTERMEDIAS--
    signal conta_4clk: unsigned (1 downto 0);
    signal new1pxl: std_logic; --acaba la cuenta del primer contador
    signal fincuenta_conta4clk: natural:=4; -- fin cuenta cuando llega a 4
    
    signal conta_800pxl: unsigned(9 downto 0); -- cuenta 800 pixeles que son = a 1 linea (columnas)
    signal new1line: std_logic; --cuenta 1 linea, acaba la cuenta del 2 contador
    signal new1line_1: std_logic; -- para alineardo con new1pxl y new1line
     
    signal conta_520line: unsigned(9 downto 0); --cuenta 520 linea (filas)  = 1 pantalla
    signal visiblepxl: std_logic; --indica si esta el pixl en zona visible (linea)
    
    signal s_vsinc: std_logic; 
    signal visibleline: std_logic; 
       
begin
-- Instanciamos los contadores--
P_conta1pixel: conta_generic
    generic map (fin_conta=>4, n_bits=>2, max=>"11")
    Port map (
        clk=>clk,
        rst=>rst,
        enable=>'1',
        up_down=>'0',
        sconta=>new1pxl,
        vconta=>conta_4clk);
        
P_conta1linea: conta_generic
    generic map (fin_conta=>c_pxl_total, n_bits=>c_nb_pxls, max=>"0000001001")
    Port map (
        clk=>clk,
        rst=>rst,
        enable=>new1pxl,
        up_down=>'0',
        sconta=>new1line,
        vconta=>conta_800pxl);
     new1line_1<=new1line and new1pxl;
     
P_conta1pantalla: conta_generic
    generic map (fin_conta=>c_line_total, n_bits=>c_nb_lines, max=>"0000001001")
    Port map (
        clk=>clk,
        rst=>rst,
        enable=>new1line_1,
        up_down=>'0',
        sconta=>s_vsinc,
        vconta=>conta_520line);
        
--SINCRONISMOS--
hsinc<='0' when (conta_800pxl>=c_pxl_2_fporch and conta_800pxl< c_pxl_2_synch) else '1';
vsinc<='0' when (conta_520line>=c_line_2_fporch and conta_520line<c_line_2_synch) else '1';
--ZONA VISIBLE--
visiblepxl<='1' when conta_800pxl<c_pxl_visible else '0';
visibleline<='1' when conta_520line<c_line_visible else '0';

--escribimos salida--
col<=conta_800pxl;
fila<=conta_520line;

visible<=visiblepxl and visibleline;


end Behavioral;
