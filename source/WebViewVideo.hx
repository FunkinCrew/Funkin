#if extension-webview
package;

import extension.webview.WebView;
import haxe.crypto.Base64;
import haxe.io.Bytes;

//webSettings.setMediaPlaybackRequiresUserGesture(false);	 xml android:usesCleartextTraffic="true"

class WebViewVideo extends WebView
{
	public static var androidPath:String = 'file:///android_asset/assets/';
	public static var base:String = 'data:text/html;base64,';

	// path without .mp4
	public static function openVideo(path:String) {
		openURL(androidPath + path + '.html');
	}

	public static function openURL(url:String)
	{
		WebView.open(url, false, null, ['http://exitme(.*)']);
	}
}
#end