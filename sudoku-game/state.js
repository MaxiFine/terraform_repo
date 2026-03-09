// Game State Management
class SudokuState {
    constructor() {
        this.board = [];
        this.initialBoard = [];
        this.solution = [];
        this.startTime = null;
        this.mistakes = 0;
        this.difficulty = 'medium';
    }

    reset(board, solution, difficulty) {
        this.board = board.map(row => [...row]);
        this.initialBoard = board.map(row => [...row]);
        this.solution = solution;
        this.startTime = Date.now();
        this.mistakes = 0;
        this.difficulty = difficulty;
    }

    incrementMistakes() {
        this.mistakes++;
    }

    getProgress() {
        const empty = this.board.flat().filter(cell => cell === 0).length;
        const total = 81;
        return Math.round(((total - empty) / total) * 100);
    }

    save() {
        try {
            localStorage.setItem('sudokuState', JSON.stringify({
                board: this.board,
                initialBoard: this.initialBoard,
                solution: this.solution,
                startTime: this.startTime,
                mistakes: this.mistakes,
                difficulty: this.difficulty
            }));
        } catch (e) {
            console.error('Failed to save game:', e);
        }
    }

    load() {
        try {
            const saved = localStorage.getItem('sudokuState');
            if (saved) {
                const data = JSON.parse(saved);
                Object.assign(this, data);
                return true;
            }
        } catch (e) {
            console.error('Failed to load game:', e);
        }
        return false;
    }
}

export default SudokuState;
