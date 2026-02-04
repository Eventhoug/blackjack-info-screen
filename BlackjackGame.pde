// BlackjackGame Class - Easy to integrate into any Processing sketch
// Usage:
//   BlackjackGame game = new BlackjackGame(x, y, width, height);
//   game.display();  // Call in draw()
//   game.handleClick(mouseX, mouseY);  // Call in mousePressed()

class BlackjackGame {
  // Position and size
  float x, y, w, h;

  // Game state
  ArrayList<Card> playerHand;
  ArrayList<Card> dealerHand;
  ArrayList<Card> deck;
  boolean gameActive = false;
  boolean dealerRevealed = false;
  String gameStatus = "Press DEAL to start";
  String statusType = "";

  // Stats
  int wins = 0;
  int losses = 0;
  int ties = 0;

  // Colors
  color feltGreen = #35654d; // Casino Green
  color feltDark = #204030;  // Darker shade for vignette
  color goldColor = #d4af37;
  color borderColor = #8b6914;
  color textLight = color(255);
  color textMuted = color(200);

  // Buttons
  Button dealBtn, hitBtn, standBtn;

  // Animation
  ArrayList<CardAnimation> animations;

  BlackjackGame(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;

    playerHand = new ArrayList<Card>();
    dealerHand = new ArrayList<Card>();
    deck = new ArrayList<Card>();
    animations = new ArrayList<CardAnimation>();

    // Create buttons
    float btnY = y + h - 90;
    float btnW = 140;
    float btnH = 50;
    float btnSpacing = 30;
    float totalBtnW = btnW * 3 + btnSpacing * 2;
    float btnStartX = x + (w - totalBtnW) / 2;

    dealBtn = new Button(btnStartX, btnY, btnW, btnH, "DEAL", #f1c40f, #2c3e50);
    hitBtn = new Button(btnStartX + btnW + btnSpacing, btnY, btnW, btnH, "HIT", #2ecc71, #2c3e50);
    standBtn = new Button(btnStartX + (btnW + btnSpacing) * 2, btnY, btnW, btnH, "STAND", #e74c3c, #ecf0f1);

    hitBtn.enabled = false;
    standBtn.enabled = false;
  }

  void display() {
    pushMatrix();
    translate(x, y);

    // Draw casino table
    drawTable();

    // Draw header
    drawHeader();

    // Draw table rules
    drawRules();

    // Draw hands
    drawHands();

    // Draw status
    drawStatus();

    // Draw buttons
    dealBtn.display();
    hitBtn.display();
    standBtn.display();

    // Update animations
    updateAnimations();

    popMatrix();
  }

  void drawTable() {
    // Main Table Shape
    noStroke();
    fill(feltGreen);
    rect(0, 0, w, h, 30);

    // Vignette (Radial Gradient workaround)
    for (float r = 0; r < max(w, h); r += 10) {
      float alpha = map(r, 0, max(w, h)*0.6, 0, 150);
      noFill();
      stroke(0, alpha);
      strokeWeight(10);
      rect(r/2, r/2, w - r, h - r, 30);
    }

    // Gold Border System
    noFill();
    strokeWeight(12);
    stroke(#5a4208); // Dark gold shadow
    rect(6, 6, w - 12, h - 12, 24);

    strokeWeight(8);
    stroke(goldColor); // Main gold
    rect(6, 6, w - 12, h - 12, 24);

    strokeWeight(2);
    stroke(255, 100); // Highlight
    rect(8, 8, w - 16, h - 16, 22);
  }

  void drawHeader() {
    // Title
    textAlign(CENTER, CENTER);

    // Header Background
    fill(0, 80);
    noStroke();
    rect(w/2 - 200, 20, 400, 60, 30);

    textSize(42);
    fill(goldColor);
    text("BLACKJACK", w/2, 48);

    // Stats Container
    float statY = 40;
    float statStartX = w - 400;

    fill(0, 60);
    rect(statStartX - 20, 15, 360, 70, 15);

    drawStat("WINS", wins, statStartX + 40, statY);
    drawStat("LOSSES", losses, statStartX + 160, statY);
    drawStat("TIES", ties, statStartX + 280, statY);
  }

  void drawStat(String label, int value, float x, float y) {
    textAlign(CENTER);
    textSize(12);
    fill(textMuted);
    text(label, x, y);
    textSize(28);
    fill(textLight);
    text(value, x, y + 25);
  }

  void drawRules() {
    textAlign(CENTER, CENTER);
    fill(255, 30);
    textSize(18);
    text("DEALER STANDS ON SOFT 17", w/2, h/2 - 40);
    textSize(14);
    text("BLACKJACK PAYS 3 TO 2 • INSURANCE PAYS 2 TO 1", w/2, h/2 - 10);
  }

  void drawHands() {
    float cardW = 100;
    float cardH = 140;
    float cardSpacing = 20;

    // Dealer hand
    float dealerY = 160;
    textAlign(LEFT, CENTER);
    textSize(18);
    fill(textMuted);
    text("DEALER", w/2 - 300, dealerY - 30);

    // Dealer value bubble
    int dealerVal = dealerRevealed ? calculateHandValue(dealerHand) : getVisibleDealerValue();
    String dealerValStr = dealerRevealed ? str(dealerVal) : (dealerVal + "?");
    drawValueBubble(dealerValStr, w/2 + 250, dealerY - 30);

    // Draw dealer cards
    float startX = (w - (dealerHand.size() * (cardW + cardSpacing))) / 2;
    for (int i = 0; i < dealerHand.size(); i++) {
      Card card = dealerHand.get(i);
      boolean hidden = (i == 1 && !dealerRevealed);
      drawCard(startX + i * (cardW + cardSpacing), dealerY, cardW, cardH, card, hidden);
    }

    // Player hand
    float playerY = h - 280;
    textAlign(LEFT, CENTER);
    textSize(18);
    fill(textMuted);
    text("PLAYER", w/2 - 300, playerY - 30);

    // Player value bubble
    int playerVal = calculateHandValue(playerHand);
    drawValueBubble(str(playerVal), w/2 + 250, playerY - 30);

    // Draw player cards
    startX = (w - (playerHand.size() * (cardW + cardSpacing))) / 2;
    for (int i = 0; i < playerHand.size(); i++) {
      Card card = playerHand.get(i);
      drawCard(startX + i * (cardW + cardSpacing), playerY, cardW, cardH, card, false);
    }
  }

  void drawValueBubble(String val, float x, float y) {
    noStroke();
    fill(0, 150);
    ellipse(x, y, 40, 40);
    stroke(goldColor);
    strokeWeight(2);
    noFill();
    ellipse(x, y, 40, 40);

    fill(goldColor);
    textSize(20);
    textAlign(CENTER, CENTER);
    text(val, x, y - 2);
  }

  void drawCard(float cx, float cy, float cw, float ch, Card card, boolean hidden) {
    // Shadow
    noStroke();
    fill(0, 50);
    rect(cx + 6, cy + 6, cw, ch, 10);

    if (hidden) {
      // Card Back
      stroke(255);
      strokeWeight(3);
      fill(#2c3e50); // Dark Blue
      rect(cx, cy, cw, ch, 10);

      // Pattern
      noStroke();
      fill(255, 15);
      ellipse(cx + cw/2, cy + ch/2, cw*0.6, cw*0.6);
      fill(255, 100);
      textSize(24);
      textAlign(CENTER, CENTER);
      text("BJ", cx + cw/2, cy + ch/2);
    } else {
      // Card Front
      stroke(200);
      strokeWeight(1);
      fill(245); // Warm White
      rect(cx, cy, cw, ch, 10);

      // Determine Color
      boolean isRed = card.suit.equals("♥") || card.suit.equals("♦");
      color txtColor = isRed ? #c0392b : #2c3e50;

      fill(txtColor);

      // Top Corner
      textAlign(CENTER, TOP);
      textSize(22);
      text(card.rank, cx + 20, cy + 10);
      drawSuit(cx + 8, cy + 35, 24, 24, card.suit);

      // Center Suit (Large)
      drawSuit(cx + cw/2 - 25, cy + ch/2 - 25, 50, 50, card.suit);

      // Bottom Corner (Rotated)
      pushMatrix();
      translate(cx + cw - 20, cy + ch - 10);
      rotate(PI);
      fill(txtColor); // Reset fill after rotate
      textSize(22);
      text(card.rank, 0, 0);
      drawSuit(-12, 25, 24, 24, card.suit);
      popMatrix();
    }
  }

  void drawStatus() {
    if (gameStatus.length() == 0) return;

    float statusY = h/2 + 60;
    textSize(24);
    float sw = textWidth(gameStatus) + 60;

    // Pill Background
    noStroke();
    fill(20, 20, 20, 200);
    rect((w - sw)/2, statusY - 30, sw, 60, 30);

    // Colored Border based on state
    if (statusType.equals("win")) stroke(#2ecc71);
    else if (statusType.equals("lose")) stroke(#e74c3c);
    else if (statusType.equals("blackjack")) stroke(#f1c40f);
    else stroke(255, 100);

    strokeWeight(3);
    noFill();
    rect((w - sw)/2, statusY - 30, sw, 60, 30);

    // Text
    fill(255);
    if (statusType.equals("blackjack")) fill(#f1c40f);
    textAlign(CENTER, CENTER);
    text(gameStatus, w/2, statusY - 4);
  }

  void updateAnimations() {
    for (int i = animations.size() - 1; i >= 0; i--) {
      CardAnimation anim = animations.get(i);
      anim.update();
      if (anim.finished) {
        animations.remove(i);
      }
    }
  }

  // Handle mouse clicks
  void handleClick(float mx, float my) {
    // Adjust mouse based on translation if needed, but here it's 1:1
    if (dealBtn.isClicked(mx, my) && dealBtn.enabled) startGame();
    if (hitBtn.isClicked(mx, my) && hitBtn.enabled) hit();
    if (standBtn.isClicked(mx, my) && standBtn.enabled) stand();
  }

  // Handle key presses
  void handleKey(char k) {
    if (k == 'd' || k == 'D') startGame();
    if ((k == 'h' || k == 'H') && hitBtn.enabled) hit();
    if ((k == 's' || k == 'S') && standBtn.enabled) stand();
  }

  // Game logic (Deck, Values, etc.)
  void createDeck() {
    deck.clear();
    String[] suits = {"♠", "♥", "♦", "♣"};
    String[] ranks = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"};

    for (String suit : suits) {
      for (String rank : ranks) {
        deck.add(new Card(suit, rank));
      }
    }

    // Shuffle
    for (int i = deck.size() - 1; i > 0; i--) {
      int j = int(random(i + 1));
      Card temp = deck.get(i);
      deck.set(i, deck.get(j));
      deck.set(j, temp);
    }
  }

  Card drawCardFromDeck() {
    if (deck.size() == 0) createDeck();
    return deck.remove(deck.size() - 1);
  }

  int calculateHandValue(ArrayList<Card> hand) {
    int value = 0;
    int aces = 0;

    for (Card card : hand) {
      if (card.rank.equals("A")) {
        aces++;
        value += 11;
      } else if (card.rank.equals("K") || card.rank.equals("Q") || card.rank.equals("J")) {
        value += 10;
      } else {
        value += int(card.rank);
      }
    }

    while (value > 21 && aces > 0) {
      value -= 10;
      aces--;
    }

    return value;
  }

  int getVisibleDealerValue() {
    if (dealerHand.size() == 0) return 0;
    Card first = dealerHand.get(0);
    if (first.rank.equals("A")) return 11;
    if (first.rank.equals("K") || first.rank.equals("Q") || first.rank.equals("J")) return 10;
    return int(first.rank);
  }

  boolean isBlackjack(ArrayList<Card> hand) {
    return hand.size() == 2 && calculateHandValue(hand) == 21;
  }

  void startGame() {
    createDeck();
    playerHand.clear();
    dealerHand.clear();
    gameActive = true;
    dealerRevealed = false;

    playerHand.add(drawCardFromDeck());
    dealerHand.add(drawCardFromDeck());
    playerHand.add(drawCardFromDeck());
    dealerHand.add(drawCardFromDeck());

    if (isBlackjack(playerHand)) {
      if (isBlackjack(dealerHand)) {
        endGame("tie", "Both have Blackjack! Push!");
      } else {
        endGame("blackjack", "BLACKJACK!");
      }
      return;
    }

    if (isBlackjack(dealerHand)) {
      endGame("lose", "Dealer has Blackjack!");
      return;
    }

    gameStatus = "Your turn - Hit or Stand?";
    statusType = "";
    dealBtn.enabled = false;
    hitBtn.enabled = true;
    standBtn.enabled = true;
  }

  void hit() {
    if (!gameActive) return;

    playerHand.add(drawCardFromDeck());
    int playerValue = calculateHandValue(playerHand);

    if (playerValue > 21) {
      endGame("lose", "Bust! You went over 21");
    } else if (playerValue == 21) {
      stand();
    }
  }

  void stand() {
    if (!gameActive) return;

    hitBtn.enabled = false;
    standBtn.enabled = false;
    dealerRevealed = true;
    gameStatus = "Dealer's turn...";

    dealerPlay();
  }

  void dealerPlay() {
    int dealerValue = calculateHandValue(dealerHand);
    int playerValue = calculateHandValue(playerHand);

    while (dealerValue < 17) {
      dealerHand.add(drawCardFromDeck());
      dealerValue = calculateHandValue(dealerHand);
    }

    if (dealerValue > 21) {
      endGame("win", "Dealer busts! You win!");
    } else if (dealerValue > playerValue) {
      endGame("lose", "Dealer wins with " + dealerValue);
    } else if (playerValue > dealerValue) {
      endGame("win", "You win with " + playerValue + "!");
    } else {
      endGame("tie", "Push! It's a tie");
    }
  }

  void endGame(String result, String message) {
    gameActive = false;
    dealerRevealed = true;
    gameStatus = message;
    statusType = result;

    if (result.equals("win") || result.equals("blackjack")) {
      wins++;
    } else if (result.equals("lose")) {
      losses++;
    } else {
      ties++;
    }

    dealBtn.enabled = true;
    hitBtn.enabled = false;
    standBtn.enabled = false;
  }
}
