package funkin.extensions;

import android.content.Intent;

import org.haxe.extension.Extension;
import org.haxe.lime.HaxeObject;

public class CallbackUtil extends Extension
{
	public static HaxeObject cbObject;

  public static int DATA_FOLDER_CLOSED = 0x01;

  /**
	 * Initializes the callback object for handling Haxe callbacks.
	 *
	 * @param cbObject The HaxeObject instance to handle callbacks.
	 */
	public static void initCallBack(final HaxeObject cbObject)
	{
		CallbackUtil.cbObject = cbObject;
	}

  @Override
	public boolean onActivityResult(int requestCode, int resultCode, Intent data)
	{
		if (cbObject != null)
		{
			try
			{
        Object[] args = new Object[2];
				args[0] = requestCode;
				args[1] = resultCode;

				cbObject.call("onActivityResult", args);
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}
		}

		return true;
	}
}
