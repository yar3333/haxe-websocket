package sys.net;

import sys.net.Host;
import sys.net.Socket;

class FrameCode
{
	public static inline var Continuation = 0x00;
	public static inline var Text = 0x01;
	public static inline var Binary = 0x02;
	public static inline var Close = 0x08;
	public static inline var Ping = 0x09;
	public static inline var Pong = 0x0A;
}

class CloseException { public function new() { }; public function toString() return Type.getClassName(Type.getClass(this)); }

class WebSocket
{
	var isServer : Bool;
	
	public var socket(default, null) : Socket;
	
	public function new(socket:Socket, isServer:Bool)
	{
		this.socket = socket;
		this.isServer = isServer;
	}
	
	public static function connect(host:String, port:Int, origin:String, url:String, key:String) : WebSocket
	{
		var socket = new Socket();
		socket.connect(new Host(host), port);
		
		WebSocketTools.sendClientHandShake(socket, url, host, port, key, origin);
		
		var rLine : String;
		while((rLine = socket.input.readLine()) != "")
		{
			//trace("Handshake from server: " + rLine);
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
		var data = socket.input.readByte();
		
		//trace("data = 0x" + StringTools.hex(data) + (socket.custom != null ? " (custom = " + socket.custom + ")" : ""));
		
		var opcode = data & 0xF;
		var rsv = (data >> 1) & 0x07;
		var fin = (data >> 7) != 0;
		//trace("opcode = 0x" + StringTools.hex(opcode) + "; fin = " + fin);
		
		if (fin)
		{
			switch (opcode)
			{
				case FrameCode.Text:
					return readString();
					
				case FrameCode.Close:
					throw new CloseException();
			}
		}
		else
		{
			if (opcode == FrameCode.Continuation)
			{
				var s = "";
				var b : Int;
				while ((b = socket.input.readByte()) != 0xFF)
				{
					s += String.fromCharCode(b);
				}
				return s;
			}
		}
		
		throw "Unsupported websocket opcode/fin: 0x" + StringTools.hex(opcode) + "/" + fin;
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
	
	function readString() : String
	{
		var data = socket.input.readByte();
		
		if (!isServer)
		{
			if (data & 0x80 == 0) // !mask
			{
				var len = data & 0x7F;
				
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
			if (data & 0x80 != 0) // mask
			{
				var len = data & 0x7F;
				
				if (len == 126)
				{
					var b2 = socket.input.readByte();
					var b3 = socket.input.readByte();
					len = (b2 << 8) + b3;
				}
				else
				if (len == 127)
				{
					var b2 = socket.input.readByte();
					var b3 = socket.input.readByte();
					var b4 = socket.input.readByte();
					var b5 = socket.input.readByte();
					len = (b2 << 24) + (b3 << 16) + (b4 << 8) + b5;
				}
				
				//Sys.println("len = " + len);
				
				// direct array init not work corectly!
				var mask = [];
				mask.push(socket.input.readByte());
				mask.push(socket.input.readByte());
				mask.push(socket.input.readByte());
				mask.push(socket.input.readByte());
				
				//Sys.println("mask = " + mask);
				
				var r = new StringBuf();
				for (i in 0...len)
				{
					r.addChar(socket.input.readByte() ^ mask[i % 4]);
				}
				
				//Sys.println("readed = " + r.toString());
				return r.toString();
			}
			else
			{
				throw "Expected masked data.";
			}
		}
	}
}