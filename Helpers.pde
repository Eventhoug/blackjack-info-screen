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
            // Shadow
            noStroke();
            fill(0, 60);
            rect(x + 3, y + 3, w, h, 10);
            
            // Button
            fill(bgColor);
            rect(x, y, w, h, 10);
            
            // Highlight
            fill(255, 40);
            rect(x, y, w, h/2, 10, 10, 0, 0);
        } else {
            fill(red(bgColor), green(bgColor), blue(bgColor), 100);
            rect(x, y, w, h, 10);
        }
        
        // Text
        textAlign(CENTER, CENTER);
        textSize(14);
        if (enabled) {
            fill(textColor);
        } else {
            fill(red(textColor), green(textColor), blue(textColor), 100);
        }
        text(label, x + w/2, y + h/2);
        
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
    float speed = 0.1;
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
        
        // Ease out
        float t = 1 - pow(1 - progress, 3);
        currentX = lerp(startX, endX, t);
        currentY = lerp(startY, endY, t);
    }
}
