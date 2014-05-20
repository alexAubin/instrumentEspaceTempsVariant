// ############################################################################################
// #                                                                                          #
// #   From a code from Igor Gonzalez Martin [igor.gonzalez.martin@gmail.com] (05-04-2007),   #
// #   translated by djmatic (19-05-2007)                                                     #
// #   adapted to implement variable-time instrument by Nicolas C. and Alex A.                #
// #                                                                                          #
// ############################################################################################

#include <string.h>
#include <ctype.h>
#include <math.h>

// ################
// #   Settings   #
// ################

const int RXpin = 0;
const int TXpin = 1;
const int baudRate = 4800;

// ########################
// #   Buffer and stuff   #
// ########################

const char targetString[7] = "$GPRMC";

int incomingByteFromSerial = -1;

char dataFromGPS[300] = "";
int dataFromGPSsize = 0;

int wordPositions[13];

// Enum for GPS data parsing
enum 
{ 
    INFO_TIME,          // 0
    INFO_STATUS,        // 1
    INFO_LATITUDE,      // 2
    INFO_LATITUDESIGN,  // 3
    INFO_LONGITUDE,     // 4
    INFO_LONGITUDESIGN, // 5
    INFO_VELOCITY,      // 6
    INFO_DIRECTION,     // 7
    INFO_DATE,          // 8
    INFO_MAGNETIC,      // 9
    INFO_EW,            // 10
    INFO_MODE,          // 11
    INFO_CHECKSUM       // 12
};

// Container for the parsed info
typedef struct
{
    // Date
    int year;
    int month;
    int day;
    
    // Time
    int hour;
    int minutes;
    int seconds;
    
    // Position
    float latitude;
    float longitude;

} GPSInfoStruct;

GPSInfoStruct GPSInfo;

// ##########################
// #   Prototypes 'n shit   #
// ##########################

void resetDataFromGPSBuffer();
bool readByteFromGPS();
void parseDataFromGPS();
void printDebugGPSInfoToSerial();
void updateVariableTimeInstrument();

// ######################
// #   Setup and loop   #
// ######################

void setup() 
{
    // Set up serial communication
    pinMode(RXpin, INPUT);
    pinMode(TXpin, OUTPUT);
    Serial.begin(baudRate);
    
    // Initialize the buffer for incoming data from GPS
    resetDataFromGPSBuffer();
}

void loop() 
{
    bool endOfTransmissionDetected = readByteFromGPS();

    if (endOfTransmissionDetected)
    {
        parseDataFromGPS();
        printDebugGPSInfoToSerial();
        updateVariableTimeInstrument();
        resetDataFromGPSBuffer();
    }

}

// ##########################################################
// #   Reset the buffer that stores the info from the GPS   #
// ##########################################################

void resetDataFromGPSBuffer()
{
    dataFromGPSsize=0;
    for (int i = 0 ; i < 300 ; i++) { dataFromGPS[i]=' '; }   
}

// ###########################################
// #   Try to read a byte from the GPS and   #
// #   returns true if end of transmission   #
// #   is detected                           #
// ###########################################

bool readByteFromGPS()
{
    // Check if new data is available
    incomingByteFromSerial=Serial.read();         
 
    // If not, wait a bit and go to next iteration
    if (incomingByteFromSerial == -1) 
    {   
        delay(100);
        return false;
    } 
    
    // Add new byte to the data buffer
    dataFromGPS[dataFromGPSsize]=incomingByteFromSerial;
    dataFromGPSsize++;                      
    
    // Debug prints
    
    /*
    Serial.print(incomingByteFromSerial,HEX);
    Serial.print(' ');
    */

    // If the byte is <CR> (carriage return), 
    // it means ends of transmission (actually this is <CR><LF>, 0x0D 0x0A)
    if (incomingByteFromSerial==0x0D) return true;
    else return false;
}

// #############################################################################
// #   Parse the content of the GPS buffer to retrieve the date and position   #
// #############################################################################

void parseDataFromGPS()
{
    // Check that the received command starts with targetString (something like $GPRMC)
    // Note : the loop starts at 1, because this code is clowny and the first byte is
    // the <LF> (0x10) from the previous transmission.
    for (int i=1;i<7;i++)
    {     
        // If the comparison fails at some point, we stop this function
        if (dataFromGPS[i] != targetString[i-1]) { return; }
    }

    // Parse the position of the separators (',' and '*') 
    
    int wordsFound=0;
    for (int i = 0 ; i < 300 ; i++)
    {
        if (dataFromGPS[i]==',') { wordPositions[wordsFound]    = i; wordsFound++; }
        if (dataFromGPS[i]=='*') { wordPositions[INFO_CHECKSUM] = i; wordsFound++; }
    }

    int j;

    // Date
    j = wordPositions[INFO_DATE];
    GPSInfo.day   = 10 * (dataFromGPS[j+1]-48) + (dataFromGPS[j+2]-48);
    GPSInfo.month = 10 * (dataFromGPS[j+3]-48) + (dataFromGPS[j+4]-48);
    GPSInfo.year  = 10 * (dataFromGPS[j+5]-48) + (dataFromGPS[j+6]-48);

    // Date
    j = wordPositions[INFO_TIME];
    GPSInfo.hour    = 10 * (dataFromGPS[j+1]-48) + (dataFromGPS[j+2]-48);
    GPSInfo.minutes = 10 * (dataFromGPS[j+3]-48) + (dataFromGPS[j+4]-48);
    GPSInfo.seconds = 10 * (dataFromGPS[j+5]-48) + (dataFromGPS[j+6]-48);

    // Latitude
    j = wordPositions[INFO_LATITUDE];
    GPSInfo.latitude  =    10 * (dataFromGPS[j+1]-48) 
                      +     1 * (dataFromGPS[j+2]-48)
                      +   0.1 * (dataFromGPS[j+3]-48)
                      +  0.01 * (dataFromGPS[j+4]-48);

    // Longitude
    j = wordPositions[INFO_LONGITUDE];
    GPSInfo.longitude  =   100 * (dataFromGPS[j+1]-48) 
                       +    10 * (dataFromGPS[j+2]-48)
                       +     1 * (dataFromGPS[j+3]-48)
                       +   0.1 * (dataFromGPS[j+4]-48)
                       +  0.01 * (dataFromGPS[j+5]-48);
}

// #####################################################
// #   Print all the info from the GPS in the Serial   #
// #####################################################

void printDebugGPSInfoToSerial()
{
    // Print info in serial output
    Serial.println("---------------");
    for (int i=0;i<12;i++)
    {
        // Find out which kind of info the i-ish word corresponds to
        switch(i)
        {
            case INFO_TIME          : Serial.print("Time in UTC (HhMmSs): "); break;
            case INFO_STATUS        : Serial.print("Status (A=OKV=KO): ");    break;
            case INFO_LATITUDE      : Serial.print("Latitude: ");             break;
            case INFO_LATITUDESIGN  : Serial.print("Direction (N/S): ");      break;
            case INFO_LONGITUDE     : Serial.print("Longitude: ");            break;
            case INFO_LONGITUDESIGN : Serial.print("Direction (E/W): ");      break;
            case INFO_VELOCITY      : Serial.print("Velocity in knots: ");    break;
            case INFO_DIRECTION     : Serial.print("Heading in degrees: ");   break;
            case INFO_DATE          : Serial.print("Date UTC (DdMmAa): ");    break;
            case INFO_MAGNETIC      : Serial.print("Magnetic degrees: ");     break;
            case INFO_EW            : Serial.print("(E/W): ");                break;
            case INFO_MODE          : Serial.print("Mode: ");                 break;
            case INFO_CHECKSUM      : Serial.print("Checksum: ");             break;
        }

        // Print the info
        for (int j=wordPositions[i] ; j<(wordPositions[i+1]-1) ; j++)
        {
            Serial.print(dataFromGPS[j+1]); 
        }
        Serial.println("");
    }
    Serial.println("---------------");
}

//
// This part is still in development, need to check for mistakes in the calculation
// At this point it should compute the time of dawn
//

void updateVariableTimeInstrument()
{
    // Compute shit for motherfucking stuff
    int N1 = GPSInfo.month * 275 / 9;
    int N2 = (GPSInfo.month + 9) / 12;
    int K = 1 + (GPSInfo.year - 4 * ( GPSInfo.year / 4 ) + 2 ) / 3;
    int rank = N1 - N2 * K + GPSInfo.day - 30;


    float DegToRad = 3.141592653 / 180;
    float M = (357 + 0.9856 * rank) * DegToRad;

    Serial.print("M :");
    Serial.print(M);

    float C = (1.914 * sin(M) + 0.02 * sin(2*M)) * DegToRad;

    Serial.print("C :");
    Serial.print(C);

    float L = (280 + C/DegToRad + 0.9856 * rank) * DegToRad;

    Serial.print("L :");
    Serial.print(L);

    float R = -2.465 * sin(2*L) + 0.053 * sin(4*L);

    Serial.print("R :");
    Serial.print(R);

    float ET = (C/DegToRad+R) * 4;

    Serial.print("ET :");
    Serial.print(ET);

    float dec = asin(0.3978 * sin(L));

    Serial.print("dec :");
    Serial.print(dec);

    float H0 = acos( (-0.01454 - sin(dec) * sin(GPSInfo.latitude)) / (cos(dec) * cos(GPSInfo.latitude) ) ) / (DegToRad * 15);

    Serial.print("H0 :");
    Serial.print(H0);

    float Hlever = 12 - H0 + ET / 60 + GPSInfo.longitude / 15;

    Serial.print("H_lever :");
    Serial.print(Hlever);

}

