/*
 * BlackjackGame
 * Self-contained blackjack table for Processing.
 * All classes prefixed "BJ" to avoid merge conflicts.
 *
 *   BlackjackGame game = new BlackjackGame(0, 0, width, height);
 *   game.display();           // in draw()
 *   game.handleClick(mx,my);  // in mousePressed()
 *   game.handleKey(k);        // in keyPressed()
 */

class BlackjackGame {

  // --- Layout ---
  float bjX, bjY, bjW, bjH;
  float bjScale = 1.0;

  // --- Card dimensions (scaled) ---
  float bjCardW, bjCardH, bjCardGap;

  // --- Hands & deck ---
  ArrayList<BJCard> bjPlayerHand, bjDealerHand, bjDeck;
  boolean bjGameActive     = false;
  boolean bjDealerRevealed = false;
  String  bjStatus         = "Place your bet \u2014 press DEAL";
  String  bjStatusType     = "";

  // --- Score tracking ---
  int bjWins = 0, bjLosses = 0, bjTies = 0;

  // --- Palette ---
  final color BJ_FELT  = #1b5e3b;
  final color BJ_FELT2 = #17492f;
  final color BJ_GOLD  = #c9a94e;
  final color BJ_RED   = #b5312c;
  final color BJ_INK   = #1a1a1a;
  final color BJ_WIN   = #2ecc71;
  final color BJ_LOSE  = #e74c3c;
  final color BJ_AMBER = #e6b832;

  // --- Layout anchors (Y positions, computed once) ---
  float bjTitleY, bjDealerLabelY, bjDealerCardY;
  float bjBannerY, bjStatusY;
  float bjPlayerLabelY, bjPlayerCardY, bjButtonY;

  // --- Buttons ---
  BJButton bjDealBtn, bjHitBtn, bjStandBtn;

  // --- Pre-rendered table surface ---
  PGraphics bjTableBuf;

  // --- Frame counter for staggered dealing ---
  int bjFrameCount = 0;


  // ----------------------------------------------------------------
  //  Setup
  // ----------------------------------------------------------------

  BlackjackGame(float x, float y, float w, float h) {
    bjX = x;
    bjY = y;
    bjW = w;
    bjH = h;
    bjScale = min(w / 1920.0, h / 1080.0);

    // Card size
    bjCardW   = 160 * bjScale;
    bjCardH   = 224 * bjScale;
    bjCardGap = 30  * bjScale;

    // Vertical layout anchors
    bjTitleY       = 20 * bjScale;
    bjDealerLabelY = 132 * bjScale;
    bjDealerCardY  = 168 * bjScale;
    bjBannerY      = (bjDealerCardY + bjCardH + (h - 340 * bjScale) - 40 * bjScale) / 2;
    bjPlayerLabelY = h - 364 * bjScale;
    bjPlayerCardY  = h - 328 * bjScale;
    bjStatusY      = bjBannerY + 50 * bjScale;
    bjButtonY      = h - 100 * bjScale;

    bjPlayerHand = new ArrayList<BJCard>();
    bjDealerHand = new ArrayList<BJCard>();
    bjDeck       = new ArrayList<BJCard>();

    // Buttons (bigger)
    float bw  = 220 * bjScale;
    float bh  = 75  * bjScale;
    float gap = 44  * bjScale;
    float totalBtnW = bw * 3 + gap * 2;
    float bx = x + (w - totalBtnW) / 2;

    bjDealBtn  = new BJButton(bx,                  bjButtonY, bw, bh, "DEAL",  BJ_AMBER, BJ_INK);
    bjHitBtn   = new BJButton(bx + bw + gap,       bjButtonY, bw, bh, "HIT",   BJ_WIN,   BJ_INK);
    bjStandBtn = new BJButton(bx + (bw + gap) * 2, bjButtonY, bw, bh, "STAND", BJ_LOSE,  #f0f0f0);
    bjHitBtn.bjEnabled   = false;
    bjStandBtn.bjEnabled = false;

    buildTableBuffer();
  }


  // ----------------------------------------------------------------
  //  Table surface (drawn once into a buffer)
  // ----------------------------------------------------------------

  void buildTableBuffer() {
    bjTableBuf = createGraphics(int(bjW), int(bjH));
    bjTableBuf.beginDraw();
    bjTableBuf.background(BJ_FELT);

    // Radial vignette
    bjTableBuf.noStroke();
    for (int i = 20; i >= 0; i--) {
      float t = i / 20.0;
      bjTableBuf.fill(lerpColor(BJ_FELT, BJ_FELT2, 1 - t), 30);
      bjTableBuf.ellipse(bjW / 2, bjH / 2, bjW * (0.6 + 0.4 * t), bjH * (0.6 + 0.4 * t));
    }

    // Dealer arc
    bjTableBuf.noFill();
    bjTableBuf.stroke(BJ_GOLD, 50);
    bjTableBuf.strokeWeight(3 * bjScale);
    bjTableBuf.arc(bjW / 2, 120 * bjScale, bjW * 0.7, bjH * 0.55, 0, PI);

    // Outer rail
    bjTableBuf.noFill();
    bjTableBuf.strokeWeight(14 * bjScale);
    bjTableBuf.stroke(#2a1a04);
    bjTableBuf.rect(4, 4, bjW - 8, bjH - 8, 18 * bjScale);
    bjTableBuf.strokeWeight(4 * bjScale);
    bjTableBuf.stroke(BJ_GOLD, 160);
    bjTableBuf.rect(10, 10, bjW - 20, bjH - 20, 14 * bjScale);
    bjTableBuf.strokeWeight(1);
    bjTableBuf.stroke(255, 25);
    bjTableBuf.rect(14, 14, bjW - 28, bjH - 28, 12 * bjScale);

    bjTableBuf.endDraw();
  }


  // ----------------------------------------------------------------
  //  Main draw loop
  // ----------------------------------------------------------------

  void display() {
    bjFrameCount++;
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

    popMatrix();
  }


  // ----------------------------------------------------------------
  //  Title bar + scoreboard
  // ----------------------------------------------------------------

  void drawTitle() {
    float tw = 500 * bjScale;
    float th = 80 * bjScale;
    float tx = bjW / 2 - tw / 2;

    noStroke();
    fill(0, 90);
    rect(tx, bjTitleY, tw, th, th / 2);

    textAlign(CENTER, CENTER);
    textSize(52 * bjScale);
    fill(BJ_GOLD);
    text("BLACKJACK", bjW / 2, bjTitleY + th / 2);

    // Scoreboard
    float sx = bjW - 480 * bjScale;
    float sw = 440 * bjScale;
    float sh = 78  * bjScale;

    fill(0, 70);
    rect(sx, bjTitleY, sw, sh, 12 * bjScale);

    drawScoreColumn("W", bjWins,   sx + 73  * bjScale, bjTitleY + sh / 2);
    drawScoreColumn("L", bjLosses, sx + 220 * bjScale, bjTitleY + sh / 2);
    drawScoreColumn("T", bjTies,   sx + 367 * bjScale, bjTitleY + sh / 2);
  }

  void drawScoreColumn(String label, int value, float cx, float cy) {
    textAlign(CENTER, CENTER);
    textSize(15 * bjScale);
    fill(180);
    text(label, cx, cy - 15 * bjScale);
    textSize(32 * bjScale);
    fill(255);
    text(value, cx, cy + 12 * bjScale);
  }


  // ----------------------------------------------------------------
  //  Rules banner
  // ----------------------------------------------------------------

  void drawRulesBanner() {
    float bw = 540 * bjScale;
    float bh = 38  * bjScale;
    float bx = bjW / 2 - bw / 2;

    noStroke();
    fill(0, 60);
    rect(bx, bjBannerY, bw, bh, bh / 2);

    fill(BJ_GOLD, 180);
    textAlign(CENTER, CENTER);
    textSize(17 * bjScale);
    text("DEALER MUST STAND ON 17", bjW / 2, bjBannerY + bh / 2);
  }


  // ----------------------------------------------------------------
  //  Draw both hands with per-card animation
  // ----------------------------------------------------------------

  void drawBothHands() {
    // Compute target positions for every card, then animate each one

    // --- Dealer ---
    drawHandLabel("DEALER", bjDealerLabelY);
    int dealerVal = bjDealerRevealed ? handValue(bjDealerHand) : visibleDealerVal();
    drawValueBadge(str(dealerVal), bjW / 2 + 360 * bjScale, bjDealerLabelY);
    updateAndDrawHand(bjDealerHand, bjDealerCardY, true);

    // --- Player ---
    drawHandLabel("PLAYER", bjPlayerLabelY);
    drawValueBadge(str(handValue(bjPlayerHand)), bjW / 2 + 360 * bjScale, bjPlayerLabelY);
    updateAndDrawHand(bjPlayerHand, bjPlayerCardY, false);
  }

  // Compute where each card should sit, animate it there, draw it
  void updateAndDrawHand(ArrayList<BJCard> hand, float rowY, boolean isDealer) {
    int n = hand.size();
    if (n == 0) return;

    float totalW = n * bjCardW + (n - 1) * bjCardGap;
    float startX = (bjW - totalW) / 2;

    for (int i = 0; i < n; i++) {
      BJCard c = hand.get(i);

      // Set target slot position
      c.bjTgtX = startX + i * (bjCardW + bjCardGap);
      c.bjTgtY = rowY;

      // Animate position (only if card hasn't reached target yet)
      if (!c.bjSlideFinished) {
        // Wait for staggered deal delay
        if (bjFrameCount < c.bjDealFrame) continue;

        c.bjSlideProg += 0.07;
        if (c.bjSlideProg >= 1.0) {
          c.bjSlideProg = 1.0;
          c.bjSlideFinished = true;
          // Auto-flip face up after landing (unless it's the dealer's hole card)
          if (!c.bjFaceUp && c.bjAutoFlip) {
            c.bjFlipping = true;
          }
        }
        float ease = 1 - pow(1 - c.bjSlideProg, 3);
        c.bjCurX = lerp(c.bjStartX, c.bjTgtX, ease);
        c.bjCurY = lerp(c.bjStartY, c.bjTgtY, ease);
      } else {
        // Already landed — smoothly track if row recenters (new card added)
        c.bjCurX = lerp(c.bjCurX, c.bjTgtX, 0.18);
        c.bjCurY = lerp(c.bjCurY, c.bjTgtY, 0.18);
      }

      // Animate flip
      if (c.bjFlipping) {
        c.bjFlipProg += 0.08;
        if (c.bjFlipProg >= 1.0) {
          c.bjFlipProg = 1.0;
          c.bjFlipping = false;
          c.bjFaceUp = true;
        }
      }

      // Determine visual state: during flip, scale X to simulate rotation
      boolean showFace;
      float scaleX;
      if (c.bjFlipping) {
        // First half: shrink showing back; second half: grow showing face
        if (c.bjFlipProg < 0.5) {
          scaleX = 1 - c.bjFlipProg * 2;   // 1 → 0
          showFace = false;
        } else {
          scaleX = (c.bjFlipProg - 0.5) * 2; // 0 → 1
          showFace = true;
        }
      } else {
        scaleX = 1.0;
        showFace = c.bjFaceUp;
      }

      // Draw the card
      drawAnimatedCard(c.bjCurX, c.bjCurY, bjCardW, bjCardH, c, showFace, scaleX);
    }
  }

  // Draw a card with optional X-scale (for flip animation)
  void drawAnimatedCard(float cx, float cy, float cw, float ch,
                        BJCard card, boolean showFace, float scaleX) {
    float drawnW = cw * scaleX;
    float offsetX = (cw - drawnW) / 2;     // keep card centered during flip

    // Drop shadow
    noStroke();
    fill(0, 40);
    rect(cx + offsetX + 5 * bjScale, cy + 5 * bjScale, drawnW, ch, 10 * bjScale);

    if (showFace) {
      drawCardFace(cx + offsetX, cy, drawnW, ch, card);
    } else {
      drawCardBack(cx + offsetX, cy, drawnW, ch);
    }
  }

  void drawHandLabel(String label, float y) {
    textAlign(LEFT, CENTER);
    textSize(22 * bjScale);
    fill(BJ_GOLD, 160);
    text(label, bjW / 2 - 400 * bjScale, y);
  }

  void drawValueBadge(String val, float cx, float cy) {
    float d = 52 * bjScale;
    noStroke();
    fill(0, 120);
    ellipse(cx, cy, d + 4, d + 4);

    stroke(BJ_GOLD, 180);
    strokeWeight(2 * bjScale);
    fill(#1a1a1a, 210);
    ellipse(cx, cy, d, d);

    noStroke();
    fill(BJ_GOLD);
    textSize(24 * bjScale);
    textAlign(CENTER, CENTER);
    text(val, cx, cy - 1);
  }


  // ----------------------------------------------------------------
  //  Card back — navy with diamond lattice
  // ----------------------------------------------------------------

  void drawCardBack(float cx, float cy, float cw, float ch) {
    float r = 10 * bjScale;

    stroke(#334455);
    strokeWeight(2 * bjScale);
    fill(#1c2a3a);
    rect(cx, cy, cw, ch, r);

    // Inner gold border
    noFill();
    stroke(BJ_GOLD, 60);
    strokeWeight(1);
    rect(cx + 6, cy + 6, cw - 12, ch - 12, r - 2);

    // Diamond lattice
    stroke(#28394d);
    strokeWeight(1);
    float step = 14 * bjScale;
    for (float d = -ch; d < cw + ch; d += step) {
      float x1 = cx + d, y1 = cy;
      float x2 = cx + d + ch, y2 = cy + ch;
      line(max(cx + 4, x1), max(cy + 4, map(max(cx + 4, x1), x1, x2, y1, y2)),
           min(cx + cw - 4, x2), min(cy + ch - 4, map(min(cx + cw - 4, x2), x1, x2, y1, y2)));
      float ya = cy + ch, yb = cy;
      line(max(cx + 4, x1), min(cy + ch - 4, map(max(cx + 4, x1), x1, x2, ya, yb)),
           min(cx + cw - 4, x2), max(cy + 4, map(min(cx + cw - 4, x2), x1, x2, ya, yb)));
    }

    // Center highlight
    noStroke();
    fill(#1c2a3a, 200);
    ellipse(cx + cw / 2, cy + ch / 2, cw * 0.5, ch * 0.35);
  }


  // ----------------------------------------------------------------
  //  Card face — white with rank + pips
  // ----------------------------------------------------------------

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

    // Pips
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
  //  Pip layouts (2-10, A, face cards)
  // ----------------------------------------------------------------

  void drawPipLayout(float cx, float cy, float cw, float ch, BJCard card) {
    String rank = card.bjRank;
    String suit = card.bjSuit;

    if (rank.equals("A")) {
      float s = cw * 0.42;
      drawSuitShape(cx + cw / 2 - s / 2, cy + ch / 2 - s / 2, s, s, suit);
      return;
    }
    if (rank.equals("J") || rank.equals("Q") || rank.equals("K")) {
      float s = cw * 0.38;
      drawSuitShape(cx + cw / 2 - s / 2, cy + ch / 2 - s / 2, s, s, suit);
      return;
    }

    int count = int(rank);
    float ps = cw * 0.13;

    float colL = cx + cw * 0.33;
    float colC = cx + cw * 0.50;
    float colR = cx + cw * 0.67;

    float r0 = cy + ch * 0.28, r1 = cy + ch * 0.37, r2 = cy + ch * 0.41;
    float r3 = cy + ch * 0.50, r4 = cy + ch * 0.59;
    float r5 = cy + ch * 0.63, r6 = cy + ch * 0.72;

    switch (count) {
      case 2:
        pip(colC,r0,ps,suit,false); pip(colC,r6,ps,suit,true); break;
      case 3:
        pip(colC,r0,ps,suit,false); pip(colC,r3,ps,suit,false); pip(colC,r6,ps,suit,true); break;
      case 4:
        pip(colL,r0,ps,suit,false); pip(colR,r0,ps,suit,false);
        pip(colL,r6,ps,suit,true);  pip(colR,r6,ps,suit,true);  break;
      case 5:
        pip(colL,r0,ps,suit,false); pip(colR,r0,ps,suit,false);
        pip(colC,r3,ps,suit,false);
        pip(colL,r6,ps,suit,true);  pip(colR,r6,ps,suit,true);  break;
      case 6:
        pip(colL,r0,ps,suit,false); pip(colR,r0,ps,suit,false);
        pip(colL,r3,ps,suit,false); pip(colR,r3,ps,suit,false);
        pip(colL,r6,ps,suit,true);  pip(colR,r6,ps,suit,true);  break;
      case 7:
        pip(colL,r0,ps,suit,false); pip(colR,r0,ps,suit,false);
        pip(colL,r3,ps,suit,false); pip(colR,r3,ps,suit,false);
        pip(colC,r2,ps,suit,false);
        pip(colL,r6,ps,suit,true);  pip(colR,r6,ps,suit,true);  break;
      case 8:
        pip(colL,r0,ps,suit,false); pip(colR,r0,ps,suit,false);
        pip(colL,r3,ps,suit,false); pip(colR,r3,ps,suit,false);
        pip(colC,r2,ps,suit,false); pip(colC,r4,ps,suit,true);
        pip(colL,r6,ps,suit,true);  pip(colR,r6,ps,suit,true);  break;
      case 9:
        pip(colL,r0,ps,suit,false); pip(colR,r0,ps,suit,false);
        pip(colL,r1,ps,suit,false); pip(colR,r1,ps,suit,false);
        pip(colC,r3,ps,suit,false);
        pip(colL,r5,ps,suit,true);  pip(colR,r5,ps,suit,true);
        pip(colL,r6,ps,suit,true);  pip(colR,r6,ps,suit,true);  break;
      case 10:
        pip(colL,r0,ps,suit,false); pip(colR,r0,ps,suit,false);
        pip(colL,r1,ps,suit,false); pip(colR,r1,ps,suit,false);
        pip(colC,r2,ps,suit,false); pip(colC,r4,ps,suit,true);
        pip(colL,r5,ps,suit,true);  pip(colR,r5,ps,suit,true);
        pip(colL,r6,ps,suit,true);  pip(colR,r6,ps,suit,true);  break;
    }
  }

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
  //  Vector suit shapes (-1..1 normalized, then scaled)
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
      beginShape();
      vertex(0, -1);
      bezierVertex(0.5, -0.5, 0.9, 0, 0.9, 0.4);
      bezierVertex(0.9, 0.8, 0, 0.3, 0, 0.3);
      bezierVertex(0, 0.3, -0.9, 0.8, -0.9, 0.4);
      bezierVertex(-0.9, 0, -0.5, -0.5, 0, -1);
      endShape();
      beginShape();
      vertex(0, 0.3);
      bezierVertex(0.1, 0.6, 0.3, 0.9, 0.5, 1);
      vertex(-0.5, 1);
      bezierVertex(-0.3, 0.9, -0.1, 0.6, 0, 0.3);
      endShape();
    } else if (suit.equals("\u2665")) {
      beginShape();
      vertex(0, 0.6);
      bezierVertex(0.8, -0.2, 0.9, -1.0, 0, -0.5);
      bezierVertex(-0.9, -1.0, -0.8, -0.2, 0, 0.6);
      endShape();
    } else if (suit.equals("\u2663")) {
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
  //  Status bar
  // ----------------------------------------------------------------

  void drawStatusBar() {
    if (bjStatus.length() == 0) return;

    textSize(30 * bjScale);
    float pillW = textWidth(bjStatus) + 90 * bjScale;
    float pillH = 66 * bjScale;
    float pillX = (bjW - pillW) / 2;
    float pillY = bjStatusY - pillH / 2;

    noStroke();
    fill(15, 15, 15, 210);
    rect(pillX, pillY, pillW, pillH, pillH / 2);

    color borderClr = color(255, 80);
    if      (bjStatusType.equals("win"))       borderClr = BJ_WIN;
    else if (bjStatusType.equals("lose"))      borderClr = BJ_LOSE;
    else if (bjStatusType.equals("blackjack")) borderClr = BJ_AMBER;

    noFill();
    stroke(borderClr);
    strokeWeight(3 * bjScale);
    rect(pillX, pillY, pillW, pillH, pillH / 2);

    fill(bjStatusType.equals("blackjack") ? BJ_AMBER : 255);
    noStroke();
    textAlign(CENTER, CENTER);
    text(bjStatus, bjW / 2, bjStatusY - 1);
  }


  // ----------------------------------------------------------------
  //  Input
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
  //  Deck
  // ----------------------------------------------------------------

  void buildDeck() {
    bjDeck.clear();
    String[] suits = { "\u2660", "\u2665", "\u2666", "\u2663" };
    String[] ranks = { "A","2","3","4","5","6","7","8","9","10","J","Q","K" };
    for (String s : suits)
      for (String r : ranks)
        bjDeck.add(new BJCard(s, r));

    // Fisher-Yates shuffle
    for (int i = bjDeck.size() - 1; i > 0; i--) {
      int j = int(random(i + 1));
      BJCard tmp = bjDeck.get(i);
      bjDeck.set(i, bjDeck.get(j));
      bjDeck.set(j, tmp);
    }
  }

  BJCard pullCard() {
    if (bjDeck.size() == 0) buildDeck();
    return bjDeck.remove(bjDeck.size() - 1);
  }

  // Create a card that will animate from the deck center to its slot
  BJCard dealCard(boolean autoFlip, int staggerIndex) {
    BJCard c = pullCard();
    c.bjStartX = bjW / 2 - bjCardW / 2;
    c.bjStartY = bjH / 2 - bjCardH / 2;
    c.bjCurX   = c.bjStartX;
    c.bjCurY   = c.bjStartY;
    c.bjAutoFlip = autoFlip;
    c.bjDealFrame = bjFrameCount + staggerIndex * 10;  // 10-frame stagger
    return c;
  }


  // ----------------------------------------------------------------
  //  Hand evaluation
  // ----------------------------------------------------------------

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
    bjGameActive     = true;
    bjDealerRevealed = false;

    // Deal 4 cards with staggered animation
    bjPlayerHand.add(dealCard(true, 0));    // player card 1 — flips face up
    bjDealerHand.add(dealCard(true, 1));    // dealer card 1 — flips face up
    bjPlayerHand.add(dealCard(true, 2));    // player card 2 — flips face up
    bjDealerHand.add(dealCard(false, 3));   // dealer hole card — stays face down

    // Check for natural blackjacks
    if (isBlackjack(bjPlayerHand)) {
      if (isBlackjack(bjDealerHand)) endGame("tie",       "Both have Blackjack \u2014 Push");
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
    // New card slides in and flips immediately (no stagger)
    BJCard c = dealCard(true, 0);
    bjPlayerHand.add(c);
    int val = handValue(bjPlayerHand);
    if      (val > 21) endGame("lose", "Bust! Over 21");
    else if (val == 21) playerStand();
  }

  void playerStand() {
    if (!bjGameActive) return;
    bjHitBtn.bjEnabled   = false;
    bjStandBtn.bjEnabled = false;
    bjDealerRevealed     = true;

    // Flip the dealer's hole card
    BJCard holeCard = bjDealerHand.get(1);
    holeCard.bjFlipping = true;
    holeCard.bjFlipProg = 0;

    bjStatus = "Dealer draws\u2026";
    dealerPlay();
  }

  void dealerPlay() {
    int dv = handValue(bjDealerHand);
    int pv = handValue(bjPlayerHand);
    int extra = 0;
    while (dv < 17) {
      extra++;
      BJCard c = dealCard(true, extra);
      bjDealerHand.add(c);
      dv = handValue(bjDealerHand);
    }

    if      (dv > 21) endGame("win",  "Dealer busts \u2014 you win!");
    else if (dv > pv) endGame("lose", "Dealer wins with " + dv);
    else if (pv > dv) endGame("win",  "You win with " + pv + "!");
    else              endGame("tie",  "Push \u2014 it's a tie");
  }

  void endGame(String result, String message) {
    bjGameActive     = false;
    bjDealerRevealed = true;
    bjStatus         = message;
    bjStatusType     = result;

    // Reveal dealer's hole card if not already flipping
    if (bjDealerHand.size() >= 2) {
      BJCard hole = bjDealerHand.get(1);
      if (!hole.bjFaceUp && !hole.bjFlipping) {
        hole.bjFlipping = true;
        hole.bjFlipProg = 0;
      }
    }

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

  class BJCard {
    String bjSuit, bjRank;

    // Slide animation
    float bjStartX, bjStartY;     // where the card slides from
    float bjTgtX, bjTgtY;         // target slot (computed each frame)
    float bjCurX, bjCurY;         // current drawn position
    float bjSlideProg = 0;        // 0→1 slide progress
    boolean bjSlideFinished = false;
    int bjDealFrame = 0;          // frame number when slide begins (stagger)

    // Flip animation
    float bjFlipProg = 0;         // 0→1 flip progress
    boolean bjFlipping = false;   // currently mid-flip?
    boolean bjFaceUp = false;     // final resting state
    boolean bjAutoFlip = true;    // flip after landing?

    BJCard(String s, String r) {
      bjSuit = s;
      bjRank = r;
    }
  }

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

    void prebakeBuffers() {
      bjOnBuf  = createGraphics(int(bjBW + 10), int(bjBH + 10));
      bjOffBuf = createGraphics(int(bjBW + 10), int(bjBH + 10));

      // Active
      bjOnBuf.beginDraw();
      bjOnBuf.clear();
      bjOnBuf.noStroke();
      bjOnBuf.fill(bjBg, 90);
      bjOnBuf.rect(0, 4, bjBW, bjBH, 14);
      bjOnBuf.fill(bjBg);
      bjOnBuf.rect(0, 0, bjBW, bjBH, 14);
      bjOnBuf.fill(255, 30);
      bjOnBuf.rect(0, 0, bjBW, bjBH / 2, 14, 14, 0, 0);
      bjOnBuf.noFill();
      bjOnBuf.stroke(255, 40);
      bjOnBuf.strokeWeight(1);
      bjOnBuf.rect(0, 0, bjBW, bjBH, 14);
      bjOnBuf.textAlign(CENTER, CENTER);
      bjOnBuf.textSize(22);
      bjOnBuf.fill(bjTxt);
      bjOnBuf.text(bjLabel, bjBW / 2, bjBH / 2 - 2);
      bjOnBuf.endDraw();

      // Disabled
      bjOffBuf.beginDraw();
      bjOffBuf.clear();
      bjOffBuf.noStroke();
      bjOffBuf.fill(28);
      bjOffBuf.rect(0, 0, bjBW, bjBH, 14);
      bjOffBuf.stroke(45);
      bjOffBuf.strokeWeight(1);
      bjOffBuf.rect(0, 0, bjBW, bjBH, 14);
      bjOffBuf.textAlign(CENTER, CENTER);
      bjOffBuf.textSize(18);
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
