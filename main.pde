/*

   Example code for connecting a Parallax GPS module to the Arduino

   Igor Gonzalez Martin. 05-04-2007
   igor.gonzalez.martin@gmail.com

   English translation by djmatic 19-05-2007

   Listen for the $GPRMC string and extract the GPS location data from this.
   Display the result in the Arduino's serial monitor.

 */ 

#include <string.h>
#include <ctype.h>
#include <math.h>

int ledPin = 13;                  // LED test pin
int rxPin = 0;                    // RX PIN 
int txPin = 1;                    // TX TX
int byteGPS=-1;
char linea[300] = "";
char comandoGPR[7] = "$GPRMC";
int cont=0;
int bien=0;
int conta=0;
int indices[13];
bool hasNewStuff = false;

void parseShitAndStuff();

void setup() {
    pinMode(ledPin, OUTPUT);       // Initialize LED pin
    pinMode(rxPin, INPUT);
    pinMode(txPin, OUTPUT);
    Serial.begin(4800);
    for (int i=0;i<300;i++){       // Initialize a buffer for received data
        linea[i]=' ';
    }   
}

void loop() 
{
    //Serial.print("test ?\n");
    digitalWrite(ledPin, HIGH);
    // Read a byte of the serial port
    byteGPS=Serial.read();         
  
    // See if the port is empty yet
    if (byteGPS == -1) 
    {   
        
        if (hasNewStuff == true)
        {
            Serial.print("\n");
            hasNewStuff=false;
        }
        
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
        //Serial.print(' ');
        if (byteGPS==0x0D)
        {            // If the received byte is = to 13, end of transmission
            // note: the actual end of transmission is <CR><LF> (i.e. 0x13 0x10)
            digitalWrite(ledPin, LOW); 
            cont=0;
            bien=0;
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
                parseShitAndStuff();
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
    // Parse shit and stuff
    int j;

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

    // Longitude
    j = indices[4];
    float longitude  =   100 * (linea[j+1]-48) 
                     +    10 * (linea[j+2]-48)
                     +     1 * (linea[j+3]-48)
                     +   0.1 * (linea[j+4]-48)
                     +  0.01 * (linea[j+5]-48);


    // Compute shit for motherfucking stuff
    int N1 = month * 275 / 9;
    int N2 = (month + 9) / 12;
    int K = 1 + (year - 4 * ( year / 4 ) + 2 ) / 3;
    int rank = N1 - N2 * K + day - 30;


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

    float H0 = acos( (-0.01454 - sin(dec) * sin(latitude)) / (cos(dec) * cos(latitude) ) ) / (DegToRad * 15);

    Serial.print("H0 :");
    Serial.print(H0);

    float Hlever = 12 - H0 + ET / 60 + longitude / 15;

    Serial.print("H_lever :");
    Serial.print(Hlever);

}

