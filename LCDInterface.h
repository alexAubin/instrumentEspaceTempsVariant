/*
 7-17-2011
 Spark Fun Electronics 2011
 Nathan Seidle
 
 This code is public domain but you buy me a beer if you use this and we meet someday (Beerware license).
 
 This code writes a series of images and text to the Nokia 5110 84x48 graphic LCD:
 http://www.sparkfun.com/products/10168
 
 Do not drive the backlight with 5V. It will smoke. However, the backlight on the LCD seems to be 
 happy with direct drive from the 3.3V regulator.

 Although the PCD8544 controller datasheet recommends 3.3V, the graphic Nokia 5110 LCD can run at 3.3V or 5V. 
 No resistors needed on the signal lines.
 
 You will need 5 signal lines to connect to the LCD, 3.3 or 5V for power, 3.3V for LED backlight, and 1 for ground.
 */

#define PIN_SCE   7 //Pin 3 on LCD
#define PIN_RESET 6 //Pin 4 on LCD
#define PIN_DC    5 //Pin 5 on LCD
#define PIN_SDIN  4 //Pin 6 on LCD
#define PIN_SCLK  3 //Pin 7 on LCD

//The DC pin tells the LCD if we are sending a command or data
#define LCD_COMMAND 0 
#define LCD_DATA  1

//You may find a different size screen, but this one is 84 by 48 pixels
#define LCD_X     84
#define LCD_Y     48

void LCDInit(void);
void LCDWrite(byte data_or_command, byte data);
void LCDClear(void);
void LCDString(char *characters);

//This table contains the hex values that represent pixels
//for a font that is 5 pixels wide and 8 pixels high
static const byte ASCII[][3] = 
{
    {0b00000000, 0b00000000, 0b00000000} //  
    ,{0b00000000, 0b00101110, 0b00000000} // !
    ,{0b00000110, 0b00000000, 0b00000110} // "
    ,{0b00000000, 0b00010000, 0b00000000} // #
    ,{0b00100100, 0b01101011, 0b00010010} // $
    ,{0b00110010, 0b00001000, 0b00100110} // %
    ,{0b00000000, 0b00010000, 0b00000000} // &
    ,{0b00000110, 0b00000000, 0b00000000} // '
    ,{0b00011100, 0b00100010, 0b00000000} // (
    ,{0b00100010, 0b00011100, 0b00000000} // )
    ,{0b00000110, 0b00000110, 0b00000000} // *
    ,{0b00001000, 0b00011100, 0b00001000} // +
    ,{0b01000000, 0b00100000, 0b00000000} // ,
    ,{0b00001000, 0b00001000, 0b00001000} // -
    ,{0b00000000, 0b00100000, 0b00000000} // .
    ,{0b00100000, 0b00011100, 0b00000010} // /
    ,{0b00011100, 0b00100010, 0b00011100} // 0
    ,{0b00100100, 0b00111110, 0b00100000} // 1
    ,{0b00110010, 0b00101010, 0b00100100} // 2
    ,{0b00100010, 0b00101010, 0b00010100} // 3
    ,{0b00001100, 0b00010000, 0b00111110} // 4
    ,{0b00100110, 0b00101010, 0b00010010} // 5
    ,{0b00011100, 0b00101010, 0b00010000} // 6
    ,{0b00000010, 0b00111010, 0b00000110} // 7
    ,{0b00010100, 0b00101010, 0b00010100} // 8
    ,{0b00000100, 0b00001010, 0b00111100} // 9
    ,{0b00000000, 0b00101000, 0b00000000} // :
    ,{0b01000000, 0b00101000, 0b00000000} // ;
    ,{0b00001000, 0b00010100, 0b00000000} // <
    ,{0b00010100, 0b00010100, 0b00010100} // =
    ,{0b00010100, 0b00001000, 0b00000000} // >
    ,{0b00000000, 0b00101010, 0b00000100} // ?
    ,{0b00000000, 0b00010000, 0b00000000} // @
    ,{0b00111100, 0b00010010, 0b00111100} // A
    ,{0b00110110, 0b00101010, 0b00010100} // B
    ,{0b00011100, 0b00100010, 0b00100010} // C
    ,{0b00111110, 0b00100010, 0b00011100} // D
    ,{0b00011100, 0b00101010, 0b00100010} // E
    ,{0b00111100, 0b00001010, 0b00000010} // F
    ,{0b00011100, 0b00100010, 0b00110010} // G
    ,{0b00111110, 0b00010000, 0b00111110} // H
    ,{0b00100010, 0b00111110, 0b00100010} // I
    ,{0b00100000, 0b00100000, 0b00011110} // J
    ,{0b00111110, 0b00001000, 0b00110100} // K
    ,{0b00011110, 0b00100000, 0b00100000} // L
    ,{0b00111110, 0b00001100, 0b00111110} // M
    ,{0b00111110, 0b00000010, 0b00111100} // N
    ,{0b00011110, 0b00100010, 0b00111100} // O
    ,{0b00111100, 0b00001010, 0b00000100} // P
    ,{0b00011100, 0b00110010, 0b00101100} // Q
    ,{0b00111110, 0b00010010, 0b00101100} // R
    ,{0b00100100, 0b00101010, 0b00010010} // S
    ,{0b00000010, 0b00111110, 0b00000010} // T
    ,{0b00111110, 0b00100000, 0b00111110} // U
    ,{0b00011110, 0b00100000, 0b00011110} // V
    ,{0b00111110, 0b00011000, 0b00111110} // W
    ,{0b00110110, 0b00001000, 0b00110110} // X
    ,{0b00001110, 0b00110000, 0b00001110} // Y
    ,{0b00110010, 0b00101010, 0b00100110} // Z
    ,{0b00111110, 0b00100010, 0b00000000} // [
    ,{0b00000010, 0b00011100, 0b00100000} // \antislash
    ,{0b00100010, 0b00111110, 0b00000000} // ]
    ,{0b00000100, 0b00000010, 0b00000100} // ^
    ,{0b00100000, 0b00100000, 0b00100000} // _
    ,{0b00000000, 0b00000010, 0b00000100} // `
    ,{0b00010000, 0b00101000, 0b00111000} // a
    ,{0b00111110, 0b00101000, 0b00010000} // b
    ,{0b00010000, 0b00101000, 0b00101000} // c
    ,{0b00010000, 0b00101000, 0b00111110} // d
    ,{0b00010000, 0b00111000, 0b00011000} // e
    ,{0b00111100, 0b00010010, 0b00000000} // f
    ,{0b00010000, 0b10101000, 0b01111000} // g
    ,{0b00111110, 0b00001000, 0b00110000} // h
    ,{0b00111010, 0b00000000, 0b00000000} // i
    ,{0b10000000, 0b01111010, 0b00000000} // j
    ,{0b00111110, 0b00010000, 0b00101000} // k
    ,{0b00000000, 0b00011110, 0b00100000} // l
    ,{0b00111000, 0b00011000, 0b00111000} // m
    ,{0b00111000, 0b00001000, 0b00110000} // n
    ,{0b00010000, 0b00101000, 0b00010000} // o
    ,{0b11111000, 0b00101000, 0b00010000} // p
    ,{0b00010000, 0b00101000, 0b11111000} // q
    ,{0b00110000, 0b00001000, 0b00000000} // r
    ,{0b00100000, 0b00111000, 0b00001000} // s
    ,{0b00011110, 0b00100100, 0b00000000} // t
    ,{0b00011000, 0b00100000, 0b00111000} // u
    ,{0b00011000, 0b00100000, 0b00011000} // v
    ,{0b00111000, 0b00110000, 0b00111000} // w
    ,{0b00101000, 0b00010000, 0b00101000} // x
    ,{0b00011000, 0b10100000, 0b01111000} // y
    ,{0b00001000, 0b00111000, 0b00100000} // z
    ,{0b00001000, 0b00110110, 0b00100010} // {
    ,{0b00000000, 0b01111110, 0b00000000} // |
    ,{0b00100010, 0b00110110, 0b00001000} // }
    ,{0b00001000, 0b00000100, 0b00000100} // ~
};


void gotoXY(int x, int y) 
{
  LCDWrite(0, 0x80 | x);  // Column.
  LCDWrite(0, 0x40 | y);  // Row.  ?
}

//This takes a large array of bits and sends them to the LCD
void LCDBitmap(char my_array[])
{
  for (int index = 0 ; index < (LCD_X * LCD_Y / 8) ; index++)
    LCDWrite(LCD_DATA, my_array[index]);
}

//This function takes in a character, looks it up in the font table/array
//And writes it to the screen
//Each character is 8 bits tall and 5 bits wide. We pad one blank column of
//pixels on each side of the character for readability.
void LCDCharacter(char character) 
{
  LCDWrite(LCD_DATA, 0x00); //Blank vertical line padding

  for (int index = 0 ; index < 3 ; index++)
    LCDWrite(LCD_DATA, ASCII[character - 0x20][index]);
    //0x20 is the ASCII character for Space (' '). The font table starts with this character

  LCDWrite(LCD_DATA, 0x00); //Blank vertical line padding
}

//Given a string of characters, one by one is passed to the LCD
void LCDString(char *characters) 
{
  while (*characters) LCDCharacter(*characters++);
}

//Clears the LCD by writing zeros to the entire screen
void LCDClear(void) 
{
  for (int index = 0 ; index < (LCD_X * LCD_Y / 8) ; index++)
    LCDWrite(LCD_DATA, 0x00);
    
  gotoXY(0, 0); //After we clear the display, return to the home position
}




//This sends the magical commands to the PCD8544

void LCDInit(void) {

  //Configure control pins
  pinMode(PIN_SCE, OUTPUT);
  pinMode(PIN_RESET, OUTPUT);
  pinMode(PIN_DC, OUTPUT);
  pinMode(PIN_SDIN, OUTPUT);
  pinMode(PIN_SCLK, OUTPUT);

  //Reset the LCD to a known state
  digitalWrite(PIN_RESET, LOW);
  digitalWrite(PIN_RESET, HIGH);

  LCDWrite(LCD_COMMAND, 0x21); //Tell LCD that extended commands follow
  LCDWrite(LCD_COMMAND, 0xB0); //Set LCD Vop (Contrast): Try 0xB1(good @ 3.3V) or 0xBF if your display is too dark
  LCDWrite(LCD_COMMAND, 0x04); //Set Temp coefficent
  LCDWrite(LCD_COMMAND, 0x14); //LCD bias mode 1:48: Try 0x13 or 0x14

  LCDWrite(LCD_COMMAND, 0x20); //We must send 0x20 before modifying the display control mode
  LCDWrite(LCD_COMMAND, 0x0C); //Set display control, normal mode. 0x0D for inverse
}

//There are two memory banks in the LCD, data/RAM and commands. This 
//function sets the DC pin high or low depending, and then sends
//the data byte
void LCDWrite(byte data_or_command, byte data) 
{
  digitalWrite(PIN_DC, data_or_command); //Tell the LCD that we are writing either to data or a command

  //Send the data
  digitalWrite(PIN_SCE, LOW);
  shiftOut(PIN_SDIN, PIN_SCLK, MSBFIRST, data);
  digitalWrite(PIN_SCE, HIGH);
}


