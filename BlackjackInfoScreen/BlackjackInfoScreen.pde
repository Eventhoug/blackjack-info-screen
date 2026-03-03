// Blackjack Info Screen 
// Controls: 1 = deal, 2 = hit, 3 = stand  (Eller kilk på knapper)

// Eksterne knapper — sæt til true for at aktivere
boolean bjButton1 = false; // DEAL
boolean bjButton2 = false; // HIT
boolean bjButton3 = false; // STAND
boolean bjButton4 = false; // BACK

BlackjackGame blackjack;

void setup() {
  fullScreen();
  smooth(8);
  frameRate(60);
  blackjack = new BlackjackGame(0, 0, width, height);
}

void draw() {
  blackjack.display();
  
 
 
// deal knap — kun på rising edge og når knappen er aktiv
  if (bjButton1 && blackjack.bjDealBtn.bjEnabled) {
    blackjack.startGame();
    bjButton1 = false;
  }

  // hit knap
  if (bjButton2 && blackjack.bjHitBtn.bjEnabled) {
    blackjack.playerHit();
    bjButton2 = false;
  }

  // stand knap
  if (bjButton3 && blackjack.bjStandBtn.bjEnabled) {
    blackjack.playerStand();
    bjButton3 = false;
  }

  // Luk spillet hvis midter knappen (Knappen med pilen) trykkes
  if (bjButton4) {
    blackjack.bjBackRequested = true;
    bjButton4 = false;
  }

}

void mousePressed() {
  blackjack.handleClick(mouseX, mouseY);
}

void keyPressed() {
  blackjack.handleKey(key);
}
