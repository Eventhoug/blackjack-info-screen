// PERFORMANCE: Pre-rendered suit shapes cache
HashMap<String, PShape> suitShapeCache = new HashMap<String, PShape>();
boolean suitCacheInitialized = false;

void initializeSuitCache() {
  if (suitCacheInitialized) return;

  // Create and cache all four suit shapes
  suitShapeCache.put("♠", createSpadeShape());
  suitShapeCache.put("♥", createHeartShape());
  suitShapeCache.put("♣", createClubShape());
  suitShapeCache.put("♦", createDiamondShape());

  suitCacheInitialized = true;
}

PShape createSpadeShape() {
  PShape s = createShape();
  s.beginShape();
  s.noStroke();
  s.fill(40);
  s.vertex(0, -1);
  s.bezierVertex(0.5, -0.5, 0.9, 0, 0.9, 0.4);
  s.bezierVertex(0.9, 0.8, 0, 0.3, 0, 0.3);
  s.bezierVertex(0, 0.3, -0.9, 0.8, -0.9, 0.4);
  s.bezierVertex(-0.9, 0, -0.5, -0.5, 0, -1);
  s.endShape();
  s.beginShape();
  s.vertex(0, 0.3);
  s.bezierVertex(0.1, 0.6, 0.3, 0.9, 0.5, 1);
  s.vertex(-0.5, 1);
  s.bezierVertex(-0.3, 0.9, -0.1, 0.6, 0, 0.3);
  s.endShape();
  return s;
}

PShape createHeartShape() {
  PShape s = createShape();
  s.beginShape();
  s.noStroke();
  s.fill(200, 40, 40);
  s.vertex(0, 0.5);
  s.bezierVertex(1.2, -0.5, 1, -1.2, 0, -0.6);
  s.bezierVertex(-1, -1.2, -1.2, -0.5, 0, 0.5);
  s.endShape();
  return s;
}

PShape createClubShape() {
  PShape s = createShape(GROUP);
  float r = 0.55;

  PShape c1 = createShape(ELLIPSE, 0, -0.5, r, r);
  c1.setFill(color(40));
  c1.setStroke(false);

  PShape c2 = createShape(ELLIPSE, -0.45, 0.15, r, r);
  c2.setFill(color(40));
  c2.setStroke(false);

  PShape c3 = createShape(ELLIPSE, 0.45, 0.15, r, r);
  c3.setFill(color(40));
  c3.setStroke(false);

  PShape stem = createShape();
  stem.beginShape();
  stem.noStroke();
  stem.fill(40);
  stem.vertex(0, 0);
  stem.bezierVertex(0.1, 0.6, 0.3, 0.9, 0.5, 1);
  stem.vertex(-0.5, 1);
  stem.bezierVertex(-0.3, 0.9, -0.1, 0.6, 0, 0);
  stem.endShape();

  s.addChild(c1);
  s.addChild(c2);
  s.addChild(c3);
  s.addChild(stem);

  return s;
}

PShape createDiamondShape() {
  PShape s = createShape();
  s.beginShape();
  s.noStroke();
  s.fill(200, 40, 40);
  s.vertex(0, -1);
  s.vertex(0.8, 0);
  s.vertex(0, 1);
  s.vertex(-0.8, 0);
  s.endShape(CLOSE);
  return s;
}

// Card class
class Card {
  String suit;
  String rank;

  Card(String suit, String rank) {
    this.suit = suit;
    this.rank = rank;
  }
}

// Button class
class Button {
  float x, y, w, h;
  String label;
  color bgColor;
  color textColor;
  boolean enabled = true;

  // Performance: Cache button graphics
  PGraphics enabledBuffer;
  PGraphics disabledBuffer;
  boolean buffersCreated = false;

  Button(float x, float y, float w, float h, String label, color bgColor, color textColor) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.bgColor = bgColor;
    this.textColor = textColor;
    createButtonBuffers();
  }

  void createButtonBuffers() {
    enabledBuffer = createGraphics(int(w + 10), int(h + 10));
    disabledBuffer = createGraphics(int(w + 10), int(h + 10));

    // Render enabled state
    enabledBuffer.beginDraw();
    enabledBuffer.clear();

    // Shadow (soft glow)
    enabledBuffer.noStroke();
    enabledBuffer.fill(bgColor, 100);
    enabledBuffer.rect(0, 4, w, h, 12);

    // Button Body
    enabledBuffer.fill(bgColor);
    enabledBuffer.rect(0, 0, w, h, 12);

    // Top Shine
    enabledBuffer.fill(255, 30);
    enabledBuffer.rect(0, 0, w, h/2, 12, 12, 0, 0);

    // Border
    enabledBuffer.noFill();
    enabledBuffer.stroke(255, 50);
    enabledBuffer.strokeWeight(1);
    enabledBuffer.rect(0, 0, w, h, 12);

    // Text
    enabledBuffer.textAlign(CENTER, CENTER);
    enabledBuffer.textSize(20);
    enabledBuffer.fill(textColor);
    enabledBuffer.text(label, w/2, h/2 - 2);

    enabledBuffer.endDraw();

    // Render disabled state
    disabledBuffer.beginDraw();
    disabledBuffer.clear();

    // Disabled State
    disabledBuffer.fill(30);
    disabledBuffer.stroke(50);
    disabledBuffer.rect(0, 0, w, h, 12);

    // Text
    disabledBuffer.textAlign(CENTER, CENTER);
    disabledBuffer.textSize(16);
    disabledBuffer.fill(100);
    disabledBuffer.text(label, w/2, h/2 - 2);

    disabledBuffer.endDraw();

    buffersCreated = true;
  }

  void display() {
    // Use cached buffers for instant rendering
    if (buffersCreated) {
      pushStyle();
      if (enabled && enabledBuffer != null) {
        image(enabledBuffer, x, y);
      } else if (!enabled && disabledBuffer != null) {
        image(disabledBuffer, x, y);
      }
      popStyle();
    }
  }

  boolean isClicked(float mx, float my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }
}

// Card animation helper
class CardAnimation {
  float startX, startY, endX, endY;
  float currentX, currentY;
  float progress = 0;
  float speed = 0.08;
  boolean finished = false;

  CardAnimation(float sx, float sy, float ex, float ey) {
    startX = sx;
    startY = sy;
    endX = ex;
    endY = ey;
    currentX = sx;
    currentY = sy;
  }

  void update() {
    progress += speed;
    if (progress >= 1) {
      progress = 1;
      finished = true;
    }

    // Ease out cubic
    float t = 1 - pow(1 - progress, 3);
    currentX = lerp(startX, endX, t);
    currentY = lerp(startY, endY, t);
  }
}

// OPTIMIZED: Vector Suit Drawing Functions using cached shapes
void drawSuit(float x, float y, float w, float h, String suit) {
  pushMatrix();
  pushStyle();

  // Center the suit in the given area
  translate(x + w/2, y + h/2);
  float size = min(w, h);
  scale(size / 2.0);

  // Set color based on suit
  noStroke();
  if (suit.equals("♥") || suit.equals("♦")) {
    fill(200, 40, 40); // Red
  } else {
    fill(40); // Black
  }

  // Draw the suit shape
  if (suit.equals("♠")) {
    // Spade
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
  } else if (suit.equals("♥")) {
    // Heart
    beginShape();
    vertex(0, 0.5);
    bezierVertex(1.2, -0.5, 1, -1.2, 0, -0.6);
    bezierVertex(-1, -1.2, -1.2, -0.5, 0, 0.5);
    endShape();
  } else if (suit.equals("♣")) {
    // Club
    float r = 0.55;
    ellipse(0, -0.5, r, r);
    ellipse(-0.45, 0.15, r, r);
    ellipse(0.45, 0.15, r, r);
    beginShape();
    vertex(0, 0);
    bezierVertex(0.1, 0.6, 0.3, 0.9, 0.5, 1);
    vertex(-0.5, 1);
    bezierVertex(-0.3, 0.9, -0.1, 0.6, 0, 0);
    endShape();
  } else if (suit.equals("♦")) {
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
