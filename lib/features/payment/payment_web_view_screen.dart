// lib/screens/subscription_webview_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'payment_service.dart';

class SubscriptionWebViewScreen extends StatefulWidget {
  final int amount;
  final String productName;
  final String planId;

  const SubscriptionWebViewScreen({
    Key? key,
    required this.amount,
    required this.productName,
    required this.planId,
  }) : super(key: key);

  @override
  _SubscriptionWebViewScreenState createState() =>
      _SubscriptionWebViewScreenState();
}

class _SubscriptionWebViewScreenState extends State<SubscriptionWebViewScreen> {
  final PaymentService _paymentService = PaymentService();
  // Initialize controller immediately to avoid LateInitializationError
  late WebViewController _controller = WebViewController();
  bool _isLoading = true;
  String? _paymentError;
  String _orderId = '';
  bool _isListeningForResult = false;

  // Change type to handle any map format
  dynamic _authData;

  @override
  void initState() {
    super.initState();
    // Generate a unique order ID
    _orderId =
        'SUB-${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}-${Uuid().v4()}';
    print('Generated Order ID: $_orderId');

    // Configure controller first
    _configureController();
    // Then set up payment
    _setupPayment();
  }

  // Initialize and configure the WebViewController
  void _configureController() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setUserAgent(
            "Mozilla/5.0 (Flutter; Subscription) Referer/https://pay.pang2chocolate.com",
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                print('WebView page started loading: $url');
                setState(() => _isLoading = true);
              },
              onPageFinished: (String url) {
                print('WebView page finished loading: $url');
                setState(() => _isLoading = false);
              },
              onNavigationRequest: (NavigationRequest request) {
                print('Navigation request to: ${request.url}');

                // Handle custom URL scheme (if used)
                if (request.url.startsWith('paymentresult://')) {
                  _handlePaymentResult(request.url);
                  return NavigationDecision.prevent;
                }

                return NavigationDecision.navigate;
              },
              onWebResourceError: (WebResourceError error) {
                print('WebView error: ${error.description}');
              },
            ),
          );
  }

  @override
  void dispose() {
    // Clean up any listeners
    super.dispose();
  }

  Future<void> _setupPayment() async {
    try {
      setState(() => _isLoading = true);

      // 1. Get authentication data from Firebase function
      final authResult = await _paymentService.authenticatePayple();

      print('Auth result: $authResult'); // Debug output

      if (authResult['success'] != true) {
        throw Exception(authResult['error'] ?? 'Authentication failed');
      }

      // Store the entire auth data
      _authData = authResult['authData'];

      // Safely extract config data, providing default values if keys don't exist
      final clientKey =
          authResult['config']?['clientKey'] ??
          'test_DF55F29DA654A8CBC0F0A9DD4B556486';
      final testMode = authResult['config']?['testMode'] ?? true;

      // 2. Get Firebase project ID for callback URL
      final FirebaseOptions options = Firebase.app().options;
      final String projectId = options.projectId;
      print('Firebase Project ID: $projectId');

      // 3. Create the callback URL - use the deployed function URL
      final callbackUrl = "https://paymentcallback-nlc5xkd7oa-uc.a.run.app";
      print('Callback URL: $callbackUrl');

      // 4. Create HTML content for subscription payment
      final htmlContent = _createSubscriptionPaymentHtml(
        callbackUrl,
        clientKey,
        testMode,
      );

      // 5. Load the HTML into WebView
      await _controller.loadHtmlString(htmlContent);

      // 6. Start listening for payment results in Firestore
      _startFirestoreListener();
    } catch (e) {
      print('Error setting up payment: $e');
      setState(() {
        _paymentError = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _createSubscriptionPaymentHtml(
    String callbackUrl,
    String clientKey,
    bool testMode,
  ) {
    final baseUrl =
        testMode ? 'https://democpay.payple.kr' : 'https://cpay.payple.kr';
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    return '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta name="referrer" content="origin">
        <title>Subscription Payment</title>
        <style>
          body {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            text-align: center;
            background-color: #f9f9f9;
          }
          .container {
            max-width: 500px;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            background-color: white;
          }
          .loader {
            border: 5px solid #f3f3f3;
            border-top: 5px solid #3498db;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 2s linear infinite;
            margin: 0 auto 20px;
          }
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
          h3 {
            color: #333;
            margin-bottom: 20px;
          }
          p {
            color: #666;
            margin-bottom: 10px;
          }
          .product-info {
            margin: 20px 0;
            padding: 15px;
            background-color: #f5f5f5;
            border-radius: 5px;
          }
          .subscription-notice {
            background-color: #e8f4fd;
            border-left: 4px solid #2196F3;
            padding: 10px;
            margin: 20px 0;
            text-align: left;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="loader"></div>
          <h3>Subscription Payment</h3>
          <p>Please wait while we connect to the payment service...</p>
          
          <div class="product-info">
            <p><strong>${widget.productName}</strong></p>
            <p>Monthly subscription: ₩${widget.amount}</p>
            <p>Order ID: ${_orderId}</p>
          </div>

          <div class="subscription-notice">
            <p><strong>Subscription Notice:</strong></p>
            <p>• You will be charged ₩${widget.amount} monthly</p>
            <p>• You can cancel your subscription anytime</p>
            <p>• First payment will be charged immediately</p>
          </div>

          <div id="resultMsg"></div>
          
          <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>
          <script src="${baseUrl}/js/v1/payment.js"></script>
          <script>
            // Display message function
            function showMessage(message, isError) {
              document.getElementById('resultMsg').innerHTML = 
                '<p style="color:' + (isError ? 'red' : 'green') + '">' + message + '</p>';
            }
            
            // Initialize payment when page loads
            window.addEventListener('load', function() {
              showMessage("Preparing subscription payment...", false);
              
              setTimeout(function() {
                showMessage("Opening payment window...", false);
                
                try {
                  // Create payment configuration for subscription
                  var paymentObj = {
                    clientKey: "${clientKey}",
                    PCD_PAY_TYPE: "card",
                    PCD_PAY_WORK: "AUTH", // AUTH for billing key only
                    PCD_CARD_VER: "01", // Required for recurring payments
                    PCD_PAY_GOODS: "${widget.productName} Monthly Subscription",
                    PCD_PAY_TOTAL: ${widget.amount},
                    PCD_PAY_OID: "${_orderId}",
                    PCD_RST_URL: "${callbackUrl}",
                    PCD_PAYER_NAME: "Subscriber",
                    PCD_PAYER_NO: "${userId}" // Pass user ID for subscription tracking
                  };
                  
                  // Define callback for handling result
                  function handlePaymentResult(params) {
                    console.log("Payment result:", params);
                    
                    if (params.PCD_PAY_RESULT === 'success') {
                      showMessage("Card registered successfully! Setting up your subscription...", false);
                      // Redirect to success URL with billing key
                      setTimeout(function() {
                        window.location.href = "paymentresult://success?orderId=${_orderId}&billingKey=" + encodeURIComponent(params.PCD_PAYER_ID);
                      }, 1500);
                    } else {
                      showMessage("Subscription setup failed: " + params.PCD_PAY_MSG, true);
                      // Redirect to failure URL
                      setTimeout(function() {
                        window.location.href = "paymentresult://failed?message=" + encodeURIComponent(params.PCD_PAY_MSG);
                      }, 1500);
                    }
                  }
                  
                  // Set callback function
                  paymentObj.callbackFunction = handlePaymentResult;
                  
                  // Open the payment window
                  PaypleCpayAuthCheck(paymentObj);
                  
                  showMessage("Payment window opening...", false);
                } catch(err) {
                  console.error("Error opening payment window:", err);
                  showMessage("Error: " + err.message, true);
                }
              }, 1000);
            });
          </script>
        </div>
      </body>
    </html>
    ''';
  }

  void _startFirestoreListener() {
    if (_isListeningForResult) return;

    _isListeningForResult = true;
    print('Starting Firestore listener for order ID: $_orderId');

    FirebaseFirestore.instance
        .collection('paymentResults')
        .doc(_orderId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              print('Payment result received in Firestore: ${snapshot.data()}');

              final status = snapshot.data()?['status'];

              if (status == 'success') {
                // Payment successful - return to previous screen with success result
                final billingKey = snapshot.data()?['billingKey'];
                Navigator.of(context).pop({
                  'success': true,
                  'orderId': _orderId,
                  'billingKey': billingKey,
                  'isSubscription': true,
                });
              } else if (status == 'failed') {
                // Payment failed - show error message
                setState(() {
                  _paymentError =
                      snapshot.data()?['failReason'] ?? 'Payment failed';
                });
              }
            }
          },
          onError: (error) {
            print('Error listening to Firestore: $error');
          },
        );
  }

  void _handlePaymentResult(String url) {
    print('Handling payment result URL: $url');

    if (url.contains('success')) {
      // Extract the billing key if available
      String? billingKey;
      try {
        final uri = Uri.parse(url);
        billingKey = uri.queryParameters['billingKey'];
      } catch (e) {
        print('Error parsing URL: $e');
      }

      Navigator.of(context).pop({
        'success': true,
        'orderId': _orderId,
        'billingKey': billingKey,
        'isSubscription': true,
      });
    } else if (url.contains('failed')) {
      // Extract error message from URL
      try {
        final uri = Uri.parse(url);
        final errorMessage = uri.queryParameters['message'] ?? 'Payment failed';

        setState(() {
          _paymentError = Uri.decodeComponent(errorMessage);
        });
      } catch (e) {
        setState(() {
          _paymentError = 'Payment failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Subscription'), elevation: 0),
      body:
          _paymentError != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 64),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        _paymentError!,
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed:
                          () => Navigator.of(context).pop({'success': false}),
                      child: Text('Go Back'),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    Container(
                      color: Colors.white.withOpacity(0.8),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Setting up subscription...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}
