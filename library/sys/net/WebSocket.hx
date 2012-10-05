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
	var isServer : Bool;
	
	public var socket(default, null) : Socket;
	
	public function new(socket:Socket, isServer:Bool)
	{
		this.socket = socket;
		this.isServer = isServer;
	}
	
	public static function connect(host:String, port:Int, origin:String, url:String) : WebSocket
	{
		var socket = new Socket();
		socket.connect(new Host(host), port);
		
		WebSocketTools.sendClientHandShake(socket, url, host, port, "key", "haquery");
		
		var rLine : String;
		while((rLine = socket.input.readLine()) != "")
		{
			trace("Handshake from server: " + rLine);
		}
		
		return new WebSocket(socket, false);
	}
	
	public function send(data:String) : Void
	{
		socket.output.writeByte(0x81);
		
		var len = 0;
		if       (data.length < 126) 	len = data.length;
		else  if (data.length < 65536)	len = 126;
		else 							len = 127;
		
		socket.output.writeByte(len | (!isServer ? 0x80 : 0x00));

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
				socket.output.writeByte((data.length >> 16) & 0xFF);
				socket.output.writeByte((data.length >> 8) & 0xFF);
				socket.output.writeByte(data.length & 0xFF);
			}
		}
		
		if (isServer)
		{
			socket.output.writeString(data);
		}
		else
		{
			var mask = [ Std.random(256), Std.random(256), Std.random(256), Std.random(256) ];
			socket.output.writeByte(mask[0]);
			socket.output.writeByte(mask[1]);
			socket.output.writeByte(mask[2]);
			socket.output.writeByte(mask[3]);
			var maskedData = new StringBuf();
			for (i in 0...data.length)
			{
				maskedData.addChar(data.charCodeAt(i) ^ mask[i % 4]);
			}
			socket.output.writeString(maskedData.toString());
		}
		
	}
	
	public function recv() : String
	{
		var opcode = socket.input.readByte();
		if (opcode == 0x81) // 0x81 = fin & text
		{
			var len = socket.input.readByte();
			if (len & 0x80 == 0) // !mask
			{
				if (len == 126)
				{
					var lenByte0 = socket.input.readByte();
					var lenByte1 = socket.input.readByte();
					len = (lenByte0 << 8) + lenByte1;
				}
				else
				if (len > 126)
				{
					var lenByte0 = socket.input.readByte();
					var lenByte1 = socket.input.readByte();
					var lenByte2 = socket.input.readByte();
					var lenByte3 = socket.input.readByte();
					len = (lenByte0 << 24) + (lenByte1 << 16) + (lenByte2 << 8) + lenByte3;
				}
				return socket.input.read(len).toString();
			}
			else
			{
				throw "Expected unmasked data.";
			}
		}
		else
		{
			throw "Unsupported websocket opcode: " + opcode;
		}
		return null;
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