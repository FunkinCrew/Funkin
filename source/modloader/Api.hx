package modloader;

import openfl.net.*;

class Api
{
    static inline final HTTPS_API_MODS = "https:\\/api/mods/";

    public function new () {
        var vars = new URLVariables ();
		vars.hello = 100;
		
		var _req = new URLRequest(HTTPS_API_MODS);
		_req.data = vars;
		_req.method = URLRequestMethod.POST;
		//_onReq = onReq;
		var _loader = new URLLoader ();
		_loader.dataFormat = URLLoaderDataFormat.TEXT;
		_loader.load(_req);
		
	}
    
    public static function test() {
        
    }
}