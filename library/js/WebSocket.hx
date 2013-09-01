package js;

import js.SWFObject;

@:native("WebSocket") extern class WebSocket
{
	static function __init__() : Void
	{
		haxe.macro.Tools.includeFile("js/WebSocket.js");
	}
	
	static var WEB_SOCKET_SWF_LOCATION(get_WEB_SOCKET_SWF_LOCATION, set_WEB_SOCKET_SWF_LOCATION) : String;
	private static inline function get_WEB_SOCKET_SWF_LOCATION() : String return cast(js.Browser.window).WEB_SOCKET_SWF_LOCATION;
	private static inline function set_WEB_SOCKET_SWF_LOCATION(path:String) : String	return cast(js.Browser.window).WEB_SOCKET_SWF_LOCATION = path;
	
	var readyState(default, null) : Int;
	
	/**
	 * Url example: "ws://example.com:10081/".
	 */
	function new(url:String) : Void;
	
	var onopen : Void->Void;
	var onmessage : { data:String }->Void;
	var onclose : Void->Void;
	
	function send(data:String) : Void;
}