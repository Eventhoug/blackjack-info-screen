# ♠ Blackjack Info Screen ♥

A blackjack game designed for info screen displays, available in both **Processing (Java)** and **Web (HTML/JS)** versions.

![Blackjack Game](https://img.shields.io/badge/Game-Blackjack-gold)
![Processing](https://img.shields.io/badge/Processing-Java-blue)
![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)

## 🎮 Processing Version (Java)

### Easy Integration

The Processing version is designed to be **super easy to integrate** into your info screen project:

```java
// In your sketch:
BlackjackGame blackjack;

void setup() {
    size(1200, 800);
    blackjack = new BlackjackGame(0, 0, width, height);
}

void draw() {
    blackjack.display();  // That's it!
}

void mousePressed() {
    blackjack.handleClick(mouseX, mouseY);
}

void keyPressed() {
    blackjack.handleKey(key);
}
```

### Quick Start

1. Copy the `BlackjackInfoScreen` folder to your Processing sketches folder
2. Open `BlackjackInfoScreen.pde` in Processing
3. Click Run!

### Files

| File                      | Description                         |
| ------------------------- | ----------------------------------- |
| `BlackjackInfoScreen.pde` | Main sketch (example usage)         |
| `BlackjackGame.pde`       | Game class - copy this to integrate |
| `Helpers.pde`             | Card, Button, Animation classes     |

### Integration API

```java
// Create game at position (x, y) with size (width, height)
BlackjackGame game = new BlackjackGame(x, y, width, height);

// Call every frame to render
game.display();

// Handle input
game.handleClick(mouseX, mouseY);  // In mousePressed()
game.handleKey(key);                // In keyPressed()

// Keyboard shortcuts: D=Deal, H=Hit, S=Stand
```

---

## 🌐 Web Version (HTML/CSS/JS)

Open `index.html` in any browser. No build tools required!

### Files

| File         | Description          |
| ------------ | -------------------- |
| `index.html` | Main game page       |
| `styles.css` | Casino table styling |
| `game.js`    | Game logic           |

---

## 🎰 Features

- ✅ Classic blackjack rules
- ✅ Casino green felt table design
- ✅ "Dealer Stands on Soft 17" rule
- ✅ Win/Loss/Tie tracking
- ✅ Info screen optimized (large text, high contrast)

## 🃏 Controls

| Action | Mouse              | Keyboard |
| ------ | ------------------ | -------- |
| Deal   | Click DEAL button  | D        |
| Hit    | Click HIT button   | H        |
| Stand  | Click STAND button | S        |

## 📜 License

MIT License - free to use and modify!

---

Made for HTX info screen displays ♠♥♦♣
