package funkin.extensions;

import android.content.Intent;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.os.Bundle;
import android.util.Log;

import funkin.extensions.CallbackUtil;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import org.haxe.extension.Extension;

import org.haxe.lime.HaxeObject;

public class FNFCExtension extends Extension
{
  public static final String LOG_TAG = "FNFCExtension";

  public static String lastFNFC = null;

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    Intent intent = mainActivity.getIntent();
    if (intent != null && intent.getData() != null) {
      handleIntent(intent, false);
    }
  }

  @Override
  public void onNewIntent(Intent intent) {
    super.onNewIntent(intent);

    if (intent != null && intent.getData() != null) {
      handleIntent(intent, true);
    }
  }

  private static void handleIntent(Intent intent, boolean doCallback)
  {
    if (Intent.ACTION_VIEW.equals(intent.getAction()))
    {
      Uri uri = intent.getData();
      if (uri != null)
      {
        try
        {
          lastFNFC = copyFNFCToCache(uri);

          if (doCallback)
          {
            CallbackUtil.callMethod("onFNFCOpen", lastFNFC);
          }
        }
        catch (IOException e)
        {
         	Log.e(LOG_TAG, e.getMessage());
        }
      }
    }
  }

  public static String copyFNFCToCache(Uri uri) throws IOException
	{
		if (uri != null)
    {
			String fileName = new File(uri.getPath()).getName();

      // Clean some Uri leftovers
			if (fileName.contains(":"))
				fileName = fileName.split(":")[1];

      File cacheFNFC = new File(mainContext.getCacheDir(), "fnfc");
      File output = new File(cacheFNFC, fileName);

      if (!cacheFNFC.exists())
        cacheFNFC.mkdir();

			if (output.exists())
				output.delete();

    	ParcelFileDescriptor parcelFileDescriptor = null;
		  FileInputStream fileInputStream = null;
			OutputStream out = null;

      try
      {
	    	parcelFileDescriptor = mainContext.getContentResolver().openFileDescriptor(uri, "r");
				fileInputStream = new FileInputStream(parcelFileDescriptor.getFileDescriptor());

				byte[] fileBytes = new byte[(int) parcelFileDescriptor.getStatSize()];
	    	fileInputStream.read(fileBytes);

				out = new FileOutputStream(output);
				out.write(fileBytes);

        if (output.exists())
          output.deleteOnExit(); // makes the file get deleted when the app closes ig?
      }
      catch (IOException e)
      {
       	Log.e(LOG_TAG, e.getMessage());
      }
			finally
			{
	    	if (fileInputStream != null)
    		  fileInputStream.close();

    	  if (parcelFileDescriptor != null)
    	   	parcelFileDescriptor.close();

				if (out != null)
					out.close();
    	}

    	return output.getAbsolutePath();
		}

		return null;
	}
}
