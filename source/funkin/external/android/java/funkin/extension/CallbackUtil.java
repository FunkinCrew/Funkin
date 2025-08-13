package funkin.extensions;

import android.content.Intent;

import org.haxe.extension.Extension;

import org.haxe.lime.HaxeObject;

public class CallbackUtil extends Extension
{
	/**
	 * Constant representing the event when the data folder is closed.
	 */
  public static int DATA_FOLDER_CLOSED = 0x01;

	private static HaxeObject haxeObject;

  /**
	 * Initializes the callback object for handling Haxe callbacks.
	 *
	 * @param haxeObject  The HaxeObject instance to handle callbacks.
	 */
	public static void initCallBack(final HaxeObject haxeObject)
	{
		CallbackUtil.haxeObject = haxeObject;
	}

  @Override
	public boolean onActivityResult(int requestCode, int resultCode, Intent data)
	{
		if (haxeObject  != null)
			haxeObject.call2("onActivityResult", requestCode, resultCode);

		return true;
	}
}
