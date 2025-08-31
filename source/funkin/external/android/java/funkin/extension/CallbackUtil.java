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

		public static void callMethod(String methodName, Object[] args)
	{
		if (haxeObject != null)
			haxeObject.call(methodName, args);
	}

	public static void callMethodVoid(String methodName)
	{
		if (haxeObject != null)
			haxeObject.call0(methodName);
	}

  @Override
	public boolean onActivityResult(int requestCode, int resultCode, Intent data)
	{
		if (haxeObject != null)
			haxeObject.call2("onActivityResult", requestCode, resultCode);

		return true;
	}
}
