// Blackjack Info Screen 
// Lowkey tror ikke det er nødvendigt at have denne fane så bare lav den om trust fr fr
// Controls: 1 = deal, 2 = hit, 3 = stand  (Eller kilk på knapper)

BlackjackGame blackjack;

void setup() {
  fullScreen();
  smooth(8);
  frameRate(60);
  blackjack = new BlackjackGame(0, 0, width, height);
}

void draw() {
  blackjack.display();
  
  // Luk spillet hvis midter knappen (Knappen med pilen) trykkes
  //#TODO lav om til at gå tilbage
  if (blackjack.bjBackRequested) {
    exit();
  }
}

void mousePressed() {
  blackjack.handleClick(mouseX, mouseY);
}

void keyPressed() {
  blackjack.handleKey(key);
}
