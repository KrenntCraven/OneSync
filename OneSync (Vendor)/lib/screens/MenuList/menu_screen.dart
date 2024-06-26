import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:onesync/models/models.dart';
import 'package:onesync/navigation.dart';
import 'package:onesync/screens/MenuList/product_details_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

// Static Data for Menu Items
class _MenuScreenState extends State<MenuScreen> {
  List<Reference> uploadedFiles = [];
  List<MenuItem> _menuItems = [];
  List<MenuItem> _displayedMenuItems = [];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> displayedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMenuItems() async {
    try {
      String userID = FirebaseAuth.instance.currentUser!.uid;
      var snapshot = await FirebaseFirestore.instance
          .collection('Menu')
          .doc(userID)
          .collection('vendorProducts')
          .get();

      print('Number of documents fetched: ${snapshot.docs.length}');
      if (snapshot.docs.isNotEmpty) {
        var menuItems =
            snapshot.docs.map((doc) => MenuItem.fromSnapshot(doc)).toList();
        setState(() {
          _menuItems = menuItems;
          _displayedMenuItems = menuItems;
        });
      } else {
        setState(() {
          _menuItems = [];
          _displayedMenuItems = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No menu items found')),
        );
      }
    } catch (e) {
      print(
          'Error fetching menu items: $e'); // It's good to print the error to the console for debugging.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching menu items: $e')),
      );
    }
  }

  String _selectedLabel = 'All';

  // Filter Function on Search Bar
  void _filterMenuItems(String query) {
    setState(() {
      _selectedLabel = query;
      _displayedMenuItems = _menuItems.where((item) {
        String lowerCaseQuery = query.toLowerCase();
        bool matchesCategory =
            item.category.toLowerCase().contains(lowerCaseQuery);
        bool matchesName = item.name.toLowerCase().contains(lowerCaseQuery);

        return lowerCaseQuery == 'all' || matchesCategory || matchesName;
      }).toList();
    });
  }

  // Add Product
  void _handleAddProduct() {
    Navigator.of(context).pushNamed('/addProduct');
  }

  // Widget for Add Product Button
  Widget _addProductButton() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: SizedBox(
        width: 25,
        height: 25,
        child: Ink(
          decoration: ShapeDecoration(
            color: const Color(0xFF4196F0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.24),
            ),
          ),
          child: IconButton(
            onPressed: _handleAddProduct,
            icon: const Icon(Icons.add, color: Colors.white),
            padding: EdgeInsets.zero,
            iconSize: 20,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }

  // Search Bar Widget
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 40.0,
        child: TextField(
          controller: _searchController,
          onChanged: _filterMenuItems,
          decoration: _searchBarDecoration(),
        ),
      ),
    );
  }

  // Search Bar Decoration
  InputDecoration _searchBarDecoration() {
    return const InputDecoration(
      contentPadding: EdgeInsets.all(8.0),
      hintText: 'Title',
      prefixIcon: Icon(Icons.search),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF717171)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF717171)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF717171)),
      ),
    );
  }

  // Filter Category Widget
  Widget _selectedLabelCategory(String label) {
    return TextButton(
      onPressed: () => _filterMenuItems(label),
      style: TextButton.styleFrom(
        foregroundColor: _selectedLabel == label ? Colors.white : Colors.blue,
        backgroundColor: _selectedLabel == label ? Colors.blue : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: _selectedLabel == label
            ? null
            : const BorderSide(color: Colors.blue),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

// Filter Category Function
  Widget _filterCategory() {
    var labels = ['All', 'Main Dishes', 'Snacks', 'Beverages'];
    return Container(
      margin: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0),
      child: SizedBox(
        height: 35,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: labels.map((label) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4.0), // Add space between each button
              child: _selectedLabelCategory(label),
            );
          }).toList(),
        ),
      ),
    );
  }

// Menu List Widget
  Widget _menuList(BuildContext context, MenuItem item) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: item),
          ),
        );
      },
      child: Container(
        width: 110,
        height: 115,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 0.26,
              color: Color(0x514D4D4D),
            ),
            borderRadius: BorderRadius.circular(5.23),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 80,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                      item.imageUrl ?? "https://via.placeholder.com/110x78"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2.61),
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xFF212121),
                        fontSize: 10,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '${item.stock} left',
                          style: const TextStyle(
                            color: Color(0xFF717171),
                            fontSize: 9,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '₱ ${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF0663C7),
                            fontSize: 10,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Grid View Widget of Menu Items
  Widget _buildMenuGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Change cross axis count as needed
            crossAxisSpacing: 6.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.88,
          ),
          itemCount:
              _displayedMenuItems.length + 1, // +1 for the 'Add Product' card
          itemBuilder: (context, index) {
            if (index == 0) {
              return DottedBorder(
                color: const Color(0xFF4196F0),
                dashPattern: const [6, 3],
                strokeWidth: 1,
                radius: const Radius.circular(5.23),
                borderType: BorderType.RRect,
                child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Card(
                      color: const Color(0xFFEEF5FC),
                      elevation: 0,
                      child: IconButton(
                        onPressed: _handleAddProduct,
                        iconSize:
                            30.0, // This property might not be necessary depending on your layout intentions.
                        color: Colors.white,
                        icon: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 20.58,
                              height: 20.58,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4196F0),
                                borderRadius: BorderRadius.circular(6.24),
                              ),
                              child: const Icon(Icons.add, size: 12.12),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Add Product',
                                style: TextStyle(
                                  color: Color(0xFF4196F0),
                                  fontSize: 9.14,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )),
              );
            } else {
              return _menuList(context, _displayedMenuItems[index - 1]);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu',
            style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 28,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                height: 0.05)),

        // Add Product Button Header
        actions: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: SizedBox(
              width: 25,
              height: 25,
              child: Ink(
                decoration: ShapeDecoration(
                  color: const Color(0xFF4196F0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.24),
                  ),
                ),
                child: IconButton(
                  onPressed: _handleAddProduct,
                  icon: const Icon(Icons.add, color: Colors.white),
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
        ],

        /* Delete Product Button Header
        actions: [
          IconButton(
          onPressed: _handleAddProduct,
          icon: const Icon(Icons.add),
          ),
        ], */
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _filterCategory(),
          _buildMenuGrid(),
        ],
      ),
      bottomNavigationBar: const Navigation(),
    );
  }
}
