
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // URL de nuestra API de Spring Boot.
  // Esta dirección funciona cuando ejecutamos Flutter en Chrome.
  static const String baseUrl = 'http://localhost:8090';

  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts();
  }

  // Solicitar los productos al backend.
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final url = Uri.parse('$baseUrl/products');

    final response = await http.get(url).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar productos. '
        'Código HTTP: ${response.statusCode}',
      );
    }

    // Convertimos el JSON recibido en una lista de Dart.
    final dynamic data = jsonDecode(response.body);

    if (data is! List) {
      throw const FormatException(
        'La API no devolvió una lista de productos.',
      );
    }

    return data
        .map(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  // Volver a consultar la API.
  void reloadProducts() {
    setState(() {
      _productsFuture = fetchProducts();
    });
  }

  // Obtener el nombre de la categoría.
  String getCategory(Map<String, dynamic> product) {
    final category = product['category'];

    if (category is Map) {
      return category['category']?.toString() ??
          'Sin categoría';
    }

    return 'Sin categoría';
  }

  // Tarjeta de cada producto.
  Widget buildProductCard(Map<String, dynamic> product) {
    final String name =
        product['name']?.toString() ?? 'Sin nombre';

    final num price =
        product['price'] is num ? product['price'] as num : 0;

    final String stock =
        product['stock']?.toString() ?? '0';

    final String category = getCategory(product);

    final bool isActive = product['active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEEE8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre y estado.
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8F1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFFFF4081),
                    size: 27,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF252238),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF817C8A),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE6F7EC)
                        : const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF16803C)
                          : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Divider(
              color: Color(0xFFF1EDF3),
            ),

            const SizedBox(height: 16),

            // Precio.
            const Text(
              'PRECIO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Color(0xFF817C8A),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '\$${price.toStringAsFixed(2)} MXN',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF4081),
              ),
            ),

            const SizedBox(height: 20),

            // Existencias.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF635B73),
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Stock disponible: $stock',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF403A50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FC),
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF252238),
        title: const Text(
          'Productos de Spring Boot',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar productos',
            onPressed: reloadProducts,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          // Mientras esperamos la respuesta.
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFFF4081),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Cargando productos...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF817C8A),
                    ),
                  ),
                ],
              ),
            );
          }

          // Si hubo un error al conectarse.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 75,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No se pudieron cargar los productos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: reloadProducts,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFF4081),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];

          // Si el servidor responde con una lista vacía.
          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No hay productos disponibles',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          // Mostrar los productos recibidos.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 750,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  20,
                  18,
                  30,
                ),
                itemCount: products.length + 1,
                itemBuilder: (context, index) {
                  // Encabezado de la lista.
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 24,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nuestros productos',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF252238),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${products.length} productos '
                            'obtenidos de Spring Boot',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF817C8A),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final product = products[index - 1];

                  return buildProductCard(product);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
