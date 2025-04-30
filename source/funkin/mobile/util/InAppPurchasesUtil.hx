package funkin.mobile.util;

#if FEATURE_MOBILE_IAP
import extension.iapcore.android.IAPAndroid;
import extension.iapcore.android.IAPProductDetails;
import extension.iapcore.android.IAPPurchase;
import extension.iapcore.android.IAPPurchaseState;
import extension.iapcore.android.IAPResponseCode;
import extension.iapcore.android.IAPResult;

/**
 * Utility class for managing in-app purchases.
 */
class InAppPurchasesUtil
{
  /**
   * A static final array containing the product IDs for fetching product details.
   */
  static final FETCH_PRODUCT_DETAILS_IDS:Array<String> = ['test_product_0'];

  /**
   * The maximum number of attempts to reconnect in case of a failure.
   */
  static final MAX_RECONNECT_ATTEMPTS:Int = 3;

  /**
   * A static variable that holds an array of currently loaded product details for in-app purchases.
   */
  public static var currentProductDetails:Array<IAPProductDetails> = [];

  /**
   * A static variable that holds an array of currently purchased for in-app purchases.
   */
  public static var currentPurchased:Array<IAPPurchase> = [];

  /**
   * A static variable to track the number of attempts made to reconnect.
   */
  static var reconnectAttempts:Int = 0;

  /**
   * Initializes the in-app purchases utility.
   */
  public static function init():Void
  {
    IAPAndroid.onLog.add(function(message:String):Void {
      logMessage(message);
    });

    IAPAndroid.onBillingSetupFinished.add(function(result:IAPResult):Void {
      if (result.getResponseCode() != IAPResponseCode.OK)
      {
        logMessage('Billing setup failed "$result"!');
        return;
      }

      reconnectAttempts = 0;

      IAPAndroid.queryPurchases();

      IAPAndroid.queryProductDetails(FETCH_PRODUCT_DETAILS_IDS);
    });

    IAPAndroid.onBillingServiceDisconnected.add(function():Void {
      logMessage("Billing service disconnected!");

      if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS)
      {
        reconnectAttempts++;

        logMessage('Attempting to reconnect... ($reconnectAttempts/$MAX_RECONNECT_ATTEMPTS)');

        IAPAndroid.startConnection();
      }
      else
      {
        logMessage('Max reconnect attempts reached.');
      }
    });

    IAPAndroid.onProductDetailsResponse.add(function(result:IAPResult, productDetails:Array<IAPProductDetails>):Void {
      if (result.getResponseCode() == IAPResponseCode.OK) currentProductDetails = productDetails;
      else
      {
        logMessage('Failed to fetch product details: "$result"');
      }
    });

    IAPAndroid.onQueryPurchasesResponse.add(function(result:IAPResult, purchases:Array<IAPPurchase>):Void {
      if (result.getResponseCode() == IAPResponseCode.OK) handlePurchases(purchases);
      else
      {
        logMessage('Failed to query purchases: "$result"');
      }
    });

    IAPAndroid.onPurchasesUpdated.add(function(result:IAPResult, purchases:Array<IAPPurchase>):Void {
      if (result.getResponseCode() == IAPResponseCode.OK) handlePurchases(purchases);
      else
      {
        logMessage('Failed to update purchases: "$result"');
      }
    });

    IAPAndroid.onAcknowledgePurchaseResponse.add(function(result:IAPResult):Void {
      if (result.getResponseCode() == IAPResponseCode.OK) logMessage('Purchase acknowledged successfully!');
      else
      {
        logMessage('Failed to acknowledge purchase: $result');
      }
    });

    IAPAndroid.init();

    IAPAndroid.startConnection();
  }

  /**
   * Initiates the purchase process for the specified item.
   *
   * @param id The identifier of the item to be purchased.
   */
  public static function purchase(id:String):Void
  {
    for (product in currentProductDetails)
    {
      if (product.getProductId() == id)
      {
        IAPAndroid.launchPurchaseFlow(product);
        return;
      }
    }

    logMessage("Didn't find product details for ID: " + id);
  }

  /**
   * Checks if the specified product ID is already purchased.
   *
   * @param id The product ID to check.
   *
   * @return `true` if the product is already purchased and acknowledged, false otherwise.
   */
  public static function isPurchased(id:String):Bool
  {
    for (purchase in currentPurchased)
    {
      if (purchase.getProducts().contains(id))
      {
        return true;
      }
    }

    return false;
  }

  @:noCompletion
  private static function logMessage(message:String):Void
  {
    #if android
    android.widget.Toast.makeText(message, android.widget.Toast.LENGTH_SHORT);
    #end

    Sys.println(message);
  }

  @:noCompletion
  private static function handlePurchases(purchases:Array<IAPPurchase>):Void
  {
    for (purchase in purchases)
    {
      if (purchase.getPurchaseState() == IAPPurchaseState.PURCHASED)
      {
        if (!purchase.isAcknowledged())
        {
          IAPAndroid.acknowledgePurchase(purchase.getPurchaseToken());
        }

        var alreadyTracked:Bool = false;

        for (existing in currentPurchased)
        {
          if (existing.getPurchaseToken() == purchase.getPurchaseToken())
          {
            alreadyTracked = true;
            break;
          }
        }

        if (!alreadyTracked)
        {
          currentPurchased.push(purchase);
        }
      }
      else
      {
        logMessage('Purchase not completed: ${purchase.getPurchaseState()}');
      }
    }
  }
}
#end
