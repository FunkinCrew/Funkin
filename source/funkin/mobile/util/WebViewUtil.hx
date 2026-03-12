package funkin.mobile.util;

#if FEATURE_MOBILE_WEBVIEW
import extension.webviewcore.WebView;

/**
 * Provides utility functions for working with WebView.
 */
class WebViewUtil
{
  /**
   * Initializes the WebView.
   */
  public static function init():Void
  {
    WebView.init();
  }

  /**
   * Opens a URL in a WebView if one is not already open.
   *
   * @param url The URL to open. If the protocol is missing, 'https://' is prepended.
   *            Only 'http' and 'https' protocols are allowed; otherwise, an error is thrown.
   * @param onCloseButtonPressed Optional callback function to be called when the WebView's close button is pressed.
   *
   * If the WebView is already open, this function does nothing.
   */
  public static function openURL(url:String, ?onCloseButtonPressed:Void->Void):Void
  {
    if (!WebView.isOpened())
    {
      var protocol:Array<String> = url.split("://");

      if (protocol.length == 1)
      {
        url = 'https://${url}';
      }
      else if (protocol[0] != 'http' && protocol[0] != 'https')
      {
        throw "openURL can only open http and https links.";
      }

      function onButtonClicked():Void
      {
        WebViewUtil.close();

        if (onCloseButtonPressed != null)
        {
          onCloseButtonPressed();
        }
      }

      WebView.onCloseButtonClicked.add(onButtonClicked);

      WebView.openWithURL(url, false, true);
    }
  }

  /**
   * Closes the currently opened WebView if it is open.
   *
   * This function checks if the WebView is currently opened.
   *
   * If so, it removes all listeners from the `onCloseButtonClicked` event to prevent any further callbacks, and then closes the WebView.
   */
  public static function close():Void
  {
    if (WebView.isOpened())
    {
      WebView.onCloseButtonClicked.removeAll();

      WebView.close();
    }
  }
}
#end
