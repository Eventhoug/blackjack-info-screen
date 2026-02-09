// BlackjackGame - Fully self-contained blackjack game component
// All inner classes prefixed with BJ to avoid naming conflicts
// Usage:
//   BlackjackGame game = new BlackjackGame(x, y, width, height);
//   game.display();           // Call in draw()
//   game.handleClick(mx, my); // Call in mousePressed()
//   game.handleKey(k);        // Call in keyPressed()

class BlackjackGame {

  // Position and size
  float bjX, bjY, bjW, bjH;

  // Auto-scaling (1920x1080 reference)
  float bjScale = 1.0;

  // Game state
  ArrayList<BJCard> bjPlayerHand, bjDealerHand, bjDeck;
  boolean bjGameActive = false;
  boolean bjDealerRevealed = false;
  String bjStatus = "Press DEAL to start";
  String bjStatusType = "";

  // Stats
  int bjWins = 0, bjLosses = 0, bjTies = 0;

  // Colors
  final color BJ_FELT     = #35654d;
  final color BJ_GOLD     = #d4af37;
  final color BJ_RED      = #c0392b;
  final color BJ_DARK     = #2c3e50;
  final color BJ_WIN      = #2ecc71;
  final color BJ_LOSE     = #e74c3c;
  final color BJ_DEAL_CLR = #f1c40f;

  // Buttons
  BJButton bjDealBtn, bjHitBtn, bjStandBtn;

  // Animations
  ArrayList<BJCardAnim> bjAnims;

  // Cached table background
  PGraphics bjTableBuf;

  // ── Constructor ──────────────────────────────────────────────
  BlackjackGame(float x, float y, float w, float h) {
    bjX = x;  bjY = y;  bjW = w;  bjH = h;
    bjScale = min(w / 1920.0, h / 1080.0);

    bjPlayerHand = new ArrayList<BJCard>();
    bjDealerHand = new ArrayList<BJCard>();
    bjDeck       = new ArrayList<BJCard>();
    bjAnims      = new ArrayList<BJCardAnim>();

    // Buttons
    float bw = 180 * bjScale, bh = 65 * bjScale, bs = 40 * bjScale;
    float totalW = bw * 3 + bs * 2;
    float bx = x + (w - totalW) / 2;
    float by = y + h - 120 * bjScale;

    bjDealBtn  = new BJButton(bx, by, bw, bh, "DEAL",  BJ_DEAL_CLR, BJ_DARK);
    bjHitBtn   = new BJButton(bx + bw + bs, by, bw, bh, "HIT", BJ_WIN, BJ_DARK);
    bjStandBtn = new BJButton(bx + (bw + bs) * 2, by, bw, bh, "STAND", BJ_LOSE, #ecf0f1);
    bjHitBtn.bjEnabled = false;
    bjStandBtn.bjEnabled = false;

    buildTableBuffer();
  }

  // ── Cached table background ──────────────────────────────────
  void buildTableBuffer() {
    bjTableBuf = createGraphics(int(bjW), int(bjH));
    bjTableBuf.beginDraw();
    bjTableBuf.noStroke();
    bjTableBuf.fill(BJ_FELT);
    bjTableBuf.rect(0, 0, bjW, bjH);
    bjTableBuf.noFill();
    bjTableBuf.strokeWeight(12);
    bjTableBuf.stroke(#5a4208);
    bjTableBuf.rect(6, 6, bjW - 12, bjH - 12);
    bjTableBuf.strokeWeight(8);
    bjTableBuf.stroke(BJ_GOLD);
    bjTableBuf.rect(6, 6, bjW - 12, bjH - 12);
    bjTableBuf.strokeWeight(2);
    bjTableBuf.stroke(255, 100);
    bjTableBuf.rect(8, 8, bjW - 16, bjH - 16);
    bjTableBuf.endDraw();
  }

  // ── Main display (call in draw()) ────────────────────────────
  void display() {
    pushMatrix();
    translate(bjX, bjY);

    if (bjTableBuf != null) image(bjTableBuf, 0, 0);
    renderHeader();
    renderRules();
    renderHands();
    renderStatus();
    bjDealBtn.render();
    bjHitBtn.render();
    bjStandBtn.render();
    tickAnimations();

    popMatrix();
  }

  // ── Header ───────────────────────────────────────────────────
  void renderHeader() {
    textAlign(CENTER, CENTER);
    fill(0, 80);  noStroke();
    rect(bjW/2 - 250*bjScale, 25*bjScale, 500*bjScale, 75*bjScale, 30*bjScale);
    textSize(52 * bjScale);
    fill(BJ_GOLD);
    text("BLACKJACK", bjW/2, 60*bjScale);

    float sx = bjW - 480*bjScale, sy = 50*bjScale;
    fill(0, 60);
    rect(sx - 25*bjScale, 20*bjScale, 440*bjScale, 85*bjScale, 15*bjScale);
    renderStat("WINS",   bjWins,   sx + 50*bjScale,  sy);
    renderStat("LOSSES", bjLosses, sx + 195*bjScale, sy);
    renderStat("TIES",   bjTies,   sx + 340*bjScale, sy);
  }

  void renderStat(String lbl, int val, float sx, float sy) {
    textAlign(CENTER);
    textSize(16 * bjScale);  fill(200);  text(lbl, sx, sy);
    textSize(34 * bjScale);  fill(255);  text(val, sx, sy + 30*bjScale);
  }

  // ── Rules banner ─────────────────────────────────────────────
  void renderRules() {
    textAlign(CENTER, CENTER);
    fill(0, 100);  noStroke();
    rect(bjW/2 - 420*bjScale, bjH/2 - 60*bjScale, 840*bjScale, 60*bjScale, 15*bjScale);
    fill(255, 200);
    textSize(24 * bjScale);
    text("DEALER STANDS ON SOFT 17", bjW/2, bjH/2 - 30*bjScale);
  }

  // ── Hands ────────────────────────────────────────────────────
  void renderHands() {
    float cw = 130*bjScale, ch = 182*bjScale, cs = 25*bjScale;

    // Dealer
    float dy = 200 * bjScale;
    textAlign(LEFT, CENTER); textSize(24*bjScale); fill(200);
    text("DEALER", bjW/2 - 380*bjScale, dy - 40*bjScale);
    int dv = bjDealerRevealed ? handValue(bjDealerHand) : visibleDealerValue();
    renderBubble(str(dv), bjW/2 + 320*bjScale, dy - 40*bjScale);

    float sx = (bjW - bjDealerHand.size() * (cw + cs)) / 2;
    for (int i = 0; i < bjDealerHand.size(); i++) {
      boolean hidden = (i == 1 && !bjDealerRevealed);
      renderCard(sx + i*(cw+cs), dy, cw, ch, bjDealerHand.get(i), hidden);
    }

    // Player
    float py = bjH - 340*bjScale;
    textAlign(LEFT, CENTER); textSize(24*bjScale); fill(200);
    text("PLAYER", bjW/2 - 380*bjScale, py - 40*bjScale);
    renderBubble(str(handValue(bjPlayerHand)), bjW/2 + 320*bjScale, py - 40*bjScale);

    sx = (bjW - bjPlayerHand.size() * (cw + cs)) / 2;
    for (int i = 0; i < bjPlayerHand.size(); i++) {
      renderCard(sx + i*(cw+cs), py, cw, ch, bjPlayerHand.get(i), false);
    }
  }

  void renderBubble(String val, float bx, float by) {
    float d = 50 * bjScale;
    noStroke(); fill(0, 150);  ellipse(bx, by, d, d);
    stroke(BJ_GOLD); strokeWeight(3*bjScale); noFill(); ellipse(bx, by, d, d);
    fill(BJ_GOLD); textSize(26*bjScale); textAlign(CENTER, CENTER);
    text(val, bx, by - 2);
  }

  // ── Card rendering ───────────────────────────────────────────
  void renderCard(float cx, float cy, float cw, float ch, BJCard card, boolean hidden) {
    noStroke(); fill(0, 50);
    rect(cx + 6*bjScale, cy + 6*bjScale, cw, ch, 10*bjScale);

    if (hidden) {
      stroke(255); strokeWeight(3*bjScale); fill(BJ_DARK);
      rect(cx, cy, cw, ch, 10*bjScale);
      noStroke(); fill(255, 15);
      ellipse(cx + cw/2, cy + ch/2, cw*0.6, cw*0.6);
      fill(255, 100); textSize(24*bjScale); textAlign(CENTER, CENTER);
      text("BJ", cx + cw/2, cy + ch/2);
    } else {
      stroke(200); strokeWeight(bjScale); fill(245);
      rect(cx, cy, cw, ch, 10*bjScale);

      boolean red = card.bjSuit.equals("\u2665") || card.bjSuit.equals("\u2666");
      color tc = red ? BJ_RED : BJ_DARK;
      fill(tc);

      // Top rank
      textAlign(CENTER, TOP); textSize(cw * 0.22);
      text(card.bjRank, cx + cw*0.20, cy + ch*0.07);

      // Pips
      renderPips(cx, cy, cw, ch, card);

      // Bottom rank (rotated)
      pushMatrix();
      translate(cx + cw - cw*0.20, cy + ch - ch*0.07);
      rotate(PI); fill(tc); textSize(cw * 0.22);
      text(card.bjRank, 0, 0);
      popMatrix();
    }
  }

  // ── Pip layouts ──────────────────────────────────────────────
  void renderPips(float cx, float cy, float cw, float ch, BJCard card) {
    String r = card.bjRank, s = card.bjSuit;

    if (r.equals("A")) {
      float p = cw * 0.42;
      renderSuit(cx + cw/2 - p/2, cy + ch/2 - p/2, p, p, s);
      return;
    }
    if (r.equals("J") || r.equals("Q") || r.equals("K")) {
      float p = cw * 0.38;
      renderSuit(cx + cw/2 - p/2, cy + ch/2 - p/2, p, p, s);
      return;
    }

    int n = int(r);
    float p = cw * 0.13;
    float xL = cx + cw*0.33, xC = cx + cw*0.50, xR = cx + cw*0.67;
    float y0 = cy+ch*0.28, y1 = cy+ch*0.37, y2 = cy+ch*0.41;
    float y3 = cy+ch*0.50, y4 = cy+ch*0.59, y5 = cy+ch*0.63, y6 = cy+ch*0.72;

    switch(n) {
      case 2:
        placePip(xC,y0,p,s,false); placePip(xC,y6,p,s,true); break;
      case 3:
        placePip(xC,y0,p,s,false); placePip(xC,y3,p,s,false); placePip(xC,y6,p,s,true); break;
      case 4:
        placePip(xL,y0,p,s,false); placePip(xR,y0,p,s,false);
        placePip(xL,y6,p,s,true);  placePip(xR,y6,p,s,true);  break;
      case 5:
        placePip(xL,y0,p,s,false); placePip(xR,y0,p,s,false);
        placePip(xC,y3,p,s,false);
        placePip(xL,y6,p,s,true);  placePip(xR,y6,p,s,true);  break;
      case 6:
        placePip(xL,y0,p,s,false); placePip(xR,y0,p,s,false);
        placePip(xL,y3,p,s,false); placePip(xR,y3,p,s,false);
        placePip(xL,y6,p,s,true);  placePip(xR,y6,p,s,true);  break;
      case 7:
        placePip(xL,y0,p,s,false); placePip(xR,y0,p,s,false);
        placePip(xL,y3,p,s,false); placePip(xR,y3,p,s,false);
        placePip(xC,y2,p,s,false);
        placePip(xL,y6,p,s,true);  placePip(xR,y6,p,s,true);  break;
      case 8:
        placePip(xL,y0,p,s,false); placePip(xR,y0,p,s,false);
        placePip(xL,y3,p,s,false); placePip(xR,y3,p,s,false);
        placePip(xC,y2,p,s,false); placePip(xC,y4,p,s,true);
        placePip(xL,y6,p,s,true);  placePip(xR,y6,p,s,true);  break;
      case 9:
        placePip(xL,y0,p,s,false); placePip(xR,y0,p,s,false);
        placePip(xL,y1,p,s,false); placePip(xR,y1,p,s,false);
        placePip(xC,y3,p,s,false);
        placePip(xL,y5,p,s,true);  placePip(xR,y5,p,s,true);
        placePip(xL,y6,p,s,true);  placePip(xR,y6,p,s,true);  break;
      case 10:
        placePip(xL,y0,p,s,false); placePip(xR,y0,p,s,false);
        placePip(xL,y1,p,s,false); placePip(xR,y1,p,s,false);
        placePip(xC,y2,p,s,false); placePip(xC,y4,p,s,true);
        placePip(xL,y5,p,s,true);  placePip(xR,y5,p,s,true);
        placePip(xL,y6,p,s,true);  placePip(xR,y6,p,s,true);  break;
    }
  }

  void placePip(float px, float py, float ps, String suit, boolean flip) {
    if (flip) {
      pushMatrix(); translate(px, py); rotate(PI);
      renderSuit(-ps/2, -ps/2, ps, ps, suit);
      popMatrix();
    } else {
      renderSuit(px - ps/2, py - ps/2, ps, ps, suit);
    }
  }

  // ── Vector suit drawing ──────────────────────────────────────
  void renderSuit(float sx, float sy, float sw, float sh, String suit) {
    pushMatrix();
    pushStyle();
    translate(sx + sw/2, sy + sh/2);
    float sz = min(sw, sh);
    scale(sz / 2.0);
    noStroke();

    boolean red = suit.equals("\u2665") || suit.equals("\u2666");
    fill(red ? color(200, 40, 40) : color(40));

    if (suit.equals("\u2660")) {           // Spade
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
    } else if (suit.equals("\u2665")) {    // Heart
      beginShape();
      vertex(0, 0.6);
      bezierVertex(0.8, -0.2, 0.9, -1.0, 0, -0.5);
      bezierVertex(-0.9, -1.0, -0.8, -0.2, 0, 0.6);
      endShape();
    } else if (suit.equals("\u2663")) {    // Club
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
    } else if (suit.equals("\u2666")) {    // Diamond
      beginShape();
      vertex(0, -1);  vertex(0.8, 0);  vertex(0, 1);  vertex(-0.8, 0);
      endShape(CLOSE);
    }

    popStyle();
    popMatrix();
  }

  // ── Status bar ───────────────────────────────────────────────
  void renderStatus() {
    if (bjStatus.length() == 0) return;
    float sy = bjH/2 + 90*bjScale;
    textSize(30 * bjScale);
    float sw = textWidth(bjStatus) + 80*bjScale;

    noStroke(); fill(20, 20, 20, 200);
    rect((bjW-sw)/2, sy - 38*bjScale, sw, 76*bjScale, 38*bjScale);

    if      (bjStatusType.equals("win"))       stroke(BJ_WIN);
    else if (bjStatusType.equals("lose"))      stroke(BJ_LOSE);
    else if (bjStatusType.equals("blackjack")) stroke(BJ_DEAL_CLR);
    else                                       stroke(255, 100);

    strokeWeight(4*bjScale); noFill();
    rect((bjW-sw)/2, sy - 38*bjScale, sw, 76*bjScale, 38*bjScale);

    fill(255);
    if (bjStatusType.equals("blackjack")) fill(BJ_DEAL_CLR);
    textAlign(CENTER, CENTER);
    text(bjStatus, bjW/2, sy - 4);
  }

  // ── Animations ───────────────────────────────────────────────
  void tickAnimations() {
    for (int i = bjAnims.size() - 1; i >= 0; i--) {
      bjAnims.get(i).tick();
      if (bjAnims.get(i).bjDone) bjAnims.remove(i);
    }
  }

  // ── Input ────────────────────────────────────────────────────
  void handleClick(float mx, float my) {
    float lx = mx - bjX, ly = my - bjY;
    if (bjDealBtn.isHit(lx, ly)  && bjDealBtn.bjEnabled)  startGame();
    if (bjHitBtn.isHit(lx, ly)   && bjHitBtn.bjEnabled)   hit();
    if (bjStandBtn.isHit(lx, ly) && bjStandBtn.bjEnabled)  stand();
  }

  void handleKey(char k) {
    if (k == 'd' || k == 'D') startGame();
    if ((k == 'h' || k == 'H') && bjHitBtn.bjEnabled)   hit();
    if ((k == 's' || k == 'S') && bjStandBtn.bjEnabled)  stand();
  }

  // ── Deck management ──────────────────────────────────────────
  void buildDeck() {
    bjDeck.clear();
    String[] suits = {"\u2660", "\u2665", "\u2666", "\u2663"};
    String[] ranks = {"A","2","3","4","5","6","7","8","9","10","J","Q","K"};
    for (String s : suits)
      for (String r : ranks)
        bjDeck.add(new BJCard(s, r));

    for (int i = bjDeck.size() - 1; i > 0; i--) {
      int j = constrain(int(random(i + 1)), 0, i);
      BJCard tmp = bjDeck.get(i);
      bjDeck.set(i, bjDeck.get(j));
      bjDeck.set(j, tmp);
    }
  }

  BJCard pullCard() {
    if (bjDeck.size() == 0) buildDeck();
    return bjDeck.remove(bjDeck.size() - 1);
  }

  // ── Hand evaluation ──────────────────────────────────────────
  int handValue(ArrayList<BJCard> hand) {
    int v = 0, aces = 0;
    for (BJCard c : hand) {
      if      (c.bjRank.equals("A"))                                                    { aces++; v += 11; }
      else if (c.bjRank.equals("K") || c.bjRank.equals("Q") || c.bjRank.equals("J"))   { v += 10; }
      else                                                                              { v += int(c.bjRank); }
    }
    while (v > 21 && aces > 0) { v -= 10; aces--; }
    return v;
  }

  int visibleDealerValue() {
    if (bjDealerHand.size() == 0) return 0;
    BJCard f = bjDealerHand.get(0);
    if (f.bjRank.equals("A")) return 11;
    if (f.bjRank.equals("K") || f.bjRank.equals("Q") || f.bjRank.equals("J")) return 10;
    return int(f.bjRank);
  }

  boolean isBlackjack(ArrayList<BJCard> hand) {
    return hand.size() == 2 && handValue(hand) == 21;
  }

  // ── Game flow ────────────────────────────────────────────────
  void startGame() {
    buildDeck();
    bjPlayerHand.clear();
    bjDealerHand.clear();
    bjAnims.clear();
    bjGameActive = true;
    bjDealerRevealed = false;

    float deckX = bjW/2 - 65*bjScale, deckY = bjH/2 - 90*bjScale;
    float cw = 130*bjScale, cs = 25*bjScale;
    float dy = 200*bjScale, py = bjH - 340*bjScale;

    // Deal 4 cards with animations
    bjPlayerHand.add(pullCard());
    float p1 = (bjW - 2*(cw+cs)) / 2;
    bjAnims.add(new BJCardAnim(deckX, deckY, p1, py));

    bjDealerHand.add(pullCard());
    bjAnims.add(new BJCardAnim(deckX, deckY, p1, dy));

    bjPlayerHand.add(pullCard());
    bjAnims.add(new BJCardAnim(deckX, deckY, p1 + cw + cs, py));

    bjDealerHand.add(pullCard());
    bjAnims.add(new BJCardAnim(deckX, deckY, p1 + cw + cs, dy));

    if (isBlackjack(bjPlayerHand)) {
      if (isBlackjack(bjDealerHand)) { endGame("tie", "Both have Blackjack! Push!"); }
      else                           { endGame("blackjack", "BLACKJACK!"); }
      return;
    }
    if (isBlackjack(bjDealerHand)) { endGame("lose", "Dealer has Blackjack!"); return; }

    bjStatus = "Your turn - Hit or Stand?";
    bjStatusType = "";
    bjDealBtn.bjEnabled  = false;
    bjHitBtn.bjEnabled   = true;
    bjStandBtn.bjEnabled = true;
  }

  void hit() {
    if (!bjGameActive) return;
    bjPlayerHand.add(pullCard());
    int pv = handValue(bjPlayerHand);
    if      (pv > 21) endGame("lose", "Bust! You went over 21");
    else if (pv == 21) stand();
  }

  void stand() {
    if (!bjGameActive) return;
    bjHitBtn.bjEnabled = false;
    bjStandBtn.bjEnabled = false;
    bjDealerRevealed = true;
    bjStatus = "Dealer's turn...";
    dealerPlay();
  }

  void dealerPlay() {
    int dv = handValue(bjDealerHand);
    int pv = handValue(bjPlayerHand);
    while (dv < 17) { bjDealerHand.add(pullCard()); dv = handValue(bjDealerHand); }

    if      (dv > 21)  endGame("win",  "Dealer busts! You win!");
    else if (dv > pv)  endGame("lose", "Dealer wins with " + dv);
    else if (pv > dv)  endGame("win",  "You win with " + pv + "!");
    else               endGame("tie",  "Push! It's a tie");
  }

  void endGame(String result, String message) {
    bjGameActive = false;
    bjDealerRevealed = true;
    bjStatus = message;
    bjStatusType = result;

    if (result.equals("win") || result.equals("blackjack")) bjWins++;
    else if (result.equals("lose")) bjLosses++;
    else bjTies++;

    bjDealBtn.bjEnabled  = true;
    bjHitBtn.bjEnabled   = false;
    bjStandBtn.bjEnabled = false;
  }

  // ════════════════════════════════════════════════════════════
  //  Inner classes (prefixed BJ to avoid merge conflicts)
  // ════════════════════════════════════════════════════════════

  class BJCard {
    String bjSuit, bjRank;
    BJCard(String s, String r) { bjSuit = s; bjRank = r; }
  }

  class BJCardAnim {
    float bjSX, bjSY, bjEX, bjEY, bjCX, bjCY;
    float bjProg = 0;
    boolean bjDone = false;

    BJCardAnim(float sx, float sy, float ex, float ey) {
      bjSX = sx; bjSY = sy; bjEX = ex; bjEY = ey; bjCX = sx; bjCY = sy;
    }

    void tick() {
      bjProg += 0.08;
      if (bjProg >= 1) { bjProg = 1; bjDone = true; }
      float t = 1 - pow(1 - bjProg, 3);
      bjCX = lerp(bjSX, bjEX, t);
      bjCY = lerp(bjSY, bjEY, t);
    }
  }

  class BJButton {
    float bjBX, bjBY, bjBW, bjBH;
    String bjLabel;
    color bjBg, bjTxt;
    boolean bjEnabled = true;
    PGraphics bjOnBuf, bjOffBuf;

    BJButton(float x, float y, float w, float h, String label, color bg, color txt) {
      bjBX = x; bjBY = y; bjBW = w; bjBH = h;
      bjLabel = label; bjBg = bg; bjTxt = txt;
      buildBuffers();
    }

    void buildBuffers() {
      bjOnBuf  = createGraphics(int(bjBW + 10), int(bjBH + 10));
      bjOffBuf = createGraphics(int(bjBW + 10), int(bjBH + 10));

      // Enabled state
      bjOnBuf.beginDraw();
      bjOnBuf.clear();
      bjOnBuf.noStroke(); bjOnBuf.fill(bjBg, 100);
      bjOnBuf.rect(0, 4, bjBW, bjBH, 12);
      bjOnBuf.fill(bjBg);
      bjOnBuf.rect(0, 0, bjBW, bjBH, 12);
      bjOnBuf.fill(255, 30);
      bjOnBuf.rect(0, 0, bjBW, bjBH/2, 12, 12, 0, 0);
      bjOnBuf.noFill(); bjOnBuf.stroke(255, 50); bjOnBuf.strokeWeight(1);
      bjOnBuf.rect(0, 0, bjBW, bjBH, 12);
      bjOnBuf.textAlign(CENTER, CENTER); bjOnBuf.textSize(20);
      bjOnBuf.fill(bjTxt); bjOnBuf.text(bjLabel, bjBW/2, bjBH/2 - 2);
      bjOnBuf.endDraw();

      // Disabled state
      bjOffBuf.beginDraw();
      bjOffBuf.clear();
      bjOffBuf.fill(30); bjOffBuf.stroke(50);
      bjOffBuf.rect(0, 0, bjBW, bjBH, 12);
      bjOffBuf.textAlign(CENTER, CENTER); bjOffBuf.textSize(16);
      bjOffBuf.fill(100); bjOffBuf.text(bjLabel, bjBW/2, bjBH/2 - 2);
      bjOffBuf.endDraw();
    }

    void render() {
      pushStyle();
      if (bjEnabled && bjOnBuf != null)       image(bjOnBuf, bjBX, bjBY);
      else if (!bjEnabled && bjOffBuf != null) image(bjOffBuf, bjBX, bjBY);
      popStyle();
    }

    boolean isHit(float mx, float my) {
      return mx >= bjBX && mx <= bjBX + bjBW && my >= bjBY && my <= bjBY + bjBH;
    }
  }
}
