# ♠ Blackjack Info Screen ♥

A blackjack game for info screen displays, built with **Processing (Java)**.

![Blackjack Game](https://img.shields.io/badge/Game-Blackjack-gold)
![Processing](https://img.shields.io/badge/Processing-Java-blue)

## 🚀 Quick Start

1. Install [Processing](https://processing.org/download)
2. Clone this repo or download the `BlackjackInfoScreen` folder
3. Open `BlackjackInfoScreen.pde` in Processing
4. Click Run!

## 🎮 Easy Integration

Copy the `.pde` files to your project and integrate with just a few lines:

```java
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

## 📁 Files

| File                      | Description                     |
| ------------------------- | ------------------------------- |
| `BlackjackInfoScreen.pde` | Main sketch (example usage)     |
| `BlackjackGame.pde`       | Game class - the main component |
| `Helpers.pde`             | Card, Button, Animation classes |

## 🔧 API Reference

```java
// Create game at position (x, y) with size (width, height)
BlackjackGame game = new BlackjackGame(x, y, width, height);

// Render the game - call in draw()
game.display();

// Handle mouse input - call in mousePressed()
game.handleClick(mouseX, mouseY);

// Handle keyboard input - call in keyPressed()
game.handleKey(key);
```

## 🃏 Controls

| Action | Mouse       | Keyboard |
| ------ | ----------- | -------- |
| Deal   | Click DEAL  | D        |
| Hit    | Click HIT   | H        |
| Stand  | Click STAND | S        |

## 🎰 Features

- ✅ Classic blackjack rules
- ✅ Casino green felt table design
- ✅ Dealer stands on soft 17
- ✅ Win/Loss/Tie tracking
- ✅ Info screen optimized

## 📜 License

MIT License

---

Made for HTX info screen displays ♠♥♦♣
