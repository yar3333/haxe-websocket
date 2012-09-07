package sys.net;

#if php
import php.Lib;
#elseif neko
import neko.Lib;
#end

import sys.net.Socket;
import sys.net.Host;

class WebSocketCloseCode 
{
	public static inline var Normal = 1000;
	public static inline var Shutdown = 1001;
	public static inline var ProtocolError = 1002;
	public static inline var DataError = 1003;
	public static inline var Reserved1 = 1004;
	public static inline var NoStatus = 1005;
	public static inline var CloseError = 1006;
	public static inline var UTF8Error = 1007;
	public static inline var PolicyError = 1008;
	public static inline var TooLargeMessage = 1009;
	public static inline var ClientExtensionError = 1010;
	public static inline var ServerRequestError = 1011;
	public static inline var TLSError = 1015;
}

class WebSocketFrame 
{
	public static inline var Continuation = 0x00;
	public static inline var Text = 0x01;
	public static inline var Binary = 0x02;
	public static inline var Close = 0x08;
	public static inline var Ping = 0x09;
	public static inline var Pong = 0x0A;
}

class WebSocket
{
	public var socket : Socket;
	
	public function new(socket:Socket)
	{
		this.socket = socket;
	}
	
	public static function connect(host:String, port:Int, origin:String, url:String) : WebSocket
	{
		var socket = new Socket();
		socket.connect(new Host(host), port);
		
		var ts = "GET " + url + " HTTP/1.1\r\n"
			   + "Upgrade: WebSocket\r\n"
			   + "Connection: Upgrade\r\n"
			   + "Host: " + host + ":" + Std.string(port) + "\r\n"
			   + "Origin: " + origin + "\r\n"
			   + "\r\n";
		socket.output.writeString(ts);
		
		var rLine : String;
		while((rLine = socket.input.readLine()) != "")
		{
			//trace("Server Handshake :" + rLine);
		}
		
		return new WebSocket(socket);
	}
	
	public function send(data:String) : Void
	{
		var len = 0;
		if       (data.length < 126) 	len = data.length;
		else  if (data.length < 65536)	len = 126;
		else 							len = 127;
		
		socket.output.writeByte(len);

		if (data.length >= 126)
		{
			if (data.length < 65536)
			{
				socket.output.writeByte((data.length >> 8) & 0xFF);
				socket.output.writeByte(data.length & 0xFF);
			}
			else
			{
				socket.output.writeByte((data.length >> 24) & 0xFF);
				socket.output.writeByte((data.length >> 16)& 0xFF);
				socket.output.writeByte((data.length >> 8) & 0xFF);
				socket.output.writeByte(data.length & 0xFF);
			}
		}
		
		socket.output.writeString(String.fromCharCode(0x81) + String.fromCharCode(data.length) + data);
	}
	
	/*public function close(aCloseCode:Int, aCloseReason:String):Void
    {
        var ms:MemoryStream = new MemoryStream();
		
		var bytesA = new ByteArray();
		bytesA[0] = Std.int((aCloseCode / 256));
		bytesA[1] = Std.int((aCloseCode % 256));
		ms.Write(bytesA, 0, 2);
		
		var bytesB = Encoding.UTF8.GetBytes(aCloseReason);
		while (bytesB.length > 123)
		{
			aCloseReason = aCloseReason.substr(0, aCloseReason.length - 1);
			bytesB = Encoding.UTF8.GetBytes(aCloseReason);
		}
		ms.Write(bytesB, 0, bytesB.length);
		send(true, false, false, false, WebSocketFrame.Close, ms);
		
		socket.close();
    }*/
}