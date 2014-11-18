import std.stdio;
import std.string;
import std.random;
import std.conv;
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
class OX
{
	Occupant[9] board;
	string[9] available;
	size_t positionIndex;
	Player[2] players = [Player.O, Player.X];
	int turnPlayer;

	// jeitinho para o console do Windows funcionar com acentos
	version(Windows)
	{
		void setConsoleCPUTF8()
		{
			// definir saí­da como código de página UTF8
			if(SetConsoleOutputCP(65001) == 0)
				throw new Exception("falha na definição do código de página do console como UTF8");
		}
		void resetConsoleCP()
		{
			// definir saí­da como código de página padrão
			if(SetConsoleOutputCP(consoleCP) == 0)
				throw new Exception("falha na definição do código de página do console como padrão inicial");
		}
	}

	void init()
	{
		// guardar valor inicial do código de página do console
		version(Windows)
		{
			int consoleCP = GetConsoleOutputCP();
		}

		foreach(position; available)
		{
			position = new string(positionIndex);
			positionIndex++;
		}
	}
	void printCurrentPlayer()
	{
		if(players[turnPlayer] == Player.O)
			writeln("Círculos");
		else
			writeln("Machados");
	}
	this()
	{
		init();
		auto rng = Random(unpredictableSeed);
		turnPlayer = uniform(0, 2, rng);
		printCurrentPlayer();
	}
	this(int firstPlayer)
	{
		init();
		turnPlayer = firstPlayer;
		printCurrentPlayer();
	}
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