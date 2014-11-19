import std.stdio, std.socket, oxcli, std.conv, std.string;

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
	auto game = new OX();

	// tentar conexão
	Socket socket;
	char[1024] buffer;
	auto isNodeTypeUndefined = true;
	auto serverAddress = new InternetAddress(2525);
	// definir modo de comunicação
	while(isNodeTypeUndefined)
	{
		try
		{
			socket = new Socket(AddressFamily.INET, SocketType.STREAM);

			socket.connect(serverAddress);
			isNodeTypeUndefined = false;
		}
		catch (Exception e)
		{
			writeln("Erro: %s", e.msg);
			writeln("Não consegui conectar em ", serverAddress.toAddrString(), ":", serverAddress.toPortString(), ", o que deseja fazer?");
			writeln("1) Iniciar como servidor na máquina.");
			writeln("2) Iniciar como servidor na rede local.");
			writeln("3) Tentar novamente em ", serverAddress.toAddrString(), ".");
			writeln("4) Alterar endereço do servidor.");
			int chosenOption;
			readf(" %d\n", &chosenOption);
			switch(chosenOption)
			{
				default:
				case 1:
					socket = new TcpSocket;
					assert(socket.isAlive);
					serverAddress = new InternetAddress("localhost", 2525);
					socket.bind(serverAddress);
					socket.listen(1);
					writeln("Servidor ouvindo em ", serverAddress.toAddrString(), ":",  serverAddress.toPortString());
					break;
				case 2:
					socket = new TcpSocket;
					assert(socket.isAlive);
					socket.bind(new InternetAddress(2525));
					socket.listen(1);
					writeln("Servidor ouvindo em ", serverAddress.toAddrString(), ":",  serverAddress.toPortString());
					break;
				case 3:
					break;
				case 4:
					auto isIPinvalid = true;
					string newAddress;
					while (isIPinvalid)
					{
						write("Digite outro endereço IP do servidor (e.g.: 123.123.222.111 ou localhost):\n>");
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
								writefln("  %s não é um endereço IP válido: %s",
										 newAddress, e.msg);
							}
						}
					}
					serverAddress = new InternetAddress(newAddress, 2525);
					break;
			}
		}
	}

	auto received = socket.receive(buffer);
	// aguarde ACK
	//writeln("O servidor disse: ", buffer[0 .. received]);
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
