package neko.net;

import neko.Lib;
import neko.vm.Thread;
import sys.net.Socket;
import sys.net.Host;
import sys.net.WebSocket;
import sys.net.WebSocketTools;

class WebSocketThreadServer
{
	var host : String;
	var port : Int;
	
	var stopRequested = false;
	
	public var listen = 128;
	public var flashSocketPolicy = true;
	public var threadCount(default, null) : Int;
	
	public function new() {}
	
	public function run(host:String, port:Int)
	{
		this.host = host;
		this.port = port;
		
		threadCount = 0;
		
		var listener = new Socket();
		listener.bind(new Host(host), port);
		listener.listen(listen);
		
		while (true)
		{
			Lib.println("begin accept...");
			var socket = listener.accept();
			
			if (stopRequested) break;
			
			Lib.println("accepted");
			Thread.create(function()
			{
				threadCount++;
				
				try
				{
					Lib.println("call shakeHands...");
					
					if (shakeHands(socket, flashSocketPolicy))
					{
						Lib.println("shakeHands ended OK");
						processIncomingConnection(new WebSocket(socket, true)); 
					}
					else
					{
						Lib.println("shakeHands ended FAIL");
					}
					try { socket.close(); } catch (e:Dynamic) {}
				}
				catch (e:Dynamic)
				{
					onError(e, haxe.Stack.exceptionStack());
				}
				
				threadCount--;
			});
		}
		
		listener.close();
	}
	
	static function shakeHands(socket:Socket, flashSocketPolicy:Bool) : Bool
	{
		var rLine = "";
		
		if (!flashSocketPolicy)
		{
			try
			{
				rLine = socket.input.readLine(); // This is for the GET / HTTP/1.1 Line
				//Lib.println("shake receive: " + rLine);
			}
			catch (e:Dynamic)
			{
				return false;
			}
		}
		else // We got to use something more advanced to read until 0x00 or CRLF
		{
			var ms = "";
			while (true)
			{
				ms += String.fromCharCode(socket.input.readByte());
				if (ms.indexOf(String.fromCharCode(0x00)) > -1)
				{
					socket.output.writeString('<cross-domain-policy><allow-access-from domain="*" to-ports="*" /></cross-domain-policy>' + String.fromCharCode(0x00));
					//Lib.println("shake send: POLICY");
					socket.close();
					return false;
				} 
				else if (ms.indexOf("\r\n") >= 0)
				{
					rLine = ms;
					//Lib.println("shake receive: " + rLine);
					break;
				}
			}
		}
		
		var clientHeaders = new Hash<String>();
		do
		{
			try
			{
				rLine = socket.input.readLine();
				//Lib.println("shake receive: " + rLine);
				var t = rLine.split(":");
				if (t.length == 2)
				{
					clientHeaders.set(StringTools.trim(t[0]), StringTools.trim(t[1]));
				}
			}
			catch (e:Dynamic)
			{
				break;
			}
		} while (rLine != "");
		
		WebSocketTools.sendServerHandShake(socket, clientHeaders.get("Sec-WebSocket-Key"));
		
		return true;
	}
	
	public function stop()
	{
		stopRequested = true;
		var s = new Socket();
		s.connect(new Host(host), port);
		try s.close() catch (e:Dynamic) {}
	}
	
	// --- CUSTOMIZABLE API ---
	
	public dynamic function onError(e:Dynamic, stack) : Void
	{
		var estr = try Std.string(e) catch (e2:Dynamic) "???" + try "[" + Std.string(e2) + "]" catch ( e : Dynamic ) "";
		Lib.print(estr + "\n" + haxe.Stack.toString(stack));
	}
	
	public dynamic function processIncomingConnection(ws:WebSocket) : Void
	{
	}
}