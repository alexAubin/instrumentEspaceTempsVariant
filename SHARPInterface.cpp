#include "SHARPInterface.h"

Adafruit_SharpMem SHARPdisplay(SCK, MOSI, SS);

void initDisplay()
{
    DEBUG(F("Initializing SHARP display..."));
    SHARPdisplay.begin();
    SHARPdisplay.clearDisplay();
    SHARPdisplay.refresh();
}


void printMessageToScreen(char* message)
{
    SHARPdisplay.clearDisplay();
    SHARPdisplay.setTextSize(1);
    SHARPdisplay.setTextColor(BLACK);
    SHARPdisplay.setCursor(0,0);
    SHARPdisplay.println(message);
    SHARPdisplay.refresh();
}

