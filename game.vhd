library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Game is 
port
(	clk : in std_logic;
	rst : in std_logic;
	
	-- VGA protocol
	r : out std_logic_vector(3 downto 0); 
	g : out std_logic_vector(3 downto 0); 
	b : out std_logic_vector(3 downto 0);
	hsync : out std_logic;
	vsync : out std_logic;
	
	kclock : in std_logic;
	kdata : in std_logic;
	test : out std_logic;
	
	hex0_0 : out std_logic;
	hex0_1 : out std_logic;
	hex0_2 : out std_logic;
	hex0_3 : out std_logic;
	hex0_4 : out std_logic;
	hex0_5 : out std_logic;
	hex0_6 : out std_logic;
	
	hex1_0 : out std_logic;
	hex1_1 : out std_logic;
	hex1_2 : out std_logic;
	hex1_3 : out std_logic;
	hex1_4 : out std_logic;
	hex1_5 : out std_logic;
	hex1_6 :	out std_logic
	
);
end Game;

architecture bhv of Game is
	-- frameBuffer
	signal fbEn : std_logic;
	signal we : std_logic;
	signal wAddrG : std_logic_vector(23 downto 0);
	signal fbDataInG : std_logic_vector(2 downto 0);
	signal rAddr : std_logic_vector(7 downto 0);
	signal spriteID : std_logic_vector(2 downto 0);
	signal random : std_logic_vector(2 downto 0);
	signal fbElement : std_logic_vector(10 downto 0);
	signal playerPos : std_logic_vector(7 downto 0);		
	
	-- vgaController
	signal vgaDataIn : std_logic_vector(39 downto 0);
	
	-- sprite_rom
	signal rowCount : std_logic_vector(8 downto 0);
	signal colCount : std_logic_vector(9 downto 0);
	
	-- Keyboard
	signal keycode : std_logic_vector(7 downto 0);
	signal keycode_new : std_logic;
	
	--swap 
	signal swap_row1 : std_logic_vector(3 downto 0);
	signal swap_col1 : std_logic_vector(3 downto 0);
	signal swap_row2 : std_logic_vector(3 downto 0);
	signal swap_col2 : std_logic_vector(3 downto 0);
	signal data_ready : std_logic;
	signal data_valid : std_logic;
	signal nullC : std_logic_vector(3 downto 0);
	signal init : std_logic;
	signal init_done : std_logic;
	signal go_up : std_logic;
	signal go_down : std_logic;
	signal go_left : std_logic;
	signal go_right : std_logic;
	signal button : std_logic;
	signal scoreOnes : std_logic_vector(3 downto 0);
	signal scoreOnesData : std_logic_vector(39 downto 0);
	signal scoreTensData : std_logic_vector(39 downto 0);
	signal score1, score10 : std_logic_vector(3 downto 0);
	
component frameBuffer is 
port 
(	clk : in std_logic;
	rst : in std_logic;
	fbEn : in std_logic;
	
	-- TODO get player position.
	
	-- gameplay write port
	we : in std_logic;
	
	--gameplay read
	playerPos : in std_logic_vector(7 downto 0);
	
	-- vga read
	vCounter : in std_logic_vector(8 downto 0);
	hCounter : in std_logic_vector(9 downto 0);
	dataOut : out std_logic_vector(2 downto 0);
	
	--swap 
	swap_row1 : in std_logic_vector(3 downto 0);
	swap_col1 : in std_logic_vector(3 downto 0);
	swap_row2 : in std_logic_vector(3 downto 0);
	swap_col2 : in std_logic_vector(3 downto 0);
	data_ready : in std_logic;
	score1 : out std_logic_vector(3 downto 0);
	score10 : out std_logic_vector(3 downto 0)
);
end component frameBuffer;

component vgaController is 
port
(	clk : in std_logic;
	rst : in std_logic;
	
	-- VGA protocol
	r : out std_logic_vector(3 downto 0); 
	g : out std_logic_vector(3 downto 0); 
	b : out std_logic_vector(3 downto 0);
	hsync : out std_logic;
	vsync : out std_logic;
	
	-- Read
	dataIn : in std_logic_vector(39 downto 0);
	rowCount : out std_logic_vector(8 downto 0);
	colCount : out std_logic_vector(9 downto 0);
	
	-- Player position
	playerPos : in std_logic_vector(7 downto 0);
	
	id : in std_logic_vector(2 downto 0);
	data_ready : in std_logic;
	swapRow1 : in std_logic_vector(3 downto 0);
	swapCol1 : in std_logic_vector(3 downto 0);
	swapRow2 : in std_logic_vector(3 downto 0);
	swapCol2 : in std_logic_vector(3 downto 0);
	
	scoreOnesData : in std_logic_vector(39 downto 0);
	scoreTensData : in std_logic_vector(39 downto 0)
);
end component vgaController;
	
component sprite_rom is
port 
(	vCounter : in std_logic_vector(8 downto 0);
	pointer : in std_logic_vector(2 downto 0);
	output : out std_logic_vector(39 downto 0)
);
end component sprite_rom;

component movement is
port (
		clk : in std_logic;
		rst : in std_logic;
		playerPos : out std_logic_vector(7 downto 0);		
		go_up : in std_logic;
		go_down : in std_logic;
		go_left : in std_logic;
		go_right : in std_logic;
		data_valid : in std_logic
);
end component movement;

component swap is 
port (	
		clk : in std_logic;
		rst : in std_logic;
		button : in std_logic;
		playerPos : in std_logic_vector(7 downto 0);
		swap_row1 : out std_logic_vector(3 downto 0);
		swap_col1 : out std_logic_vector(3 downto 0);
		swap_row2 : out std_logic_vector(3 downto 0);
		swap_col2 : out std_logic_vector(3 downto 0);
		data_ready : out std_logic;
		data_valid : in std_logic
);
end component swap;

component ps2_keyboard is
port
(	clk          : in  std_logic;  -- System Clock	
	rst		  	: in  std_logic;                    
   ps2_clk      : in  std_logic;  -- Keyboard clock                
   ps2_data     : in  std_logic;                     
   go_up			: out std_logic;
   go_down 		: out std_logic;
   go_left 		: out std_logic;
   go_right 		:out std_logic;
   sel			: out std_logic;
   valid     : out std_logic      -- Data received correctly
);                     --transfer_en that new PS/2 code is available on ps2_code bus
end component ps2_keyboard;


component onesRom is
port 
(	vCounter : in std_logic_vector(8 downto 0);
	scoreOnes : in std_logic_vector(3 downto 0);
	output : out std_logic_vector(39 downto 0);
	test : out std_logic
);
end component onesRom;

component tensRom is
port 
(	vCounter : in std_logic_vector(8 downto 0);
	scoreTens : in std_logic_vector(3 downto 0);
	output : out std_logic_vector(39 downto 0)
);
end component tensRom;

component score is
port (
	clk : in std_logic;
   score1 : in std_logic_vector(3 downto 0);
   score10 : in std_logic_vector(3 downto 0);   
	hex00 : out std_logic;
	hex01 : out std_logic;
	hex02 : out std_logic;
	hex03 : out std_logic;
	hex04 : out std_logic;
	hex05 : out std_logic;
	hex06 : out std_logic;
	hex10 : out std_logic;
	hex11 : out std_logic;
	hex12 : out std_logic;
	hex13 : out std_logic;
	hex14 : out std_logic;
	hex15 : out std_logic;
	hex16 : out std_logic
);
end component score;

begin

process(clk)
begin
	if rst = '0' then 
		init <= '0';
	else
		if rising_edge(clk) then 
			if init_done = '1' then 
				init <= '0';
			else 
				init <= '1';
			end if;
		end if;
	end if;
end process;


fbEn <= '1';
we <= '1';

-- Create the needed components.
fb : frameBuffer port map(clk, rst, fbEn, we, playerPos, rowCount, colCount, spriteID, swap_row1, swap_col1, swap_row2, swap_col2, data_ready, score1, score10);
vga : vgaController port map(clk, rst, r, g, b, hsync, vsync, vgaDataIn, rowCount, colCount, playerPos, spriteID, data_ready, swap_row1, swap_col1, swap_row2, swap_col2, scoreOnesData, scoreTensData);
rom : sprite_rom port map(rowCount, spriteID, vgaDataIn);
mv : movement port map(clk, rst, playerPos, go_up, go_down, go_left, go_right, data_valid);
ps2 : ps2_keyboard port map(clk, rst, kclock, kdata, go_up, go_down, go_left, go_right, button, data_valid);
sw : swap port map(clk, rst, button, playerPos, swap_row1, swap_col1, swap_row2, swap_col2, data_ready, data_valid);
sc : score port map(clk, score1, score10, hex0_0, hex0_1, hex0_2, hex0_3, hex0_4, hex0_5, hex0_6, hex1_0, hex1_1, hex1_2, hex1_3, hex1_4, hex1_5, hex1_6);
end bhv;
