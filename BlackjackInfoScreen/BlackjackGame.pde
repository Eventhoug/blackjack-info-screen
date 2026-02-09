/*
 * BlackjackGame
 * A self-contained blackjack table that can be dropped into any Processing sketch.
 * All classes are prefixed "BJ" so nothing collides when merged with other code.
 *
 * Quick start:
 *   BlackjackGame game = new BlackjackGame(0, 0, width, height);
 *   // in draw()          -> game.display();
 *   // in mousePressed()  -> game.handleClick(mouseX, mouseY);
 *   // in keyPressed()    -> game.handleKey(key);
 */

class BlackjackGame {

  // --- Layout ---
  float bjX, bjY, bjW, bjH;
  float bjScale = 1.0;            // scales everything relative to 1920x1080

  // --- Hands & deck ---
  ArrayList<BJCard> bjPlayerHand, bjDealerHand, bjDeck;
  boolean bjGameActive      = false;
  boolean bjDealerRevealed  = false;
  String  bjStatus          = "Place your bet — press DEAL";
  String  bjStatusType      = "";

  // --- Score tracking ---
  int bjWins = 0, bjLosses = 0, bjTies = 0;

  // --- Palette ---
  final color BJ_FELT  = #1b5e3b;   // dark casino felt
  final color BJ_FELT2 = #17492f;   // darker felt for vignette
  final color BJ_GOLD  = #c9a94e;   // muted gold trim
  final color BJ_RED   = #b5312c;   // card-red (suits)
  final color BJ_INK   = #1a1a1a;   // card-black (suits + text)
  final color BJ_WIN   = #2ecc71;
  final color BJ_LOSE  = #e74c3c;
  final color BJ_AMBER = #e6b832;   // deal / blackjack highlight

  // --- Buttons ---
  BJButton bjDealBtn, bjHitBtn, bjStandBtn;

  // --- Deal animations ---
  ArrayList<BJCardAnim> bjAnims;

  // --- Pre-rendered table surface ---
  PGraphics bjTableBuf;


  // ----------------------------------------------------------------
  //  Setup
  // ----------------------------------------------------------------

  BlackjackGame(float x, float y, float w, float h) {
    bjX = x;
    bjY = y;
    bjW = w;
    bjH = h;
    bjScale = min(w / 1920.0, h / 1080.0);

    bjPlayerHand = new ArrayList<BJCard>();
    bjDealerHand = new ArrayList<BJCard>();
    bjDeck       = new ArrayList<BJCard>();
    bjAnims      = new ArrayList<BJCardAnim>();

    float bw = 180 * bjScale;
    float bh = 65  * bjScale;
    float gap = 40 * bjScale;
    float totalBtnW = bw * 3 + gap * 2;
    float bx = x + (w - totalBtnW) / 2;
    float by = y + h - 120 * bjScale;

    bjDealBtn  = new BJButton(bx,                 by, bw, bh, "DEAL",  BJ_AMBER, BJ_INK);
    bjHitBtn   = new BJButton(bx + bw + gap,      by, bw, bh, "HIT",   BJ_WIN,   BJ_INK);
    bjStandBtn = new BJButton(bx + (bw + gap) * 2, by, bw, bh, "STAND", BJ_LOSE,  #f0f0f0);
    bjHitBtn.bjEnabled   = false;
    bjStandBtn.bjEnabled = false;

    buildTableBuffer();
  }


  // ----------------------------------------------------------------
  //  Table surface  (drawn once into an off-screen buffer)
  // ----------------------------------------------------------------

  void buildTableBuffer() {
    bjTableBuf = createGraphics(int(bjW), int(bjH));
    bjTableBuf.beginDraw();
    bjTableBuf.background(BJ_FELT);

    // Radial vignette — darker edges give depth
    bjTableBuf.noStroke();
    for (int i = 20; i >= 0; i--) {
      float t = i / 20.0;
      bjTableBuf.fill(lerpColor(BJ_FELT, BJ_FELT2, 1 - t), 30);
      float ew = bjW * (0.6 + 0.4 * t);
      float eh = bjH * (0.6 + 0.4 * t);
      bjTableBuf.ellipse(bjW / 2, bjH / 2, ew, eh);
    }

    // Dealer arc — the curved line players sit around
    bjTableBuf.noFill();
    bjTableBuf.stroke(BJ_GOLD, 50);
    bjTableBuf.strokeWeight(3 * bjScale);
    bjTableBuf.arc(bjW / 2, 120 * bjScale, bjW * 0.7, bjH * 0.55, 0, PI);

    // Outer rail (thick dark + gold inset)
    bjTableBuf.noFill();
    bjTableBuf.strokeWeight(14 * bjScale);
    bjTableBuf.stroke(#2a1a04);
    bjTableBuf.rect(4, 4, bjW - 8, bjH - 8, 18 * bjScale);

    bjTableBuf.strokeWeight(4 * bjScale);
    bjTableBuf.stroke(BJ_GOLD, 160);
    bjTableBuf.rect(10, 10, bjW - 20, bjH - 20, 14 * bjScale);

    // Thin inner highlight
    bjTableBuf.strokeWeight(1);
    bjTableBuf.stroke(255, 25);
    bjTableBuf.rect(14, 14, bjW - 28, bjH - 28, 12 * bjScale);

    bjTableBuf.endDraw();
  }


  // ----------------------------------------------------------------
  //  Main draw loop — call this every frame
  // ----------------------------------------------------------------

  void display() {
    pushMatrix();
    translate(bjX, bjY);

    if (bjTableBuf != null) image(bjTableBuf, 0, 0);

    drawTitle();
    drawRulesBanner();
    drawBothHands();
    drawStatusBar();

    bjDealBtn.render();
    bjHitBtn.render();
    bjStandBtn.render();

    tickAnimations();
    popMatrix();
  }


  // ----------------------------------------------------------------
  //  Title bar + scoreboard
  // ----------------------------------------------------------------

  void drawTitle() {
    // Title pill
    float tw = 460 * bjScale;
    float th = 70 * bjScale;
    float tx = bjW / 2 - tw / 2;
    float ty = 28 * bjScale;

    noStroke();
    fill(0, 90);
    rect(tx, ty, tw, th, th / 2);

    textAlign(CENTER, CENTER);
    textSize(48 * bjScale);
    fill(BJ_GOLD);
    text("BLACKJACK", bjW / 2, ty + th / 2);

    // Scoreboard
    float sx = bjW - 460 * bjScale;
    float sy = 28  * bjScale;
    float sw = 420 * bjScale;
    float sh = 72  * bjScale;

    fill(0, 70);
    rect(sx, sy, sw, sh, 12 * bjScale);

    drawScoreColumn("W", bjWins,   sx + 70  * bjScale, sy + sh / 2);
    drawScoreColumn("L", bjLosses, sx + 210 * bjScale, sy + sh / 2);
    drawScoreColumn("T", bjTies,   sx + 350 * bjScale, sy + sh / 2);
  }

  void drawScoreColumn(String label, int value, float cx, float cy) {
    textAlign(CENTER, CENTER);
    textSize(14 * bjScale);
    fill(180);
    text(label, cx, cy - 14 * bjScale);
    textSize(30 * bjScale);
    fill(255);
    text(value, cx, cy + 10 * bjScale);
  }


  // ----------------------------------------------------------------
  //  Rules banner  (center of table between the two hands)
  // ----------------------------------------------------------------

  void drawRulesBanner() {
    float bw = 520 * bjScale;
    float bh = 36  * bjScale;
    float bx = bjW / 2 - bw / 2;
    float by = bjH / 2 - bh / 2 - 30 * bjScale;

    noStroke();
    fill(0, 60);
    rect(bx, by, bw, bh, bh / 2);

    fill(BJ_GOLD, 180);
    textAlign(CENTER, CENTER);
    textSize(16 * bjScale);
    text("DEALER MUST STAND ON 17", bjW / 2, by + bh / 2);
  }


  // ----------------------------------------------------------------
  //  Draw both hands (dealer on top, player on bottom)
  // ----------------------------------------------------------------

  void drawBothHands() {
    float cardW   = 130 * bjScale;
    float cardH   = 182 * bjScale;
    float cardGap = 25  * bjScale;

    // --- Dealer hand ---
    float dealerY = 200 * bjScale;
    drawHandLabel("DEALER", dealerY - 40 * bjScale);

    int dealerVal = bjDealerRevealed ? handValue(bjDealerHand) : visibleDealerVal();
    drawValueBadge(str(dealerVal), bjW / 2 + 320 * bjScale, dealerY - 40 * bjScale);

    float startX = (bjW - bjDealerHand.size() * (cardW + cardGap)) / 2;
    for (int i = 0; i < bjDealerHand.size(); i++) {
      boolean faceDown = (i == 1 && !bjDealerRevealed);
      drawCard(startX + i * (cardW + cardGap), dealerY, cardW, cardH,
               bjDealerHand.get(i), faceDown);
    }

    // --- Player hand ---
    float playerY = bjH - 340 * bjScale;
    drawHandLabel("PLAYER", playerY - 40 * bjScale);
    drawValueBadge(str(handValue(bjPlayerHand)),
                   bjW / 2 + 320 * bjScale, playerY - 40 * bjScale);

    startX = (bjW - bjPlayerHand.size() * (cardW + cardGap)) / 2;
    for (int i = 0; i < bjPlayerHand.size(); i++) {
      drawCard(startX + i * (cardW + cardGap), playerY, cardW, cardH,
               bjPlayerHand.get(i), false);
    }
  }

  void drawHandLabel(String label, float y) {
    textAlign(LEFT, CENTER);
    textSize(20 * bjScale);
    fill(BJ_GOLD, 160);
    text(label, bjW / 2 - 380 * bjScale, y);
  }

  // Small gold circle showing the hand total
  void drawValueBadge(String val, float cx, float cy) {
    float d = 46 * bjScale;
    noStroke();
    fill(0, 120);
    ellipse(cx, cy, d + 4, d + 4);       // shadow ring

    stroke(BJ_GOLD, 180);
    strokeWeight(2 * bjScale);
    fill(#1a1a1a, 210);
    ellipse(cx, cy, d, d);

    noStroke();
    fill(BJ_GOLD);
    textSize(22 * bjScale);
    textAlign(CENTER, CENTER);
    text(val, cx, cy - 1);
  }


  // ----------------------------------------------------------------
  //  Single card
  // ----------------------------------------------------------------

  void drawCard(float cx, float cy, float cw, float ch,
                BJCard card, boolean faceDown) {

    // Soft drop-shadow
    noStroke();
    fill(0, 40);
    rect(cx + 5 * bjScale, cy + 5 * bjScale, cw, ch, 10 * bjScale);

    if (faceDown) {
      drawCardBack(cx, cy, cw, ch);
    } else {
      drawCardFace(cx, cy, cw, ch, card);
    }
  }

  // Card back — navy with diamond cross-hatch pattern
  void drawCardBack(float cx, float cy, float cw, float ch) {
    float r = 10 * bjScale;

    // Base
    stroke(#334455);
    strokeWeight(2 * bjScale);
    fill(#1c2a3a);
    rect(cx, cy, cw, ch, r);

    // Inner border
    noFill();
    stroke(BJ_GOLD, 60);
    strokeWeight(1);
    rect(cx + 6, cy + 6, cw - 12, ch - 12, r - 2);

    // Diamond lattice pattern
    stroke(#28394d);
    strokeWeight(1);
    float step = 14 * bjScale;
    // We clip manually by only drawing lines inside the card area
    for (float d = -ch; d < cw + ch; d += step) {
      float x1 = cx + d;
      float y1 = cy;
      float x2 = cx + d + ch;
      float y2 = cy + ch;
      // Diagonal going down-right
      line(max(cx + 4, x1), max(cy + 4, map(max(cx + 4, x1), x1, x2, y1, y2)),
           min(cx + cw - 4, x2), min(cy + ch - 4, map(min(cx + cw - 4, x2), x1, x2, y1, y2)));
      // Diagonal going up-right
      float ya = cy + ch;
      float yb = cy;
      line(max(cx + 4, x1), min(cy + ch - 4, map(max(cx + 4, x1), x1, x2, ya, yb)),
           min(cx + cw - 4, x2), max(cy + 4, map(min(cx + cw - 4, x2), x1, x2, ya, yb)));
    }

    // Center oval highlight
    noStroke();
    fill(#1c2a3a, 200);
    ellipse(cx + cw / 2, cy + ch / 2, cw * 0.5, ch * 0.35);
  }

  // Card face — white with rank + pips
  void drawCardFace(float cx, float cy, float cw, float ch, BJCard card) {
    float r = 10 * bjScale;

    stroke(190);
    strokeWeight(bjScale);
    fill(250);
    rect(cx, cy, cw, ch, r);

    boolean isRed = card.bjSuit.equals("\u2665") || card.bjSuit.equals("\u2666");
    color ink = isRed ? BJ_RED : BJ_INK;
    fill(ink);

    // Top-left rank
    textAlign(CENTER, TOP);
    textSize(cw * 0.22);
    text(card.bjRank, cx + cw * 0.20, cy + ch * 0.06);

    // Suit pips in the middle
    drawPipLayout(cx, cy, cw, ch, card);

    // Bottom-right rank (upside-down)
    pushMatrix();
    translate(cx + cw * 0.80, cy + ch * 0.94);
    rotate(PI);
    fill(ink);
    textAlign(CENTER, TOP);
    textSize(cw * 0.22);
    text(card.bjRank, 0, 0);
    popMatrix();
  }


  // ----------------------------------------------------------------
  //  Pip layouts — mirrors a real deck (2-10, A, face cards)
  // ----------------------------------------------------------------

  void drawPipLayout(float cx, float cy, float cw, float ch, BJCard card) {
    String rank = card.bjRank;
    String suit = card.bjSuit;

    // Ace — one big centered suit
    if (rank.equals("A")) {
      float s = cw * 0.42;
      drawSuitShape(cx + cw / 2 - s / 2, cy + ch / 2 - s / 2, s, s, suit);
      return;
    }

    // Face cards — one medium centered suit
    if (rank.equals("J") || rank.equals("Q") || rank.equals("K")) {
      float s = cw * 0.38;
      drawSuitShape(cx + cw / 2 - s / 2, cy + ch / 2 - s / 2, s, s, suit);
      return;
    }

    // Number cards (2-10) — standard pip grid
    int count = int(rank);
    float ps = cw * 0.13;                             // pip size

    float colL = cx + cw * 0.33;                      // left column
    float colC = cx + cw * 0.50;                      // center column
    float colR = cx + cw * 0.67;                      // right column

    float row0 = cy + ch * 0.28;                      // row positions top to bottom
    float row1 = cy + ch * 0.37;
    float row2 = cy + ch * 0.41;
    float row3 = cy + ch * 0.50;
    float row4 = cy + ch * 0.59;
    float row5 = cy + ch * 0.63;
    float row6 = cy + ch * 0.72;

    switch (count) {
      case 2:
        pip(colC, row0, ps, suit, false);
        pip(colC, row6, ps, suit, true);
        break;
      case 3:
        pip(colC, row0, ps, suit, false);
        pip(colC, row3, ps, suit, false);
        pip(colC, row6, ps, suit, true);
        break;
      case 4:
        pip(colL, row0, ps, suit, false);  pip(colR, row0, ps, suit, false);
        pip(colL, row6, ps, suit, true);   pip(colR, row6, ps, suit, true);
        break;
      case 5:
        pip(colL, row0, ps, suit, false);  pip(colR, row0, ps, suit, false);
        pip(colC, row3, ps, suit, false);
        pip(colL, row6, ps, suit, true);   pip(colR, row6, ps, suit, true);
        break;
      case 6:
        pip(colL, row0, ps, suit, false);  pip(colR, row0, ps, suit, false);
        pip(colL, row3, ps, suit, false);  pip(colR, row3, ps, suit, false);
        pip(colL, row6, ps, suit, true);   pip(colR, row6, ps, suit, true);
        break;
      case 7:
        pip(colL, row0, ps, suit, false);  pip(colR, row0, ps, suit, false);
        pip(colL, row3, ps, suit, false);  pip(colR, row3, ps, suit, false);
        pip(colC, row2, ps, suit, false);
        pip(colL, row6, ps, suit, true);   pip(colR, row6, ps, suit, true);
        break;
      case 8:
        pip(colL, row0, ps, suit, false);  pip(colR, row0, ps, suit, false);
        pip(colL, row3, ps, suit, false);  pip(colR, row3, ps, suit, false);
        pip(colC, row2, ps, suit, false);  pip(colC, row4, ps, suit, true);
        pip(colL, row6, ps, suit, true);   pip(colR, row6, ps, suit, true);
        break;
      case 9:
        pip(colL, row0, ps, suit, false);  pip(colR, row0, ps, suit, false);
        pip(colL, row1, ps, suit, false);  pip(colR, row1, ps, suit, false);
        pip(colC, row3, ps, suit, false);
        pip(colL, row5, ps, suit, true);   pip(colR, row5, ps, suit, true);
        pip(colL, row6, ps, suit, true);   pip(colR, row6, ps, suit, true);
        break;
      case 10:
        pip(colL, row0, ps, suit, false);  pip(colR, row0, ps, suit, false);
        pip(colL, row1, ps, suit, false);  pip(colR, row1, ps, suit, false);
        pip(colC, row2, ps, suit, false);  pip(colC, row4, ps, suit, true);
        pip(colL, row5, ps, suit, true);   pip(colR, row5, ps, suit, true);
        pip(colL, row6, ps, suit, true);   pip(colR, row6, ps, suit, true);
        break;
    }
  }

  // Place a single pip; if flipped it rotates 180 degrees (bottom half of card)
  void pip(float px, float py, float size, String suit, boolean flipped) {
    if (flipped) {
      pushMatrix();
      translate(px, py);
      rotate(PI);
      drawSuitShape(-size / 2, -size / 2, size, size, suit);
      popMatrix();
    } else {
      drawSuitShape(px - size / 2, py - size / 2, size, size, suit);
    }
  }


  // ----------------------------------------------------------------
  //  Vector suit shapes (spade, heart, diamond, club)
  //  All drawn in a normalized -1..1 coordinate space then scaled.
  // ----------------------------------------------------------------

  void drawSuitShape(float sx, float sy, float sw, float sh, String suit) {
    pushMatrix();
    pushStyle();
    translate(sx + sw / 2, sy + sh / 2);
    scale(min(sw, sh) / 2.0);
    noStroke();

    boolean isRed = suit.equals("\u2665") || suit.equals("\u2666");
    fill(isRed ? color(185, 30, 30) : color(30));

    if (suit.equals("\u2660")) {
      // Spade body
      beginShape();
      vertex(0, -1);
      bezierVertex(0.5, -0.5, 0.9, 0, 0.9, 0.4);
      bezierVertex(0.9, 0.8, 0, 0.3, 0, 0.3);
      bezierVertex(0, 0.3, -0.9, 0.8, -0.9, 0.4);
      bezierVertex(-0.9, 0, -0.5, -0.5, 0, -1);
      endShape();
      // Spade stem
      beginShape();
      vertex(0, 0.3);
      bezierVertex(0.1, 0.6, 0.3, 0.9, 0.5, 1);
      vertex(-0.5, 1);
      bezierVertex(-0.3, 0.9, -0.1, 0.6, 0, 0.3);
      endShape();

    } else if (suit.equals("\u2665")) {
      // Heart
      beginShape();
      vertex(0, 0.6);
      bezierVertex(0.8, -0.2, 0.9, -1.0, 0, -0.5);
      bezierVertex(-0.9, -1.0, -0.8, -0.2, 0, 0.6);
      endShape();

    } else if (suit.equals("\u2663")) {
      // Club — three circles + stem
      float cr = 0.55;
      ellipse(0, -0.5, cr, cr);
      ellipse(-0.45, 0.15, cr, cr);
      ellipse(0.45, 0.15, cr, cr);
      beginShape();
      vertex(0, 0);
      bezierVertex(0.1, 0.6, 0.3, 0.9, 0.5, 1);
      vertex(-0.5, 1);
      bezierVertex(-0.3, 0.9, -0.1, 0.6, 0, 0);
      endShape();

    } else if (suit.equals("\u2666")) {
      // Diamond
      beginShape();
      vertex(0, -1);
      vertex(0.8, 0);
      vertex(0, 1);
      vertex(-0.8, 0);
      endShape(CLOSE);
    }

    popStyle();
    popMatrix();
  }


  // ----------------------------------------------------------------
  //  Status bar  (shows game messages like "Bust!" or "You win!")
  // ----------------------------------------------------------------

  void drawStatusBar() {
    if (bjStatus.length() == 0) return;

    float cy = bjH / 2 + 90 * bjScale;
    textSize(28 * bjScale);
    float pillW = textWidth(bjStatus) + 80 * bjScale;
    float pillH = 60 * bjScale;
    float pillX = (bjW - pillW) / 2;
    float pillY = cy - pillH / 2;

    // Dark pill background
    noStroke();
    fill(15, 15, 15, 210);
    rect(pillX, pillY, pillW, pillH, pillH / 2);

    // Colour-coded border
    color borderClr = color(255, 80);
    if      (bjStatusType.equals("win"))       borderClr = BJ_WIN;
    else if (bjStatusType.equals("lose"))      borderClr = BJ_LOSE;
    else if (bjStatusType.equals("blackjack")) borderClr = BJ_AMBER;

    noFill();
    stroke(borderClr);
    strokeWeight(3 * bjScale);
    rect(pillX, pillY, pillW, pillH, pillH / 2);

    // Text
    fill(bjStatusType.equals("blackjack") ? BJ_AMBER : 255);
    noStroke();
    textAlign(CENTER, CENTER);
    text(bjStatus, bjW / 2, cy - 1);
  }


  // ----------------------------------------------------------------
  //  Animation tick (card-deal slide)
  // ----------------------------------------------------------------

  void tickAnimations() {
    for (int i = bjAnims.size() - 1; i >= 0; i--) {
      bjAnims.get(i).tick();
      if (bjAnims.get(i).bjDone) bjAnims.remove(i);
    }
  }


  // ----------------------------------------------------------------
  //  Input handling
  // ----------------------------------------------------------------

  void handleClick(float mx, float my) {
    float lx = mx - bjX;
    float ly = my - bjY;
    if (bjDealBtn.isHit(lx, ly)  && bjDealBtn.bjEnabled)  startGame();
    if (bjHitBtn.isHit(lx, ly)   && bjHitBtn.bjEnabled)   playerHit();
    if (bjStandBtn.isHit(lx, ly) && bjStandBtn.bjEnabled)  playerStand();
  }

  void handleKey(char k) {
    if (k == 'd' || k == 'D')                           startGame();
    if ((k == 'h' || k == 'H') && bjHitBtn.bjEnabled)   playerHit();
    if ((k == 's' || k == 'S') && bjStandBtn.bjEnabled)  playerStand();
  }


  // ----------------------------------------------------------------
  //  Deck helpers
  // ----------------------------------------------------------------

  // Build a fresh 52-card deck and shuffle it (Fisher-Yates)
  void buildDeck() {
    bjDeck.clear();
    String[] suits = { "\u2660", "\u2665", "\u2666", "\u2663" };
    String[] ranks = { "A","2","3","4","5","6","7","8","9","10","J","Q","K" };
    for (String s : suits)
      for (String r : ranks)
        bjDeck.add(new BJCard(s, r));

    for (int i = bjDeck.size() - 1; i > 0; i--) {
      int j = int(random(i + 1));
      BJCard tmp = bjDeck.get(i);
      bjDeck.set(i, bjDeck.get(j));
      bjDeck.set(j, tmp);
    }
  }

  // Take the top card; reshuffle automatically if the deck runs out
  BJCard pullCard() {
    if (bjDeck.size() == 0) buildDeck();
    return bjDeck.remove(bjDeck.size() - 1);
  }


  // ----------------------------------------------------------------
  //  Hand evaluation
  // ----------------------------------------------------------------

  // Standard blackjack value: face cards = 10, aces = 11 or 1
  int handValue(ArrayList<BJCard> hand) {
    int total = 0, aces = 0;
    for (BJCard c : hand) {
      if      (c.bjRank.equals("A"))                                                  { aces++; total += 11; }
      else if (c.bjRank.equals("K") || c.bjRank.equals("Q") || c.bjRank.equals("J")) { total += 10; }
      else                                                                            { total += int(c.bjRank); }
    }
    while (total > 21 && aces > 0) { total -= 10; aces--; }
    return total;
  }

  // Value of the dealer's face-up card only (second card hidden)
  int visibleDealerVal() {
    if (bjDealerHand.size() == 0) return 0;
    BJCard first = bjDealerHand.get(0);
    if (first.bjRank.equals("A")) return 11;
    if (first.bjRank.equals("K") || first.bjRank.equals("Q") || first.bjRank.equals("J")) return 10;
    return int(first.bjRank);
  }

  boolean isBlackjack(ArrayList<BJCard> hand) {
    return hand.size() == 2 && handValue(hand) == 21;
  }


  // ----------------------------------------------------------------
  //  Game flow
  // ----------------------------------------------------------------

  void startGame() {
    buildDeck();
    bjPlayerHand.clear();
    bjDealerHand.clear();
    bjAnims.clear();
    bjGameActive     = true;
    bjDealerRevealed = false;

    // Starting positions for the deal animation
    float deckX = bjW / 2 - 65 * bjScale;
    float deckY = bjH / 2 - 90 * bjScale;
    float cw = 130 * bjScale;
    float cs = 25  * bjScale;
    float dealerY = 200 * bjScale;
    float playerY = bjH - 340 * bjScale;
    float leftX = (bjW - 2 * (cw + cs)) / 2;

    // Deal alternating: player, dealer, player, dealer
    bjPlayerHand.add(pullCard());
    bjAnims.add(new BJCardAnim(deckX, deckY, leftX, playerY));

    bjDealerHand.add(pullCard());
    bjAnims.add(new BJCardAnim(deckX, deckY, leftX, dealerY));

    bjPlayerHand.add(pullCard());
    bjAnims.add(new BJCardAnim(deckX, deckY, leftX + cw + cs, playerY));

    bjDealerHand.add(pullCard());
    bjAnims.add(new BJCardAnim(deckX, deckY, leftX + cw + cs, dealerY));

    // Check for natural blackjacks right away
    if (isBlackjack(bjPlayerHand)) {
      if (isBlackjack(bjDealerHand)) endGame("tie",       "Both have Blackjack — Push");
      else                           endGame("blackjack", "BLACKJACK!");
      return;
    }
    if (isBlackjack(bjDealerHand)) {
      endGame("lose", "Dealer Blackjack");
      return;
    }

    bjStatus     = "Hit or Stand?";
    bjStatusType = "";
    bjDealBtn.bjEnabled  = false;
    bjHitBtn.bjEnabled   = true;
    bjStandBtn.bjEnabled = true;
  }

  void playerHit() {
    if (!bjGameActive) return;
    bjPlayerHand.add(pullCard());
    int val = handValue(bjPlayerHand);
    if      (val > 21) endGame("lose", "Bust! Over 21");
    else if (val == 21) playerStand();   // auto-stand on 21
  }

  void playerStand() {
    if (!bjGameActive) return;
    bjHitBtn.bjEnabled   = false;
    bjStandBtn.bjEnabled = false;
    bjDealerRevealed     = true;
    bjStatus = "Dealer draws\u2026";
    dealerPlay();
  }

  // Dealer draws until 17 or higher, then we compare
  void dealerPlay() {
    int dv = handValue(bjDealerHand);
    int pv = handValue(bjPlayerHand);
    while (dv < 17) {
      bjDealerHand.add(pullCard());
      dv = handValue(bjDealerHand);
    }

    if      (dv > 21) endGame("win",  "Dealer busts — you win!");
    else if (dv > pv) endGame("lose", "Dealer wins with " + dv);
    else if (pv > dv) endGame("win",  "You win with " + pv + "!");
    else              endGame("tie",  "Push — it's a tie");
  }

  void endGame(String result, String message) {
    bjGameActive     = false;
    bjDealerRevealed = true;
    bjStatus         = message;
    bjStatusType     = result;

    if (result.equals("win") || result.equals("blackjack")) bjWins++;
    else if (result.equals("lose")) bjLosses++;
    else bjTies++;

    bjDealBtn.bjEnabled  = true;
    bjHitBtn.bjEnabled   = false;
    bjStandBtn.bjEnabled = false;
  }


  // ================================================================
  //  Inner classes
  // ================================================================

  /* A single playing card (suit + rank). */
  class BJCard {
    String bjSuit, bjRank;
    BJCard(String s, String r) { bjSuit = s; bjRank = r; }
  }

  /* Slide animation for a dealt card (ease-out cubic). */
  class BJCardAnim {
    float bjSX, bjSY;   // start
    float bjEX, bjEY;   // end
    float bjCX, bjCY;   // current
    float bjProg = 0;
    boolean bjDone = false;

    BJCardAnim(float sx, float sy, float ex, float ey) {
      bjSX = sx; bjSY = sy;
      bjEX = ex; bjEY = ey;
      bjCX = sx; bjCY = sy;
    }

    void tick() {
      bjProg += 0.08;
      if (bjProg >= 1) { bjProg = 1; bjDone = true; }
      float ease = 1 - pow(1 - bjProg, 3);   // cubic ease-out
      bjCX = lerp(bjSX, bjEX, ease);
      bjCY = lerp(bjSY, bjEY, ease);
    }
  }

  /* A pre-rendered button with enabled / disabled states. */
  class BJButton {
    float bjBX, bjBY, bjBW, bjBH;
    String  bjLabel;
    color   bjBg, bjTxt;
    boolean bjEnabled = true;
    PGraphics bjOnBuf, bjOffBuf;

    BJButton(float x, float y, float w, float h,
             String label, color bg, color txt) {
      bjBX = x; bjBY = y; bjBW = w; bjBH = h;
      bjLabel = label; bjBg = bg; bjTxt = txt;
      prebakeBuffers();
    }

    // Draw button graphics once into PGraphics so we just blit each frame
    void prebakeBuffers() {
      bjOnBuf  = createGraphics(int(bjBW + 10), int(bjBH + 10));
      bjOffBuf = createGraphics(int(bjBW + 10), int(bjBH + 10));

      // --- Active look ---
      bjOnBuf.beginDraw();
      bjOnBuf.clear();
      bjOnBuf.noStroke();
      bjOnBuf.fill(bjBg, 90);
      bjOnBuf.rect(0, 4, bjBW, bjBH, 12);           // shadow
      bjOnBuf.fill(bjBg);
      bjOnBuf.rect(0, 0, bjBW, bjBH, 12);           // body
      bjOnBuf.fill(255, 30);
      bjOnBuf.rect(0, 0, bjBW, bjBH / 2, 12, 12, 0, 0);  // top highlight
      bjOnBuf.noFill();
      bjOnBuf.stroke(255, 40);
      bjOnBuf.strokeWeight(1);
      bjOnBuf.rect(0, 0, bjBW, bjBH, 12);           // border
      bjOnBuf.textAlign(CENTER, CENTER);
      bjOnBuf.textSize(20);
      bjOnBuf.fill(bjTxt);
      bjOnBuf.text(bjLabel, bjBW / 2, bjBH / 2 - 2);
      bjOnBuf.endDraw();

      // --- Disabled look ---
      bjOffBuf.beginDraw();
      bjOffBuf.clear();
      bjOffBuf.noStroke();
      bjOffBuf.fill(28);
      bjOffBuf.rect(0, 0, bjBW, bjBH, 12);
      bjOffBuf.stroke(45);
      bjOffBuf.strokeWeight(1);
      bjOffBuf.rect(0, 0, bjBW, bjBH, 12);
      bjOffBuf.textAlign(CENTER, CENTER);
      bjOffBuf.textSize(16);
      bjOffBuf.fill(80);
      bjOffBuf.text(bjLabel, bjBW / 2, bjBH / 2 - 2);
      bjOffBuf.endDraw();
    }

    void render() {
      pushStyle();
      if (bjEnabled && bjOnBuf != null)       image(bjOnBuf, bjBX, bjBY);
      else if (!bjEnabled && bjOffBuf != null) image(bjOffBuf, bjBX, bjBY);
      popStyle();
    }

    boolean isHit(float mx, float my) {
      return mx >= bjBX && mx <= bjBX + bjBW
          && my >= bjBY && my <= bjBY + bjBH;
    }
  }
}
