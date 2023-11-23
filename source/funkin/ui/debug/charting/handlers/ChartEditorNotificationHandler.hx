package funkin.ui.debug.charting.handlers;

import haxe.ui.notifications.Notification;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;

class ChartEditorNotificationHandler
{
  public static function setupNotifications(state:ChartEditorState):Void
  {
    // Setup notifications.
    @:privateAccess
    NotificationManager.GUTTER_SIZE = 20;
  }

  /**
   * Send a notification with a checkmark indicating success.
   * @param state The current state of the chart editor.
   */
  public static function success(state:ChartEditorState, title:String, body:String):Notification
  {
    return sendNotification(title, body, NotificationType.Success);
  }

  /**
   * Send a notification with a warning icon.
   * @param state The current state of the chart editor.
   */
  public static function warning(state:ChartEditorState, title:String, body:String):Notification
  {
    return sendNotification(title, body, NotificationType.Warning);
  }

  /**
   * Send a notification with a warning icon.
   * @param state The current state of the chart editor.
   */
  public static inline function warn(state:ChartEditorState, title:String, body:String):Notification
  {
    return warning(state, title, body);
  }

  /**
   * Send a notification with a cross indicating an error.
   * @param state The current state of the chart editor.
   */
  public static function error(state:ChartEditorState, title:String, body:String):Notification
  {
    return sendNotification(title, body, NotificationType.Error);
  }

  /**
   * Send a notification with a cross indicating failure.
   * @param state The current state of the chart editor.
   */
  public static inline function failure(state:ChartEditorState, title:String, body:String):Notification
  {
    return error(state, title, body);
  }

  /**
   * Send a notification with an info icon.
   * @param state The current state of the chart editor.
   */
  public static function info(state:ChartEditorState, title:String, body:String):Notification
  {
    return sendNotification(title, body, NotificationType.Info);
  }

  /**
   * Clear all active notifications.
   * @param state The current state of the chart editor.
   */
  public static function clearNotifications(state:ChartEditorState):Void
  {
    NotificationManager.instance.clearNotifications();
  }

  /**
   * Clear a specific notification.
   * @param state The current state of the chart editor.
   * @param notif The notification to clear.
   */
  public static function clearNotification(state:ChartEditorState, notif:Notification):Void
  {
    NotificationManager.instance.removeNotification(notif);
  }

  static function sendNotification(title:String, body:String, ?type:NotificationType):Notification
  {
    #if !mac
    return NotificationManager.instance.addNotification(
      {
        title: title,
        body: body,
        type: type ?? NotificationType.Default,
        expiryMs: Constants.NOTIFICATION_DISMISS_TIME
      });
    #else
    trace('WARNING: Notifications are not supported on Mac OS.');
    #end
  }
}
