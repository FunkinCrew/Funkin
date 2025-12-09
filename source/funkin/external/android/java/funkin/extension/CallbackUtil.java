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

	public static void callMethod(String methodName)
	{
		if (haxeObject != null)
		{
			Object[] args = new Object[2];
			args[0] = methodName;
			args[1] = new Object[0];
			haxeObject.call("dispatchCallback", args);
		}
	}

	public static void callMethod(String methodName, Object arg1)
	{
		if (haxeObject != null)
		{
			Object[] _args = {arg1};
			Object[] args = new Object[2];
			args[0] = methodName;
			args[1] = _args;
			haxeObject.call("dispatchCallback", args);
		}
	}

	public static void callMethod(String methodName, Object arg1, Object arg2)
	{
		if (haxeObject != null)
		{
			Object[] _args = {arg1, arg2};
			Object[] args = new Object[2];
			args[0] = methodName;
			args[1] = _args;
			haxeObject.call("dispatchCallback", args);
		}
	}

	public static void callMethod(String methodName, Object arg1, Object arg2, Object arg3)
	{
		if (haxeObject != null)
		{
			Object[] _args = {arg1, arg2, arg3};
			Object[] args = new Object[2];
			args[0] = methodName;
			args[1] = _args;
			haxeObject.call("dispatchCallback", args);
		}
	}

	public static void callMethod(String methodName, Object arg1, Object arg2, Object arg3, Object arg4)
	{
		if (haxeObject != null)
		{
			Object[] _args = {arg1, arg2, arg3, arg4};
			Object[] args = new Object[2];
			args[0] = methodName;
			args[1] = _args;
			haxeObject.call("dispatchCallback", args);
		}
	}

	public static void callMethod(String methodName, Object[] args)
	{
		if (haxeObject != null)
		{
			Object[] _args = new Object[2];
			args[0] = methodName;
			args[1] = args;
			haxeObject.call("dispatchCallback", _args);
		}
	}

  @Override
	public boolean onActivityResult(int requestCode, int resultCode, Intent data)
	{
		callMethod("onActivityResult", requestCode, resultCode);

		return true;
	}
}
