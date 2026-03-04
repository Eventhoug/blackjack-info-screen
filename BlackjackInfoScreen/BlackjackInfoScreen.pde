// Blackjack Info Screen 
// Sensorer: 1 = deal, 2 = hit, 3 = stand, 4 = ubrugt, 5 = back

import processing.serial.*;

Serial port;
boolean[] sensorSidstAktiv = new boolean[5]; // Edge detection for sensorer
final float SENSOR_THRESHOLD = 30.0;         // cm — hånd tættere end dette = tryk

BlackjackGame blackjack;

void setup() {
  fullScreen();
  smooth(8);
  frameRate(60);
  blackjack = new BlackjackGame(0, 0, width, height);

  // Serial setup — forbind til Arduino
  String[] porte = Serial.list();
  println("Tilgængelige porte:");
  for (int i = 0; i < porte.length; i++) {
    println("  [" + i + "] " + porte[i]);
  }
  if (porte.length > 0) {
    port = new Serial(this, porte[0], 115200); // Juster index hvis nødvendigt
    port.bufferUntil('\n');
  } else {
    println("ADVARSEL: Ingen seriel port fundet — kører uden sensorer");
  }
}

void draw() {
  blackjack.bjDisplay();

  // Luk spillet hvis back-knappen trykkes
  if (blackjack.bjBackRequested) {
    exit();
  }
}

void mousePressed() {
  blackjack.bjHandleClick(mouseX, mouseY);
}

void keyPressed() {
  blackjack.bjHandleKey(key);
}

// Modtag sensordata fra Arduino: "dist1 dist2 dist3 dist4 dist5\n"
void serialEvent(Serial p) {
  String linje = trim(p.readStringUntil('\n'));
  if (linje == null || linje.length() == 0) return;

  String[] dele = split(linje, ' ');
  if (dele.length != 5) return;

  for (int i = 0; i < 5; i++) {
    float afstand = float(dele[i]);
    boolean aktivNu = afstand > 0 && afstand < SENSOR_THRESHOLD;

    // Rising edge — kun trigger ved overgang fra langt til tæt
    if (aktivNu && !sensorSidstAktiv[i]) {
      switch (i) {
        case 0: blackjack.bjButton1 = true; break; // DEAL
        case 1: blackjack.bjButton2 = true; break; // HIT
        case 2: blackjack.bjButton3 = true; break; // STAND
        case 3: blackjack.bjButton4 = true; break; // (ubrugt)
        case 4: blackjack.bjButton5 = true; break; // BACK
      }
    }
    sensorSidstAktiv[i] = aktivNu;
  }
}
