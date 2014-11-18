import oxcli;
import std.stdio;
import std.socket;
import std.utf;
import std.conv;
version(Windows)
{
	// biblioteca do console Windows
	extern(Windows) int SetConsoleOutputCP(uint);
	extern(Windows) int GetConsoleOutputCP();
	int consoleCPUTF8 = 65001;
	int consoleCP;
}

int main(string[] argv)
{
	version(Windows)
	{
		int consoleCP = GetConsoleOutputCP();
		// definir saí­da como UTF8
		if(SetConsoleOutputCP(65001) == 0)
			throw new Exception("falha na definiçãodo código de página do console");
	}
    Socket listener = new TcpSocket;
	assert(listener.isAlive);

	listener.bind(new InternetAddress("localhost", 2525));
	listener.listen(1);
	// ox test
	auto game = new OX;

	writeln("Ouvindo na porta: 2525");
	auto client = listener.accept();
	writefln("Conexão de %s estabelecida.", client.remoteAddress().toString());
	auto sent = client.send(to!(char[])(game.turnPlayer));

	version(Windows)
	{
		if(SetConsoleOutputCP(consoleCP) == 0)
			throw new Exception("falha na definiçãodo código de página do console");
	}

	auto isRunning = true;
	char[1024] buffer;
	while (isRunning)
	{
		// ler e imprimir
		auto got = client.receive(buffer);
		if(got > 0)
		{
			// posição
			if(buffer[0] == '#' && got == 2)
			{
				writefln("recebi posição %s", buffer[1]);
				int pos = buffer[1];
			}
			else
				writeln(buffer[0 .. got]);
		}
		else
		{
			//		client.send(buffer[0 .. got]);
			foreach(line; stdin.byLine)
			{
				client.send(line);
				writeln(buffer[0 .. client.receive(buffer)]);
			}
		}
	}
    return 0;
}