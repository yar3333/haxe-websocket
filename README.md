# websocket #

WebSocket implementation for sys platforms. Unblocked and threaded servers for neko.

## Example

See `tests` folder. Quick code below:

```haxe
// Haxe / Neko

class MyConnection extends neko.net.WebSocketServerLoop.ClientData
{
	// your custom fields if you need data associated to each connection
}

class Main
{
	static function main()
	{
		var serverLoop = new neko.net.WebSocketServerLoop<MyConnection>(function(socket) return new MyConnection(socket));
		
		serverLoop.processIncomingMessage = function(connection:MyConnection, message:String)
		{
			trace("Incoming: " + message);
			// use connection.ws to send answer/close connection
		};
		
		serverLoop.run(new Host("localhost"), 5121);   
	}
}
```

```javascript
// JavaScript or Haxe

var ws = new WebSocket("ws://localhost:5121"); // use native js WebSocket class (js.html.WebSocket in haxe)
ws.onopen = function()
{
	console.log("CONNECT");
	ws.send("TestString");
};
ws.onmessage = function(e)
{
	console.log("RECEIVE: " + e.data);
};
ws.onclose = function()
{
	console.log("DISCONNECT");
};
```