import neko.net.WebSocketServerLoop;
import sys.net.Host;

class MyDataRelatedToConnection extends WebSocketServerLoop.ClientData
{
	// your custom fields if you need data associated to each connection
}

class Main
{
	static function main()
	{
		var serverLoop = new WebSocketServerLoop<MyDataRelatedToConnection>(function(socket) return new MyDataRelatedToConnection(socket));
		
		serverLoop.processIncomingMessage = function(data:MyDataRelatedToConnection, message:String)
		{
			trace("Incoming: " + message);
			// use may use data.ws to send answer/close connection
		};
		
		serverLoop.run(new Host("localhost"), 5121);   
	}
}