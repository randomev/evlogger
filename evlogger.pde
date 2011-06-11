#include <NewSoftSerial.h>
#include <TinyGPS.h>
#include <SD.h>
//#include<stdlib.h>

TinyGPS gps;
NewSoftSerial nss(2, 3, true); // inverted

void gpsdump(TinyGPS &gps);
bool feedgps();
void printFloat(double f, int digits = 2);
String separator = ",";
String dataseparator = ";";
#define LED_RED 9
#define LED_GREEN 8

// On the Ethernet Shield, CS is pin 4. Note that even if it's not
// used as the CS pin, the hardware CS pin (10 on most Arduino boards,
// 53 on the Mega) must be left as an output or the SD library
// functions will not work.
const int chipSelect = 4;

void setup()
{
  int sensorValue;
  
  Serial.begin(115200);
  nss.begin(4800);
  
  Serial.println("EV datalogger ");
  Serial.println("Henry Palonen / 2011");
  Serial.println();
  Serial.println("Date;Time,Alt(cm);Speed(kmph);Current,Lat,Long");
  pinMode(LED_GREEN, OUTPUT);     
  pinMode(LED_RED, OUTPUT);     
  
  digitalWrite(LED_GREEN,HIGH);   // set the LED on
  digitalWrite(LED_RED,HIGH);   // set the LED on
  delay(100);
  digitalWrite(LED_GREEN,LOW);   // set the LED on
  
  // change reference to 1.1V and read few times since after changing reference
  // the measurements are not accurate
  analogReference(INTERNAL);
  for (int i=0;i<10;i++)
  {
    sensorValue = analogRead(A0);
    sensorValue = map(sensorValue, 0, 1024, 0, 1100);
    
    Serial.println(sensorValue, DEC);
  }
  
  // For SD-card;
  // make sure that the default chip select pin is set to
  // output, even if you don't use it:
  pinMode(10, OUTPUT);
  
  // see if the card is present and can be initialized:
  if (!SD.begin(chipSelect)) {
    Serial.println("Card failed, or not present");
    // don't do anything more:
    return;
  }
  Serial.println("card initialized.");
  
  
}

void loop()
{
  bool newdata = false;
  unsigned long start = millis();

  // 1 sec rec interval
  while (millis() - start < 1000)
  {
    if (feedgps())
    {
      newdata = true;
      digitalWrite(LED_RED,LOW);
      digitalWrite(LED_GREEN,HIGH);
    }
  }

  if (newdata)
  {
    //Serial.println("Acquired Data");
    //Serial.println("-------------");
    makelog(gps);
    //Serial.println("-------------");
    Serial.println();
  } else {
    digitalWrite(LED_GREEN, LOW);
  }

}


void makelog(TinyGPS &gps)
{
  long lat, lon;
  float flat, flon;
  unsigned long age, date, time, chars;
  int year;
  byte month, day, hour, minute, second, hundredths;
  unsigned short sentences, failed;
  String dataString = "";
/*
  gps.get_position(&lat, &lon, &age);
  Serial.print("Lat/Long(10^-5 deg): "); Serial.print(lat); Serial.print(", "); Serial.print(lon); 
  Serial.print(" Fix age: "); Serial.print(age); Serial.println("ms.");
 
  feedgps(); // If we don't feed the gps during this long routine, we may drop characters and get checksum errors
*/
  feedgps();

  gps.crack_datetime(&year, &month, &day, &hour, &minute, &second, &hundredths, &age);
  dataString += String(static_cast<int>(month)); 
  dataString += String("/"); 
  dataString += String(static_cast<int>(day)); 
  dataString += String("/"); 
  dataString += String(year);
  dataString += String(dataseparator);
  
  dataString += String(static_cast<int>(hour)); 
  dataString += String(":"); 
  dataString += String(static_cast<int>(minute)); 
  dataString += String(":"); 
  dataString += String(static_cast<int>(second)); 
  //Serial.print("."); Serial.print(static_cast<int>(hundredths));
  dataString += String(separator);

//  Serial.print(" Fix age: "); Serial.print(age); Serial.println("ms.");

  feedgps();

//  Serial.print("  Fix age: ");  Serial.print(age); Serial.println("ms.");
  
  //Serial.print("Alt(cm): "); 
  dataString += String(gps.altitude());
  dataString += String(dataseparator);
  
  feedgps();

  //Serial.print(" Course(10^-2 deg): "); Serial.print(gps.course()); Serial.print(" Speed(10^-2 knots): "); Serial.println(gps.speed());
  //Serial.print("Alt(float): "); printFloat(gps.f_altitude()); Serial.print(" Course(float): "); printFloat(gps.f_course()); Serial.println();
  //Serial.print("Speed(knots): "); printFloat(gps.f_speed_knots()); Serial.print(" (mph): ");  printFloat(gps.f_speed_mph());
  //Serial.print(" (mps): "); printFloat(gps.f_speed_mps()); 
  //Serial.print(" (kmph): "); 
  //printFloat(gps.f_speed_kmph()); 
  dataString += String(gps.speed());
  dataString += String(dataseparator);

  int sensorValue = analogRead(A0);
  sensorValue = map(sensorValue, 0, 1024, 0, 1100);
  dataString += String(sensorValue, DEC);

  dataString += String(separator);

  feedgps();

  gps.get_position(&lat, &lon, &age);
  dataString += String(lat);
  dataString += String(", ");
  dataString += String(lon);
  
  //gps.f_get_position(&flat, &flon, &age);
  //printFloat(flat, 5); Serial.print(", "); printFloat(flon, 5);

  //dataString += String(flat);
  //dataString += String(", ");
  //dataString += String(flon);

  // open the file. note that only one file can be open at a time,
  // so you have to close this one before opening another.
  File dataFile = SD.open("datalog.txt", FILE_WRITE);

  // if the file is available, write to it:
  if (dataFile) {
    dataFile.println(dataString);
    dataFile.close();
    // print to the serial port too:
    Serial.println(dataString);
  }  
  // if the file isn't open, pop up an error:
  else {
    Serial.println("error opening datalog.txt");
  } 
  
  digitalWrite(LED_GREEN,LOW);

//  feedgps();

//  gps.stats(&chars, &sentences, &failed);
//  Serial.print("Stats: characters: "); Serial.print(chars); Serial.print(" sentences: "); Serial.print(sentences); Serial.print(" failed checksum: "); Serial.println(failed);
}
  
bool feedgps()
{
  while (nss.available())
  {
    if (gps.encode(nss.read()))
      return true;
  }
  return false;
}


void printFloat(double number, int digits)
{
  // Handle negative numbers
  if (number < 0.0)
  {
     Serial.print('-');
     number = -number;
  }

  // Round correctly so that print(1.999, 2) prints as "2.00"
  double rounding = 0.5;
  for (uint8_t i=0; i<digits; ++i)
    rounding /= 10.0;
  
  number += rounding;

  // Extract the integer part of the number and print it
  unsigned long int_part = (unsigned long)number;
  double remainder = number - (double)int_part;
  Serial.print(int_part);

  // Print the decimal point, but only if there are digits beyond
  if (digits > 0)
    Serial.print("."); 

  // Extract digits from the remainder one at a time
  while (digits-- > 0)
  {
    remainder *= 10.0;
    int toPrint = int(remainder);
    Serial.print(toPrint);
    remainder -= toPrint; 
  } 
}

