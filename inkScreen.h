#ifndef INKSCREEN_H
#define INKSCREEN_H

#include "Adafruit_GFX.h"
#include "Adafruit_SharpMem.h"

// any pins can be used
#define SCK 10
#define MOSI 11
#define SS 13

Adafruit_SharpMem display(SCK, MOSI, SS);

#define BLACK 0
#define WHITE 1

#endif
