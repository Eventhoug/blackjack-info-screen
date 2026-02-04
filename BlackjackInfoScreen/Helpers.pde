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

  Button(float x, float y, float w, float h, String label, color bgColor, color textColor) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.bgColor = bgColor;
    this.textColor = textColor;
  }

  void display() {
    pushStyle();

    if (enabled) {
      // Shadow (soft glow)
      noStroke();
      fill(bgColor, 100);
      rect(x, y + 4, w, h, 12);

      // Button Body
      fill(bgColor);
      rect(x, y, w, h, 12);

      // Top Shine
      fill(255, 30);
      rect(x, y, w, h/2, 12, 12, 0, 0);

      // Border
      noFill();
      stroke(255, 50);
      strokeWeight(1);
      rect(x, y, w, h, 12);
    } else {
      // Disabled State
      fill(30);
      stroke(50);
      rect(x, y, w, h, 12);
    }

    // Text
    textAlign(CENTER, CENTER);
    textSize(16);
    if (enabled) {
      fill(textColor);
    } else {
      fill(100);
    }
    text(label, x + w/2, y + h/2 - 2);

    popStyle();
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

// Vector Suit Drawing Functions
void drawSuit(float x, float y, float w, float h, String suit) {
  pushStyle();
  pushMatrix();
  translate(x + w/2, y + h/2);
  float s = min(w, h) / 2.0;
  scale(s);

  noStroke();
  if (suit.equals("♥") || suit.equals("♦")) {
    fill(200, 40, 40); // Standard Red
  } else {
    fill(40); // Soft Black
  }

  if (suit.equals("♠")) drawSpade();
  else if (suit.equals("♥")) drawHeart();
  else if (suit.equals("♣")) drawClub();
  else if (suit.equals("♦")) drawDiamond();

  popMatrix();
  popStyle();
}

void drawSpade() {
  beginShape();
  vertex(0, -1);
  bezierVertex(0.5, -0.5, 0.9, 0, 0.9, 0.4);
  bezierVertex(0.9, 0.8, 0, 0.3, 0, 0.3);
  bezierVertex(0, 0.3, -0.9, 0.8, -0.9, 0.4);
  bezierVertex(-0.9, 0, -0.5, -0.5, 0, -1);
  endShape();
  // Stem
  beginShape();
  vertex(0, 0.3);
  bezierVertex(0.1, 0.6, 0.3, 0.9, 0.5, 1);
  vertex(-0.5, 1);
  bezierVertex(-0.3, 0.9, -0.1, 0.6, 0, 0.3);
  endShape();
}

void drawHeart() {
  beginShape();
  vertex(0, 0.5);
  bezierVertex(1.2, -0.5, 1, -1.2, 0, -0.6);
  bezierVertex(-1, -1.2, -1.2, -0.5, 0, 0.5);
  endShape();
}

void drawClub() {
  float r = 0.55;
  ellipse(0, -0.5, r, r);
  ellipse(-0.45, 0.15, r, r);
  ellipse(0.45, 0.15, r, r);
  // Stem
  beginShape();
  vertex(0, 0);
  bezierVertex(0.1, 0.6, 0.3, 0.9, 0.5, 1);
  vertex(-0.5, 1);
  bezierVertex(-0.3, 0.9, -0.1, 0.6, 0, 0);
  endShape();
}

void drawDiamond() {
  beginShape();
  vertex(0, -1);
  vertex(0.8, 0);
  vertex(0, 1);
  vertex(-0.8, 0);
  endShape(CLOSE);
}
