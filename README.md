# Blackjack Info Screen

A professional blackjack game for info screens, built with **Processing (Java)**.

![Blackjack Game](https://img.shields.io/badge/Game-Blackjack-gold)
![Processing](https://img.shields.io/badge/Processing-Visuals-green)

## Visual Redesign

- **Vector Graphics**: Suits (♠♥♦♣) are drawn mathematically, ensuring perfect rendering on any display without missing font glyphs.
- **Casino Aesthetics**: Realistic green felt table, gold borders, and dynamic lighting effects.
- **Polished UI**: Tactile buttons, clear status messages, and smooth card animations.

## Quick Start

1. Install [Processing](https://processing.org/download)
2. Open `BlackjackInfoScreen.pde`
3. Click Run!

## Easy Integration

Copy the `.pde` files to your project and integrate with just a few lines:

```java
BlackjackGame blackjack;

void setup() {
    fullScreen(); // Recommended for info screens
    // or size(1920, 1080);
    blackjack = new BlackjackGame(0, 0, width, height);
}

void draw() {
    blackjack.display();
}

void mousePressed() {
    blackjack.handleClick(mouseX, mouseY);
}

void keyPressed() {
    blackjack.handleKey(key);
}
```

## Files

| File                      | Description                                         |
| ------------------------- | --------------------------------------------------- |
| `BlackjackInfoScreen.pde` | Main sketch entry point                             |
| `BlackjackGame.pde`       | Main game class with drawing logic                  |
| `Helpers.pde`             | Utilities: Card class, Buttons, Vector Suit drawing |

## Controls

| Action | Mouse       | Keyboard |
| ------ | ----------- | -------- |
| Deal   | Click DEAL  | D        |
| Hit    | Click HIT   | H        |
| Stand  | Click STAND | S        |

## License

MIT License

---

Made for HTX info screen displays
