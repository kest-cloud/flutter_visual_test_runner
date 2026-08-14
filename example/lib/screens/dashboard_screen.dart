import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({super.key, this.userName = 'Alex'});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _cartCount = 0;
  final Set<int> _addedItems = {};

  void _addToCart(int index) {
    setState(() {
      _cartCount++;
      _addedItems.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store Dashboard',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            Text(
              'Welcome back, ${widget.userName}!',
              style: const TextStyle(fontSize: 11.0, color: Color(0xFF00E5FF), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          // Cart Icon with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                key: const Key('cart_icon_btn'),
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () {},
              ),
              if (_cartCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5252),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartCount',
                      key: const Key('cart_badge'),
                      style: const TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Metrics Cards Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Revenue', '\$12,450', const Color(0xFF00E5FF), Icons.trending_up),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: _buildStatCard('Orders', '128', const Color(0xFF00E676), Icons.shopping_bag_outlined),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: _buildStatCard('Visitors', '3.2k', const Color(0xFF7C4DFF), Icons.people_outline),
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          // Catalog Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Catalog',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                '20 items available',
                style: TextStyle(fontSize: 11.0, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Product List
          ...List.generate(20, (index) {
            final itemNumber = index + 1;
            final isAdded = _addedItems.contains(itemNumber);

            return Container(
              margin: const EdgeInsets.only(bottom: 10.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        '#$itemNumber',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Item #$itemNumber',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '\$${(itemNumber * 19.99).toStringAsFixed(2)} • High Quality',
                          style: const TextStyle(fontSize: 11.0, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    key: Key('add_btn_$itemNumber'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdded ? const Color(0xFF00E676) : const Color(0xFF00E5FF),
                      foregroundColor: const Color(0xFF090D16),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    onPressed: () => _addToCart(itemNumber),
                    child: Text(
                      isAdded ? 'Added ✓' : 'Add to Cart',
                      style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.0, color: color),
          const SizedBox(height: 6.0),
          Text(
            value,
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2.0),
          Text(
            label,
            style: const TextStyle(fontSize: 10.0, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
