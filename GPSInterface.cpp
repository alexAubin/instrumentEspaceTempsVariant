
// ###########################################################################

#include <SoftwareSerial.h>
#include "GPSInterface.h"

void addByteToBuffer(int byte);
bool parseDataFromGPS();

GPSInterface gpsInterface;
SoftwareSerial gpsSerial(GPS_PIN_TX,GPS_PIN_RX);

// ###########################################################################

void initGPSInterface()
{
    DEBUG(F("Initializing GPS..."));
    gpsSerial.begin(9600);
    resetGPSInterface();
}

void resetGPSInterface()
{

    // Initialize buffer with empty stuff
    gpsInterface.dataFromGPSLength = 0;
    for (int i = 0 ; i < GPS_BUFFER_SIZE ; i++)
        gpsInterface.dataFromGPS[i] = ' ';
    for (int i = 0 ; i < 13              ; i++)
        gpsInterface.indices[i] = -1;

}

void addByteToBuffer(int byte)
{
    // If buffer is already full, reset the interface
    if (gpsInterface.dataFromGPSLength >= GPS_BUFFER_SIZE)
        resetGPSInterface();

    gpsInterface.dataFromGPS[gpsInterface.dataFromGPSLength] = byte;
    gpsInterface.dataFromGPSLength++;
}

bool readGPS()
{
    // Read a byte of the serial port
    int byteFromGPS = gpsSerial.read();

    // If byte is empty, just wait a bit and return
    if (byteFromGPS == -1)
    {
        return false;
    }

    DEBUG((char) byteFromGPS);

    // Else, we have new stuff to read.
    // Put the new byte in the buffer
    addByteToBuffer(byteFromGPS);

    // If the new byte is not a carriage return, nothing else to do.
    if (byteFromGPS != 0x0D) return false;
    // Else, this is the end of current transmission
    // NB: the actual end of transmission is <CR><LF> (i.e. 0x13 0x10)
    else return parseDataFromGPS();
}

bool parseDataFromGPS()
{

    // The string we are interested in is $GPRMC, so lets check the data
    // we received start with this.
    char GPRMC[7] = "$GPRMC";

    // The following for loop starts at 1,
    // because this code is clowny and the first byte is
    // the <LF> (0x10) from the previous transmission.
    bool thisIsGPRMC = true;
    for (int i = 1 ; i < 7 ; i++)
    {
        if (gpsInterface.dataFromGPS[i] != GPRMC[i-1]) thisIsGPRMC = false;
    }

    // If this is not GPRMC, just reset stuff and return
    if (!thisIsGPRMC) { resetGPSInterface(); return false; }

    // Otherwise, lets look deeper into the string
    // We want to identify the different substring delimited by ','
    int nextIndex = 0;
    for (int i = 0 ; i < GPS_BUFFER_SIZE ; i++)
    {
        if (gpsInterface.dataFromGPS[i] == ',')
        {
            // FIXME : possible buffer overflow here !
            gpsInterface.indices[nextIndex] = i;
            nextIndex++;
        }
        if (gpsInterface.dataFromGPS[i]=='*')
        {    // ... and the "*"
            gpsInterface.indices[12] = i;
            nextIndex++;
        }
    }

    DEBUG(F("---------------"));
    for (int i=0;i<12;i++)
    {
        switch(i)
        {
            case 0  :DEBUG(F("Time in UTC (HhMmSs): ")); break;
            case 1  :DEBUG(F("Status (A=OK,V=KO): "));   break;
            case 2  :DEBUG(F("Latitude: "));             break;
            case 3  :DEBUG(F("Direction (N/S): "));      break;
            case 4  :DEBUG(F("Longitude: "));            break;
            case 5  :DEBUG(F("Direction (E/W): "));      break;
            case 6  :DEBUG(F("Velocity in knots: "));    break;
            case 7  :DEBUG(F("Heading in degrees: "));   break;
            case 8  :DEBUG(F("Date UTC (DdMmAa): "));    break;
            case 9  :DEBUG(F("Magnetic degrees: "));     break;
            case 10 :DEBUG(F("(E/W): "));                break;
            case 11 :DEBUG(F("Mode: "));                 break;
            case 12 :DEBUG(F("Checksum: "));             break;
        }

        for (int j =  gpsInterface.indices[i]      ;
                 j < (gpsInterface.indices[i+1]-1) ;
                 j++
            )
            DEBUG_NOLN(gpsInterface.dataFromGPS[j+1]);

        DEBUG("");
    }
    DEBUG(F("---------------"));

}


