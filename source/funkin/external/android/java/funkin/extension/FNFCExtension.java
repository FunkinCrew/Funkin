package funkin.extensions;

import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.FileUtils;
import android.os.Bundle;
import android.util.Log;
import android.util.Base64;

import funkin.extensions.CallbackUtil;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

import org.haxe.extension.Extension;

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
    if (uri == null) return null;

    File output = null;

    try
    {
      File cacheFNFC = new File(mainContext.getCacheDir(), "fnfc");
      if (!cacheFNFC.exists() && !cacheFNFC.mkdirs())
        throw new IOException("Failed to create FNFC cache dir at: " + cacheFNFC.getAbsolutePath());

      output = new File(cacheFNFC, fnfcCacheName(uri));

      InputStream in = null;
      OutputStream out = null;

      try
      {
        in = mainContext.getContentResolver().openInputStream(uri);
        if (in == null)
          throw new IOException("Failed to get input stream for Uri: " + uri.toString());

        out = new FileOutputStream(output);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
        {
          FileUtils.copy(in, out);
        }
        else
        {
          Files.copy(in, output.toPath(), StandardCopyOption.REPLACE_EXISTING);
        }

        out.flush();
      }
      finally
      {
        if (in != null)
          in.close();
        if (out != null)
          out.close();
      }

      if (output.length() <= 0)
        throw new IOException("The copied Uri file (" + uri.toString() + ") ended empty at: " + output.getAbsolutePath());

      return output.getAbsolutePath();
    }
    catch (Throwable t)
    {
      Log.e("trace", "Failed to copy FNFC from " + uri.toString() + ". Error message: " + t.getMessage());
      if (output != null) output.delete();
      return null;
    }
  }

  private static String fnfcCacheName(Uri uri)
  {
    try
    {
      byte[] digest = MessageDigest.getInstance("SHA-256")
          .digest(uri.toString().getBytes(StandardCharsets.UTF_8));
      return Base64.encodeToString(digest,
          Base64.URL_SAFE | Base64.NO_WRAP | Base64.NO_PADDING) + ".fnfc";
    }
    catch (Exception e)
    {
      return Integer.toHexString(uri.toString().hashCode()) + ".fnfc";
    }
  }
}
