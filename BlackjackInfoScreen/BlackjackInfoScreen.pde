// Main Processing Sketch - Blackjack Info Screen Game
// Easy integration: just call BlackjackGame.display() in your draw() function

BlackjackGame blackjack;

void setup() {
  fullScreen();
  smooth(8); // Enable antialiasing for better quality
  frameRate(60); // Cap at 60fps for optimal performance
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
