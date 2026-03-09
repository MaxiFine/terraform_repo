// Sudoku Game Logic
class SudokuEngine {
    constructor() {
        this.difficulties = { easy: 35, medium: 45, hard: 55 };
    }

    generatePuzzle(difficulty = 'medium') {
        const board = this.createEmptyBoard();
        this.fillBoard(board);
        const solution = board.map(row => [...row]);
        this.removeCells(board, this.difficulties[difficulty]);
        return { board, solution };
    }

    createEmptyBoard() {
        return Array(9).fill().map(() => Array(9).fill(0));
    }

    fillBoard(board) {
        const empty = this.findEmpty(board);
        if (!empty) return true;

        const [row, col] = empty;
        const candidates = this.getCandidates(board, row, col);
        this.shuffle(candidates);

        for (let num of candidates) {
            board[row][col] = num;
            if (this.fillBoard(board)) return true;
            board[row][col] = 0;
        }
        return false;
    }

    solve(board) {
        const empty = this.findEmpty(board);
        if (!empty) return true;

        const [row, col] = empty;
        const candidates = this.getCandidates(board, row, col);

        for (let num of candidates) {
            board[row][col] = num;
            if (this.solve(board)) return true;
            board[row][col] = 0;
        }
        return false;
    }

    findEmpty(board) {
        let minOptions = 10;
        let bestCell = null;

        for (let i = 0; i < 9; i++) {
            for (let j = 0; j < 9; j++) {
                if (board[i][j] === 0) {
                    const options = this.getCandidates(board, i, j).length;
                    if (options < minOptions) {
                        minOptions = options;
                        bestCell = [i, j];
                        if (options === 1) return bestCell;
                    }
                }
            }
        }
        return bestCell;
    }

    getCandidates(board, row, col) {
        const used = new Set();

        for (let i = 0; i < 9; i++) {
            if (board[row][i]) used.add(board[row][i]);
            if (board[i][col]) used.add(board[i][col]);
        }

        const boxRow = Math.floor(row / 3) * 3;
        const boxCol = Math.floor(col / 3) * 3;
        for (let i = 0; i < 3; i++) {
            for (let j = 0; j < 3; j++) {
                if (board[boxRow + i][boxCol + j]) {
                    used.add(board[boxRow + i][boxCol + j]);
                }
            }
        }

        const candidates = [];
        for (let num = 1; num <= 9; num++) {
            if (!used.has(num)) candidates.push(num);
        }
        return candidates;
    }

    removeCells(board, count) {
        let removed = 0;
        while (removed < count) {
            const i = Math.floor(Math.random() * 9);
            const j = Math.floor(Math.random() * 9);
            if (board[i][j] !== 0) {
                board[i][j] = 0;
                removed++;
            }
        }
    }

    validateSolution(board, solution) {
        for (let i = 0; i < 9; i++) {
            for (let j = 0; j < 9; j++) {
                if (board[i][j] !== solution[i][j]) return false;
            }
        }
        return true;
    }

    findConflicts(board) {
        const conflicts = new Set();
        const rows = Array(9).fill().map(() => new Map());
        const cols = Array(9).fill().map(() => new Map());
        const boxes = Array(9).fill().map(() => new Map());

        board.forEach((row, i) => {
            row.forEach((val, j) => {
                if (!val) return;

                const box = Math.floor(i / 3) * 3 + Math.floor(j / 3);
                const idx = i * 9 + j;

                if (rows[i].has(val)) {
                    conflicts.add(idx);
                    conflicts.add(rows[i].get(val));
                }
                if (cols[j].has(val)) {
                    conflicts.add(idx);
                    conflicts.add(cols[j].get(val));
                }
                if (boxes[box].has(val)) {
                    conflicts.add(idx);
                    conflicts.add(boxes[box].get(val));
                }

                rows[i].set(val, idx);
                cols[j].set(val, idx);
                boxes[box].set(val, idx);
            });
        });

        return conflicts;
    }

    shuffle(array) {
        for (let i = array.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [array[i], array[j]] = [array[j], array[i]];
        }
    }
}

export default SudokuEngine;
