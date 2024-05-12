----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.04.2024 19:52:14
-- Design Name: 
-- Module Name: circuito_general - Estructural
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

entity circuito_general is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
            btnu: in std_logic;
            btnd: in std_logic;
            btnr: in std_logic;
            btnl: in std_logic;
           rojo : out STD_LOGIC_VECTOR (3 downto 0);
           verde : out STD_LOGIC_VECTOR (3 downto 0);
           azul : out STD_LOGIC_VECTOR (3 downto 0);
           hsinc : out STD_LOGIC;
           vsinc : out STD_LOGIC);
end circuito_general;

architecture Estructural of circuito_general is

component pinta_barras
Port ( rst: in std_logic;
         clk: in std_logic;
    visible      : in std_logic;
    col          : in unsigned(10-1 downto 0);
    fila         : in unsigned(10-1 downto 0);
    dato_memo_verde     : in std_logic_vector (15 downto 0); -- cada celda 16x16 bits
    dato_memo_azul : in std_logic_vector (15 downto 0);
    dato_memo_rojo : in std_logic_vector (15 downto 0);
    dato_memo2_verde : in std_logic_vector (31 downto 0); -- memoria pista carreras 32x30
    dato_memo2_azul : in std_logic_vector (31 downto 0); -- memoria pista carreras 32x30
        btn_sube: in std_logic;
        btn_baja: in std_logic;
        btn_dcha: in std_logic;
        btn_izq: in std_logic;
    addr_memo_verde     : out std_logic_vector (8-1 downto 0); --memo16x16 tiene 256 direcciones de memoria -> log en base 2 de 256 = 8 bits
    addr_memo_azul     : out std_logic_vector (8-1 downto 0);
    addr_memo_rojo     : out std_logic_vector (8-1 downto 0);
    addr_memo2_verde : out std_logic_vector (5-1 downto 0); --memo32x30 tiene 30 direcciones -> log base 2 de 30 = 5 bits
    addr_memo2_azul : out std_logic_vector (5-1 downto 0);
    rojo         : out std_logic_vector(c_nb_red-1 downto 0);
    verde        : out std_logic_vector(c_nb_green-1 downto 0);
    azul         : out std_logic_vector(c_nb_blue-1 downto 0)
  );
end component; 

component sincro_vga
Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           col : out unsigned (9 downto 0);
           fila : out unsigned (9 downto 0);
           visible : out STD_LOGIC;
           hsinc : out STD_LOGIC;
           vsinc : out STD_LOGIC);
end component;

component memo_16x16_verde
  port (
    clk  : in  std_logic;   -- reloj
    addr : in  std_logic_vector(8-1 downto 0);
    dout : out std_logic_vector(16-1 downto 0) );
 end component;
 
 component memo_16x16_rojo
  port (
    clk  : in  std_logic;   -- reloj
    addr : in  std_logic_vector(8-1 downto 0);
    dout : out std_logic_vector(16-1 downto 0) );
 end component;
 
 component memo_16x16_azul
  port (
    clk  : in  std_logic;   -- reloj
    addr : in  std_logic_vector(8-1 downto 0);
    dout : out std_logic_vector(16-1 downto 0) );
 end component;
 
 component pista_carreras_verde
  port (
    clk  : in  std_logic;   -- reloj
    addr : in  std_logic_vector(5-1 downto 0);
    dout : out std_logic_vector(32-1 downto 0) );
end component;

component pista_carreras_azul
  port (
    clk  : in  std_logic;   -- reloj
    addr : in  std_logic_vector(5-1 downto 0);
    dout : out std_logic_vector(32-1 downto 0) );
end component;

--SEÑALES INTERMEDIAS--
--sincro->pinta_barras
    signal s_col: unsigned (9 downto 0);
    signal s_fila: unsigned (9 downto 0);
    signal s_visible: std_logic;
--pinta_barras->memoria
    signal p_azul: std_logic_vector (7 downto 0);
    signal p_verde: std_logic_vector (7 downto 0);
    signal p_rojo: std_logic_vector (7 downto 0);
    signal q_azul: std_logic_vector (15 downto 0);
    signal q_verde: std_logic_vector (15 downto 0);
    signal q_rojo: std_logic_vector (15 downto 0);
    --pinta barras --> pista carreras 
    signal p2_verde: std_logic_vector (4 downto 0);
    signal q2_verde: std_logic_vector (31 downto 0);
    signal p2_azul: std_logic_vector (4 downto 0);
    signal q2_azul: std_logic_vector (31 downto 0);
    

begin

Primer_componente: sincro_vga
port map (
    rst => rst,
    clk => clk,
    vsinc => vsinc,
    hsinc => hsinc,
    col => s_col,
    fila => s_fila,
    visible => s_visible);

Segundo_componente: pinta_barras
port map (
    clk => clk,
    rst => rst,
    visible => s_visible,
    fila => s_fila,
    col => s_col,
        btn_sube => btnu,
        btn_baja => btnd,
        btn_izq => btnl,
        btn_dcha => btnr,
    rojo => rojo,
    verde => verde,
    azul => azul,
    dato_memo_verde => q_verde,
    dato_memo_azul => q_azul,
    dato_memo_rojo => q_rojo,
    addr_memo_verde => p_verde,
    addr_memo_azul => p_azul,
    addr_memo_rojo => p_rojo,
    dato_memo2_verde=> q2_verde,
    dato_memo2_azul =>q2_azul,
    addr_memo2_verde => p2_verde,
    addr_memo2_azul => p2_azul );

Tercer_componente: memo_16x16_verde
Port map ( 
    clk => clk,
    addr =>p_verde,
    dout => q_verde);
Cuarto_componente: memo_16x16_azul
Port map ( 
    clk => clk,
    addr =>p_azul,
    dout => q_azul);
Quinto_componente: memo_16x16_rojo
Port map ( 
    clk => clk,
    addr =>p_rojo,
    dout => q_rojo);
    
Sexto_componente: pista_carreras_verde
Port map (
    clk => clk,
    addr => p2_verde,
    dout => q2_verde);
    
Septimo_componente: pista_carreras_azul
Port map (
    clk => clk,
    addr => p2_azul,
    dout => q2_azul);
end Estructural;
