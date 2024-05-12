
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.VGA_PKG.ALL; 

entity pinta_barras is
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
end pinta_barras;

architecture behavioral of pinta_barras is

--señales sincro vga -> pinta barras
--  constant c_bar_width : natural := 64;
  signal col_interna : unsigned (3 downto 0);
  signal fila_interna : unsigned (3 downto 0);
  signal col_cuad : unsigned (5 downto 0);
  signal fila_cuad : unsigned (5 downto 0);
--señales pinta barras -> memoria pacman 
--  signal dato_pacman : std_logic; --pixel blanc/negro que viene de la memoria
  signal pacman_col: unsigned(5 downto 0);
  signal pacman_fila: unsigned(5 downto 0);
  signal addr_fila_memo: std_logic_vector (3 downto 0); -- para seleccionar el pacman (es la imagen 4 que se correspone a los 4 bits mas significatos 0011) y  el fantasma
  signal dir_memo: std_logic_vector (3 downto 0);
  --pinta barras --> memo fantasma
--  signal dato_fantasma : std_logic;
  signal fant_col: unsigned (5 downto 0);
  signal fant_fila: unsigned (5 downto 0);
  --pinta barras --> memo pista carreras --> ampliamos x16, es decir, quitamos los 4 bits menos significativos
  signal pista_col, pista_fila : unsigned (4 downto 0);
--  signal dato_pista: std_logic;
  
--señales muestreo
    signal conta_muestreo: unsigned (23 downto 0); -- para contar 10 millones hacen falta 24 bits
    signal s_muestreo: std_logic; --se pondrá a 1 cada 100ms = 0,1 seg = 1 decima de segundo
    constant finconta_muestreo : natural:= 10**7; 

---señales FSM fantasma
    type estados is (dcha_baja, izq_baja, dcha_sube, izq_sube);
    signal e_act, e_sig : estados;
    
 -- mejoras
    signal dato_pista_azul : std_logic;
    signal dato_pista_verde: std_logic; 
    signal color_pista: unsigned (1 downto 0);

    signal dato_player_azul, dato_player_verde, dato_player_rojo : std_logic;
    signal color_memo : unsigned (2 downto 0);
    
--componentes
    component conta_generic
       generic (fin_conta: natural := 10**7; 
            n_bits: natural := 24;
            max: unsigned:="1001");
        Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           enable : in std_logic; -- señal que habilita cuenta 
           up_down: in std_logic; -- señal de cuenta ascendente/descendente SW OFF = ASCENDENTE, SW ON= DESCENDENTE
           sconta : out STD_LOGIC; --emitirá una señal/pulso cada periodo deseado,
           vconta : out unsigned (n_bits-1 downto 0)); -- tendrá los bits necesarios para contar hasta el valor deseado y se realiza a partir de la señal s-conta. 
    end component;

begin

col_interna <=not ( col (3 downto 0)); -- invertimos el valor de las columnas (asociadas al dato de memoria) para cambiar la orientacion de los sprites (el pacman mira a la dcha no a la izq)
fila_interna <= fila (3 downto 0);
col_cuad <= col(9 downto 4);
fila_cuad <= fila(9 downto 4);

dir_memo<=std_logic_vector(fila_interna); -- dir_memo es la direecion de memoria que se solicita = fila interna
addr_memo_azul<=addr_fila_memo&dir_memo; --concatenamos la fila interna y la fila de la memo16x16(compuesta de 16 filas internas) para seleccionar 1 de entre 16 imagenes
addr_memo_verde<=addr_fila_memo&dir_memo;
addr_memo_rojo<=addr_fila_memo&dir_memo;

dato_player_verde<=dato_memo_verde(to_integer(col_interna));
dato_player_azul<=dato_memo_azul(to_integer(col_interna));
dato_player_rojo<=dato_memo_rojo(to_integer(col_interna));


--para la pista de carreras tenemos que ampliar la memoria x16-->quitamos 4 bits menos significativos
pista_col <= col(8 downto 4);
pista_fila <= fila(8 downto 4);
addr_memo2_verde <= std_logic_vector (pista_fila);
addr_memo2_azul <= std_logic_vector (pista_fila);
dato_pista_verde<=dato_memo2_verde(to_integer(pista_col));
dato_pista_azul<=dato_memo2_azul(to_integer(pista_col));

P_muestreo_100ms: conta_generic
    generic map (fin_conta=>finconta_muestreo, n_bits => 24, max=>"100110001001011010000000")
    Port Map ( rst=>rst,
               clk=>clk,
               enable=>'1',
               up_down=>'0',
               sconta=>s_muestreo,
               vconta=>conta_muestreo);
               
--movimiento del pacman con los pulsadores
 P_pulsa_movimiento_pacman: process (rst, clk)
 begin
    if rst='1' then
        pacman_col <= (others=>'0');         
        pacman_fila <= (others=>'0');
    elsif clk'event and clk='1' then
        if s_muestreo = '1' then 
            if btn_dcha = '1' then
                if pacman_col <31 then -- valor de columna maximo del campo de juego 
                pacman_col <= pacman_col + 1;  
                end if;
            elsif btn_izq = '1' then
                if pacman_col > 0 then -- valor minimo de col de campo de juego
                pacman_col <= pacman_col - 1;
                end if;
            elsif btn_sube = '1' then
                if pacman_fila > 0 then 
                pacman_fila <= pacman_fila - 1;
                end if;
            elsif btn_baja = '1' then 
                if pacman_fila < 29 then
                pacman_fila <= pacman_fila + 1;
                end if;
            end if;
       end if;
  end if;
end process;

--moviemiento del fantasma --> FSM
P_posicion_fant_sec: process (clk, rst)
begin
    if rst ='1' then
        fant_col <= "001111";
        fant_fila <= (others => '0');
    elsif clk'event and clk='1' then
        if s_muestreo = '1' then
            case e_act is 
            when dcha_baja =>
                fant_col <= fant_col + 1;
                fant_fila <= fant_fila +1;
            when dcha_sube =>
                fant_col <= fant_col + 1;
                fant_fila <= fant_fila - 1;
            when izq_baja =>
                fant_col <= fant_col - 1;
                fant_fila <= fant_fila + 1;
            when izq_sube =>
                fant_col <= fant_col - 1;
                fant_fila <= fant_fila - 1;
            end case;
       end if;
   end if;
end process;
            
P_fsm_sec: Process (clk, rst)
begin
    if rst = '1' then
        e_act <= dcha_baja;
    elsif clk'event and clk='1' then
        e_act <= e_sig;
   end if;
end process;

P_fsm_comb: Process (e_act, fant_fila, fant_col)
begin
    e_sig<=e_act;
    case e_act is 
        when dcha_baja =>
            if fant_col = 31 then
                e_sig <= izq_baja;
            elsif fant_fila = 29 then
                e_sig <= dcha_sube;
            end if;
        when izq_baja =>
            if fant_col = 0 then
                e_sig <= dcha_baja;
            elsif fant_fila = 29 then 
                e_sig <= izq_sube;
           end if; 
       when dcha_sube =>
           if fant_col = 31 then
                e_sig <= izq_sube;
           elsif fant_fila = 0 then
                e_sig <= dcha_baja;
           end if;
       when izq_sube =>
            if fant_col = 0 then
                e_sig <= dcha_sube;
            elsif fant_fila = 0 then
                e_sig <= izq_baja;
            end if;
   end case;
end process;

--index colores pista 
--P_pintar_pista: process (dato_pista_verde, dato_pista_azul, color_pista)
--begin
    color_pista <= "00" when (dato_pista_verde ='0') and (dato_pista_azul ='0') else
                    "01" when (dato_pista_verde = '0' )and (dato_pista_azul ='1') else 
                    "10" when (dato_pista_verde ='1') and (dato_pista_azul='0') else
                    "11" when (dato_pista_verde ='1')and (dato_pista_azul='1');
      
    color_memo <= "000" when (dato_player_verde ='0') and (dato_player_azul ='0') and (dato_player_rojo = '0') else --NEGRO
                  "001" when (dato_player_verde ='0') and (dato_player_azul ='0') and (dato_player_rojo = '1') else --ROJO
                  "010" when (dato_player_verde ='0') and (dato_player_azul ='1') and (dato_player_rojo = '0') else --AZUL
                  "100" when (dato_player_verde ='1') and (dato_player_azul ='0') and (dato_player_rojo = '0') else -- VERDE
                  "011" WHEN (dato_player_verde ='0') and (dato_player_azul ='1') and (dato_player_rojo = '1') else --ROSA
                  "101" WHEN (dato_player_verde ='1') and (dato_player_azul ='0') and (dato_player_rojo = '1') else  --AMARILLO
                  "110" WHEN (dato_player_verde ='0') and (dato_player_azul ='0') and (dato_player_rojo = '0') else --CIAN
                  "111" WHEN (dato_player_verde ='1') and (dato_player_azul ='1') and (dato_player_rojo = '1');  --BLANCO       
       
                   
                   
 P_pinta: Process (visible, col, fila, col_interna, fila_interna, fila_cuad, col_cuad, color_memo, color_pista)
begin -- begin negro 
    rojo <= (others => '0');
    verde <= (others => '0');
    azul <= (others => '0');
    if visible ='1' then
        if col < 513 then
        if (fila_cuad = pacman_fila) and (col_cuad = pacman_col) then -- pintar pacman
            addr_fila_memo <= "0011"; -- fila de imagen 4 es un pacman
            if color_memo = "000" then
                verde <= "0000";
                azul <= "0000";
                rojo <= "0000";
            elsif color_memo = "001" then
                verde <= "0000";
                azul <= "0000";
                rojo <= "1111";
            elsif color_memo = "010" then
                verde <= "0000";
                azul <= "1111";
                rojo <= "0000"; 
            elsif color_memo = "011" then
                verde <= "0000";
                azul <= "1111";
                rojo <= "1111";
            elsif color_memo= "100" then
                verde <= "1111";
                azul <= "0000";
                rojo <= "0000";
            elsif color_memo = "101" then
                verde <= "1111";
                azul <= "0000";
                rojo <= "1111";
            elsif color_memo = "110" then
                verde <= "1111";
                azul <= "1111";
                rojo <= "0000";
            
            else    
                if color_pista = "00"  then
                    rojo <= "1111";
                    azul <= "0000" ;
                    verde <= "0000";
                elsif color_pista = "01" then
                    rojo <= "0000";
                    verde <= "0000";
                    azul <= "1111";
                elsif color_pista ="10" then
                    rojo <= "0000";
                    azul <= "0000" ;
                    verde <= "1111";
                else -- dato_pista_verde = 1 y dato_pista_azul = 1
                    rojo <= "1111";
                    verde <= "1111";
                    azul<="1111";
                end if;
           end if; 
       elsif (fila_cuad = fant_fila) and (col_cuad = fant_col) then -- pintar fantasma
            addr_fila_memo <= "0100";
            if color_memo = "000" then
                verde <= "0000";
                azul <= "0000";
                rojo <= "0000";
            elsif color_memo = "001" then
                verde <= "0000";
                azul <= "0000";
                rojo <= "1111";
            elsif color_memo = "010" then
                verde <= "0000";
                azul <= "1111";
                rojo <= "0000"; 
            elsif color_memo = "011" then
                verde <= "0000";
                azul <= "1111";
                rojo <= "1111";
            elsif color_memo= "100" then
                verde <= "1111";
                azul <= "0000";
                rojo <= "0000";
            elsif color_memo = "101" then
                verde <= "1111";
                azul <= "0000";
                rojo <= "1111";
            elsif color_memo = "110" then
                verde <= "1111";
                azul <= "1111";
                rojo <= "0000";
            
            else    
                if color_pista = "00"  then
                    rojo <= "1111";
                    azul <= "0000" ;
                    verde <= "0000";
                elsif color_pista = "01" then
                    rojo <= "0000";
                    verde <= "0000";
                    azul <= "1111";
                elsif color_pista ="10" then
                    rojo <= "0000";
                    azul <= "0000" ;
                    verde <= "1111";
                else -- dato_pista_verde = 1 y dato_pista_azul = 1
                    rojo <= "1111";
                    verde <= "1111";
                    azul<="1111";
                end if;
           end if; 
        else
           if color_pista = "00"  then
                rojo <= "1111";
                azul <= "0000" ;
                verde <= "0000";
            elsif color_pista = "01" then
                rojo <= "0000";
                verde <= "0000";
                azul <= "1111";
            elsif color_pista ="10" then
                rojo <= "0000";
                azul <= "0000" ;
                verde <= "1111";
            else -- dato_pista_verde = 1 y dato_pista_azul = 1
                rojo <= "1111";
                verde <= "1111";
                azul<="1111";
            end if;
        end if;
      
               
       end if;
   end if;
end process;

end Behavioral;
