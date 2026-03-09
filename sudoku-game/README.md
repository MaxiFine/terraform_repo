# Sudoku Web Application

A modern, modular Sudoku game built with vanilla JavaScript and clean architecture principles.

## Features

- **Modern UI**: Gradient background, smooth animations, responsive design
- **Three Difficulty Levels**: Easy (35 empty cells), Medium (45), Hard (55)
- **Game Stats**: Timer, mistakes counter, progress tracker
- **Smart Features**:
  - Real-time conflict detection
  - Keyboard navigation (arrow keys)
  - Auto-save to localStorage
  - Visual feedback for valid/invalid entries
  - Completed row/column highlighting

## Architecture

The codebase follows separation of concerns with modular design:

### Modules

- **`engine.js`** - Game logic (puzzle generation, solving, validation)
- **`state.js`** - State management (game data, persistence)
- **`ui.js`** - UI controller (rendering, event handling)
- **`game.js`** - Main controller (coordinates all modules)
- **`style.css`** - Styling and animations
- **`index.html`** - HTML structure

### Design Patterns

- **MVC Pattern**: Separation of Model (State), View (UI), Controller (Game)
- **Single Responsibility**: Each module has one clear purpose
- **Error Handling**: Try-catch blocks with fallback behavior
- **Debouncing**: Optimized input validation

## Performance Optimizations

- Constraint propagation solver (10-100x faster)
- Debounced validation (150ms)
- O(n) conflict detection using hash maps
- RequestAnimationFrame for smooth animations

## How to Use

1. Open `index.html` in a modern browser (supports ES6 modules)
2. Select difficulty level (Easy/Medium/Hard)
3. Fill cells using mouse or keyboard
4. Use arrow keys to navigate
5. Click "Check" to verify solution
6. Game auto-saves progress

## Browser Requirements

- Modern browser with ES6 module support
- Chrome 61+, Firefox 60+, Safari 11+, Edge 16+

## File Structure

```
├── index.html      # Entry point
├── style.css       # Styles
├── game.js         # Main controller
├── engine.js       # Game logic
├── state.js        # State management
├── ui.js           # UI controller
└── README.md       # Documentation
```

## Technical Details

- Pure JavaScript (ES6 modules)
- No external dependencies
- LocalStorage for persistence
- CSS Grid for layout
- CSS animations for feedback

