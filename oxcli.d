/*
Trabalho de Redes Grau B
Orlando Borges Botelho - Interface e Integração bate-papo/jogo
Thales Kautzmann Padilla - Lógica e Envio de Comandos
*/
module oxcli;
import std.process, std.stdio, std.string, std.random, std.conv, std.socket;
// http://ddili.org/ders/d.en/logical_expressions.html
version(Windows)
{
	// biblioteca do console Windows
	extern(Windows) int SetConsoleOutputCP(uint);
	extern(Windows) int GetConsoleOutputCP();
	int consoleCPUTF8 = 65001;
	int consoleCP;
}


//int main(string[] argv)
//{
//    version(Windows)
//    {
//        // definir saída como UTF8
//        if(SetConsoleOutputCP(65001) == 0)
//            throw new Exception("failure");
//    }
//    writeln("Bem vindo ao Jogo da Velha em rede!");
//
//    Occupant[9] board;
//    string[9] available;
//    size_t positionIndex;
//    foreach(position; available)
//    {
//        position = new string(positionIndex);
//        positionIndex++;
//    }
//
//    printBoard(board);
//
//    // definir turno
//    Player[2] players = [Player.O, Player.X];
//    auto rng = Random(unpredictableSeed);
//    auto turnPlayer = uniform(0, 2, rng);
//    writeln(turnPlayer);
//    if(players[turnPlayer] == Player.O)
//        writeln("Círculos");
//    else
//        writeln("Machados");
//
//
//
//    // receber jogada
//    for(int i = 0; i < 9; i++)
//    {
//        playerMove(board, players, turnPlayer, available);
//    }
//
//    return 0;
//}

class OX
{
	// jeitinho para o console do Windows funcionar com acentos
	version(Windows)
	{
		int consoleCP;
		void consoleFixBegin() // para consertar acentos do código fonte
		{
			// definir saí­da como código de página UTF8
			if(SetConsoleOutputCP(65001) == 0)
				throw new Exception("falha na definição do código de página do console como UTF8");
		}
		void consoleFixEnd() // para aceitar acentos da entrada do usuário
		{
			// definir saí­da como código de página padrão
			if(SetConsoleOutputCP(consoleCP) == 0)
				throw new Exception("falha na definição do código de página do console como padrão inicial");
		}
	}
	enum Occupant: string
	{
		None = " ",
		O = "O",
		X = "X"
	}
	enum Player: Occupant
	{
		O = Occupant.O,
		X = Occupant.X
	}
	enum NodeType
	{
		Server,
		Client
	}
	auto isPlaying = true;
	auto areThereChanges = false;
	Occupant[9] board;
	string[9] available;
	size_t positionIndex;
	string sendMessage;
	string receivedMessage;
	string message;
	size_t playerMove;
	Player[2] players = [Player.O, Player.X];
	Player turnPlayer;
	Player thisPlayer;
	Player winner;
	auto hasPlayerMoved = false;
	auto hasPlayerWon = false;
	Socket socket;
	char[1024] buffer;
	auto isNodeTypeUndefined = true;
	NodeType nodeType = void;
	auto address = "localhost";
	InternetAddress serverAddress;
	this() // configura o jogo
	{
		serverAddress = new InternetAddress("localhost", 2525);
		// guardar valor inicial do código de página do console
		version(Windows)
		{
			consoleCP = GetConsoleOutputCP();
		}
		// marcar número das posições no tabuleiro
		foreach(position; available)
		{
			position = new string(positionIndex);
			positionIndex++;
		}
		// definir modo de conexão
		while(isNodeTypeUndefined)
		{
			// tentar conexão local
			try
			{
				socket = new Socket(AddressFamily.INET, SocketType.STREAM);
				consoleFixBegin();
					writeln("Tentando conectar em: ", serverAddress.toAddrString(), ".");
				consoleFixEnd();
				socket.connect(serverAddress);
				// receber qual é o jogador do servidor
				auto got = socket.receive(buffer);
				// definir jogador oposto
				if(buffer[0] == 'O')
				{
					thisPlayer = Player.X;
					turnPlayer = Player.O;
				}
				else
				{
					thisPlayer = Player.O;
					turnPlayer = Player.X;
				}
				nodeType = NodeType.Client;
				consoleFixBegin();
					writeln("Conectado em: ", serverAddress.toAddrString(), ".");
				consoleFixEnd();
				isNodeTypeUndefined = false;
			}
			catch (Exception e)
			{
				consoleFixBegin();
					writefln("Erro: %s\n", e.msg);
					writeln("Não consegui conectar em ", serverAddress.toAddrString(), ":", serverAddress.toPortString(), ", o que deseja fazer?");
					writeln("1) Iniciar como servidor na máquina.");
					writeln("2) Iniciar como servidor na rede local.");
					writeln("3) Tentar novamente em ", serverAddress.toAddrString(), ".");
					writeln("4) Alterar endereço do servidor.");
				consoleFixEnd();
				int chosenOption;
				readf(" %d\n", &chosenOption);
				switch(chosenOption)
				{
					default: break;
					case 1:
						startServer(new InternetAddress("localhost", 2525));
						isNodeTypeUndefined = false;
						break;
					case 2:
						startServer(new InternetAddress(2525));
						isNodeTypeUndefined = false;
						break;
					case 3:
						nodeType = NodeType.Client;
						break;
					case 4:
						nodeType = NodeType.Client;
						auto isIPinvalid = true;
						string newAddress;
						while (isIPinvalid)
						{
							consoleFixBegin();
								write("Digite outro endereço IP do servidor (e.g.: 123.123.222.111 ou localhost):\n>");
							consoleFixEnd();
							newAddress = readln().chomp();
							if(newAddress == "localhost")
								isIPinvalid = false;
							else
							{
								try
								{
									Address address = parseAddress(newAddress);
									isIPinvalid = false;
								}
								catch (SocketException e)
								{
									consoleFixBegin();
										writefln("  %s não é um endereço IP válido: %s",
											 newAddress, e.msg);
									consoleFixEnd();
								}
							}
						}
						serverAddress = new InternetAddress(newAddress, 2525);
						break;
				}
			}
		}
		switch(nodeType)
		{
			case NodeType.Server:
				auto rng = Random(unpredictableSeed);
				auto player = uniform(0, 2, rng);
				if(players[player] == Player.O)
				{
					turnPlayer = Player.O;
					thisPlayer = turnPlayer;
				}
				else
				{
					thisPlayer = Player.X;
					thisPlayer = turnPlayer;
				}
				break;
			case NodeType.Client:
				break;
			default: break;
		}
		render();
	}
	~this() // encerra o jogo e fecha conexões
	{
		socket.close();
	}
	void restart()
	{
		for(int i = 0; i < 9; i++)
		{
			board[i] = Occupant.None;
			available[i] = new string(i);
		}
		//foreach(occupant; board)
		//{
		//    *(occupant).ptr = Occupant.None;
		//}
		//available = new string[9];
		//foreach(position; available)
		//{
		//    position = new string(positionIndex);
		//    positionIndex++;
		//}
		areThereChanges = true;
		render();
		start();
	}
	void start()
	{
		socket.blocking = false;
		isPlaying = true;
		hasPlayerWon = false;
		while(isPlaying)
		{
			if(areThereChanges)
			{
				render();
				areThereChanges = false;
			}
			input();
			update();
		}
	}
	void render()
	{
		version(Windows) {
			system("cls");
		} else {
			system("clear");
		}
		printBoard();
		consoleFixBegin();
			write("Você é ");
			printPlayer(thisPlayer);
			write("O turno é de ");
			printPlayer(turnPlayer);
			writeln("Comandos (apenas no seu turno):");
			writeln("\tTexto + Enter: Envia mensagem.");
			writeln("\t# + Númer de 1 à 9: posição.");
		consoleFixEnd();

		writeln(message);
		if(hasPlayerWon)
		{
			consoleFixBegin();
				write("\n\n\n\tPARABÉNS, ");
				printPlayer(winner);
				writeln(" venceu a partida!!!");
				if(winner == thisPlayer)
				{
					writeln("Será que seu oponente quer uma revanche!?");
					consoleFixEnd();
				}
				else
				{
					consoleFixEnd();
					string answer;
					do
					{
						consoleFixBegin();
							writeln("E aí? Vai uma revanche? (s = sim, n = não");
						consoleFixEnd();
						answer = readln().chomp();
					} while (answer != "s" && answer != "n");
					if(answer == "s")
						restart();
					else
						isPlaying = false;
				}

		}
	}
	void input()
	{
		// ler e imprimir
		if(turnPlayer != thisPlayer) // esperando o outro
		{
			auto got = socket.receive(buffer);
			if(got > 0)
			{
				receivedMessage = to!(string)(buffer[0 .. got]);
				//// posição
				//if(buffer[0] == '#' && got == 2)
				//{
				//    receivedMessage = to!(string)(buffer[0 .. got]);
				//}
				//else
				//{
				//}
			}
		}
		else // meu turno
		{
			foreach(line; stdin.byLine)
				{
					sendMessage = to!(string)(line);
					//if(line[0] == '#' && line.length == 2)
					//{
					//    playerMove = line[1];
					//    hasPlayerMoved = true;
					//    nextPlayer();
					//}
					//socket.send(line);
					break;
				}
		}
	}
	Player otherPlayer()
	{
		if(thisPlayer == Player.O)
			return Player.X;
		else
			return Player.O;
	}
	Player occupantToPlayer(Occupant occupant)
	{
		if(occupant == Occupant.O)
			return Player.O;
		else
			return Player.X;
	}
	void update()
	{
		playerMove = 0;
		if(sendMessage.length > 0 || receivedMessage.length > 0)
			areThereChanges = true;
		if(turnPlayer == thisPlayer)
		{
			// foi uma jogada
			if(sendMessage[0] == '#' && sendMessage.length == 2)
			{
				string test = to!(string)(sendMessage[1]);
				playerMove = parse!(size_t)(test);
				// validar jogada
				if(playerMoves(playerMove))
				{
					socket.send(sendMessage);
					nextPlayer();
				}
				else
				{
					writeln(turnPlayer, ", esta posição já está ocupada.");
				}
			}
			else
			{
				message = "Eu disse: " ~ sendMessage;
				socket.send(sendMessage);
			}
		}
		else
		{
			if(receivedMessage.length > 0)
			{
				if(receivedMessage[0] == '#' && receivedMessage.length == 2)
				{
					string test = to!(string)(receivedMessage[1]);
					playerMove = parse!(size_t)(test);
					board[playerMove - 1] = otherPlayer();

					nextPlayer();
				}
				else
					message = "Oponente disse: " ~ receivedMessage;
			}
		}
		sendMessage = receivedMessage = "";
		hasPlayerWon = checkForVictory();
	}
	bool checkForVictory()
	{
		// centro primeiro
		if(board[4] != Occupant.None)
		{
			for(int i = 0; i < 4; i++)
			{
				int offset = 4 - i;
				if((board[4] == board[4 - offset]) &&
				   (board[4] == board[4 + offset]))
				{
					hasPlayerWon = true;
					winner = occupantToPlayer(board[4]);
					return true;
				}

			}
		}
		// perímetro
		int[4] perimeter = [1, 3, 5, 7];
		foreach(index; perimeter)
		{
			if(board[index] != Occupant.None)
			{
				// horizontais
				if((index % 3) == 1)
				{
					if((board[index] == board[index - 1]) &&
						(board[index] == board[index + 1]))
					{
						hasPlayerWon = true;
						winner = occupantToPlayer(board[index]);
						return true;
					}
				}
				// verticais
				else 
				{
					if((board[index] == board[index - 3]) &&
						(board[index] == board[index + 3]))
					{
						hasPlayerWon = true;
						winner = occupantToPlayer(board[index]);
						return true;
					}
				}
			}
		}
		return false;
	}
	void startServer(InternetAddress serverAddress)
	{
		nodeType = NodeType.Server; // servidor, não tentar mais conectar
		Socket listener = new TcpSocket;
		assert(listener.isAlive);
		//serverAddress = new InternetAddress("localhost", 2525);
		listener.bind(serverAddress);
		listener.listen(1);
		consoleFixBegin();
			writeln("Servidor ouvindo em ", serverAddress.toAddrString(), ":",  serverAddress.toPortString());
		consoleFixEnd();
		socket = listener.accept();
		consoleFixBegin();
			writeln("Aceitei conexão de ", socket.remoteAddress().toAddrString(), ":",  serverAddress.toPortString());
		consoleFixEnd();
		listener.close();
		socket.send(to!(char[])(thisPlayer));


	}
	void printPlayer(Player player)
	{
		if(player == Player.O)
			writeln("Círculos");
		else
			writeln("Machados");
	}
	void writePosition(Occupant quadrant, size_t position)
	{
		if(quadrant == Occupant.None)
			write(position);
		else
			write(*(quadrant).ptr);
	}
	void printBoard()
	{
		// imprimir tabuleiro
		size_t lineCounter;
		size_t positionCounter;
		foreach(quadrant; board)
		{
			positionCounter++;
			lineCounter++;
			if(lineCounter < 3)
			{
				writePosition(quadrant, positionCounter);
				write("|");
			}
			else
			{
				writePosition(quadrant, positionCounter);
				write("\n");
				lineCounter = 0;
			}
		}

	}
	bool playerMoves(size_t toPosition)
	{
		if(board[toPosition - 1] != Occupant.None)
			return false;
		else
		{
			board[toPosition - 1] = thisPlayer;
			return true;
		}
	}
	void nextPlayer()
	{
		if(turnPlayer == Player.O)
			turnPlayer = Player.X;
		else
			turnPlayer = Player.O;
	}
}