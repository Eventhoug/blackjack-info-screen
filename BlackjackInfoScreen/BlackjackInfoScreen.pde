// Main Processing Sketch - Blackjack Info Screen Game
// Easy integration: just call BlackjackGame.display() in your draw() function

BlackjackGame blackjack;

void setup() {
  size(1200, 800);
  blackjack = new BlackjackGame(0, 0, width, height);
}

void draw() {
  // Simply call display() to render the game
  blackjack.display();
}

void mousePressed() {
  blackjack.handleClick(mouseX, mouseY);
}

void keyPressed() {
  blackjack.handleKey(key);
}
