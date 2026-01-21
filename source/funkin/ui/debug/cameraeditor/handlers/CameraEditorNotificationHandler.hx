package funkin.ui.debug.cameraeditor.handlers;

#if FEATURE_CHART_EDITOR
import haxe.ui.animation.AnimationBuilder;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.core.Screen;
import haxe.ui.notifications.Notification;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationData.NotificationActionData;

/**
 * Handles notifications for the camera editor.
 */
class CameraEditorNotificationHandler
{
  /**
   * Performs initial setup for notifications.
   * @param state
   */
  public static function setupNotifications(state:CameraEditorState):Void
  {
    // Setup notifications.
    @:privateAccess
    NotificationManager.GUTTER_SIZE = 8;

    NotificationManager.instance.animationFn = AnimateFromBottom;
  }

  /**
   * A custom function to handle the animation of notifications from the bottom.
   * @param notifications Notifications to display
   * @return An array of animation builders
   */
  public static function AnimateFromBottom(notifications:Array<Notification>):Array<AnimationBuilder>
  {
    // since GUTTER_SIZE affects both x and y, we'll replace the positioning with this!
    // for some reason the first notif always has a downwards offset of like 10 and idk how to fix that
    // that was also a problem before this

    var builders = [];

    var scy = Screen.instance.height;
    var baselineY = scy - 65;

    for (notification in notifications)
    {
      var builder = new AnimationBuilder(notification);
      builder.setPosition(0, "top", Std.int(notification.top), true);
      builder.setPosition(100, "top", Std.int(baselineY - notification.height), true);
      if (notification.opacity == 0)
      {
        builder.setPosition(0, "opacity", 0, true);
        builder.setPosition(100, "opacity", 1, true);
      }
      builders.push(builder);
      baselineY -= (notification.height + @:privateAccess NotificationManager.SPACING);
    }

    return builders;
  }

  /**
   * Send a notification with a checkmark indicating success.
   * @param state The current state of the chart editor.
   */
  public static function success(state:CameraEditorState, title:String, body:String):Notification
  {
    return sendNotification(state, title, body, NotificationType.Success);
  }

  /**
   * Send a notification with a warning icon.
   * @param state The current state of the chart editor.
   */
  public static function warning(state:CameraEditorState, title:String, body:String):Notification
  {
    return sendNotification(state, title, body, NotificationType.Warning);
  }

  /**
   * Send a notification with a warning icon.
   * @param state The current state of the chart editor.
   */
  public static inline function warn(state:CameraEditorState, title:String, body:String):Notification
  {
    return warning(state, title, body);
  }

  /**
   * Send a notification with a cross indicating an error.
   * @param state The current state of the chart editor.
   */
  public static function error(state:CameraEditorState, title:String, body:String):Notification
  {
    return sendNotification(state, title, body, NotificationType.Error);
  }

  /**
   * Send a notification with a cross indicating failure.
   * @param state The current state of the chart editor.
   */
  public static inline function failure(state:CameraEditorState, title:String, body:String):Notification
  {
    return error(state, title, body);
  }

  /**
   * Send a notification with an info icon.
   * @param state The current state of the chart editor.
   */
  public static function info(state:CameraEditorState, title:String, body:String):Notification
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
  public static function infoWithActions(state:CameraEditorState, title:String, body:String, actions:Array<NotificationActionData>):Notification
  {
    return sendNotification(state, title, body, NotificationType.Info, actions);
  }

  /**
   * Clear all active notifications.
   * @param state The current state of the chart editor.
   */
  public static function clearNotifications(state:CameraEditorState):Void
  {
    NotificationManager.instance.clearNotifications();
  }

  /**
   * Clear a specific notification.
   * @param state The current state of the chart editor.
   * @param notif The notification to clear.
   */
  public static function clearNotification(state:CameraEditorState, notif:Notification):Void
  {
    NotificationManager.instance.removeNotification(notif);
  }

  static function sendNotification(state:CameraEditorState, title:String, body:String, ?type:NotificationType,
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
#end
