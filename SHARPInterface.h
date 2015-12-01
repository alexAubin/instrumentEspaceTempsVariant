#ifndef INKSCREEN_H
#define INKSCREEN_H

#include "common.h"
#include "Adafruit_GFX.h"
#include "Adafruit_SharpMem.h"

#define SCK  10
#define MOSI 11
#define SS   13

extern Adafruit_SharpMem SHARPdisplay;

#define BLACK 0
#define WHITE 1

void initDisplay();
void printMessageToScreen(char* message);

#endif
