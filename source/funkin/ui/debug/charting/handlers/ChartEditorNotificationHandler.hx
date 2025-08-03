package funkin.ui.debug.charting.handlers;

import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.notifications.Notification;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationData.NotificationActionData;

class ChartEditorNotificationHandler
{
  public static function setupNotifications(state:ChartEditorState):Void
  {
    // Setup notifications.
    @:privateAccess
    NotificationManager.GUTTER_SIZE = 45;
  }

  /**
   * Send a notification with a checkmark indicating success.
   * @param state The current state of the chart editor.
   */
  public static function success(state:ChartEditorState, title:String, body:String):Notification
  {
    return sendNotification(state, title, body, NotificationType.Success);
  }

  /**
   * Send a notification with a warning icon.
   * @param state The current state of the chart editor.
   */
  public static function warning(state:ChartEditorState, title:String, body:String):Notification
  {
    return sendNotification(state, title, body, NotificationType.Warning);
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
    return sendNotification(state, title, body, NotificationType.Error);
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
    return sendNotification(state, title, body, NotificationType.Info);
  }

  /**
   * Send a notification with an info icon and one or more actions.
   * @param state The current state of the chart editor.
   * @param title The title of the notification.
   * @param body The body of the notification.
   * @param actions The actions to add to the notification.
   * @return The notification that was sent.
   */
  public static function infoWithActions(state:ChartEditorState, title:String, body:String, actions:Array<NotificationActionData>):Notification
  {
    return sendNotification(state, title, body, NotificationType.Info, actions);
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

  static function sendNotification(state:ChartEditorState, title:String, body:String, ?type:NotificationType,
      ?actions:Array<NotificationActionData>):Notification
  {
    var actionNames:Array<String> = actions == null ? [] : actions.map(action -> action.text);

    var notif = NotificationManager.instance.addNotification(
      {
        title: title,
        body: body,
        type: type ?? NotificationType.Default,
        expiryMs: Constants.NOTIFICATION_DISMISS_TIME,
        actions: actions
      });

    if (actions != null && actions.length > 0)
    {
      // TODO: Tell Ian that this is REALLY dumb.
      var actionsContainer:HBox = notif.findComponent('actionsContainer', HBox);
      actionsContainer.walkComponents(function(component) {
        if (Std.isOfType(component, Button))
        {
          var button:Button = cast component;
          var action:Null<NotificationActionData> = actions.find(action -> action.text == button.text);
          if (action != null && action.callback != null)
          {
            button.onClick = function(_) {
              // Don't allow actions to be clicked while the playtest is open.
              if (state.subState != null) return;
              action.callback(action);
            };
          }
        }
        return true; // Continue walking.
      });
    }

    return notif;
    #if false
    // TODO: Implement notifications on Mac OS OR... make sure the null is handled properly on mac?
    return null;
    trace('WARNING: Notifications are not supported on Mac OS.');
    #end
  }
}

typedef NotificationAction =
{
  text:String,
  callback:Void->Void
}
