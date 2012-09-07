package neko.net;

import neko.Lib;
import neko.vm.Thread;

import sys.net.Socket;
import sys.net.Host;
import sys.net.WebSocket;
import sys.net.WebSocketServerTools;

class WebSocketThreadServer
{
	public var processIncomingConnection : WebSocket->Void;
	
	public function new() {}
	
	public function run(host:String, port:Int, connections:Int, ?flashSocketPolicy:Bool)
	{
		var listener = new Socket();
		listener.bind(new Host(host), port);
		listener.listen(connections);
		
		while (true)
		{
			Lib.println("begin accept...");
			var socket = listener.accept();
			Lib.println("accepted");
			Thread.create(function()
			{
				Lib.println("call shakeHands...");
				if (shakeHands(socket, flashSocketPolicy))
				{
					Lib.println("shakeHands ended OK");
					if (processIncomingConnection != null)
					{
						processIncomingConnection(new WebSocket(socket)); 
					}
				}
				else
				{
					Lib.println("shakeHands ended FAIL");
				}
				try { socket.close(); } catch (e:Dynamic) {}
			});
		}
	}
	
	public static function shakeHands(socket:Socket, flashSocketPolicy:Bool) : Bool
	{
		var rLine = "";
		
		if (!flashSocketPolicy)
		{
			try
			{
				rLine = socket.input.readLine(); // This is for the GET / HTTP/1.1 Line
				Lib.println("shake receive: " + rLine);
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
					Lib.println("shake send: POLICY");
					socket.close();
					return false;
				} 
				else if (ms.indexOf("\r\n") >= 0)
				{
					rLine = ms;
					Lib.println("shake receive: " + rLine);
					break;
				}
			}
		}
		
		//var method_url_protocol = rLine;

		var clientHeaders = new Hash<String>();
		do
		{
			try
			{
				rLine = socket.input.readLine();
				Lib.println("shake receive: " + rLine);
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
		
		WebSocketServerTools.sendHandsShake(socket, clientHeaders.get("Sec-WebSocket-Key"));
		
		return true;
	}
}