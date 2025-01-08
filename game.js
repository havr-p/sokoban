class Sokoban{
    floorValue = 0;
    wallValue = 1;
    goalValue = 2;
    crateValue = 3;
    playerValue = 4;
    left = {
        row: 0,
        column: -1
    };
    right = {
        row: 0,
        column: 1
    };
    up = {
        row: -1,
        column: 0
    }
    down = {
        row: 1,
        column: 0
    }
    stringItems = " #.$@*+";
    stringMoves = "UDLR";
    buildLevelFromString(levelString){
        this.level = [];
        this.undoArray = [];
        this.moves = "";
        this.crates = [];
        let rows = levelString.split("\n");
        for(let i = 0; i < rows.length; i++){
            this.level[i] = [];
            for(var j = 0; j < rows[i].length; j++){
                let value = this.stringItems.indexOf(rows[i].charAt(j));
                this.level[i][j] = value;
                if(this.isCrateAt(i, j)){
                    this.crates.push(new SokobanItem(i, j, this));
                }
                if(this.isPlayerAt(i, j)){
                    this.player = new SokobanItem(i, j, this);
                }
            }
        }
    }
    getPlayer(){
        return this.player;
    }
    getCrates(){
        return this.crates;
    }
    getItemAt(row, column){
        return this.level[row][column];
    }
    getLevelRows(){
        return this.level.length;
    }
    getLevelColumns(){
        return this.level[0].length;
    }
    countCrates(){
        return this.crates.length;
    }
    countCratesOnGoal(){
        let goals = 0;
        this.crates.forEach(function(crate){
            if(crate.isOnGoal()){
                goals ++;
            }
        })
        return goals;
    }
    isLevelSolved(){
        return this.countCrates() == this.countCratesOnGoal();
    }
    moveLeft(){
        if(this.canMove(this.left)){
            return this.doMove(this.left);
        }
        return false;
    }
    moveRight(){
        if(this.canMove(this.right)){
            return this.doMove(this.right);
        }
        return false;
    }
    moveUp(){
        if(this.canMove(this.up)){
            return this.doMove(this.up);
        }
        return false;
    }
    moveDown(){
        if(this.canMove(this.down)){
            return this.doMove(this.down);
        }
        return false;
    }
    isWalkableAt(row, column){
        return this.getItemAt(row, column) == this.floorValue || this.getItemAt(row, column) == this.goalValue;
    }
    isCrateAt(row, column){
        return this.getItemAt(row, column) == this.crateValue || this.getItemAt(row, column) == this.crateValue + this.goalValue;
    }
    isPlayerAt(row, column){
        return this.getItemAt(row, column) == this.playerValue || this.getItemAt(row, column) == this.playerValue + this.goalValue;
    }
    isGoalAt(row, column){
        return this.getItemAt(row, column) == this.goalValue || this.getItemAt(row, column) == this.playerValue + this.goalValue || this.getItemAt(row, column) == this.crateValue + this.goalValue;
    }
    isPushableCrateAt(row, column, direction){
        let movedCrateRow = row + direction.row;
        let movedCrateColumn = column + direction.column;
        return this.isCrateAt(row, column) && this.isWalkableAt(movedCrateRow, movedCrateColumn);
    }
    canMove(direction){
        let movedPlayerRow = this.player.getRow() + direction.row;
        let movedPlayerColumn = this.player.getColumn() + direction.column;
        return this.isWalkableAt(movedPlayerRow, movedPlayerColumn) || this.isPushableCrateAt(movedPlayerRow, movedPlayerColumn, direction);
    }
    removePlayerFrom(row, column){
        this.level[row][column] -= this.playerValue;
    }
    addPlayerTo(row, column){
        this.level[row][column] += this.playerValue;
    }
    moveCrate(crate, fromRow, fromColumn, toRow, toColumn){
        crate.moveTo(toRow, toColumn);
        crate.onGoal = this.isGoalAt(toRow, toColumn);
        this.level[fromRow][fromColumn] -= this.crateValue;
        this.level[toRow][toColumn] += this.crateValue;
    }
    movePlayer(fromRow, fromColumn, toRow, toColumn){
        this.player.moveTo(toRow, toColumn);
        this.player.onGoal = this.isGoalAt(toRow, toColumn);
        this.level[fromRow][fromColumn] -= this.playerValue;
        this.level[toRow][toColumn] += this.playerValue;;
    }
    doMove(direction){
        this.undoArray.push(this.copyArray(this.level));
        let stepRow = this.player.getRow() + direction.row;
        let stepColumn = this.player.getColumn() + direction.column;
        this.crates.forEach(function(crate){
            if(crate.getRow() == stepRow && crate.getColumn() == stepColumn){
                this.moveCrate(crate, stepRow, stepColumn, stepRow + direction.row, stepColumn + direction.column);
            }
            else{
                crate.dontMove();
            }
        }.bind(this));
        this.movePlayer(this.player.getRow(), this.player.getColumn(), stepRow, stepColumn);
        this.moves += this.stringMoves.charAt(direction.row == 0 ? (direction.column == 1 ? 3 : 2) : (direction.row == 1 ? 1 : 0));
        return true;
    }
    undoMove(){
        if(this.undoArray.length > 0){
            this.undoLevel = this.undoArray.pop();
            this.level = [];
            this.level = this.copyArray(this.undoLevel);
            this.moves = this.moves.substring(0, this.moves.length - 1);
            this.player.undoMove();
            this.crates.forEach(function(crate){
                crate.undoMove();
            }.bind(this));
            return false;
        }
    }
    levelToString(){
        let string = "";
        this.level.forEach(function(row){
            row.forEach(function(item){
                string += this.stringItems.charAt(item);
            }.bind(this));
            string += "\n";
        }.bind(this));
        return string;
    }
    getMoves(){
        return this.moves;
    }
    copyArray(a){
        var newArray = a.slice(0);
        for(let i = newArray.length; i > 0; i--){
            if(newArray[i] instanceof Array){
                newArray[i] = this.copyArray(newArray[i]);
            }
        }
        return newArray;
    }
}

class SokobanItem{
    constructor(row, column, parent){
        this.parent = parent;
        this.positionHistory = [{
            row: row,
            column: column
        }];
    }
    getRow(){
        return this.positionHistory[this.positionHistory.length - 1].row;
    }
    getColumn(){
        return this.positionHistory[this.positionHistory.length - 1].column;
    }
    getPrevRow(){
        return this.positionHistory[this.positionHistory.length - 2].row;
    }
    getPrevColumn(){
        return this.positionHistory[this.positionHistory.length - 2].column;
    }
    hasMoved(){
        return (this.positionHistory.length > 1) && (this.getRow() != this.getPrevRow() || this.getColumn() != this.getPrevColumn());
    }
    setData(data){
        this.data = data;
    }
    getData(){
        return this.data;
    }
    moveTo(row, column){
        this.positionHistory.push({
            row: row,
            column: column
        })
    }
    dontMove(){
        this.positionHistory.push({
            row: this.getRow(),
            column: this.getColumn()
        })
    }
    undoMove(){
        this.positionHistory.pop();
    }
    isOnGoal(){
        return this.parent.isGoalAt(this.getRow(), this.getColumn());
    }
}
