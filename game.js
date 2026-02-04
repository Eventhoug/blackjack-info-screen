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
function createCardElement(card, hidden = false, isNew = false) {
    const cardEl = document.createElement('div');
    const colorClass = hidden ? 'hidden' : (card.suit === '♥' || card.suit === '♦' ? 'red' : 'black');
    const newClass = isNew ? ' new-card' : '';
    cardEl.className = `card ${colorClass}${newClass}`;
    
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

// Add a single card to display (without re-rendering all cards)
function addCardToDisplay(container, card, hidden = false) {
    const cardEl = createCardElement(card, hidden, true);
    container.appendChild(cardEl);
}

// Update hand values display
function updateHandValues(revealDealer = false) {
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

// Render all hands (used for initial deal and reveal)
function renderHands(revealDealer = false) {
    // Clear existing cards
    dealerCardsEl.innerHTML = '';
    playerCardsEl.innerHTML = '';
    
    // Render dealer cards
    dealerHand.forEach((card, index) => {
        const hidden = index === 1 && !revealDealer;
        const cardEl = createCardElement(card, hidden, false);
        dealerCardsEl.appendChild(cardEl);
    });
    
    // Render player cards
    playerHand.forEach((card, index) => {
        const cardEl = createCardElement(card, false, false);
        playerCardsEl.appendChild(cardEl);
    });
    
    updateHandValues(revealDealer);
}

// Initial deal with staggered animations
function dealInitialCards() {
    dealerCardsEl.innerHTML = '';
    playerCardsEl.innerHTML = '';
    
    // Deal cards with delays for animation effect
    setTimeout(() => {
        const card1 = createCardElement(playerHand[0], false, true);
        playerCardsEl.appendChild(card1);
    }, 0);
    
    setTimeout(() => {
        const card2 = createCardElement(dealerHand[0], false, true);
        dealerCardsEl.appendChild(card2);
    }, 150);
    
    setTimeout(() => {
        const card3 = createCardElement(playerHand[1], false, true);
        playerCardsEl.appendChild(card3);
    }, 300);
    
    setTimeout(() => {
        const card4 = createCardElement(dealerHand[1], true, true);
        dealerCardsEl.appendChild(card4);
        updateHandValues(false);
    }, 450);
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
    
    // Animate initial deal
    dealInitialCards();
    
    // Check for blackjack after animation completes
    setTimeout(() => {
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
    }, 600);
}

// Player hits
function hit() {
    if (!gameActive) return;
    
    const newCard = drawCard();
    playerHand.push(newCard);
    
    // Only add the new card (with animation)
    addCardToDisplay(playerCardsEl, newCard, false);
    updateHandValues(false);
    
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
    }, 800);
}

// Dealer's turn
function dealerPlay() {
    const dealerValue = calculateHandValue(dealerHand);
    const playerValue = calculateHandValue(playerHand);
    
    if (dealerValue < 17) {
        const newCard = drawCard();
        dealerHand.push(newCard);
        
        // Only add the new card (with animation)
        addCardToDisplay(dealerCardsEl, newCard, false);
        updateHandValues(true);
        
        setTimeout(() => dealerPlay(), 600);
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
