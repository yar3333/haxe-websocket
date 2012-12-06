package js;

import js.Lib;
import js.SWFObject;

@:native("WebSocket") extern class WebSocket
{
	static function __init__() : Void
	{
		haxe.macro.Tools.includeFile("js/WebSocket.js");
	}
	
	public static var WEB_SOCKET_SWF_LOCATION(WEB_SOCKET_SWF_LOCATION_getter, WEB_SOCKET_SWF_LOCATION_setter) : String;
	private static inline function WEB_SOCKET_SWF_LOCATION_getter() : String
	{
		return cast(Lib.window).WEB_SOCKET_SWF_LOCATION;
	}
	private static inline function WEB_SOCKET_SWF_LOCATION_setter(path:String) : String
	{
		return cast(Lib.window).WEB_SOCKET_SWF_LOCATION = path;
	}
	
	public var readyState(default, null) : Int;
	
	/**
	 * Url example: "ws://example.com:10081/".
	 */
	function new(url:String) : Void;
	
	var onopen : Void->Void;
	var onmessage : { data:String }->Void;
	var onclose : Void->Void;
	
	function send(data:String) : Void;
}