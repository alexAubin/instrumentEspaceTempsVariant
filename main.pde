/*

   Example code for connecting a Parallax GPS module to the Arduino

   Igor Gonzalez Martin. 05-04-2007
   igor.gonzalez.martin@gmail.com

   English translation by djmatic 19-05-2007

   Listen for the $GPRMC string and extract the GPS location data from this.
   Display the result in the Arduino's serial monitor.

 */ 
hfhshfgiziertuert
#include <ctype.h>
#include <math.h>
#include "inkScreen.h"
//#include "LCDInterface.h"

using namespace std;

int ledPin = 13;                  // LED test pin
int rxPin = 0;                    // RX PIN 
int txPin = 1;                    // TX TX
int byteGPS=-1;
char linea[300] = "";
//char comandoGPR[7] = "$GPRMC";
int cont=0;
int bien=0;
int conta=0;
int indices[13];
bool hasNewStuff = false;

void parseShitAndStuff();
void printFloat(float f);
void printFloatln(float f);

void printIntInString(char* output, int i);
void printFloatInString(char* output, float f);
void printHourInString(char* output, int h, int m, char separator);
void appendString(char* output, char* input);

void setup()
{
    //pinMode(ledPin, OUTPUT);       // Initialize LED pin
    //pinMode(rxPin, INPUT);
    //pinMode(txPin, OUTPUT);
    
    Serial.begin(4800);
    
    for (int i=0;i<300;i++){       // Initialize a buffer for received data
        linea[i]=' ';
    }

    // start & clear the display
    display.begin();
    delay(500);
    display.refresh();
    delay(500);
    display.clearDisplay();
}

void loop() 
{
    //Serial.print("test ?\n");
    //digitalWrite(ledPin, HIGH);
    // Read a byte of the serial port
    byteGPS=Serial.read();         
  
    // See if the port is empty yet
    if (byteGPS == -1) 
    {   
        delay(100); 
    } 
    else
    {
        hasNewStuff=true;
        // note: there is a potential buffer overflow here!
        linea[conta]=byteGPS;        // If there is serial port data, it is put in the buffer
        conta++;                      
        //if (byteGPS < 0x10) Serial.print('0'); 
        //Serial.print(byteGPS,HEX);

        //Serial.print('\n');
        if (byteGPS==0x0D)
        {            
            // If the received byte is = to 13, end of transmission
            // note: the actual end of transmission is <CR><LF> (i.e. 0x13 0x10)
            //digitalWrite(ledPin, LOW); 
            cont=0;
            bien=0;
            
            char comandoGPR[7] = "$GPRMC";
            // The following for loop starts at 1, because this code is clowny and the first byte is the <LF> (0x10) from the previous transmission.
            for (int i=1;i<7;i++)
            {     
                // Verifies if the received command starts with $GPR
                if (linea[i]==comandoGPR[i-1])
                {
                    bien++;
                }
            }
            if(bien==6)
            {    
                // If yes, continue and process the data
                for (int i=0;i<300;i++)
                {
                    if (linea[i]==',')
                    {   
                        // check for the position of the  "," separator
                        // note: again, there is a potential buffer overflow here!
                        indices[cont]=i;
                        cont++;
                    }
                    if (linea[i]=='*')
                    {    // ... and the "*"
                        indices[12]=i;
                        cont++;
                    }
                }
                 
                Serial.println("---------------");
                for (int i=0;i<12;i++){
                    switch(i)
                    {
                        case 0 :Serial.print("Time in UTC (HhMmSs): ");break;
                        case 1 :Serial.print("Status (A=OK,V=KO): ");break;
                        case 2 :Serial.print("Latitude: ");break;
                        case 3 :Serial.print("Direction (N/S): ");break;
                        case 4 :Serial.print("Longitude: ");break;
                        case 5 :Serial.print("Direction (E/W): ");break;
                        case 6 :Serial.print("Velocity in knots: ");break;
                        case 7 :Serial.print("Heading in degrees: ");break;
                        case 8 :Serial.print("Date UTC (DdMmAa): ");break;
                        case 9 :Serial.print("Magnetic degrees: ");break;
                        case 10 :Serial.print("(E/W): ");break;
                        case 11 :Serial.print("Mode: ");break;
                        case 12 :Serial.print("Checksum: ");break;
                    }
                    for (int j=indices[i];j<(indices[i+1]-1);j++){
                        Serial.print(linea[j+1]); 
                    }
                    Serial.println("");
                }
                Serial.println("---------------");
               
    Serial.println("calling parse");
                parseShitAndStuff();
    Serial.println("out parse");
            
            }
            conta=0;                    // Reset the buffer
            for (int i=0;i<300;i++){    //  
                linea[i]=' ';             
            }                 
        }
    }
}

void parseShitAndStuff()
{
    Serial.println("----------");
    Serial.println("in parse");
    // Parse shit and stuff
    int j;

    // Time
    j = indices[0];
    int hour    = 10 * (linea[j+1]-48) + (linea[j+2]-48);
    int minutes = 10 * (linea[j+3]-48) + (linea[j+4]-48);
    int seconds = 10 * (linea[j+5]-48) + (linea[j+6]-48);
    float current_time = hour + (minutes / 60.0) + (seconds / 3600.0);

    Serial.print("Hour (UTC +0) : ");
    Serial.print(hour);
    Serial.print(":");
    Serial.print(minutes);
    Serial.print(":");
    Serial.println(seconds);

    // Date
    j = indices[8];
    int day   = 10 * (linea[j+1]-48) + (linea[j+2]-48);
    int month = 10 * (linea[j+3]-48) + (linea[j+4]-48);
    int year  = 10 * (linea[j+5]-48) + (linea[j+6]-48);

    // Latitude
    j = indices[2];
    float latitude  =    10 * (linea[j+1]-48) 
                    +     1 * (linea[j+2]-48)
                    +   0.1 * (linea[j+3]-48)
                    +  0.01 * (linea[j+4]-48);
/*
    j = indices[3];
    char directionlat[2];
    directionlat[0] = linea[j+1];
    directionlat[1] = '/0';
*/

    // Longitude
    j = indices[4];
    float longitude  =   100 * (linea[j+1]-48) 
                     +    10 * (linea[j+2]-48)
                     +     1 * (linea[j+3]-48)
                     +   0.1 * (linea[j+4]-48)
                     +  0.01 * (linea[j+5]-48);
/*
    j = indices[5];
    char directionlong[2];
    directionlong[0] = linea[j+1];
    directionlong[1] = '/0';
*/

    // Compute shit for motherfucking stuff
    int N1 = month * 275 / 9;
    int N2 = (month + 9) / 12;
    int K = 1 + (year - 4 * ( year / 4 ) + 2 ) / 3;
    int rank = N1 - N2 * K + day - 30;
    float DegToRad = M_PI / 180.0;
    float M = (357 + 0.9856 * rank) * DegToRad;
    float C = (1.914 * sin(M) + 0.02 * sin(2*M));
    float L = (280 + C + 0.9856 * rank) * DegToRad;
    float R = -2.465 * sin(2*L) + 0.053 * sin(4*L);
    float ET = (C+R) * 4;
    float dec = asin(0.3978 * sin(L));
    float H0 = acos( (-0.01454 - sin(dec) * sin(latitude*DegToRad)) / (cos(dec) * cos(latitude*DegToRad) ) ) / (DegToRad * 15);
    float Hlever   = 12 - H0 + ET / 60 + longitude / 15 - 1;
    float Hcoucher = 12 + H0 + ET / 60 + longitude / 15 - 1;

    int lati = latitude / 100;
    int longi = longitude / 100;

    int Hlever_hours   = int(Hlever);
    int Hlever_minutes = int((Hlever - Hlever_hours) * 60);
    
    int Hcoucher_hours   = int(Hcoucher);
    int Hcoucher_minutes = int((Hcoucher - Hcoucher_hours) * 60);

    Serial.print("H_lever : ");
    Serial.print(Hlever_hours);
    Serial.print(":");
    Serial.println(Hlever_minutes);
    
    Serial.print("H_coucher : ");
    Serial.print(Hcoucher_hours);
    Serial.print(":");
    Serial.println(Hcoucher_minutes);

    float delta_lever   = current_time - Hlever;
    float delta_coucher = current_time - Hcoucher;

    float Sol_duree   = Hcoucher - Hlever;
    float Night_duree = 24 - Sol_duree;

    int Sol_duree_hours   = int(Sol_duree);
    int Sol_duree_minutes = int((Sol_duree - Sol_duree_hours) * 60);
    
    Serial.print("Sol_duree : ");
    Serial.print(Sol_duree_hours);
    Serial.print(":");
    Serial.println(Sol_duree_minutes);

    Serial.print("Delta lever : ");
    printFloatln(delta_lever);
    Serial.print("Delta coucher : ");
    printFloatln(delta_coucher);

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

    Serial.print("Moyenne de S-var : ");
    printFloatln(S_var_mean);

    Serial.print("Current_S-var : ");
    printFloatln(current_S_var);

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

    Serial.print("Current H-var : ");
    Serial.print(H_var_hours);
    Serial.print(";");
    Serial.println(H_var_minutes);
   
  
    char message[126] = "\0";
    
    appendString(message,"Hstand: ");
    //hour + 1 for Hstand = UTC+1
    printHourInString(message+8, hour + 1, minutes, ':');
    
    appendString(message,"        ");
    
    appendString(message, "S_var: ");
    printFloatInString(message+28, current_S_var);
 
    appendString(message,"        ");

    appendString(message,"H_var: ");
    printHourInString(message+49, H_var_hours,H_var_minutes, ';');

    appendString(message,"                                                  ");

    
    Serial.println("Printing on screen");
    //gotoXY(0, 0);
/*
    display.setTextSize(1);
    display.setTextColor(WHITE,BLACK);
    display.setCursor(0,0);
    display.println(message);
    display.refresh();
    delay(500);
    display.clearDisplay();
*/
    display.setTextSize(1);
    display.setTextColor(BLACK);
    display.setCursor(0,0);
    display.println("Hello, world!");
    display.setTextColor(WHITE, BLACK); // 'inverted' text
    display.println(3.141592);
    display.setTextSize(2);
    display.setTextColor(BLACK);
    display.print("0x"); display.println(0xDEADBEEF, HEX);
    display.refresh();

}

void appendString(char* output, char* input)
{
    int i = 0;
    for (i = 0 ; ; i++) { if (output[i] == '\0') break; }

    for (int j = 0 ; input[j] != '\0' ; j++)
    {
        output[i++] = input[j]; 
    }
    output[i] = '\0';

    return;
}

void printFloat(float f)
{
    if (f < 0) 
    {
        Serial.print('-');
        f = -f;
    }

    if (f > 1) Serial.print(int(f));
    else Serial.print('0');

    Serial.print('.');
   
    f = f - int(f);    int a = int(f *    10);  Serial.print(a);
    f = f - a * 0.1;   int b = int(f *   100);  Serial.print(b);
    f = f - b * 0.01;  int c = int(f *  1000);  Serial.print(c);
    f = f - c * 0.001; int d = int(f * 10000);  Serial.print(d);
}

void printFloatInString(char* output, float f)
{
    int index = 0;
    if (f < 0) 
    {
        output[index++] = '-';
        f = -f;
    }

    if (f > 1) output[index++] = (int(f)+48); 
    else output[index++] = '0'; 

    output[index++] = '.'; 
   
    f -= int(f);    int a = int(f *    10); output[index++] = a+48; 
    f -= a * 0.1;   int b = int(f *   100); output[index++] = b+48; 
    f -= b * 0.01;  int c = int(f *  1000); output[index++] = c+48; 
    f -= c * 0.001; int d = int(f * 10000); output[index++] = d+48;

    output[index] = '\0';

    return;
}

/* Find out what's going on here
void printIntInString(char* output, int i)
{
    int index = 0;
    if (i < 0) 
    {
        output[index++] = '-';
        i = -i;
    }

    if (i >= 10) 
    {
        output[index++] = (int(i/10)+48); 
    i = (int) (i / 10);  
    }
    
    output[index++] = (int(i)+48); 
    output[index] = '\0';

    return;
}
*/


void printHourInString(char* output, int h, int m, char separator)
{
    int index = 0;

    if (h >= 10) output[index++] = int(h/10)+48; 
    else output[index++] = '0';
    if (h > 1)  output[index++] = int(h - (h/10)*10)+48; 
    else output[index++] = '0';


    output[index++] = separator; 
    
    if (m >= 10) output[index++] = int(m/10)+48; 
    else output[index++] = '0';
    if (m > 1)  output[index++] = int(m - (m/10)*10)+48; 
    else output[index++] = '0';
    
    output[index] = '\0';

    return;
}

void printFloatln(float f)
{
    printFloat(f);
    Serial.print('\n');
}





