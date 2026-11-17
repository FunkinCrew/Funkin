package funkin.extensions;

import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.FileUtils;
import android.os.Bundle;
import android.provider.OpenableColumns;
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
import java.util.Locale;

import org.haxe.extension.Extension;

public class FNFLoaderExtension extends Extension
{
  public static String lastFNFC = null;
  public static String lastFNFMOD = null;
  public static String lastModArchive = null;
  public static String lastModArchiveName = null;
  public static String lastModArchiveError = null;

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
        lastFNFC = null;
        lastFNFMOD = null;
        lastModArchive = null;
        lastModArchiveName = null;
        lastModArchiveError = null;

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
            String displayName = displayNameForUri(uri);
            String extension = archiveExtension(displayName, mainContext.getContentResolver().getType(uri));

            if ("fnfc".equals(extension))
            {
              try
              {
                lastFNFC = copyFNFCToCache(uri);

                if (lastFNFC != null && doCallback)
                {
                  CallbackUtil.callMethod("onFNFCOpen", lastFNFC);
                }
              }
              catch (IOException e)
              {
                Log.e("trace", e.getMessage());
              }
            }
            else if (extension != null)
            {
              try
              {
                lastModArchiveName = safeDisplayName(displayName, extension);
                lastModArchive = copyModArchiveToCache(uri, lastModArchiveName);
                lastModArchiveError = null;

                if (doCallback)
                {
                  CallbackUtil.callMethod("onModArchiveOpen", lastModArchive, lastModArchiveName);
                }
              }
              catch (IOException e)
              {
                lastModArchive = null;
                lastModArchiveName = null;
                lastModArchiveError = e.getMessage() == null ? "The mod archive could not be copied" : e.getMessage();
                Log.e("trace", "Failed to copy mod archive from " + uri, e);

                if (doCallback)
                {
                  CallbackUtil.callMethod("onModArchiveError", lastModArchiveError);
                }
              }
            }
            break;
        }
      }
    }
  }

  public static String copyFNFCToCache(Uri uri) throws IOException
  {
    if (uri == null) return null;

    try
    {
      return copyUriToCache(uri, "fnfc", fnfcCacheName(uri));
    }
    catch (Exception e)
    {
      Log.e("trace", "Failed to copy FNFC from " + uri.toString() + ". Error message: " + e.getMessage());
      throw new IOException("Failed to copy FNFC: " + e.getMessage(), e);
    }
  }

  private static String copyModArchiveToCache(Uri uri, String fileName) throws IOException
  {
    return copyUriToCache(uri, "mod-archives", modArchiveCacheName(uri, fileName));
  }

  private static String copyUriToCache(Uri uri, String cacheFolder, String fileName) throws IOException
  {
    File cacheDir = new File(mainContext.getCacheDir(), cacheFolder);
    if (!cacheDir.exists() && !cacheDir.mkdirs())
      throw new IOException("Failed to create cache directory at: " + cacheDir.getAbsolutePath());

    File output = new File(cacheDir, fileName);

    try (InputStream in = mainContext.getContentResolver().openInputStream(uri))
    {
      if (in == null)
        throw new IOException("Failed to get input stream for Uri: " + uri.toString());

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
      {
        try (OutputStream out = new FileOutputStream(output))
        {
          FileUtils.copy(in, out);
          out.flush();
        }
      }
      else
      {
        Files.copy(in, output.toPath(), StandardCopyOption.REPLACE_EXISTING);
      }
    }
    catch (Exception e)
    {
      output.delete();
      if (e instanceof IOException) throw (IOException)e;
      throw new IOException("Failed to copy Uri file: " + e.getMessage(), e);
    }

    if (output.length() <= 0)
    {
      output.delete();
      throw new IOException("The copied Uri file (" + uri.toString() + ") ended empty at: " + output.getAbsolutePath());
    }

    return output.getAbsolutePath();
  }

  private static String displayNameForUri(Uri uri)
  {
    Cursor cursor = null;

    try
    {
      cursor = mainContext.getContentResolver().query(uri, new String[] {OpenableColumns.DISPLAY_NAME}, null, null, null);
      if (cursor != null && cursor.moveToFirst())
      {
        int columnIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
        if (columnIndex >= 0)
        {
          String name = cursor.getString(columnIndex);
          if (name != null && !name.isEmpty()) return name;
        }
      }
    }
    catch (RuntimeException e)
    {
      Log.w("trace", "Could not read the display name for " + uri, e);
    }
    finally
    {
      if (cursor != null) cursor.close();
    }

    String lastPathSegment = uri.getLastPathSegment();
    return lastPathSegment == null ? null : Uri.decode(lastPathSegment);
  }

  private static String archiveExtension(String displayName, String mimeType)
  {
    if (displayName != null)
    {
      String lowerName = displayName.toLowerCase(Locale.ROOT);
      if (lowerName.endsWith(".fnfc")) return "fnfc";
      if (lowerName.endsWith(".zip")) return "zip";
    }

    if (mimeType != null)
    {
      String lowerMimeType = mimeType.toLowerCase(Locale.ROOT);
      if ("application/zip".equals(lowerMimeType) || "application/x-zip-compressed".equals(lowerMimeType))
      {
        return "zip";
      }
    }

    return null;
  }

  private static String safeDisplayName(String displayName, String extension)
  {
    String name = displayName == null ? "mod" : displayName.replace('\\', '/');
    name = name.substring(name.lastIndexOf('/') + 1);
    name = name.replaceAll("[^A-Za-z0-9._-]", "_");

    if (name.isEmpty()) name = "mod";
    if (!name.toLowerCase(Locale.ROOT).endsWith("." + extension)) name += "." + extension;

    return name;
  }

  private static String modArchiveCacheName(Uri uri, String fileName)
  {
    try
    {
      byte[] digest = MessageDigest.getInstance("SHA-256")
          .digest((uri.toString() + System.nanoTime()).getBytes(StandardCharsets.UTF_8));
      String uniqueName = Base64.encodeToString(digest,
          Base64.URL_SAFE | Base64.NO_WRAP | Base64.NO_PADDING);
      return uniqueName + "-" + fileName;
    }
    catch (Exception e)
    {
      return Integer.toHexString((uri.toString() + System.nanoTime()).hashCode()) + "-" + fileName;
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
