package funkin.mobile.util;

#if android
import android.callback.CallBack;
import android.os.Build;
import android.os.Environment;
import android.Permissions;
import android.Settings;
#end

/**
 * Utility class for handling Android permissions.
 */
class PermissionsUtil
{
  // Constants for permission request codes
  static final REQUEST_CODE_READ:Int = 100;
  static final REQUEST_CODE_WRITE:Int = 101;
  static final REQUEST_CODE_MANAGE:Int = 102;

  /**
   * Checks and requests the necessary permissions based on the Android version.
   */
  public static function checkAndRequestPermissions():Void
  {
    #if android
    // Initialize the CallBack for handling permission results and activity results
    CallBack.init();

    // Handle activity result for managing all files access permission
    CallBack.onActivityResult.add(function(data:Dynamic):Void {
      if (data == null) return;

      switch (data.requestCode)
      {
        case REQUEST_CODE_MANAGE:
          // Handle result for MANAGE_EXTERNAL_STORAGE permission
          if (Environment.isExternalStorageManager())
          {
            // Permission granted
          }
          else
          {
            // Permission denied, handle accordingly
          }
      }
    });

    // Handle permission request results
    CallBack.onRequestPermissionsResult.add(function(data:Dynamic):Void {
      if (data == null) return;

      switch (data.requestCode)
      {
        case REQUEST_CODE_READ:
          // Handle result for READ_EXTERNAL_STORAGE permission
          if (data.grantResults.length > 0 && data.grantResults[0] == 0)
          {
            // Permission granted
          }
          else
          {
            // Permission denied, handle accordingly
          }
        case REQUEST_CODE_WRITE:
          // Handle result for WRITE_EXTERNAL_STORAGE permission
          if (data.grantResults.length > 0 && data.grantResults[0] == 0)
          {
            // Permission granted
          }
          else
          {
            // Permission denied, handle accordingly
          }
      }
    });

    // Check and request permissions based on the Android version
    switch (VERSION.SDK_INT)
    {
      case version if (version >= VERSION_CODES.R): // For Android 11+ or equal
        if (!Environment.isExternalStorageManager())
        {
          Settings.requestSetting('android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION', REQUEST_CODE_MANAGE);
        }
      case version if (version >= VERSION_CODES.M): // For Android 6+ or equal
        final grantedPermissions:Array<String> = Permissions.getGrantedPermissions();

        if (!grantedPermissions.contains('android.permission.READ_EXTERNAL_STORAGE'))
        {
          Permissions.requestPermission('android.permission.READ_EXTERNAL_STORAGE', REQUEST_CODE_READ);
        }

        if (!grantedPermissions.contains('android.permission.WRITE_EXTERNAL_STORAGE'))
        {
          Permissions.requestPermission('android.permission.WRITE_EXTERNAL_STORAGE', REQUEST_CODE_WRITE);
        }
    }
    #end
  }
}
