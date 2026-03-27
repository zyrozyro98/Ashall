import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shape;

  const ShimmerLoading.rectangular({super.key, this.width = double.infinity, required this.height})
    : shape = const RoundedRectangleBorder();

  const ShimmerLoading.circular({super.key, required this.width, required this.height, this.shape = const CircleBorder()});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(color: Colors.grey, shape: shape),
      ),
    );
  }
}

class ProductSkeleton extends StatelessWidget {
  const ProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: ShimmerLoading.rectangular(height: 100)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading.rectangular(height: 20, width: 80),
                const SizedBox(height: 10),
                const ShimmerLoading.rectangular(height: 15, width: 60),
                const SizedBox(height: 15),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const ShimmerLoading.rectangular(height: 20, width: 40),
                  const ShimmerLoading.circular(width: 25, height: 25),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
