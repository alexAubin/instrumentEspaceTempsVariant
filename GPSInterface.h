/*
    Arduino interface for a Parallax GPS module to the Arduino
    Inspired from a code from

       Igor Gonzalez Martin. 05-04-2007
       igor.gonzalez.martin@gmail.com

       English translation by djmatic 19-05-2007

    Listen for the $GPRMC string and extract the GPS location data from this.
    Display the result in the Arduino's serial monitor.

*/

#ifndef GPS_INTERFACE
#define GPS_INTERFACE

#include "common.h"

#define GPS_PIN_TX 2
#define GPS_PIN_RX 3
#define GPS_BUFFER_SIZE 300

struct GPSInterface
{
    char dataFromGPS[GPS_BUFFER_SIZE];
    int  dataFromGPSLength;
    int  indices[13];
};

extern GPSInterface gpsInterface;

void initGPSInterface();
void resetGPSInterface();
bool readGPS();

#endif
