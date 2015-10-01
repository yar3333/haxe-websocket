# websocket #

WebSocket implementation for neko server.

## Example of the server code (server/neko)

```haxe
class MyDataRelatedToConnection extends WebSocketServerLoop.ClientData
{
	// your custom fields if you need data associated to each connection
}
```

```haxe
class Main
{
	static function main()
	{
		var serverLoop = new WebSocketServerLoop<MyDataRelatedToConnection>(HERE_YOU_CAN_OPTIONALLY_SPECIFY_HANDLER_CALLED_ON_NEW_CONNECTION_FROM_CLIENT_TO_CREATE_YOUR_CUSTOM_MyDataRelatedToConnection);

		serverLoop.processIncomingMessage = function(data:MyDataRelatedToConnection, message:String)
		{
			trace(message);
			// use may use data.ws to send answer/close connection
		};

		serverLoop.run("YOUR_HOSTNAME_TO_BIND", YOUR_PORT_NUMBER_TO_BIND);   
	}
}
```

## Example of the client code (browser/js)

```haxe
var ws = new js.WebSocket("ws://YOUR_HOSTNAME:PORT"); // use native js WebSocket!
ws.send("TestString");
```