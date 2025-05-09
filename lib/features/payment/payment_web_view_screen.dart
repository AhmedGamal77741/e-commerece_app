// payment_web_view_screen.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String url;
  const PaymentWebView({Key? key, required this.url}) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // No need to set WebView.platform for newer versions of webview_flutter

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          // spoof a real Chrome UA so Payple’s CDN won’t block
          ..setUserAgent(
            'Mozilla/5.0 (Linux; Android 10; Pixel 3) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/113.0.0.0 Mobile Safari/537.36',
          )
          // enable DOM storage & mixed content
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) => setState(() => _isLoading = true),
              onPageFinished: (_) => setState(() => _isLoading = false),
              onWebResourceError: (err) {
                debugPrint(
                  'WebView resource error: ${err.description} (code=${err.errorCode})',
                );
              },
              onNavigationRequest: (req) {
                if (req.url.startsWith('https://handlebillingcallback-')) {
                  final uri = Uri.parse(req.url);
                  final state = uri.queryParameters['PCD_PAY_STATE'];
                  final msg = uri.queryParameters['PCD_PAY_MSG'];
                  final ok = (state == '00');
                  Navigator.of(context).pop(ok);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) => setState(() => _isLoading = true),
              onPageFinished: (_) => setState(() => _isLoading = false),
              onWebResourceError: (err) {
                debugPrint(
                  'WebView resource error: ${err.description} (code=${err.errorCode})',
                );
              },
              onNavigationRequest: (req) {
                // catch the Payple callback redirect
                if (req.url.startsWith('https://handlebillingcallback-')) {
                  final uri = Uri.parse(req.url);
                  final state = uri.queryParameters['PCD_PAY_STATE'];
                  final msg = uri.queryParameters['PCD_PAY_MSG'];
                  // success when PCD_PAY_STATE == '00'
                  final ok = (state == '00');
                  Navigator.of(context).pop(ok);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          // load with Referer/Origin so script isn’t blocked
          ..loadRequest(
            Uri.parse(widget.url),
            headers: {
              'Referer': 'https://e-commerce-app-34fb2.web.app',
              'Origin': 'https://e-commerce-app-34fb2.web.app',
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
