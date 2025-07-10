package funkin.util;

import android.content.Intent;
import android.content.ContentResolver;
import android.net.Uri;
import android.os.Build;
import android.provider.DocumentsContract;
import android.content.pm.PackageInfo;

import funkin.extensions.CallbackUtil;

import java.util.List;

import org.haxe.extension.Extension;


public class DataFolderUtil
{
  /**
   * A method that opens the Application's data folder for browsing through the Storage Access Framework.
   * It's highly based on some code borrowed from Mterial Files
   * https://github.com/zhanghai/MaterialFiles
   */
  public static void openDataFolder()
  {
    ::if (APP_PACKAGE != "")::
    if (Extension.mainActivity != null)
    {
      Intent intent = new Intent(Intent.ACTION_VIEW);
      intent.setDataAndType(DocumentsContract.buildRootUri("::APP_PACKAGE::.docprovider", ""), "vnd.android.document/directory");
      intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

      String documentsUiPackage = getDocumentsUiPackage();
      if (documentsUiPackage != null) {
        intent.setPackage(documentsUiPackage);
        Extension.mainActivity.startActivityForResult(intent, CallbackUtil.DATA_FOLDER_CLOSED);
      }
    }
    ::end::
  }

  private static String getDocumentsUiPackage() {
    List<PackageInfo> packageInfos = Extension.mainContext.getPackageManager().getPackagesHoldingPermissions(
        new String[]{"android.permission.MANAGE_DOCUMENTS"}, 0
    );

    PackageInfo targetPackage = null;
    for (PackageInfo pkg : packageInfos) {
        if (pkg.packageName.endsWith(".documentsui")) {
            targetPackage = pkg;
            break;
        }
    }

    if (targetPackage == null && !packageInfos.isEmpty()) {
        targetPackage = packageInfos.get(0);
    }

    return targetPackage != null ? targetPackage.packageName : null;
  }
}
