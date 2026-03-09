// UI Controller
class SudokuUI {
    constructor(gridElement, infoElements) {
        this.grid = gridElement;
        this.timer = infoElements.timer;
        this.mistakes = infoElements.mistakes;
        this.progress = infoElements.progress;
        this.difficulty = infoElements.difficulty;
        this.timerInterval = null;
        this.validationTimeout = null;
        this.selectedCell = null;
        this.inputs = [];
    }

    renderGrid(board, solution, onInput, onSelect) {
        this.grid.innerHTML = '';
        this.inputs = [];

        board.forEach((row, i) => {
            row.forEach((val, j) => {
                const input = this.createCell(i, j, val, solution[i][j] !== 0);
                input.onclick = () => {
                    this.selectCell(input);
                    onSelect?.(i, j);
                };
                input.onkeydown = (e) => this.handleKeyboard(e, input);
                input.oninput = (e) => this.handleInput(e, input, onInput);
                this.grid.appendChild(input);
                this.inputs.push(input);
            });
        });
    }

    createCell(row, col, value, isLocked) {
        const input = document.createElement('input');
        input.type = 'text';
        input.maxLength = 1;
        input.value = value || '';
        input.dataset.row = row;
        input.dataset.col = col;
        if (isLocked) input.readOnly = true;
        return input;
    }

    handleInput(e, input, callback) {
        e.target.value = e.target.value.replace(/[^1-9]/g, '');
        
        if (e.target.value) {
            e.target.classList.add('valid');
            setTimeout(() => e.target.classList.remove('valid'), 300);
        }

        clearTimeout(this.validationTimeout);
        this.validationTimeout = setTimeout(() => {
            const row = parseInt(input.dataset.row);
            const col = parseInt(input.dataset.col);
            callback?.(row, col, e.target.value);
        }, 150);
    }

    handleKeyboard(e, input) {
        if (input.readOnly) return;
        
        const row = parseInt(input.dataset.row);
        const col = parseInt(input.dataset.col);
        let newIdx;

        if (e.key === 'ArrowUp' && row > 0) newIdx = (row - 1) * 9 + col;
        else if (e.key === 'ArrowDown' && row < 8) newIdx = (row + 1) * 9 + col;
        else if (e.key === 'ArrowLeft' && col > 0) newIdx = row * 9 + (col - 1);
        else if (e.key === 'ArrowRight' && col < 8) newIdx = row * 9 + (col + 1);
        else if (e.key >= '1' && e.key <= '9') {
            input.value = e.key;
            input.dispatchEvent(new Event('input'));
            e.preventDefault();
        } else if (e.key === 'Backspace' || e.key === 'Delete') {
            input.value = '';
            input.dispatchEvent(new Event('input'));
        }

        if (newIdx !== undefined) {
            e.preventDefault();
            this.inputs[newIdx].focus();
            this.selectCell(this.inputs[newIdx]);
        }
    }

    selectCell(cell) {
        if (this.selectedCell) this.selectedCell.classList.remove('selected');
        this.selectedCell = cell;
        cell.classList.add('selected');
    }

    highlightConflicts(conflicts) {
        this.inputs.forEach((input, idx) => {
            if (conflicts.has(idx)) {
                input.classList.add('conflict');
            } else {
                input.classList.remove('conflict');
            }
        });
    }

    updateInfo(state) {
        this.mistakes.textContent = state.mistakes;
        this.difficulty.textContent = state.difficulty.charAt(0).toUpperCase() + state.difficulty.slice(1);
        this.progress.textContent = state.getProgress() + '%';
    }

    startTimer(startTime) {
        clearInterval(this.timerInterval);
        this.timerInterval = setInterval(() => {
            const elapsed = Math.floor((Date.now() - startTime) / 1000);
            const mins = Math.floor(elapsed / 60).toString().padStart(2, '0');
            const secs = (elapsed % 60).toString().padStart(2, '0');
            this.timer.textContent = `${mins}:${secs}`;
        }, 1000);
    }

    stopTimer() {
        clearInterval(this.timerInterval);
    }

    showMessage(message, isSuccess = true) {
        alert(message);
    }

    getBoardFromInputs() {
        const board = Array(9).fill().map(() => Array(9).fill(0));
        this.inputs.forEach((input, idx) => {
            const row = Math.floor(idx / 9);
            const col = idx % 9;
            board[row][col] = parseInt(input.value) || 0;
        });
        return board;
    }
}

export default SudokuUI;
