
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/listing.dart';

/// Саҳифаи харид ва фармоиши доставка.
/// Пардохт ва курьер ҳанӯз ба провайдери беруна пайваст нестанд.
class MarketplaceOrderScreen extends StatefulWidget {
  const MarketplaceOrderScreen({
    super.key,
    required this.listing,
  });

  final Listing listing;

  @override
  State<MarketplaceOrderScreen> createState() =>
      _MarketplaceOrderScreenState();
}

class _MarketplaceOrderScreenState
    extends State<MarketplaceOrderScreen> {
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  int _quantity = 1;
  String _delivery = 'delivery';
  bool _saving = false;

  num get _price => widget.listing.price ?? 0;
  num get _subtotal => _price * _quantity;

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _show('Барои фармоиш аввал ба ҳисоб ворид шав.');
      return;
    }

    if (widget.listing.ownerId == user.uid) {
      _show('Моли худатро фармоиш дода наметавонӣ.');
      return;
    }

    if (_price <= 0) {
      _show('Фурӯшанда ҳоло нархи молро нишон надодааст.');
      return;
    }

    if (_phone.text.trim().isEmpty) {
      _show('Рақами телефонатро навис.');
      return;
    }

    if (_delivery == 'delivery' &&
        _address.text.trim().isEmpty) {
      _show('Суроғаи доставкаро навис.');
      return;
    }

    setState(() => _saving = true);

    try {
      final db = FirebaseFirestore.instance;
      final order = db.collection('orders').doc();

      // Номи коллексия: orders.
      // Доставка то мувофиқаи фурӯшанда нархи муайян надорад.
      await order.set({
        'listingId': widget.listing.id,
        'listingTitle': widget.listing.title,
        'listingImage': widget.listing.coverImage,
        'buyerId': user.uid,
        'sellerId': widget.listing.ownerId,
        'quantity': _quantity,
        'unitPrice': _price,
        'subtotal': _subtotal,
        'currency': 'TJS',
        'deliveryMethod': _delivery,
        'deliveryAddress': _delivery == 'delivery'
            ? _address.text.trim()
            : '',
        'buyerPhone': _phone.text.trim(),
        'note': _note.text.trim(),
        'deliveryFee': null,
        'total': _subtotal,
        'status': 'pending_seller_confirmation',
        'deliveryStatus': _delivery == 'delivery'
            ? 'awaiting_seller_quote'
            : 'pickup',
        'paymentStatus': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Фармоиш сабт шуд'),
          content: const Text(
            'Фурӯшанда бояд фармоиш ва арзиши доставкаро тасдиқ кунад. '
            'Ҳоло пардохт ё фиристодани мол тасдиқ нашудааст.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Фаҳмо'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _show(
          'Фармоиш сабт нашуд. Қоидаҳои Firestore ва пайвасти Firebase-ро санҷ.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.listing;

    return Scaffold(
      appBar: AppBar(title: const Text('Харид ва доставка')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (item.coverImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                item.coverImage!,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(height: 80),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_price.toStringAsFixed(0)} сомонӣ × $_quantity',
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(height: 28),

          const Text(
            'Миқдори мол',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$_quantity',
                style: const TextStyle(fontSize: 18),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Text(
            'Тарзи гирифтани мол',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          RadioListTile<String>(
            value: 'delivery',
            groupValue: _delivery,
            title: const Text('Доставка'),
            subtitle: const Text(
              'Арзиши расониданро бо фурӯшанда мувофиқа кун.',
            ),
            onChanged: (v) => setState(() => _delivery = v!),
          ),
          RadioListTile<String>(
            value: 'pickup',
            groupValue: _delivery,
            title: const Text('Худам мегирам'),
            subtitle: const Text('Ҷойи гирифтани молро мувофиқа кун.'),
            onChanged: (v) => setState(() => _delivery = v!),
          ),

          if (_delivery == 'delivery') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Суроғаи доставка',
                hintText: 'Шаҳр, кӯча, хона',
                border: OutlineInputBorder(),
              ),
            ),
          ],

          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Рақами телефон',
              hintText: '+992...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Шарҳ ба фурӯшанда (ихтиёрӣ)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Ҳисоби фармоиш',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _summaryRow('Нархи мол', _subtotal),
          _summaryRow(
            'Доставка',
            null,
            extra: _delivery == 'delivery'
                ? 'Бо фурӯшанда мувофиқа мешавад'
                : 'Гирифтан аз ҷониби харидор',
          ),
          const Divider(height: 24),
          _summaryRow('Ҷамъ (бе доставка)', _subtotal, bold: true),

          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _placeOrder,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Сабти фармоиш'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Пардохти онлайн ҳоло пайваст нест. '
            'Фармоиш то тасдиқи фурӯшанда интизор мемонад.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String title,
    num? amount, {
    String? extra,
    bool bold = false,
  }) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(title, style: style)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              extra ?? '${amount!.toStringAsFixed(0)} сомонӣ',
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
