/*
 BlackjackGame
 Alle klasserne er navngievet præfikset "BJ"- 
 
 For at spille skal man:
 BlackjackGame game = new BlackjackGame(0, 0, width, height);
 game.display();           // Kald i draw()
 game.handleClick(mx,my);  // Kald i mousePressed()
 game.handleKey(k);        // Kald i keyPressed()
 Tjek game.bjBackRequested for at gå tilbage til hovedmenuen.
 */

class BlackjackGame {

  // Position og størrelse
  float bjX, bjY, bjW, bjH;
  float bjScale = 1.0;

  // Kortdimensioner
  float bjCardW, bjCardH, bjCardGap;

  // Hænder og kortbunke
  ArrayList<BJCard> bjPlayerHand, bjDealerHand, bjDeck;
  boolean bjGameActive = false;
  boolean bjDealerRevealed = false;
  String bjStatus = "Press DEAL to start";
  String bjStatusType = "";

  // Tilbage-knap flag (tjekkes udefra for at forlade skærmen)
  boolean bjBackRequested = false;

  // Pointtælling
  int bjWins = 0, bjLosses = 0, bjTies = 0;

  // Farvepalet
  final color BJ_FELT = #1b5e3b;
  final color BJ_FELT2 = #17492f;
  final color BJ_GOLD = #c9a94e;
  final color BJ_RED = #b5312c;
  final color BJ_INK = #1a1a1a;
  final color BJ_WIN = #2ecc71;
  final color BJ_LOSE = #e74c3c;
  final color BJ_AMBER = #e6b832;

  // Lodredde positioner
  float bjTitleY, bjDealerLabelY, bjDealerCardY;
  float bjBannerY, bjStatusY;
  float bjPlayerLabelY, bjPlayerCardY;

  // Knapper langs kanten
  // 1 (venstre) = DEAL
  // 2 (bund-venstre) = HIT
  // midten-bund = TILBAGE (pil-ikon)
  // 3 (bund-højre) = STAND
  // 4 (højre) = ubrugt
  BJButton bjDealBtn, bjHitBtn, bjBackBtn, bjStandBtn, bjBtn4;

  // Forud-renderet bordoverflade
  PGraphics bjTableBuf;

  // Frame-tæller til forskudt kortgivning
  int bjFrameCount = 0;

  // Dealer-tur state (bruges til forsinkelse mellem kort)
  boolean bjDealerTurnActive = false;
  int bjDealerNextDrawFrame = 0;
  int bjDealerDrawDelay = 45; // frames mellem hvert dealer-kort (~0.75 sek ved 60fps)


  // Opsætning
  BlackjackGame(float x, float y, float w, float h) {
    bjX = x;
    bjY = y;
    bjW = w;
    bjH = h;
    bjScale = min(w / 1920.0, h / 1080.0);

    // Kortstørrelse
    bjCardW = 160 * bjScale;
    bjCardH = 224 * bjScale;
    bjCardGap = 30 * bjScale;

    // Lodredde positioner (spredt ud for at undgå overlap)
    bjTitleY = 20 * bjScale;
    bjDealerLabelY = 130 * bjScale;
    bjDealerCardY = 166 * bjScale;
    bjPlayerLabelY = h - 370 * bjScale;
    bjPlayerCardY = h - 334 * bjScale;

    // Banner og status placeres mellem de to hænder
    float midZone = (bjDealerCardY + bjCardH + bjPlayerLabelY) / 2;
    bjBannerY = midZone - 54 * bjScale;
    bjStatusY = midZone + 28 * bjScale;

    bjPlayerHand = new ArrayList<BJCard>();
    bjDealerHand = new ArrayList<BJCard>();
    bjDeck = new ArrayList<BJCard>();

    // Knapper langs kanterne
    float sideBtnW = 120 * bjScale; // sideknapper
    float sideBtnH = 110 * bjScale;
    float botBtnW = 120 * bjScale; // bundknapper
    float botBtnH = 72 * bjScale;
    float inset = 20 * bjScale; // afstand fra skærmkant

    float sideY = h / 2 - sideBtnH / 2; // lodret centreret
    float botY = h - inset - botBtnH; // fastgjort til bunden

    // 1: DEL — venstre kant, lodret centreret
    bjDealBtn = new BJButton(inset, sideY, sideBtnW, sideBtnH,
                              "DEAL", BJ_AMBER, BJ_INK);
    // 2: TRÆK — bundkant, venstre kvart
    bjHitBtn = new BJButton(w * 0.22, botY, botBtnW, botBtnH,
                              "HIT", BJ_WIN, BJ_INK);
    // TILBAGE — bundkant, centreret (pil tegnes ovenpå)
    bjBackBtn = new BJButton(w / 2 - botBtnW / 2, botY, botBtnW, botBtnH,
                              "", #607d8b, #f0f0f0);
    // 3: STÅ — bundkant, højre kvart
    bjStandBtn = new BJButton(w * 0.78 - botBtnW, botY, botBtnW, botBtnH,
                              "STAND", BJ_LOSE, #f0f0f0);
    // 4: ubrugt — højre kant, lodret centreret
    bjBtn4 = new BJButton(w - inset - sideBtnW, sideY, sideBtnW, sideBtnH,
                              "", #444444, #888888);

    bjHitBtn.bjEnabled = false;
    bjStandBtn.bjEnabled = false;
    bjBtn4.bjEnabled = false;

    buildTableBuffer();
  }


  // Bordoverflade (tegnes én gang i en buffer)
  void buildTableBuffer() {
    bjTableBuf = createGraphics(int(bjW), int(bjH));
    bjTableBuf.beginDraw();
    bjTableBuf.background(BJ_FELT);

    // Cirkulær vignette-effekt (mørkere kanter)
    bjTableBuf.noStroke();
    for (int i = 20; i >= 0; i--) {
      float t = i / 20.0;
      bjTableBuf.fill(lerpColor(BJ_FELT, BJ_FELT2, 1 - t), 30);
      bjTableBuf.ellipse(bjW / 2, bjH / 2, bjW * (0.6 + 0.4 * t), bjH * (0.6 + 0.4 * t));
    }

    // Dealers halvbue
    bjTableBuf.noFill();
    bjTableBuf.stroke(BJ_GOLD, 50);
    bjTableBuf.strokeWeight(3 * bjScale);
    bjTableBuf.arc(bjW / 2, 120 * bjScale, bjW * 0.7, bjH * 0.55, 0, PI);

    // Ydre ramme/kant
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


  // Hoved-tegneløkke
  void display() {
    bjFrameCount++;
    pushMatrix();
    translate(bjX, bjY);

    if (bjTableBuf != null) image(bjTableBuf, 0, 0);

    drawTitle();
    drawRulesBanner();
    drawBothHands();
    drawStatusBar();

    // Dealer trækker kort med forsinkelse
    if (bjDealerTurnActive) {
      dealerTick();
    }

    // Tegn alle knapper
    bjDealBtn.render();
    bjHitBtn.render();
    bjBackBtn.render();
    bjStandBtn.render();

    // Tegn pil-ikon på tilbage-knappen
    drawBackArrow();

    // Nummerlabels ved hver knap
    drawBtnLabel("1", bjDealBtn, true);
    drawBtnLabel("2", bjHitBtn, false);
    drawBtnLabel("3", bjStandBtn, false);

    popMatrix();
  }

  // Nummerlabel: sideknapper viser nedenunder, bundknapper viser ovenover
  void drawBtnLabel(String num, BJButton btn, boolean sideBtn) {
    textSize(14 * bjScale);
    fill(BJ_GOLD, 130);
    if (sideBtn) {
      // Placer label under sideknappen
      textAlign(CENTER, TOP);
      text(num, btn.bjBX + btn.bjBW / 2, btn.bjBY + btn.bjBH + 4 * bjScale);
    } else {
      // Placer label over bundknappen
      textAlign(CENTER, BOTTOM);
      text(num, btn.bjBX + btn.bjBW / 2, btn.bjBY - 4 * bjScale);
    }
  }

  // Tegn en opadpegende pil på tilbage-knappen
  void drawBackArrow() {
    float cx = bjBackBtn.bjBX + bjBackBtn.bjBW / 2;
    float cy = bjBackBtn.bjBY + bjBackBtn.bjBH / 2;
    float sz = min(bjBackBtn.bjBW, bjBackBtn.bjBH) * 0.38;

    noStroke();
    fill(bjBackBtn.bjEnabled ? color(#f0f0f0) : color(80));

    // Pilhoved (trekant der peger op)
    beginShape();
    vertex(cx, cy - sz);
    vertex(cx + sz, cy + sz * 0.2);
    vertex(cx - sz, cy + sz * 0.2);
    endShape(CLOSE);

    // Pilskaft
    rectMode(CENTER);
    rect(cx, cy + sz * 0.5, sz * 0.5, sz * 0.6);
    rectMode(CORNER);
  }


  // Titellinje og resultattavle
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

    // Resultattavle
    float sx = bjW - 480 * bjScale;
    float sw = 440 * bjScale;
    float sh = 78 * bjScale;

    fill(0, 70);
    rect(sx, bjTitleY, sw, sh, 12 * bjScale);

    drawScoreColumn("W", bjWins, sx + 73 * bjScale, bjTitleY + sh / 2);
    drawScoreColumn("L", bjLosses, sx + 220 * bjScale, bjTitleY + sh / 2);
    drawScoreColumn("T", bjTies, sx + 367 * bjScale, bjTitleY + sh / 2);
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


  // Banner med spillets regler
  void drawRulesBanner() {
    float bw = 620 * bjScale;
    float bh = 42 * bjScale;
    float bx = bjW / 2 - bw / 2;

    noStroke();
    fill(0, 60);
    rect(bx, bjBannerY, bw, bh, bh / 2);

    fill(BJ_GOLD, 180);
    textAlign(CENTER, CENTER);
    textSize(22 * bjScale);
    text("DEALER MUST HIT SOFT 17", bjW / 2, bjBannerY + bh / 2);
  }


  // Tegn begge hænder med animation per kort
  void drawBothHands() {
    // Dealer
    drawHandLabel("DEALER", bjDealerLabelY);
    int dealerVal = bjDealerRevealed ? handValue(bjDealerHand) : visibleDealerVal();
    drawValueBadge(str(dealerVal), bjW / 2 + 360 * bjScale, bjDealerLabelY);
    updateAndDrawHand(bjDealerHand, bjDealerCardY, true);

    // Spiller
    drawHandLabel("PLAYER", bjPlayerLabelY);
    drawValueBadge(str(handValue(bjPlayerHand)), bjW / 2 + 360 * bjScale, bjPlayerLabelY);
    updateAndDrawHand(bjPlayerHand, bjPlayerCardY, false);
  }

  void updateAndDrawHand(ArrayList<BJCard> hand, float rowY, boolean isDealer) {
    int n = hand.size();
    if (n == 0) return;

    float totalW = n * bjCardW + (n - 1) * bjCardGap;
    float startX = (bjW - totalW) / 2;

    for (int i = 0; i < n; i++) {
      BJCard c = hand.get(i);

      c.bjTgtX = startX + i * (bjCardW + bjCardGap);
      c.bjTgtY = rowY;

      if (!c.bjSlideFinished) {
        if (bjFrameCount < c.bjDealFrame) continue;

        c.bjSlideProg += 0.07;
        if (c.bjSlideProg >= 1.0) {
          c.bjSlideProg = 1.0;
          c.bjSlideFinished = true;
          if (!c.bjFaceUp && c.bjAutoFlip) {
            c.bjFlipping = true;
          }
        }
        float ease = 1 - pow(1 - c.bjSlideProg, 3);
        c.bjCurX = lerp(c.bjStartX, c.bjTgtX, ease);
        c.bjCurY = lerp(c.bjStartY, c.bjTgtY, ease);
      } else {
        c.bjCurX = lerp(c.bjCurX, c.bjTgtX, 0.18);
        c.bjCurY = lerp(c.bjCurY, c.bjTgtY, 0.18);
      }

      if (c.bjFlipping) {
        c.bjFlipProg += 0.08;
        if (c.bjFlipProg >= 1.0) {
          c.bjFlipProg = 1.0;
          c.bjFlipping = false;
          c.bjFaceUp = true;
        }
      }

      boolean showFace;
      float scaleX;
      if (c.bjFlipping) {
        if (c.bjFlipProg < 0.5) {
          scaleX = 1 - c.bjFlipProg * 2;
          showFace = false;
        } else {
          scaleX = (c.bjFlipProg - 0.5) * 2;
          showFace = true;
        }
      } else {
        scaleX = 1.0;
        showFace = c.bjFaceUp;
      }

      drawAnimatedCard(c.bjCurX, c.bjCurY, bjCardW, bjCardH, c, showFace, scaleX);
    }
  }

  void drawAnimatedCard(float cx, float cy, float cw, float ch,
                        BJCard card, boolean showFace, float scaleX) {
    float drawnW = cw * scaleX;
    float offsetX = (cw - drawnW) / 2;

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


  // Kortbagside (mørkeblå med guldramme)
  void drawCardBack(float cx, float cy, float cw, float ch) {
    float r = 10 * bjScale;

    stroke(#334455);
    strokeWeight(2 * bjScale);
    fill(#1c2a3a);
    rect(cx, cy, cw, ch, r);

    noFill();
    stroke(BJ_GOLD, 60);
    strokeWeight(1);
    rect(cx + 6, cy + 6, cw - 12, ch - 12, r - 2);

    noStroke();
    fill(#1c2a3a, 200);
    ellipse(cx + cw / 2, cy + ch / 2, cw * 0.5, ch * 0.35);
  }


  // Kortforside (hvid med værdi og kulør-symboler)
  void drawCardFace(float cx, float cy, float cw, float ch, BJCard card) {
    float r = 10 * bjScale;

    stroke(190);
    strokeWeight(bjScale);
    fill(250);
    rect(cx, cy, cw, ch, r);

    boolean isRed = card.bjSuit.equals("\u2665") || card.bjSuit.equals("\u2666");
    color ink = isRed ? BJ_RED : BJ_INK;
    fill(ink);

    textAlign(CENTER, TOP);
    textSize(cw * 0.22);
    text(card.bjRank, cx + cw * 0.20, cy + ch * 0.06);

    drawPipLayout(cx, cy, cw, ch, card);

    pushMatrix();
    translate(cx + cw * 0.80, cy + ch * 0.94);
    rotate(PI);
    fill(ink);
    textAlign(CENTER, TOP);
    textSize(cw * 0.22);
    text(card.bjRank, 0, 0);
    popMatrix();
  }


  // Kulør-layouts (2-10, Es, billedkort)
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
// Layouts for 2-10 (billedkort og Es håndteres særskilt ovenfor)
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
// Tegn et enkelt kulør-symbol (pip), med mulighed for at vende det på hovedet
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


  // Vektor-kulørformer, tegnes i normaliseret -1..1 rum og skaleres derefter
  void drawSuitShape(float sx, float sy, float sw, float sh, String suit) {
    pushMatrix();
    pushStyle();
    translate(sx + sw / 2, sy + sh / 2);
    scale(min(sw, sh) / 2.0);
    noStroke();

    boolean isRed = suit.equals("\u2665") || suit.equals("\u2666");
    fill(isRed ? color(185, 30, 30) : color(28));

    if (suit.equals("\u2660")) {
      // Spar spids top, brede lapper, smal midje
      beginShape();
      vertex(0, -1);
      bezierVertex( 0.1, -0.8,  1.0, -0.3,  0.9,  0.2);
      bezierVertex( 0.8,  0.6,  0.2,  0.55,  0.05, 0.35);
      vertex(0, 0.35);
      vertex(-0.05, 0.35);
      bezierVertex(-0.2,  0.55, -0.8,  0.6, -0.9,  0.2);
      bezierVertex(-1.0, -0.3, -0.1, -0.8,  0,    -1);
      endShape(CLOSE);
      // Stilk
      beginShape();
      vertex(-0.1,  0.3);
      vertex(-0.35, 1.0);
      vertex( 0.35, 1.0);
      vertex( 0.1,  0.3);
      endShape(CLOSE);

    } else if (suit.equals("\u2665")) {
      // Hjerter to runde buler i toppen, spids bund
      beginShape();
      vertex(0, 0.95);
      bezierVertex( 0.05, 0.8,  0.5,  0.25, 0.85, -0.05);
      bezierVertex( 1.1, -0.35, 1.0, -0.85, 0.55, -0.85);
      bezierVertex( 0.25, -0.85, 0.05, -0.6, 0, -0.35);
      bezierVertex(-0.05, -0.6, -0.25, -0.85, -0.55, -0.85);
      bezierVertex(-1.0, -0.85, -1.1, -0.35, -0.85, -0.05);
      bezierVertex(-0.5,  0.25, -0.05, 0.8,  0, 0.95);
      endShape(CLOSE);

    } else if (suit.equals("\u2663")) {
      // Klør — tre runde lapper og en stilk
      ellipse(0,     -0.4,  0.72, 0.72);
      ellipse(-0.44,  0.15, 0.72, 0.72);
      ellipse( 0.44,  0.15, 0.72, 0.72);
      beginShape();
      vertex(-0.12, 0.1);
      vertex(-0.35, 1.0);
      vertex( 0.35, 1.0);
      vertex( 0.12, 0.1);
      endShape(CLOSE);

    } else if (suit.equals("\u2666")) {
      // Ruder — høj rombe
      beginShape();
      vertex( 0,    -1);
      vertex( 0.62,  0);
      vertex( 0,     1);
      vertex(-0.62,  0);
      endShape(CLOSE);
    }

    popStyle();
    popMatrix();
  }


  // Statuslinje
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
    if (bjStatusType.equals("win")) borderClr = BJ_WIN;
    else if (bjStatusType.equals("lose")) borderClr = BJ_LOSE;
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


  // Input (1=DEL, 2=TRÆK, 3=STÅ, centerpil=TILBAGE)
  void handleClick(float mx, float my) {
    float lx = mx - bjX;
    float ly = my - bjY;
    if (bjBackBtn.isHit(lx, ly)) handleBack();
    if (bjDealBtn.isHit(lx, ly) && bjDealBtn.bjEnabled) startGame();
    if (bjHitBtn.isHit(lx, ly) && bjHitBtn.bjEnabled) playerHit();
    if (bjStandBtn.isHit(lx, ly) && bjStandBtn.bjEnabled) playerStand();
  }

  void handleKey(char k) {
    // Taltaster: 1=DEL 2=TRÆK 3=STÅ
    if (k == '1' && bjDealBtn.bjEnabled) startGame();
    if (k == '2' && bjHitBtn.bjEnabled) playerHit();
    if (k == '3' && bjStandBtn.bjEnabled) playerStand();
  }

  // Tilbage-knappen sætter et flag koden udenfor bestemmer hvad der sker
  void handleBack() {
    bjBackRequested = true;
  }

  // Kortbunke
  void buildDeck() {
    bjDeck.clear();
    String[] suits = { "\u2660", "\u2665", "\u2666", "\u2663" }; // Spar, Hjerter, Ruder, Klør i unicode
    String[] ranks = { "A","2","3","4","5","6","7","8","9","10","J","Q","K" }; // Es, 2-10, Knægt, Dronning, Konge
    for (String s : suits) //lav 52 kort 
      for (String r : ranks)
        bjDeck.add(new BJCard(s, r));

    // Blandings-algoritme
    for (int i = bjDeck.size() - 1; i > 0; i--) {
      int j = int(random(i + 1));
      BJCard tmp = bjDeck.get(i);
      bjDeck.set(i, bjDeck.get(j));
      bjDeck.set(j, tmp);
    }
  }

  BJCard pullCard() { // Træk det øverste kort, byg ny bunke hvis tom
    if (bjDeck.size() == 0) buildDeck();
    return bjDeck.remove(bjDeck.size() - 1);
  }

  BJCard dealCard(boolean autoFlip, int staggerIndex) { // Træk et kort og sæt dets startposition og animationsegenskaber
    BJCard c = pullCard();
    c.bjStartX = bjW / 2 - bjCardW / 2;
    c.bjStartY = bjH / 2 - bjCardH / 2;
    c.bjCurX = c.bjStartX;
    c.bjCurY = c.bjStartY;
    c.bjAutoFlip = autoFlip;
    c.bjDealFrame = bjFrameCount + staggerIndex * 10;
    return c;
  }


  // Beregning af håndværdi
  int handValue(ArrayList<BJCard> hand) {
    int total = 0, aces = 0;
    for (BJCard c : hand) {
      if (c.bjRank.equals("A")) { aces++; total += 11; }
      else if (c.bjRank.equals("K") || c.bjRank.equals("Q") || c.bjRank.equals("J")) { total += 10; }
      else { total += int(c.bjRank); }
    }
    while (total > 21 && aces > 0) { total -= 10; aces--; }
    return total;
  }

  int visibleDealerVal() { // Værdien af dealerens synlige kort
    if (bjDealerHand.size() == 0) return 0;
    BJCard first = bjDealerHand.get(0);
    if (first.bjRank.equals("A")) return 11;
    if (first.bjRank.equals("K") || first.bjRank.equals("Q") || first.bjRank.equals("J")) return 10;
    return int(first.bjRank);
  }

  boolean isBlackjack(ArrayList<BJCard> hand) {
    return hand.size() == 2 && handValue(hand) == 21;
  }


  // Spilforløb
  void startGame() {
    buildDeck();
    bjPlayerHand.clear();
    bjDealerHand.clear();
    bjGameActive = true;
    bjDealerRevealed = false;

    bjPlayerHand.add(dealCard(true, 0));
    bjDealerHand.add(dealCard(true, 1));
    bjPlayerHand.add(dealCard(true, 2));
    bjDealerHand.add(dealCard(false, 3));

    if (isBlackjack(bjPlayerHand)) { // Tjek for Blackjack før dealerens tur starter
      if (isBlackjack(bjDealerHand)) endGame("tie", "Both have Blackjack \u2014 Push"); // Begge har Blackjack = uafgjort
      else endGame("blackjack", "BLACKJACK!"); // Spiller har Blackjack = spiller vinder
      return;
    }
    if (isBlackjack(bjDealerHand)) { // Dealer har Blackjack = spiller taber
      endGame("lose", "Dealer Blackjack");
      return;
    }
  // Printer status og aktiverer Hit/Stand knapper
    bjStatus = "Hit or Stand?";
    bjStatusType = "";
    bjDealBtn.bjEnabled = false;
    bjHitBtn.bjEnabled = true;
    bjStandBtn.bjEnabled = true;
  }

// Spiller vælger at trække et kort
  void playerHit() { 
    if (!bjGameActive) return;
    BJCard c = dealCard(true, 0);
    bjPlayerHand.add(c);
    int val = handValue(bjPlayerHand); // Tjek for bust eller 21 efter at have trukket
    if (val > 21) endGame("lose", "Bust! Over 21");
    else if (val == 21) playerStand();
  }

// Spilleren vælger at stå, dealerens tur starter
  void playerStand() {
    if (!bjGameActive) return;
    bjHitBtn.bjEnabled = false;
    bjStandBtn.bjEnabled = false;
    bjDealerRevealed = true;

// Start dealerens tur ved at sætte det skjulte kort til at flippe og opdatere status
    BJCard holeCard = bjDealerHand.get(1);
    holeCard.bjFlipping = true;
    holeCard.bjFlipProg = 0;

    bjStatus = "Dealer draws\u2026";
    bjDealerTurnActive = true;
    bjDealerNextDrawFrame = bjFrameCount + bjDealerDrawDelay;
  }

  // Kaldes hvert frame under dealerens tur
  void dealerTick() {
    if (bjFrameCount < bjDealerNextDrawFrame) return;

// Dealer trækker kort indtil håndværdien er mindst 17, derefter afgøres spillet
    int dv = handValue(bjDealerHand);
    if (dv < 17) {
      BJCard c = dealCard(true, 0);
      bjDealerHand.add(c);
      bjDealerNextDrawFrame = bjFrameCount + bjDealerDrawDelay;
    } else {
      bjDealerTurnActive = false;
      int pv = handValue(bjPlayerHand);
      if (dv > 21) endGame("win", "Dealer busts \u2014 you win!");
      else if (dv > pv) endGame("lose", "Dealer wins with " + dv);
      else if (pv > dv) endGame("win", "You win with " + pv + "!");
      else endGame("tie", "Push \u2014 it's a tie");
    }
  }

// Afslutter spillet, viser resultat og opdaterer statistik
  void endGame(String result, String message) {
    bjGameActive = false;
    bjDealerRevealed = true;
    bjStatus = message;
    bjStatusType = result;

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

    bjDealBtn.bjEnabled = true;
    bjHitBtn.bjEnabled = false;
    bjStandBtn.bjEnabled = false;
  }


  // Indre klasser
  // BJCard repræsenterer et kort og dets animationsstatus
  class BJCard {
    String bjSuit, bjRank;

    float bjStartX, bjStartY;
    float bjTgtX, bjTgtY;
    float bjCurX, bjCurY;
    float bjSlideProg = 0;
    boolean bjSlideFinished = false;
    int bjDealFrame = 0;

    float bjFlipProg = 0;
    boolean bjFlipping = false;
    boolean bjFaceUp = false;
    boolean bjAutoFlip = true;

    BJCard(String s, String r) {
      bjSuit = s;
      bjRank = r;
    }
  }

// BJButton repræsenterer en knap med grafik for aktiv og deaktiveret tilstand
  class BJButton {
    float bjBX, bjBY, bjBW, bjBH;
    String bjLabel;
    color bjBg, bjTxt;
    boolean bjEnabled = true;
    PGraphics bjOnBuf, bjOffBuf;

    BJButton(float x, float y, float w, float h,
             String label, color bg, color txt) {
      bjBX = x; bjBY = y; bjBW = w; bjBH = h;
      bjLabel = label; bjBg = bg; bjTxt = txt;
      prebakeBuffers();
    }

    void prebakeBuffers() {
bjOnBuf = createGraphics(int(bjBW + 10), int(bjBH + 10));
      bjOffBuf = createGraphics(int(bjBW + 10), int(bjBH + 10));

      // Aktiv tilstand
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
      if (bjLabel.length() > 0) {
        bjOnBuf.textAlign(CENTER, CENTER);
        bjOnBuf.textSize(24);
        bjOnBuf.fill(bjTxt);
        bjOnBuf.text(bjLabel, bjBW / 2, bjBH / 2 - 2);
      }
      bjOnBuf.endDraw();

      // Deaktiveret tilstand
      bjOffBuf.beginDraw();
      bjOffBuf.clear();
      bjOffBuf.noStroke();
      bjOffBuf.fill(28);
      bjOffBuf.rect(0, 0, bjBW, bjBH, 14);
      bjOffBuf.stroke(45);
      bjOffBuf.strokeWeight(1);
      bjOffBuf.rect(0, 0, bjBW, bjBH, 14);
      if (bjLabel.length() > 0) {
        bjOffBuf.textAlign(CENTER, CENTER);
        bjOffBuf.textSize(20);
        bjOffBuf.fill(80);
        bjOffBuf.text(bjLabel, bjBW / 2, bjBH / 2 - 2);
      }
      bjOffBuf.endDraw();
    }
// Tegn knappen i den korrekte tilstand
    void render() {
      pushStyle();
      if (bjEnabled && bjOnBuf != null) image(bjOnBuf, bjBX, bjBY);
      else if (!bjEnabled && bjOffBuf != null) image(bjOffBuf, bjBX, bjBY);
      popStyle();
    }
// Tjek om et klik rammer knappen
    boolean isHit(float mx, float my) {
      return mx >= bjBX && mx <= bjBX + bjBW
          && my >= bjBY && my <= bjBY + bjBH;
    }
  }
}
