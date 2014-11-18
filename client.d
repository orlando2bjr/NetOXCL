import std.stdio, std.socket, oxcli, std.conv;

version(Windows)
{
	// biblioteca do console Windows
	extern(Windows) int SetConsoleOutputCP(uint);
}

int main(string[] argv)
{
	version(Windows)
	{
		// definir saída como UTF8
		//if(SetConsoleOutputCP(65001) == 0)
		//    throw new Exception("falha");
	}
	auto socket = new Socket(AddressFamily.INET, SocketType.STREAM);
	char[1024] buffer;
	socket.connect(new InternetAddress("localhost", 2525));
	// ox test

	auto received = socket.receive(buffer);
	// aguarde ACK
	//writeln("O servidor disse: ", buffer[0 .. received]);
	auto game = new OX(to!int(buffer[0 .. received]));
	auto isRunning = true;
	socket.blocking = false;
	while(isRunning)
	{
		auto got = socket.receive(buffer);
		if(got > 0)
			writeln(buffer[0 .. got]);
		else
		{
			foreach(line; stdin.byLine)
			{
				socket.send(line);
				//writeln(buffer[0 .. got]);
			}
		}
	}
    return 0;
}
