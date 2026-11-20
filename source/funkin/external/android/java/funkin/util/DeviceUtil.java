package funkin.util;

import android.app.ActivityManager;
import android.content.Context;
import android.os.Build;

import org.haxe.extension.Extension;

public class DeviceUtil
{
	public static int getTotalMemory()
	{
		if (Extension.mainContext == null)
			return 0;

		ActivityManager manager = (ActivityManager) Extension.mainContext.getSystemService(Context.ACTIVITY_SERVICE);

		if (manager == null)
			return 0;

		ActivityManager.MemoryInfo info = new ActivityManager.MemoryInfo();
		manager.getMemoryInfo(info);
		return (int) (info.totalMem / (1024 * 1024));
	}

	public static int getPerformanceClass()
	{
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
			return Build.VERSION.MEDIA_PERFORMANCE_CLASS;

		return 0;
	}
}
