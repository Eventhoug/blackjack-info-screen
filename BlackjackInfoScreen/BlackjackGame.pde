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
    color feltGreen = color(26, 71, 42);
    color feltDark = color(15, 45, 26);
    color goldColor = color(244, 208, 63);
    color borderColor = color(139, 105, 20);
    color textLight = color(255, 255, 255, 220);
    color textMuted = color(255, 255, 255, 130);
    
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
        float btnY = y + h - 80;
        float btnW = 120;
        float btnH = 50;
        float btnSpacing = 20;
        float totalBtnW = btnW * 3 + btnSpacing * 2;
        float btnStartX = x + (w - totalBtnW) / 2;
        
        dealBtn = new Button(btnStartX, btnY, btnW, btnH, "DEAL", color(244, 208, 63), color(30, 30, 30));
        hitBtn = new Button(btnStartX + btnW + btnSpacing, btnY, btnW, btnH, "HIT", color(46, 204, 113), color(255));
        standBtn = new Button(btnStartX + (btnW + btnSpacing) * 2, btnY, btnW, btnH, "STAND", color(231, 76, 60), color(255));
        
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
        // Table background with rounded top
        noStroke();
        
        // Main felt
        fill(feltGreen);
        rect(0, 0, w, h, 150, 150, 20, 20);
        
        // Inner shadow/gradient effect
        for (int i = 0; i < 50; i++) {
            float alpha = map(i, 0, 50, 30, 0);
            fill(0, alpha);
            rect(i, i, w - i*2, h - i*2, 150 - i, 150 - i, 20, 20);
        }
        
        // Gold border
        noFill();
        stroke(borderColor);
        strokeWeight(8);
        rect(4, 4, w - 8, h - 8, 146, 146, 16, 16);
        
        // Inner gold line
        stroke(201, 162, 39, 80);
        strokeWeight(2);
        rect(15, 15, w - 30, h - 30, 140, 140, 15, 15);
    }
    
    void drawHeader() {
        // Title
        textAlign(CENTER, CENTER);
        textSize(36);
        fill(goldColor);
        text("♠ BLACKJACK ♥", w/2, 50);
        
        // Stats
        float statY = 45;
        float statSpacing = 100;
        float statStartX = w - 350;
        
        textSize(12);
        fill(textMuted);
        text("WINS", statStartX, statY - 12);
        text("LOSSES", statStartX + statSpacing, statY - 12);
        text("TIES", statStartX + statSpacing * 2, statY - 12);
        
        textSize(24);
        fill(goldColor);
        text(wins, statStartX, statY + 12);
        text(losses, statStartX + statSpacing, statY + 12);
        text(ties, statStartX + statSpacing * 2, statY + 12);
    }
    
    void drawRules() {
        textAlign(CENTER, CENTER);
        fill(255, 255, 255, 40);
        textSize(16);
        text("DEALER STANDS ON SOFT 17", w/2, h/2 - 20);
        textSize(12);
        text("BLACKJACK PAYS 3 TO 2", w/2, h/2 + 5);
        text("INSURANCE PAYS 2 TO 1", w/2, h/2 + 25);
    }
    
    void drawHands() {
        float cardW = 80;
        float cardH = 112;
        float cardSpacing = 15;
        
        // Dealer hand
        float dealerY = 120;
        textAlign(LEFT, CENTER);
        textSize(14);
        fill(textLight);
        text("DEALER", 50, dealerY);
        
        // Dealer value
        int dealerVal = dealerRevealed ? calculateHandValue(dealerHand) : getVisibleDealerValue();
        String dealerValStr = dealerRevealed ? str(dealerVal) : (dealerVal + "?");
        
        fill(0, 0, 0, 100);
        rect(w - 100, dealerY - 18, 60, 36, 6);
        fill(goldColor);
        textAlign(CENTER, CENTER);
        textSize(20);
        text(dealerValStr, w - 70, dealerY);
        
        // Draw dealer cards
        float dealerCardsX = (w - (dealerHand.size() * (cardW + cardSpacing) - cardSpacing)) / 2;
        for (int i = 0; i < dealerHand.size(); i++) {
            Card card = dealerHand.get(i);
            boolean hidden = (i == 1 && !dealerRevealed);
            drawCard(dealerCardsX + i * (cardW + cardSpacing), dealerY + 30, cardW, cardH, card, hidden);
        }
        
        // Player hand
        float playerY = h - 250;
        textAlign(LEFT, CENTER);
        textSize(14);
        fill(textLight);
        text("PLAYER", 50, playerY);
        
        // Player value
        int playerVal = calculateHandValue(playerHand);
        fill(0, 0, 0, 100);
        rect(w - 100, playerY - 18, 60, 36, 6);
        fill(goldColor);
        textAlign(CENTER, CENTER);
        textSize(20);
        text(playerVal, w - 70, playerY);
        
        // Draw player cards
        float playerCardsX = (w - (playerHand.size() * (cardW + cardSpacing) - cardSpacing)) / 2;
        for (int i = 0; i < playerHand.size(); i++) {
            Card card = playerHand.get(i);
            drawCard(playerCardsX + i * (cardW + cardSpacing), playerY + 30, cardW, cardH, card, false);
        }
    }
    
    void drawCard(float cx, float cy, float cw, float ch, Card card, boolean hidden) {
        // Card shadow
        noStroke();
        fill(0, 60);
        rect(cx + 4, cy + 4, cw, ch, 8);
        
        if (hidden) {
            // Card back
            fill(30, 58, 95);
            rect(cx, cy, cw, ch, 8);
            
            // Pattern
            fill(255, 20);
            textAlign(CENTER, CENTER);
            textSize(10);
            text("♠ ♥ ♦ ♣", cx + cw/2, cy + ch/2);
        } else {
            // Card front
            fill(255);
            rect(cx, cy, cw, ch, 8);
            
            // Card color
            if (card.suit.equals("♥") || card.suit.equals("♦")) {
                fill(196, 30, 58);
            } else {
                fill(30, 30, 30);
            }
            
            // Top corner
            textAlign(CENTER, TOP);
            textSize(18);
            text(card.rank, cx + 15, cy + 8);
            textSize(16);
            text(card.suit, cx + 15, cy + 26);
            
            // Center suit (faded)
            fill(red(color(196, 30, 58)), green(color(196, 30, 58)), blue(color(196, 30, 58)), 40);
            if (card.suit.equals("♥") || card.suit.equals("♦")) {
                fill(196, 30, 58, 40);
            } else {
                fill(30, 30, 30, 40);
            }
            textSize(40);
            textAlign(CENTER, CENTER);
            text(card.suit, cx + cw/2, cy + ch/2);
            
            // Bottom corner (rotated)
            pushMatrix();
            translate(cx + cw - 15, cy + ch - 20);
            rotate(PI);
            if (card.suit.equals("♥") || card.suit.equals("♦")) {
                fill(196, 30, 58);
            } else {
                fill(30, 30, 30);
            }
            textAlign(CENTER, TOP);
            textSize(18);
            text(card.rank, 0, -12);
            textSize(16);
            text(card.suit, 0, 6);
            popMatrix();
        }
    }
    
    void drawStatus() {
        float statusY = h/2 + 60;
        
        // Status background
        textSize(18);
        float statusW = textWidth(gameStatus) + 40;
        float statusH = 40;
        float statusX = (w - statusW) / 2;
        
        // Color based on status type
        if (statusType.equals("win")) {
            fill(46, 204, 113, 80);
            stroke(46, 204, 113, 150);
        } else if (statusType.equals("lose")) {
            fill(231, 76, 60, 80);
            stroke(231, 76, 60, 150);
        } else if (statusType.equals("tie")) {
            fill(52, 152, 219, 80);
            stroke(52, 152, 219, 150);
        } else if (statusType.equals("blackjack")) {
            fill(goldColor);
            stroke(goldColor);
        } else {
            fill(0, 120);
            stroke(255, 50);
        }
        
        strokeWeight(1);
        rect(statusX, statusY - statusH/2, statusW, statusH, 20);
        
        // Status text
        textAlign(CENTER, CENTER);
        if (statusType.equals("blackjack")) {
            fill(30);
        } else if (statusType.equals("win")) {
            fill(93, 252, 141);
        } else if (statusType.equals("lose")) {
            fill(255, 123, 107);
        } else if (statusType.equals("tie")) {
            fill(126, 200, 248);
        } else {
            fill(textLight);
        }
        text(gameStatus, w/2, statusY);
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
        float localX = mx - x;
        float localY = my - y;
        
        if (dealBtn.isClicked(localX, localY) && dealBtn.enabled) {
            startGame();
        }
        if (hitBtn.isClicked(localX, localY) && hitBtn.enabled) {
            hit();
        }
        if (standBtn.isClicked(localX, localY) && standBtn.enabled) {
            stand();
        }
    }
    
    // Handle key presses
    void handleKey(char k) {
        if (k == 'd' || k == 'D') startGame();
        if ((k == 'h' || k == 'H') && hitBtn.enabled) hit();
        if ((k == 's' || k == 'S') && standBtn.enabled) stand();
    }
    
    // Game logic
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
