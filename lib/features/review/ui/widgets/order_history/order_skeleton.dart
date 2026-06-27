import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ---------------------------------------------------------------------------
// OrderSkeletonList — full page shimmer shown on first load
// ---------------------------------------------------------------------------

/// Displays a list of shimmer skeleton cards while order data is loading.
class OrderSkeletonList extends StatelessWidget {
  const OrderSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => Divider(color: ColorsManager.primary300),
        itemBuilder: (_, index) => ShimmerCard(index: index),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ShimmerCard — each skeleton item animates with a staggered delay
// ---------------------------------------------------------------------------

/// A single shimmer skeleton card with animated gradient.
class ShimmerCard extends StatefulWidget {
  const ShimmerCard({super.key, required this.index});
  final int index;

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Stagger each card's shimmer phase slightly
    _shimmer = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, _) {
          final gradient = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFE8E8E8),
              Color(0xFFF5F5F5),
              Color(0xFFE8E8E8),
            ],
            stops: [
              (_shimmer.value - 0.5).clamp(0.0, 1.0),
              _shimmer.value.clamp(0.0, 1.0),
              (_shimmer.value + 0.5).clamp(0.0, 1.0),
            ],
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image placeholder
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: gradient,
                ),
              ),
              horizontalSpace(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    verticalSpace(6),
                    // Seller name line
                    ShimmerLine(gradient: gradient, width: 80.w, height: 11.h),
                    verticalSpace(8),
                    // Product name line
                    ShimmerLine(
                      gradient: gradient,
                      width: 160.w,
                      height: 13.h,
                    ),
                    verticalSpace(8),
                    // Price line
                    ShimmerLine(
                      gradient: gradient,
                      width: 100.w,
                      height: 11.h,
                    ),
                    verticalSpace(14),
                    // Buttons row
                    Row(
                      children: [
                        ShimmerLine(
                          gradient: gradient,
                          width: 72.w,
                          height: 28.h,
                          radius: 6,
                        ),
                        horizontalSpace(8),
                        ShimmerLine(
                          gradient: gradient,
                          width: 100.w,
                          height: 28.h,
                          radius: 6,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ShimmerLine — a single rectangular shimmer placeholder
// ---------------------------------------------------------------------------

/// A simple gradient-animated line used as a shimmer placeholder.
class ShimmerLine extends StatelessWidget {
  const ShimmerLine({
    super.key,
    required this.gradient,
    required this.width,
    required this.height,
    this.radius = 4,
  });

  final LinearGradient gradient;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OrderCardSkeleton — per-item skeleton used while product data loads
// ---------------------------------------------------------------------------

/// A single card skeleton shown while an individual product's data loads.
class OrderCardSkeleton extends StatefulWidget {
  const OrderCardSkeleton({super.key});

  @override
  State<OrderCardSkeleton> createState() => _OrderCardSkeletonState();
}

class _OrderCardSkeletonState extends State<OrderCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmer = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, _) {
          final gradient = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFE8E8E8),
              Color(0xFFF5F5F5),
              Color(0xFFE8E8E8),
            ],
            stops: [
              (_shimmer.value - 0.5).clamp(0.0, 1.0),
              _shimmer.value.clamp(0.0, 1.0),
              (_shimmer.value + 0.5).clamp(0.0, 1.0),
            ],
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: gradient,
                ),
              ),
              horizontalSpace(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    verticalSpace(6),
                    ShimmerLine(gradient: gradient, width: 80.w, height: 11.h),
                    verticalSpace(8),
                    ShimmerLine(
                      gradient: gradient,
                      width: 160.w,
                      height: 13.h,
                    ),
                    verticalSpace(8),
                    ShimmerLine(
                      gradient: gradient,
                      width: 100.w,
                      height: 11.h,
                    ),
                    verticalSpace(14),
                    Row(
                      children: [
                        ShimmerLine(
                          gradient: gradient,
                          width: 72.w,
                          height: 28.h,
                          radius: 6,
                        ),
                        horizontalSpace(8),
                        ShimmerLine(
                          gradient: gradient,
                          width: 100.w,
                          height: 28.h,
                          radius: 6,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
