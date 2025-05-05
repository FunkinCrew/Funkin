package funkin.mobile.util;

#if FEATURE_MOBILE_IAP
#if android
import extension.iapcore.android.IAPAndroid;
import extension.iapcore.android.IAPProductDetails;
import extension.iapcore.android.IAPPurchase;
import extension.iapcore.android.IAPPurchaseState;
import extension.iapcore.android.IAPResponseCode;
import extension.iapcore.android.IAPResult;
#elseif (ios || tvos)
import extension.iapcore.apple.IAPApple;
import extension.iapcore.apple.IAPProductDetails;
import extension.iapcore.apple.IAPPurchase;
import extension.iapcore.apple.IAPPurchaseState;
#end

/**
 * Utility class for managing in-app purchases.
 */
class InAppPurchasesUtil
{
  #if android
  static final FETCH_PRODUCT_DETAILS_IDS:Array<String> = ['test_product_0'];
  #elseif (ios || tvos)
  static final FETCH_PRODUCT_DETAILS_IDS:Array<String> = ['adfree'];
  #end

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
    #if android
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
    #else
    IAPApple.onProductDetailsReceived.add(function(productDetails:Array<IAPProductDetails>):Void {
      if (productDetails != null) currentProductDetails = productDetails;
    });

    IAPApple.onPurchasesUpdated.add(function(purchases:Array<IAPPurchase>):Void {
      handlePurchases(purchases);
    });

    IAPApple.init();

    IAPApple.restorePurchases();

    IAPApple.requestProducts(FETCH_PRODUCT_DETAILS_IDS);
    #end
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
      #if android
      if (product.getProductId() == id)
      {
        IAPAndroid.launchPurchaseFlow(product);
        return;
      }
      #elseif (ios || tvos)
      if (product.getProductIdentifier() == id)
      {
        IAPApple.purchaseProduct(product);
        return;
      }
      #end
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
      #if android
      if (purchase.getProducts().contains(id))
      {
        return true;
      }
      #elseif (ios || tvos)
      if (purchase.getPaymentProductIdentifier() == id)
      {
        return true;
      }
      #end
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
      #if android
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
          logMessage('Android purchase tracked: ${purchase.getPurchaseToken()}');
        }
        else
        {
          logMessage('Android purchase already tracked: ${purchase.getPurchaseToken()}');
        }
      }
      else
      {
        logMessage('Android purchase not completed: ${purchase.getPurchaseState()}');
      }
      #elseif (ios || tvos)
      logMessage('Transaction ID: ${purchase.getTransactionIdentifier()}');
      logMessage('Transaction Date: ${purchase.getTransactionDate()}');
      logMessage('Transaction Payment Product ID: ${purchase.getPaymentProductIdentifier()}');
      var alreadyTracked:Bool = false;
      for (existing in currentPurchased)
      {
        if (existing.getTransactionIdentifier() == purchase.getTransactionIdentifier())
        {
          alreadyTracked = true;
          break;
        }
      }
      switch (purchase.getTransactionState())
      {
        case IAPPurchaseState.PURCHASING:
          logMessage('iOS purchase is in progress.');

        case IAPPurchaseState.DEFERRED:
          logMessage('iOS purchase is deferred.');

        case IAPPurchaseState.FAILED:
          logMessage('iOS purchase failed.');
          IAPApple.finishPurchase(purchase);

        case IAPPurchaseState.PURCHASED | IAPPurchaseState.RESTORED:
          logMessage('iOS purchase successful or restored.');
          if (!alreadyTracked)
          {
            currentPurchased.push(purchase);
            logMessage('iOS purchase tracked: ${purchase.getTransactionIdentifier()}');
            IAPApple.finishPurchase(purchase);
          }
          else
          {
            logMessage('iOS purchase already tracked: ${purchase.getTransactionIdentifier()}');
          }
      }
      #end
    }
  }
}
#end
