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

public class FNFLoaderExtension extends Extension
{
  public static String lastFNFC = null;
  public static String lastFNFMOD = null;

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
        switch (uri.getScheme())
        {
          case "funkin":
            lastFNFMOD = uri.toString();

            if (doCallback)
            {
              CallbackUtil.callMethod("onFNFMODOpen", lastFNFMOD);
            }
            break;
          default:
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
              Log.e("trace", e.getMessage());
            }
            break;
        }
      }
    }
  }

  public static String copyFNFCToCache(Uri uri) throws IOException
  {
    if (uri != null)
    {
      String fileName = new File(uri.getPath()).getName();

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
          output.deleteOnExit();
      }
      catch (IOException e)
      {
        Log.e("trace", e.getMessage());
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
