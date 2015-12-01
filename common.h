
#ifndef COMMON_H
#define COMMON_H

#include "Arduino.h"

#define DEBUG(message)      Serial.println(message)
#define DEBUG_NOLN(message) Serial.print  (message)
//#define DEBUG(message)

using namespace std;

void printFloat(float f);
void printFloatln(float f);
void printIntInString(char* output, int i);
void printFloatInString(char* output, float f);
void printHourInString(char* output, int h, int m, char separator);
void appendString(char* output, char* input);

#endif
