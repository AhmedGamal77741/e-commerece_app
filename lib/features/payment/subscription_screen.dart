// lib/screens/subscription_management_screen.dart
import 'package:ecommerece_app/features/payment/payment_web_view_screen.dart';
import 'package:flutter/material.dart';
import 'payment_service.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  @override
  _SubscriptionManagementScreenState createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionData;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final subscriptionData = await _paymentService.getUserSubscription();
      setState(() {
        _subscriptionData = subscriptionData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading subscription: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    try {
      setState(() => _isCancelling = true);
      await _paymentService.cancelSubscription();
      _loadSubscriptionStatus(); // Refresh data
    } catch (e) {
      print('Cancel error: $e');
    } finally {
      setState(() => _isCancelling = false);
    }
  }

  Future<void> _startNewSubscription() async {
    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => SubscriptionWebViewScreen(
                amount: 1000,
                productName: 'Premium Subscription',
                planId: 'premium_monthly',
              ),
        ),
      );

      if (result != null && result['success'] == true) {
        _loadSubscriptionStatus(); // Refresh data
      }
    } catch (e) {
      print('Subscription error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveSubscription =
        _subscriptionData != null && _subscriptionData!['active'] == true;

    return Scaffold(
      appBar: AppBar(title: Text('Subscription')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadSubscriptionStatus,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    hasActiveSubscription
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color:
                                        hasActiveSubscription
                                            ? Colors.green
                                            : Colors.grey,
                                    size: 28,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    hasActiveSubscription
                                        ? 'Active Subscription'
                                        : 'No Active Subscription',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              if (hasActiveSubscription) ...[
                                SizedBox(height: 16),

                                // Billing key display (for testing)
                                Text(
                                  'Billing Key: ${_subscriptionData!['details']?['billingKey'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),

                                SizedBox(height: 20),

                                // Cancel button
                                ElevatedButton(
                                  onPressed:
                                      _isCancelling
                                          ? null
                                          : _cancelSubscription,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child:
                                      _isCancelling
                                          ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Text('Cancel Subscription'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Subscription options (if no active subscription)
                      if (!hasActiveSubscription) ...[
                        Text(
                          'Subscribe to Premium:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 12),

                        // Simple plan card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Premium Monthly',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 8),

                                Text(
                                  '₩1,000/month',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 16),

                                ElevatedButton(
                                  onPressed: _startNewSubscription,
                                  child: Text('Subscribe Now'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }
}
