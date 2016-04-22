import neko.net.WebSocketServerLoop;
import sys.net.Host;

class MyConnection extends WebSocketServerLoop.ClientData
{
	// your custom fields if you need data associated to each connection
}

class Main
{
	static function main()
	{
		var serverLoop = new WebSocketServerLoop<MyConnection>(function(socket) return new MyConnection(socket));
		
		serverLoop.processIncomingMessage = function(connection:MyConnection, message:String)
		{
			trace("Incoming: " + message);
			// use "connection.ws" to send answer
			// use "serverLoop.closeConnection(connection.ws.socket)" to close connection and remove socket from processing
		};
		
		serverLoop.run(new Host("localhost"), 5121);   
	}
}