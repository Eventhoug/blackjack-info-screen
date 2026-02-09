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

  // Performance optimization
  PGraphics tableBuffer;
  boolean needsRedraw = true;

  // Auto-scaling for fullscreen
  float scale = 1.0;

  BlackjackGame(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;

    // Calculate scale factor based on screen size (1920x1080 is reference)
    float scaleX = w / 1920.0;
    float scaleY = h / 1080.0;
    scale = min(scaleX, scaleY); // Use the smaller scale to ensure everything fits

    playerHand = new ArrayList<Card>();
    dealerHand = new ArrayList<Card>();
    deck = new ArrayList<Card>();
    animations = new ArrayList<CardAnimation>();

    // Create buttons - auto-scaled based on screen size
    float btnY = y + h - (120 * scale);
    float btnW = 180 * scale;
    float btnH = 65 * scale;
    float btnSpacing = 40 * scale;
    float totalBtnW = btnW * 3 + btnSpacing * 2;
    float btnStartX = x + (w - totalBtnW) / 2;

    dealBtn = new Button(btnStartX, btnY, btnW, btnH, "DEAL", #f1c40f, #2c3e50);
    hitBtn = new Button(btnStartX + btnW + btnSpacing, btnY, btnW, btnH, "HIT", #2ecc71, #2c3e50);
    standBtn = new Button(btnStartX + (btnW + btnSpacing) * 2, btnY, btnW, btnH, "STAND", #e74c3c, #ecf0f1);

    hitBtn.enabled = false;
    standBtn.enabled = false;

    // Create and cache table background
    createTableBuffer();
  }

  void createTableBuffer() {
    tableBuffer = createGraphics(int(w), int(h));
    tableBuffer.beginDraw();

    // Single solid background shape - sharp corners
    tableBuffer.noStroke();
    tableBuffer.fill(feltGreen);
    tableBuffer.rect(0, 0, w, h);

    // Gold Border System - sharp corners
    tableBuffer.noFill();
    tableBuffer.strokeWeight(12);
    tableBuffer.stroke(#5a4208); // Dark gold shadow
    tableBuffer.rect(6, 6, w - 12, h - 12);

    tableBuffer.strokeWeight(8);
    tableBuffer.stroke(goldColor); // Main gold
    tableBuffer.rect(6, 6, w - 12, h - 12);

    tableBuffer.strokeWeight(2);
    tableBuffer.stroke(255, 100); // Highlight
    tableBuffer.rect(8, 8, w - 16, h - 16);

    tableBuffer.endDraw();
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
    // Use pre-rendered cached buffer - massive performance boost!
    if (tableBuffer != null) {
      image(tableBuffer, 0, 0);
    }
  }

  void drawHeader() {
    // Title
    textAlign(CENTER, CENTER);

    // Header Background
    fill(0, 80);
    noStroke();
    rect(w/2 - 250*scale, 25*scale, 500*scale, 75*scale, 30*scale);

    textSize(52*scale);
    fill(goldColor);
    text("BLACKJACK", w/2, 60*scale);

    // Stats Container - auto-scaled
    float statY = 50*scale;
    float statStartX = w - 480*scale;

    fill(0, 60);
    rect(statStartX - 25*scale, 20*scale, 440*scale, 85*scale, 15*scale);

    drawStat("WINS", wins, statStartX + 50*scale, statY);
    drawStat("LOSSES", losses, statStartX + 195*scale, statY);
    drawStat("TIES", ties, statStartX + 340*scale, statY);
  }

  void drawStat(String label, int value, float x, float y) {
    textAlign(CENTER);
    textSize(16*scale);
    fill(textMuted);
    text(label, x, y);
    textSize(34*scale);
    fill(textLight);
    text(value, x, y + 30*scale);
  }

  void drawRules() {
    textAlign(CENTER, CENTER);

    // Add semi-transparent background for better visibility
    fill(0, 100);
    noStroke();
    rect(w/2 - 420*scale, h/2 - 60*scale, 840*scale, 60*scale, 15*scale);

    fill(255, 200);
    textSize(24*scale);
    text("DEALER STANDS ON SOFT 17", w/2, h/2 - 30*scale);
  }

  void drawHands() {
    float cardW = 130*scale;
    float cardH = 182*scale;
    float cardSpacing = 25*scale;

    // Dealer hand
    float dealerY = 200*scale;
    textAlign(LEFT, CENTER);
    textSize(24*scale);
    fill(textMuted);
    text("DEALER", w/2 - 380*scale, dealerY - 40*scale);

    // Dealer value bubble - show just the value without ?
    int dealerVal = dealerRevealed ? calculateHandValue(dealerHand) : getVisibleDealerValue();
    String dealerValStr = str(dealerVal);
    drawValueBubble(dealerValStr, w/2 + 320*scale, dealerY - 40*scale);

    // Draw dealer cards
    float startX = (w - (dealerHand.size() * (cardW + cardSpacing))) / 2;
    for (int i = 0; i < dealerHand.size(); i++) {
      Card card = dealerHand.get(i);
      boolean hidden = (i == 1 && !dealerRevealed);
      drawCard(startX + i * (cardW + cardSpacing), dealerY, cardW, cardH, card, hidden);
    }

    // Player hand
    float playerY = h - 340*scale;
    textAlign(LEFT, CENTER);
    textSize(24*scale);
    fill(textMuted);
    text("PLAYER", w/2 - 380*scale, playerY - 40*scale);

    // Player value bubble
    int playerVal = calculateHandValue(playerHand);
    drawValueBubble(str(playerVal), w/2 + 320*scale, playerY - 40*scale);

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
    ellipse(x, y, 50*scale, 50*scale);
    stroke(goldColor);
    strokeWeight(3*scale);
    noFill();
    ellipse(x, y, 50*scale, 50*scale);

    fill(goldColor);
    textSize(26*scale);
    textAlign(CENTER, CENTER);
    text(val, x, y - 2);
  }

  void drawCard(float cx, float cy, float cw, float ch, Card card, boolean hidden) {
    // Shadow
    noStroke();
    fill(0, 50);
    rect(cx + 6*scale, cy + 6*scale, cw, ch, 10*scale);

    if (hidden) {
      // Card Back
      stroke(255);
      strokeWeight(3*scale);
      fill(#2c3e50); // Dark Blue
      rect(cx, cy, cw, ch, 10*scale);

      // Pattern
      noStroke();
      fill(255, 15);
      ellipse(cx + cw/2, cy + ch/2, cw*0.6, cw*0.6);
      fill(255, 100);
      textSize(24*scale);
      textAlign(CENTER, CENTER);
      text("BJ", cx + cw/2, cy + ch/2);
    } else {
      // Card Front
      stroke(200);
      strokeWeight(1*scale);
      fill(245); // Warm White
      rect(cx, cy, cw, ch, 10*scale);

      // Determine Color
      boolean isRed = card.suit.equals("♥") || card.suit.equals("♦");
      color txtColor = isRed ? #c0392b : #2c3e50;

      fill(txtColor);

      // Top Corner - scaled
      textAlign(CENTER, TOP);
      textSize(cw * 0.22);
      text(card.rank, cx + cw * 0.20, cy + ch * 0.07);

      // Draw pip pattern based on card rank
      drawCardPips(cx, cy, cw, ch, card);

      // Bottom Corner (Rotated)
      pushMatrix();
      translate(cx + cw - cw * 0.20, cy + ch - ch * 0.07);
      rotate(PI);
      fill(txtColor); // Reset fill after rotate
      textSize(cw * 0.22);
      text(card.rank, 0, 0);
      popMatrix();
    }
  }

  // Draw correct number of suit pips arranged like real playing cards
  void drawCardPips(float cx, float cy, float cw, float ch, Card card) {
    String rank = card.rank;
    String suit = card.suit;

    // Ace - one large center pip
    if (rank.equals("A")) {
      float ps = cw * 0.42;
      drawSuit(cx + cw/2 - ps/2, cy + ch/2 - ps/2, ps, ps, suit);
      return;
    }

    // Face cards (J, Q, K) - large suit in center
    if (rank.equals("J") || rank.equals("Q") || rank.equals("K")) {
      float ps = cw * 0.38;
      drawSuit(cx + cw/2 - ps/2, cy + ch/2 - ps/2, ps, ps, suit);
      return;
    }

    // Number cards (2-10)
    int num = int(rank);
    float ps = cw * 0.13;

    // Column x-positions (center of pip)
    float cL = cx + cw * 0.33;
    float cC = cx + cw * 0.50;
    float cR = cx + cw * 0.67;

    // Row y-positions (center of pip) - within the card body area
    float r0 = cy + ch * 0.28;
    float r1 = cy + ch * 0.37;
    float r2 = cy + ch * 0.41;
    float r3 = cy + ch * 0.50;
    float r4 = cy + ch * 0.59;
    float r5 = cy + ch * 0.63;
    float r6 = cy + ch * 0.72;

    switch(num) {
      case 2:
        pip(cC, r0, ps, suit, false);
        pip(cC, r6, ps, suit, true);
        break;
      case 3:
        pip(cC, r0, ps, suit, false);
        pip(cC, r3, ps, suit, false);
        pip(cC, r6, ps, suit, true);
        break;
      case 4:
        pip(cL, r0, ps, suit, false);
        pip(cR, r0, ps, suit, false);
        pip(cL, r6, ps, suit, true);
        pip(cR, r6, ps, suit, true);
        break;
      case 5:
        pip(cL, r0, ps, suit, false);
        pip(cR, r0, ps, suit, false);
        pip(cC, r3, ps, suit, false);
        pip(cL, r6, ps, suit, true);
        pip(cR, r6, ps, suit, true);
        break;
      case 6:
        pip(cL, r0, ps, suit, false);
        pip(cR, r0, ps, suit, false);
        pip(cL, r3, ps, suit, false);
        pip(cR, r3, ps, suit, false);
        pip(cL, r6, ps, suit, true);
        pip(cR, r6, ps, suit, true);
        break;
      case 7:
        pip(cL, r0, ps, suit, false);
        pip(cR, r0, ps, suit, false);
        pip(cL, r3, ps, suit, false);
        pip(cR, r3, ps, suit, false);
        pip(cC, r2, ps, suit, false);
        pip(cL, r6, ps, suit, true);
        pip(cR, r6, ps, suit, true);
        break;
      case 8:
        pip(cL, r0, ps, suit, false);
        pip(cR, r0, ps, suit, false);
        pip(cL, r3, ps, suit, false);
        pip(cR, r3, ps, suit, false);
        pip(cC, r2, ps, suit, false);
        pip(cC, r4, ps, suit, true);
        pip(cL, r6, ps, suit, true);
        pip(cR, r6, ps, suit, true);
        break;
      case 9:
        pip(cL, r0, ps, suit, false);
        pip(cR, r0, ps, suit, false);
        pip(cL, r1, ps, suit, false);
        pip(cR, r1, ps, suit, false);
        pip(cC, r3, ps, suit, false);
        pip(cL, r5, ps, suit, true);
        pip(cR, r5, ps, suit, true);
        pip(cL, r6, ps, suit, true);
        pip(cR, r6, ps, suit, true);
        break;
      case 10:
        pip(cL, r0, ps, suit, false);
        pip(cR, r0, ps, suit, false);
        pip(cL, r1, ps, suit, false);
        pip(cR, r1, ps, suit, false);
        pip(cC, r2, ps, suit, false);
        pip(cC, r4, ps, suit, true);
        pip(cL, r5, ps, suit, true);
        pip(cR, r5, ps, suit, true);
        pip(cL, r6, ps, suit, true);
        pip(cR, r6, ps, suit, true);
        break;
    }
  }

  // Draw a single pip at center position, optionally inverted (rotated 180°)
  void pip(float pcx, float pcy, float ps, String suit, boolean inverted) {
    if (inverted) {
      pushMatrix();
      translate(pcx, pcy);
      rotate(PI);
      drawSuit(-ps/2, -ps/2, ps, ps, suit);
      popMatrix();
    } else {
      drawSuit(pcx - ps/2, pcy - ps/2, ps, ps, suit);
    }
  }

  void drawStatus() {
    if (gameStatus.length() == 0) return;

    float statusY = h/2 + 90*scale;
    textSize(30*scale);
    float sw = textWidth(gameStatus) + 80*scale;

    // Pill Background
    noStroke();
    fill(20, 20, 20, 200);
    rect((w - sw)/2, statusY - 38*scale, sw, 76*scale, 38*scale);

    // Colored Border based on state
    if (statusType.equals("win")) stroke(#2ecc71);
    else if (statusType.equals("lose")) stroke(#e74c3c);
    else if (statusType.equals("blackjack")) stroke(#f1c40f);
    else stroke(255, 100);

    strokeWeight(4*scale);
    noFill();
    rect((w - sw)/2, statusY - 38*scale, sw, 76*scale, 38*scale);

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
    // Convert global mouse coordinates to local game coordinates
    float localX = mx - x;
    float localY = my - y;

    if (dealBtn.isClicked(localX, localY) && dealBtn.enabled) startGame();
    if (hitBtn.isClicked(localX, localY) && hitBtn.enabled) hit();
    if (standBtn.isClicked(localX, localY) && standBtn.enabled) stand();
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

    // Shuffle - using constrained random to prevent array bounds issues
    for (int i = deck.size() - 1; i > 0; i--) {
      int j = int(random(i + 1));
      // Safety: ensure j is within valid bounds
      j = constrain(j, 0, i);
      Card temp = deck.get(i);
      deck.set(i, deck.get(j));
      deck.set(j, temp);
    }
  }

  Card drawCardFromDeck() {
    if (deck.size() == 0) {
      createDeck();
    }
    if (deck.size() == 0) {
      // Emergency fallback - should never happen
      return new Card("♠", "A");
    }
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
    animations.clear();
    gameActive = true;
    dealerRevealed = false;

    // Deal with animation
    float deckX = w/2 - 65*scale;
    float deckY = h/2 - 90*scale;
    float cardW = 130*scale;
    float cardSpacing = 25*scale;

    // Calculate positions
    float dealerY = 200*scale;
    float playerY = h - 340*scale;

    // Deal cards with staggered animation
    Card c1 = drawCardFromDeck();
    playerHand.add(c1);
    float p1X = (w - (2 * (cardW + cardSpacing))) / 2;
    animations.add(new CardAnimation(deckX, deckY, p1X, playerY));

    Card c2 = drawCardFromDeck();
    dealerHand.add(c2);
    float d1X = (w - (2 * (cardW + cardSpacing))) / 2;
    animations.add(new CardAnimation(deckX, deckY, d1X, dealerY));

    Card c3 = drawCardFromDeck();
    playerHand.add(c3);
    float p2X = p1X + cardW + cardSpacing;
    animations.add(new CardAnimation(deckX, deckY, p2X, playerY));

    Card c4 = drawCardFromDeck();
    dealerHand.add(c4);
    float d2X = d1X + cardW + cardSpacing;
    animations.add(new CardAnimation(deckX, deckY, d2X, dealerY));

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
