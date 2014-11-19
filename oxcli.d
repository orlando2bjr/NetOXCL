import std.stdio, std.string, std.random, std.conv, std.socket;
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
	Occupant[9] board;
	string[9] available;
	size_t positionIndex;
	Player[2] players = [Player.O, Player.X];
	int turnPlayer;
	Socket server;
	Socket client;
	char[1024] buffer;
	auto isNodeTypeUndefined = true;
	NodeType nodeType = void;
	auto address = "localhost";
	InternetAddress serverAddress;
	this()
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
				server = new Socket(AddressFamily.INET, SocketType.STREAM);
				consoleFixBegin();
					writeln("Tentando conectar em: ", serverAddress.toAddrString(), ".");
				consoleFixEnd();
				server.connect(serverAddress);
				nodeType = NodeType.Client;
				consoleFixBegin();
					writeln("Conectado em: ", serverAddress.toAddrString(), ".");
				consoleFixEnd();
				isNodeTypeUndefined = false;
			}
			catch (Exception e)
			{
				consoleFixBegin();
					writeln("Erro: %s", e.msg);
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
						//nodeType = NodeType.Server; // servidor, não tentar mais conectar
						//client = new TcpSocket;
						//assert(client.isAlive);
						//serverAddress = new InternetAddress("localhost", 2525);
						//socket.bind(serverAddress);
						//socket.listen(1);
						//consoleFixBegin();
						//    writeln("Servidor ouvindo em ", serverAddress.toAddrString(), ":",  serverAddress.toPortString());
						//consoleFixEnd();
						break;
					case 2:
						startServer(new InternetAddress(2525));
						isNodeTypeUndefined = false;
						//nodeType = NodeType.Server; // servidor, não tentar mais conectar
						//socket = new TcpSocket;
						//assert(socket.isAlive);
						//socket.bind(new InternetAddress(2525));
						//socket.listen(1);
						//consoleFixBegin();
						//    writeln("Servidor ouvindo em ", serverAddress.toAddrString(), ":",  serverAddress.toPortString());
						//consoleFixEnd();
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
				break;
			case NodeType.Client:
				break;
			default: break;
		}

		auto rng = Random(unpredictableSeed);
		turnPlayer = uniform(0, 2, rng);
		printCurrentPlayer();
	}
	void startServer(InternetAddress serverAddress)
	{
		nodeType = NodeType.Server; // servidor, não tentar mais conectar
		Socket listener = new TcpSocket;
		assert(listener.isAlive);
		serverAddress = new InternetAddress("localhost", 2525);
		listener.bind(serverAddress);
		listener.listen(1);
		consoleFixBegin();
			writeln("Servidor ouvindo em ", serverAddress.toAddrString(), ":",  serverAddress.toPortString());
		consoleFixEnd();
		client = listener.accept();
		consoleFixBegin();
			writeln("Aceitei conexão de ", client.remoteAddress().toAddrString(), ":",  serverAddress.toPortString());
		consoleFixEnd();
		listener.close();


	}
	void printCurrentPlayer()
	{
		if(players[turnPlayer] == Player.O)
			writeln("Círculos");
		else
			writeln("Machados");
	}
	//this(int firstPlayer)
	//{
	//    init();
	//    turnPlayer = firstPlayer;
	//    printCurrentPlayer();
	//}
	void writePosition(Occupant quadrant, size_t position)
	
	{
		if(quadrant == Occupant.None)
			write(position);
		else
			write(*(quadrant).ptr);
	}
	void printBoard(T)(T board[9])
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
	void updateAvailablePositions(Occupant[9] board, ref string[9] available)
	{
		for(int i = 0; i < board.length; i++)
		{
			if(board[i] == Occupant.None)
				available[i] = to!string(i);
			else
				available[i] = "-";
		}
	}
	void playerMove(ref Occupant[9] board, ref Player[2] players, ref int turnPlayer, ref string[9] available)
	{
		int move;
		updateAvailablePositions(board, available);
		do
		{
			write(players[turnPlayer], ", escolha uma posição: ");
			readf(" %s", &move);
			if(board[move - 1] != Occupant.None)
			{
				writeln(players[turnPlayer], ", esta posição já está ocupada.");
				write("Por favor, ");
			}
		} while (board[move - 1] != Occupant.None);
		board[move - 1] = players[turnPlayer];
		printBoard(board);
		turnPlayer = (turnPlayer + 1) % players.length;

	}


}