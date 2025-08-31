package funkin.extensions;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import funkin.extensions.CallbackUtil;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;

import org.haxe.extension.Extension;

import org.haxe.lime.HaxeObject;

public class FNFCExtension extends Extension
{
  public static String launchedFile = null;

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
      handleIntent(mainActivity.getIntent(), true);
    }
  }

  public static String queryLaunchedFNFC()
  {
    return launchedFile;
  }


  private static void handleIntent(Intent intent, boolean doCallback)
  {
    if (Intent.ACTION_VIEW.equals(intent.getAction())) {
      Uri uri = intent.getData();
      if (uri != null) {
        File output = new File(mainContext.getCacheDir(), new File("fnfc", uri.getPath()).getName());

        try {
          InputStream in = mainContext.getContentResolver().openInputStream(uri);
          OutputStream out = new FileOutputStream(output);
          byte[] buffer = new byte[8192];
          int len;
          while ((len = in.read(buffer)) > 0) {
            out.write(buffer, 0, len);
          }
        }
        catch (Exception e) {
            Log.e("Exception", e.getMessage());
        }

        launchedFile = output.getAbsolutePath();

        if (doCallback)
        {
          Object[] args = new Object[1];
          args[0] = launchedFile;
          CallbackUtil.callMethod("onOpenFNFC", args);
        }
      }
    }
  }
}
