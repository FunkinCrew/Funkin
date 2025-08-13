package funkin.util;

import android.content.Intent;
import android.content.ContentResolver;
import android.net.Uri;
import android.os.Build;
import android.provider.DocumentsContract;
import android.content.pm.PackageInfo;

import java.util.List;

import org.haxe.extension.Extension;

public class DataFolderUtil
{
  /**
   * A method that opens the Application's data folder for browsing through the Storage Access Framework.
   * It's highly based on some code borrowed from Mterial Files
   * https://github.com/zhanghai/MaterialFiles
   */
  public static void openDataFolder(int requestCode)
  {
    ::if (APP_PACKAGE != "")::
    if (Extension.mainActivity != null)
    {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setDataAndType(DocumentsContract.buildRootUri("::APP_PACKAGE::.docprovider", ""), "vnd.android.document/directory");
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
        Extension.mainActivity.startActivityForResult(intent, requestCode);
    }
    ::end::
  }
}
