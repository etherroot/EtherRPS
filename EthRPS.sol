contract EthRPS {

  	enum GameStatus { Started, Active, Canceled, Finished }
  	
  	enum Shapes { Nothing, Rock, Paper, Scissors }
	
  	struct Game {
		address starter;
		address joiner;
		uint bet;
		Shapes starterShape;
		Shapes joinerShape;
		GameStatus status;
		uint startTime;
		uint activeTime;
		uint finishTime;
  	}
    
	uint formShapeTimeOut = 1 seconds;
	address owner;
	uint minBet = 1 ether;
	Game [] games;
	uint count = 0;
	
	function EthRPS() {
		owner = msg.sender;
	}
	
	function start() public {
		if (msg.value <= minBet) return;
		games.length +=1;
		games[games.length -1] = Game( {starter: msg.sender,
										 joiner: 0x0,
										 bet: msg.value,
										 starterShape: Shapes.Nothing,
										 joinerShape: Shapes.Nothing,
										 status: GameStatus.Started,
										 startTime: now,
										 activeTime:0,
										 finishTime: 0
										} );
	}
	
	function cancel(uint gameId) public{
		if (gameId >= games.length) return;
		if (games[gameId].status != GameStatus.Started) return;
		if (msg.sender != games[gameId].starter) return;
		
		games[gameId].status = GameStatus.Canceled;
		games[gameId].starter.send(games[gameId].bet);
	}
	
	function join(uint gameId) public {
		if (gameId >= games.length) return;
		if (msg.value < games[gameId].bet) return;
		if (games[gameId].status != GameStatus.Started) return;
	
		games[gameId].status = GameStatus.Active;
		games[gameId].activeTime = now;
		games[gameId].joiner = msg.sender;
		games[gameId].startTime = now;
	}
	
	
	function formShape(Shapes shape, uint gameId) public {
		if (gameId >= games.length) return;
		if (games[gameId].status != GameStatus.Active) return;
		
		if ((msg.sender == games[gameId].starter) && games[gameId].starterShape == Shapes.Nothing){
			games[gameId].starterShape = shape;
			if (games[gameId].joinerShape != Shapes.Nothing) finishGame(gameId);
		}
		if ((msg.sender == games[gameId].joiner) && games[gameId].joinerShape == Shapes.Nothing){
			games[gameId].joinerShape = shape;
			if (games[gameId].starterShape != Shapes.Nothing) finishGame(gameId);
		}
	}
	
	
	function finishGame (uint gameId) private{
		int result = selectWinner(games[gameId].starterShape, games[gameId].joinerShape);
		if (result == 1) games[gameId].starter.send(games[gameId].bet * 2 * 99 / 100);
		if (result == 2) games[gameId].joiner.send(games[gameId].bet * 2 * 99 / 100);
		if (result == 0){
			games[gameId].starter.send(games[gameId].bet * 99 / 100);
			games[gameId].joiner.send(games[gameId].bet * 99 / 100);
		}
		games[gameId].status = GameStatus.Finished;
		games[gameId].finishTime = now;
		owner.send(games[gameId].bet * 2 / 100);
	}
	
	function forceFinishGameByTimeout (uint gameId) public {
		if (gameId >= games.length) return;
		if (games[gameId].status != GameStatus.Active) return;
		if (now < games[gameId].activeTime + formShapeTimeOut) return;
		
		finishGame(gameId);
	}
	
	function selectWinner(Shapes shape1, Shapes shape2) private returns (int){
		if (shape1 == Shapes.Nothing){
			if (shape2 == Shapes.Nothing) return 0;
			if (shape2 == Shapes.Rock) return 2;
			if (shape2 == Shapes.Paper) return 2;
			if (shape2 == Shapes.Scissors) return 2;
		}
		if (shape1 == Shapes.Rock){
			if (shape2 == Shapes.Nothing) return 1;
			if (shape2 == Shapes.Rock) return 0;
			if (shape2 == Shapes.Paper) return 2;
			if (shape2 == Shapes.Scissors) return 1;
		}
		if (shape1 == Shapes.Paper){
			if (shape2 == Shapes.Nothing) return 1;
			if (shape2 == Shapes.Rock) return 1;
			if (shape2 == Shapes.Paper) return 0;
			if (shape2 == Shapes.Scissors) return 2;
		}
		if (shape1 == Shapes.Scissors){
			if (shape2 == Shapes.Nothing) return 1;
			if (shape2 == Shapes.Rock) return 2;
			if (shape2 == Shapes.Paper) return 1;
			if (shape2 == Shapes.Scissors) return 0;
		}
	}		
	
	function getFinishedGames(uint gameId) public constant returns ( address starter, address joiner, uint bet, Shapes starterShape, Shapes joinerShape){
		if (gameId >= games.length) return;
		if (games[gameId].status != GameStatus.Finished) return;
		starter = games[gameId].starter;
		joiner = games[gameId].joiner;
		bet = games[gameId].bet;
		starterShape = games[gameId].starterShape;
		joinerShape = games[gameId].joinerShape;
	}
	
	function getGamesCount() public constant returns( uint count){
		count = games.length;
	}
	
 }
