// Main Game Controller
import SudokuEngine from './engine.js';
import SudokuState from './state.js';
import SudokuUI from './ui.js';

class SudokuGame {
    constructor() {
        this.engine = new SudokuEngine();
        this.state = new SudokuState();
        this.ui = new SudokuUI(
            document.getElementById('grid'),
            {
                timer: document.getElementById('timer'),
                mistakes: document.getElementById('mistakes'),
                progress: document.getElementById('progress'),
                difficulty: document.getElementById('difficulty')
            }
        );

        this.init();
    }

    init() {
        try {
            if (!this.state.load()) {
                this.newGame();
            } else {
                this.resumeGame();
            }
        } catch (e) {
            console.error('Initialization failed:', e);
            this.newGame();
        }
    }

    newGame(difficulty = 'medium') {
        try {
            const { board, solution } = this.engine.generatePuzzle(difficulty);
            this.state.reset(board, solution, difficulty);
            this.renderGame();
            this.ui.startTimer(this.state.startTime);
            this.state.save();
        } catch (e) {
            console.error('Failed to create new game:', e);
            this.ui.showMessage('Failed to create game. Please try again.', false);
        }
    }

    resumeGame() {
        try {
            this.renderGame();
            this.ui.startTimer(this.state.startTime);
        } catch (e) {
            console.error('Failed to resume game:', e);
            this.newGame();
        }
    }

    renderGame() {
        this.ui.renderGrid(
            this.state.board,
            this.state.initialBoard,
            (row, col, value) => this.onCellInput(row, col, value),
            (row, col) => this.onCellSelect(row, col)
        );
        this.ui.updateInfo(this.state);
        this.validateBoard();
    }

    onCellInput(row, col, value) {
        this.state.board[row][col] = parseInt(value) || 0;
        this.validateBoard();
        this.ui.updateInfo(this.state);
        this.state.save();
    }

    onCellSelect(row, col) {
        // Handle cell selection if needed
    }

    validateBoard() {
        try {
            const conflicts = this.engine.findConflicts(this.state.board);
            this.ui.highlightConflicts(conflicts);
            
            if (conflicts.size > 0) {
                this.state.incrementMistakes();
                this.ui.updateInfo(this.state);
            }
        } catch (e) {
            console.error('Validation failed:', e);
        }
    }

    checkSolution() {
        try {
            const currentBoard = this.ui.getBoardFromInputs();
            const isCorrect = this.engine.validateSolution(currentBoard, this.state.solution);
            
            if (isCorrect) {
                this.ui.stopTimer();
                this.ui.showMessage('Correct! Well done!', true);
            } else {
                this.ui.showMessage('Not quite right. Keep trying!', false);
            }
        } catch (e) {
            console.error('Solution check failed:', e);
            this.ui.showMessage('Failed to check solution.', false);
        }
    }
}

// Initialize game
const game = new SudokuGame();

// Expose methods to global scope for button onclick handlers
window.newGame = (difficulty) => game.newGame(difficulty);
window.checkSolution = () => game.checkSolution();
