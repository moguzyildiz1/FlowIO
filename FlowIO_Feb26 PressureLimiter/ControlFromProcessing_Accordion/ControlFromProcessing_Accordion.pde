//1. Install controlP5 by downloading the .zip file and estracting it into the /Documents/Processing/libraries folder.
//2. Download the Firmate library (cc.arduino) from Sketch >> Import Library >> Add library >> Arduino (Firmata)

import controlP5.*;
import processing.serial.*;

Serial myPort;
ControlP5 cp5;
Textlabel myLabel1;
Textlabel myLabel2;
Textlabel myLabel3;
Textlabel myLabel4;
Textlabel myLabel5;
Textlabel myLabel6;
Textlabel mylabelAll;
CheckBox checkbox;
Accordion accordion;
Group inflationGroup; //These are groups that will go into the accordion.
Group vacuumGroup;
Group releaseGroup;
Group senseGroup;
Group pressureLimitsGroup;
Group multiportControlGroup;

boolean p1 = false;
boolean p2 = false;
boolean p3 = false;
boolean p4 = false;
boolean p5 = false;
boolean blueLed=true;
boolean redLed=true;
byte ports;

float pressureValue=0;
boolean vacuuming = false; //these two variables will keep track of the state of the system. 
boolean inflating = false; 
float maxP; //if we have a slider/knob with the same string name, then the value of this variable will equal to the value of that slider.
float minP;

PImage pressureGaugeImage;
PImage batteryImage;

Knob minPressureKnob;
Knob maxPressureKnob;
Textlabel pressureValLabel;
Textlabel batteryPercentageLabel;

void setup() {
  size(900,950);

  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 115200);
    
  cp5 = new ControlP5(this);
   
  //create a new font
  PFont p = createFont("Verdana",15);  
  ControlFont myFont = new ControlFont(p);
  cp5.setFont(myFont);
  
               
  setupBarOnTop();
  setupAccordion();
  setupInflationButtons();
  setupVacuumButtons();
  setupReleaseButtons();
  setupSenseButtons();
  setupPressureKnobs();
  setupMultiportButtons();
}
void draw() {
  background(80, 79, 89);  
  image(pressureGaugeImage, 300,15);
  image(batteryImage, 50,15);
  ports=0x00;
  if(p5) ports ^= 0x01;
  if(p4) ports ^= 0x02;
  if(p3) ports ^= 0x04;
  if(p2) ports ^= 0x08;
  if(p1) ports ^= 0x10;
  
  //I can keep track of the state the system is in in Processing. Or I can have the system report to me the state it currently is operating in. 
  //For now, I would like to keep track in processing of just whether it is in a vacuuming or inflating state only. I don't care about configurations
  //or how many pumps are active or which ports are open. Just 2 boolean variables are all I need. 
  
  //TODO: There is a problem that happens because we set the pressure value to 0. Thus, in the library we should use negative value for the pressure if we want to indicate an error message.
  if(vacuuming==true && pressureValue < minP){
     //send the stop command and set vacuuming to false.
     vacuuming=false;
     myPort.write('!');
     myPort.write(0xFF);
  }
   if(inflating==true && pressureValue > maxP){
     inflating=false;
     myPort.write('!');
     myPort.write(0xFF);
  }
  
  getBatteryAndPressure();
  
  println(pressureValue);
}

/*###########################################################################################################################################
#####################################################---BEGIN FUNCTION DEFINITIONS---########################################################
*/
void setupMultiportButtons(){
  cp5.addToggle("p1").setPosition(150,5).setSize(50,40).moveTo(multiportControlGroup);
  cp5.addToggle("p2").setPosition(220,5).setSize(50,40).moveTo(multiportControlGroup);
  cp5.addToggle("p3").setPosition(290,5).setSize(50,40).moveTo(multiportControlGroup);
  cp5.addToggle("p4").setPosition(360,5).setSize(50,40).moveTo(multiportControlGroup);
  cp5.addToggle("p5").setPosition(430,5).setSize(50,40).moveTo(multiportControlGroup);
     
  cp5.addButton("Inflate").setPosition(150,80).setSize(100,40).moveTo(multiportControlGroup)
     .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {
       //we first want to sense the pressure and then decide whether to inflate or not.
      myPort.write('?'); myPort.write(ports);
      //I WANT TO READ THE PRESSURE HERE INTO A VARIABLE different than pressureValue, and then do my if-condition based on that variable!!!
      //BUT HOW CAN I GET THE PRESSURE VALUE RIGHT HERE?
      delay(900); //delay to get the pressure value. But unfortunately internally what happens now is that the system will go into the STOP state, as it 
       //transitions from the sense to the inflation state. This would require a modification of the library, so that we don't go through STOP after sense,
       //because what we should be doing now is simply start the pump without closing and reopening port valve. But lets see if this works first as it is.
       if(pressureValue < maxP){
           myPort.write('+'); myPort.write(ports); inflating=true;
       }
      }})
     .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write(ports); inflating=false;}});
  cp5.addButton("Vacuum").setPosition(265,80).setSize(100,40).moveTo(multiportControlGroup)
     .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('-'); myPort.write(ports); vacuuming=true;}})
     .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write(ports); vacuuming=false;}});
  cp5.addButton("Release").setPosition(380,80).setSize(100,40).moveTo(multiportControlGroup)
     .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('^'); myPort.write(ports);}})
     .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write(ports);}});
}
void stopActionAll(){
    myPort.write('!');
    myPort.write('0');
}

void getBatteryAndPressure(){
  while(myPort.available() > 0){
    String str = myPort.readStringUntil('\n');
    if(str != null){
      if(str.length() > 7){
        if(str.substring(0,5).equals("Batt:")){ //https://processing.org/reference/String.html
          String batteryStr = str.substring(5,7); //returns positions 5 and 6 (starting position is 0).
          batteryPercentageLabel.setText(batteryStr+ "%");
        }
        if(str.substring(0,5).equals("Pres:")){ 
          String pressureStr = str.substring(5,9); //returns positions 5 and 6 (starting position is 0).
          pressureValue = float(pressureStr);
          pressureValLabel.setText(pressureStr+ " psi");
        }
      }
    }
  }
}

void setupInflationButtons(){
  //I want the inflation to be maintained only while the button is BEING HELD pressed.
  //Once relased, the inflation should stop. If I want to inflate it more, i press it again. 
  //############################################################################################
  cp5.addButton("+1").setPosition(100,10).setSize(80,80).moveTo(inflationGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('+'); myPort.write('p'); inflating=true;}}) //If I don't send the same command twice, then the FlowIO behaves in unintended way. Maybe something is bad with the FlowIO embedded code.
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('p'); inflating=false;}});
  cp5.addButton("+2").setPosition(200,10).setSize(80,80).moveTo(inflationGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('+'); myPort.write('h'); inflating=true;}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('h'); inflating=false;}});
  cp5.addButton("+3").setPosition(300,10).setSize(80,80).moveTo(inflationGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('+'); myPort.write('d'); inflating=true;}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('d'); inflating=false;}});
  cp5.addButton("+4").setPosition(400,10).setSize(80,80).moveTo(inflationGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('+'); myPort.write('b'); inflating=true;}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('b'); inflating=false;}});
  cp5.addButton("+5").setPosition(500,10).setSize(80,80).moveTo(inflationGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('+'); myPort.write('a'); inflating=true;}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('a'); inflating=false;}});
    
    //.setColorBackground(color(0, 179, 255)) //default color
     //.setColorForeground(color(82, 204, 240)) //hover color
     //.setColorActive(color(0, 179, 255))  //when pressed
}
void setupVacuumButtons(){  
  cp5.addButton("-1").setPosition(100,10).setSize(80,80).moveTo(vacuumGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('-'); myPort.write('p'); vacuuming=true;}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('p'); vacuuming=false;}});
  cp5.addButton("-2").setPosition(200,10).setSize(80,80).moveTo(vacuumGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('-'); myPort.write('h'); vacuuming=true;}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('h'); vacuuming=false;}});
  cp5.addButton("-3").setPosition(300,10).setSize(80,80).moveTo(vacuumGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('-'); myPort.write('d'); vacuuming=true;}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('d'); vacuuming=false;}});
  cp5.addButton("-4").setPosition(400,10).setSize(80,80).moveTo(vacuumGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('-'); myPort.write('b'); vacuuming=true;}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('b'); vacuuming=false;}});
  cp5.addButton("-5").setPosition(500,10).setSize(80,80).moveTo(vacuumGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('-'); myPort.write('a'); vacuuming=true;}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('a'); vacuuming=false;}});
}

void setupReleaseButtons(){
  cp5.addButton("^1").setPosition(100,10).setSize(80,80).moveTo(releaseGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('^'); myPort.write('p');}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('p');}});
  cp5.addButton("^2").setPosition(200,10).setSize(80,80).moveTo(releaseGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('^'); myPort.write('h');}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('h');}});
  cp5.addButton("^3").setPosition(300,10).setSize(80,80).moveTo(releaseGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('^'); myPort.write('d');}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('d');}});
  cp5.addButton("^4").setPosition(400,10).setSize(80,80).moveTo(releaseGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('^'); myPort.write('b');}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('b');}});
  cp5.addButton("^5").setPosition(500,10).setSize(80,80).moveTo(releaseGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('^'); myPort.write('a');}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('a');}});
}

void setupSenseButtons(){
  cp5.addButton("?1").setPosition(100,10).setSize(80,80).moveTo(senseGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('?'); myPort.write('p');}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('p');}});
  cp5.addButton("?2").setPosition(200,10).setSize(80,80).moveTo(senseGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('?'); myPort.write('h');}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('h');}});
  cp5.addButton("?3").setPosition(300,10).setSize(80,80).moveTo(senseGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('?'); myPort.write('d');}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('d');}});
  cp5.addButton("?4").setPosition(400,10).setSize(80,80).moveTo(senseGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('?'); myPort.write('b');}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('b');}});
  cp5.addButton("?5").setPosition(500,10).setSize(80,80).moveTo(senseGroup)
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('?'); myPort.write('a');}})
    .onRelease(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('!'); myPort.write('a');}});
}

void setupBarOnTop(){
  PImage[] pwrIcons = {loadImage("pwrOn.png"),loadImage("pwrHover.png"),loadImage("pwrOff.png")};
  cp5.addButton("PWR").setPosition(800,10).setImages(pwrIcons).updateSize()
     .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {myPort.write('f'); myPort.write('f');}});
  
  
  PImage[] blueLedIcons = {loadImage("blueLedOff.png"),loadImage("blueLedOn.png")};
  cp5.addToggle("blueLed").setPosition(720,15).setImages(blueLedIcons).updateSize()
     .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {
       if(blueLed){myPort.write('b'); myPort.write('1');}
       else{       myPort.write('b'); myPort.write(0x00);}}});
  
  PImage[] redLedIcons = {loadImage("redLedOff.png"),loadImage("redLedOn.png")};
  cp5.addToggle("redLed").setPosition(650,15).setImages(redLedIcons).updateSize()
    .onPress(new CallbackListener(){public void controlEvent(CallbackEvent theEvent) {
      if(redLed){myPort.write('r'); myPort.write('1');}
       else{       myPort.write('r'); myPort.write(0x00);}}});
 
 pressureGaugeImage = loadImage("pressure.png"); 
 pressureValLabel = cp5.addTextlabel("pressureValue")
                       .setPosition(350,15)
                       .setFont(createFont("Verdana",30))
                       .setText("?");
  
 batteryImage = loadImage("battery.png");
 batteryPercentageLabel = cp5.addTextlabel("batteryPercentage")
                       .setPosition(90,15)
                       .setFont(createFont("Verdana",30))
                       .setText("?");
}

void setupPressureKnobs(){
  minPressureKnob = cp5.addKnob("minP")
                       .setRange(0,15)
                       .setPosition(100,5)
                       .setRadius(50)
                       .setDragDirection(Knob.HORIZONTAL)
                       .setColorForeground(color(255,255,0))
                       .setColorBackground(color(0, 160, 100))
                       .setColorActive(color(255,255,0))
                       .setDefaultValue(15.0)
                       .setLabel("P min")
                       .setValue(8)
                       .moveTo(pressureLimitsGroup)
                       ;
  maxPressureKnob = cp5.addKnob("maxP")
                       .setRange(15,20)
                       .setPosition(280,5)
                       .setRadius(50)
                       .setDragDirection(Knob.HORIZONTAL)
                       .setColorForeground(color(255,255,0))
                       .setColorBackground(color(0, 160, 100))
                       .setColorActive(color(255,255,0))
                       .setDefaultValue(15.0)
                       .setLabel("P max")
                       .setValue(18)
                       .moveTo(pressureLimitsGroup)
                       ;
                       
} 


void setupAccordion(){  
  pressureLimitsGroup = cp5.addGroup("Pressure Limits")
                          .setBackgroundColor(color(0,64))
                          .setBarHeight(25)
                          .setColorBackground(color(0,64))
                          .setColorForeground(color(0,64))
                          .setBackgroundHeight(150)
                          ;
  
  multiportControlGroup = cp5.addGroup("Multiport Control")
                          .setBackgroundColor(color(0,64))
                          .setBarHeight(25)
                          .setColorBackground(color(0,64))
                          .setColorForeground(color(0,64))
                          .setBackgroundHeight(150)
                          ;
  
  inflationGroup = cp5.addGroup("InflationGroup")
                          .setBackgroundColor(color(0,64))
                          .setBarHeight(25)
                          .setColorBackground(color(0,64))
                          .setColorForeground(color(0,64))
                          .setCaptionLabel("Inflation")
                          ;
  vacuumGroup = cp5.addGroup("VacuumGroup")
                          .setBackgroundColor(color(0,64))
                          .setBarHeight(25)
                          .setColorBackground(color(0,64))
                          .setColorForeground(color(0,64))
                          .setCaptionLabel("Vacuum")
                          ;
  releaseGroup = cp5.addGroup("ReleaseGroup")
                          .setBackgroundColor(color(0,64))
                          .setBarHeight(25)
                          .setColorBackground(color(0,64))
                          .setColorForeground(color(0,64))
                          .setCaptionLabel("Release")
                          ;
  senseGroup = cp5.addGroup("SenseGroup")
                          .setBackgroundColor(color(0,64))
                          .setBarHeight(25)
                          .setColorBackground(color(0,64))
                          .setColorForeground(color(0,64))
                          .setCaptionLabel("Sense")
                          ;                          
  accordion = cp5.addAccordion("accd")
                 .setPosition(50,90)
                 .setWidth(800)
                 .addItem(pressureLimitsGroup)
                 .addItem(multiportControlGroup)
                 .addItem(inflationGroup)
                 .addItem(vacuumGroup)
                 .addItem(releaseGroup)
                 .addItem(senseGroup)
                 .open(0,1)
                 .setCollapseMode(Accordion.MULTI);
                 ;
}  
