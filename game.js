// Blackjack Game Logic

// Card suits and ranks
const suits = ['♠', '♥', '♦', '♣'];
const ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

// Game state
let deck = [];
let playerHand = [];
let dealerHand = [];
let gameActive = false;
let stats = {
    wins: 0,
    losses: 0,
    ties: 0
};

// DOM Elements
const dealerCardsEl = document.getElementById('dealer-cards');
const playerCardsEl = document.getElementById('player-cards');
const dealerValueEl = document.getElementById('dealer-value');
const playerValueEl = document.getElementById('player-value');
const gameStatusEl = document.getElementById('game-status');
const dealBtn = document.getElementById('deal-btn');
const hitBtn = document.getElementById('hit-btn');
const standBtn = document.getElementById('stand-btn');
const winsEl = document.getElementById('wins');
const lossesEl = document.getElementById('losses');
const tiesEl = document.getElementById('ties');

// Create and shuffle deck
function createDeck() {
    deck = [];
    for (const suit of suits) {
        for (const rank of ranks) {
            deck.push({ suit, rank });
        }
    }
    shuffleDeck();
}

function shuffleDeck() {
    for (let i = deck.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [deck[i], deck[j]] = [deck[j], deck[i]];
    }
}

// Draw a card from the deck
function drawCard() {
    if (deck.length === 0) {
        createDeck();
    }
    return deck.pop();
}

// Calculate hand value
function calculateHandValue(hand) {
    let value = 0;
    let aces = 0;
    
    for (const card of hand) {
        if (card.rank === 'A') {
            aces++;
            value += 11;
        } else if (['K', 'Q', 'J'].includes(card.rank)) {
            value += 10;
        } else {
            value += parseInt(card.rank);
        }
    }
    
    // Adjust for aces
    while (value > 21 && aces > 0) {
        value -= 10;
        aces--;
    }
    
    return value;
}

// Check if hand is blackjack
function isBlackjack(hand) {
    return hand.length === 2 && calculateHandValue(hand) === 21;
}

// Create card element
function createCardElement(card, hidden = false) {
    const cardEl = document.createElement('div');
    cardEl.className = `card ${hidden ? 'hidden' : (card.suit === '♥' || card.suit === '♦' ? 'red' : 'black')}`;
    
    if (!hidden) {
        cardEl.innerHTML = `
            <div class="corner top">
                <span class="rank">${card.rank}</span>
                <span class="suit">${card.suit}</span>
            </div>
            <span class="center-suit">${card.suit}</span>
            <div class="corner bottom">
                <span class="rank">${card.rank}</span>
                <span class="suit">${card.suit}</span>
            </div>
        `;
    }
    
    return cardEl;
}

// Render hands
function renderHands(revealDealer = false) {
    // Clear existing cards
    dealerCardsEl.innerHTML = '';
    playerCardsEl.innerHTML = '';
    
    // Render dealer cards
    dealerHand.forEach((card, index) => {
        const hidden = index === 1 && !revealDealer;
        const cardEl = createCardElement(card, hidden);
        cardEl.style.animationDelay = `${index * 0.15}s`;
        dealerCardsEl.appendChild(cardEl);
    });
    
    // Render player cards
    playerHand.forEach((card, index) => {
        const cardEl = createCardElement(card);
        cardEl.style.animationDelay = `${index * 0.15}s`;
        playerCardsEl.appendChild(cardEl);
    });
    
    // Update values
    const playerValue = calculateHandValue(playerHand);
    playerValueEl.textContent = playerValue;
    
    if (revealDealer) {
        dealerValueEl.textContent = calculateHandValue(dealerHand);
    } else {
        // Show only first card value when hidden
        dealerValueEl.textContent = dealerHand.length > 0 ? 
            (dealerHand[0].rank === 'A' ? '11' : 
             ['K', 'Q', 'J'].includes(dealerHand[0].rank) ? '10' : 
             dealerHand[0].rank) + '?' : '0';
    }
}

// Update game status
function setGameStatus(message, type = '') {
    const statusText = gameStatusEl.querySelector('.status-text');
    statusText.textContent = message;
    statusText.className = `status-text ${type}`;
}

// Update stats display
function updateStats() {
    winsEl.textContent = stats.wins;
    lossesEl.textContent = stats.losses;
    tiesEl.textContent = stats.ties;
}

// Toggle button states
function setButtonStates(deal, hit, stand) {
    dealBtn.disabled = !deal;
    hitBtn.disabled = !hit;
    standBtn.disabled = !stand;
}

// Start new game
function startGame() {
    createDeck();
    playerHand = [];
    dealerHand = [];
    gameActive = true;
    
    // Deal initial cards
    playerHand.push(drawCard());
    dealerHand.push(drawCard());
    playerHand.push(drawCard());
    dealerHand.push(drawCard());
    
    renderHands(false);
    
    // Check for blackjack
    if (isBlackjack(playerHand)) {
        if (isBlackjack(dealerHand)) {
            endGame('tie', 'Both have Blackjack! Push!');
        } else {
            endGame('blackjack', '🎉 BLACKJACK! 🎉');
        }
        return;
    }
    
    if (isBlackjack(dealerHand)) {
        endGame('lose', 'Dealer has Blackjack!');
        return;
    }
    
    setGameStatus('Your turn - Hit or Stand?');
    setButtonStates(false, true, true);
}

// Player hits
function hit() {
    if (!gameActive) return;
    
    playerHand.push(drawCard());
    renderHands(false);
    
    const playerValue = calculateHandValue(playerHand);
    
    if (playerValue > 21) {
        endGame('lose', 'Bust! You went over 21');
    } else if (playerValue === 21) {
        stand();
    }
}

// Player stands
function stand() {
    if (!gameActive) return;
    
    setButtonStates(false, false, false);
    setGameStatus('Dealer\'s turn...');
    
    // Reveal dealer's hidden card
    renderHands(true);
    
    // Dealer draws cards
    setTimeout(() => {
        dealerPlay();
    }, 1000);
}

// Dealer's turn
function dealerPlay() {
    const dealerValue = calculateHandValue(dealerHand);
    const playerValue = calculateHandValue(playerHand);
    
    if (dealerValue < 17) {
        dealerHand.push(drawCard());
        renderHands(true);
        setTimeout(() => dealerPlay(), 800);
    } else {
        // Determine winner
        determineWinner(playerValue, dealerValue);
    }
}

// Determine winner
function determineWinner(playerValue, dealerValue) {
    if (dealerValue > 21) {
        endGame('win', 'Dealer busts! You win!');
    } else if (dealerValue > playerValue) {
        endGame('lose', `Dealer wins with ${dealerValue}`);
    } else if (playerValue > dealerValue) {
        endGame('win', `You win with ${playerValue}!`);
    } else {
        endGame('tie', 'Push! It\'s a tie');
    }
}

// End game
function endGame(result, message) {
    gameActive = false;
    renderHands(true);
    
    switch (result) {
        case 'win':
        case 'blackjack':
            stats.wins++;
            setGameStatus(message, result === 'blackjack' ? 'blackjack' : 'win');
            break;
        case 'lose':
            stats.losses++;
            setGameStatus(message, 'lose');
            break;
        case 'tie':
            stats.ties++;
            setGameStatus(message, 'tie');
            break;
    }
    
    updateStats();
    setButtonStates(true, false, false);
}

// Initialize
updateStats();
setGameStatus('Press DEAL to start');
