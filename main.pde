/*

   Example code for connecting a Parallax GPS module to the Arduino

   Igor Gonzalez Martin. 05-04-2007
   igor.gonzalez.martin@gmail.com

   English translation by djmatic 19-05-2007

   Listen for the $GPRMC string and extract the GPS location data from this.
   Display the result in the Arduino's serial monitor.

 */
#include <ctype.h>
#include <math.h>

#include "common.h"
#include "SHARPInterface.h"
//#include "LCDInterface.h"
#include "GPSInterface.h"

using namespace std;

void updateIGTV();
char messageForDisplay[126];

// ########################################################################


void setup()
{
    //Serial.begin(9600);
    //DEBUG(F("Starting Serial debug..."));

    initGPSInterface();
    initDisplay();
    
    messageForDisplay[0] = '\0';    

    delay(1000);
    
//    printMessageToScreen("Hello from the screen !");
    SHARPdisplay.clearDisplay();
    SHARPdisplay.setTextSize(1);
    SHARPdisplay.setTextColor(BLACK);
    SHARPdisplay.setCursor(0,0);
    SHARPdisplay.println("Hello from the screen !");
    SHARPdisplay.refresh();

    delay(1000);
}

void loop()
{

    bool newData = readGPS();

    if (newData)
    {
        DEBUG(F("Received stuff !"));
        updateIGTV();
        printMessageToScreen(messageForDisplay);
        resetGPSInterface();
    }
    

}

void updateIGTV()
{
    
    DEBUG(F("in parse"));
   
    char* dataFromGPS = gpsInterface.dataFromGPS;
    int*  indices     = gpsInterface.indices;

    // Parse shit and stuff
    int j;

    // Time
    j = indices[0];
    int hour    = 10 * (dataFromGPS[j+1]-48) + (dataFromGPS[j+2]-48);
    int minutes = 10 * (dataFromGPS[j+3]-48) + (dataFromGPS[j+4]-48);
    int seconds = 10 * (dataFromGPS[j+5]-48) + (dataFromGPS[j+6]-48);
    float current_time = hour + (minutes / 60.0) + (seconds / 3600.0);

    //DEBUG_NOLN(F("Hour (UTC +0) : "));
    //DEBUG(hour);
    //DEBUG(F(":"));
    //DEBUG(minutes);
    //DEBUG(F(":"));
    //DEBUG(seconds);
    //DEBUG_NOLN(F("calc : "));

    // Date
    j = indices[8];
    int day   = 10 * (dataFromGPS[j+1]-48) + (dataFromGPS[j+2]-48);
    int month = 10 * (dataFromGPS[j+3]-48) + (dataFromGPS[j+4]-48);
    int year  = 10 * (dataFromGPS[j+5]-48) + (dataFromGPS[j+6]-48);

    // Latitude
    j = indices[2];
    float latitude  =    10 * (dataFromGPS[j+1]-48)
                    +     1 * (dataFromGPS[j+2]-48)
                    +   0.1 * (dataFromGPS[j+3]-48)
                    +  0.01 * (dataFromGPS[j+4]-48);

    // Longitude
    j = indices[4];
    float longitude  =   100 * (dataFromGPS[j+1]-48)
                     +    10 * (dataFromGPS[j+2]-48)
                     +     1 * (dataFromGPS[j+3]-48)
                     +   0.1 * (dataFromGPS[j+4]-48)
                     +  0.01 * (dataFromGPS[j+5]-48);

    // Use longitude/latitude information to compute sunrise and sunset time
    int N1          = month * 275 / 9;
    int N2          = (month + 9) / 12;
    int K           = 1 + (year - 4 * ( year / 4 ) + 2 ) / 3;
    int rank        = N1 - N2 * K + day - 30;
    float DegToRad  = M_PI / 180.0;
    float M         = (357 + 0.9856 * rank) * DegToRad;
    float C         = (1.914 * sin(M) + 0.02 * sin(2*M));
    float L         = (280 + C + 0.9856 * rank) * DegToRad;
    float R         = -2.465 * sin(2*L) + 0.053 * sin(4*L);
    float ET        = (C+R) * 4;
    float dec       = asin(0.3978 * sin(L));
    float H0        = acos(     (-0.01454 - sin(dec) * sin(latitude*DegToRad)) 
                              / (cos(dec) * cos(latitude*DegToRad) )
                          ) 
                          / (DegToRad * 15);
    float Hlever    = 12 - H0 + ET / 60 + longitude / 15 - 1;
    float Hcoucher  = 12 + H0 + ET / 60 + longitude / 15 - 1;

    int Hlever_hours   = int(Hlever);
    int Hlever_minutes = int((Hlever - Hlever_hours) * 60);

    int Hcoucher_hours   = int(Hcoucher);
    int Hcoucher_minutes = int((Hcoucher - Hcoucher_hours) * 60);

    //DEBUG_NOLN(F("H_lever : "));
    //DEBUG_NOLN(Hlever_hours);
    //DEBUG_NOLN(F(":"));
    //DEBUG(Hlever_minutes);

    //DEBUG_NOLN(F("H_coucher : "));
    //DEBUG_NOLN(Hcoucher_hours);
    //DEBUG_NOLN(F(":"));
    //DEBUG(Hcoucher_minutes);

    float delta_lever   = current_time - Hlever;
    float delta_coucher = current_time - Hcoucher;

    float Sol_duree   = Hcoucher - Hlever;
    float Night_duree = 24 - Sol_duree;

    int Sol_duree_hours   = int(Sol_duree);
    int Sol_duree_minutes = int((Sol_duree - Sol_duree_hours) * 60);

    //DEBUG_NOLN(F("Sol_duree : "));
    //DEBUG_NOLN(Sol_duree_hours);
    //DEBUG_NOLN(F(":"));
    //DEBUG(Sol_duree_minutes);

    //DEBUG(F("Delta lever : "));
    //printFloatln(delta_lever);
    //DEBUG(F("Delta coucher : "));
    //printFloatln(delta_coucher);

    float S_var_mean;
    float current_S_var;

    // TODO : properly manage case between hour = 0 and hour = Hlever (check night's hour of previous day)
    if ((current_time > Hlever) && (current_time < Hcoucher))
    {
        S_var_mean = Sol_duree / 12;
        current_S_var = 1.0 + (S_var_mean - 1.0) * M_PI / 2.0 * sin(delta_lever * M_PI / Sol_duree);
    }
    else
    {
        S_var_mean = Night_duree / 12;
        current_S_var = 1.0 + (S_var_mean - 1.0) * M_PI / 2.0 * sin(delta_coucher * M_PI / Night_duree);
    }

    //DEBUG_NOLN(F("Moyenne de S-var : "));
    //printFloatln(S_var_mean);
    
    //DEBUG_NOLN(F("Current_S-var : "));
    //printFloatln(current_S_var);

    float H_var;
    if ((current_time > Hlever) && (current_time < Hcoucher))
    {
         H_var = delta_lever + (1.0/S_var_mean-1) * Sol_duree / 2.0 * (1.0 - cos(delta_lever * M_PI / Sol_duree));
    }
    else
    {
        H_var = delta_coucher + (1.0/S_var_mean-1) * Night_duree / 2.0 * (1.0 - cos(delta_coucher * M_PI / Night_duree));
    }
    int H_var_hours = int(H_var);
    int H_var_minutes = (H_var - H_var_hours) * 60;

    //DEBUG_NOLN(F("Current H-var : "));
    //DEBUG(H_var_hours);
    //DEBUG_NOLN(F(";"));
    //DEBUG(H_var_minutes);


    messageForDisplay[0] = '\0';    

    appendString(messageForDisplay,"Hstand: ");
    //hour + 1 for Hstand = UTC+1
    printHourInString(messageForDisplay+8, hour + 1, minutes, ':');

    appendString(messageForDisplay,"        ");

    appendString(messageForDisplay, "S_var: ");
    printFloatInString(messageForDisplay+28, current_S_var);

    appendString(messageForDisplay,"        ");

    appendString(messageForDisplay,"H_var: ");
    printHourInString(messageForDisplay+49, H_var_hours,H_var_minutes, ';');

    DEBUG(F("Printing on screen"));

    DEBUG(messageForDisplay);
    //gotoXY(0, 0);

}

