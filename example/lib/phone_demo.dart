//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// A shopping list in a phone, and a "Show me" button that plays a script on
// it: fingertips tap, hold, drag, swipe, scroll, slide, type and move between
// pages, all for real. Every place the script names is a KeyAnchor.

import 'package:flutter/material.dart';
import 'package:key_flow/key_flow.dart';

/// The page holding the phone and its "Show me" button.
class PhoneDemo extends StatefulWidget {
  /// Whether to play the script as soon as the page shows.
  final bool playAtStart;

  const PhoneDemo({super.key, this.playAtStart = false});

  @override
  State<PhoneDemo> createState() => _PhoneDemoState();
}

class _PhoneDemoState extends State<PhoneDemo> {
  final _shop = _Shop();
  final _phone = GlobalKey<NavigatorState>();
  var _ended = '';

  @override
  void initState() {
    super.initState();
    if (widget.playAtStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void dispose() {
    _shop.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    _shop.reset();
    _phone.currentState!.popUntil((route) => route.isFirst);
    setState(() => _ended = '');
    final end = await KeyFlow.of(context).play(_script);
    if (mounted) setState(() => _ended = 'The demo ${end.name}.');
  }

  static const _script = KeyScript(
    cursors: [
      KeyCursor(
        id: 'ana',
        kind: KeyCursorKind.touch,
        label: 'Ana',
        color: Color(0xFFE91E63),
      ),
      KeyCursor(
        id: 'ben',
        kind: KeyCursorKind.touch,
        label: 'Ben',
        color: Color(0xFF00897B),
      ),
    ],
    steps: [
      KeyStep.caption('Tap to tick things off'),
      KeyStep.tap('item-milk/tick'),
      KeyStep.tap('item-eggs/tick'),
      KeyStep.caption('Hold a row for more'),
      KeyStep.hold('item-bread'),
      KeyStep.tap('to-top'),
      KeyStep.caption('Drag the handle to reorder'),
      KeyStep.drag('item-apples/handle', by: Offset(0, 150)),
      KeyStep.caption('Swipe left to remove'),
      KeyStep.drag('item-tea', by: Offset(-260, 0)),
      KeyStep.caption('Swipe up to scroll'),
      KeyStep.drag('list', by: Offset(0, -380)),
      KeyStep.caption('It swipes until it finds what it needs'),
      KeyStep.scrollTo('item-soap', within: 'list'),
      KeyStep.tap('item-soap/tick'),
      KeyStep.caption('Open an item'),
      KeyStep.scrollTo('item-cheese', within: 'list'),
      KeyStep.tap('item-cheese'),
      KeyStep.caption('Slide to choose how many'),
      KeyStep.drag('amount', by: Offset(90, 0)),
      KeyStep.type('The mature one', at: 'note'),
      KeyStep.tap('back'),
      KeyStep.caption('Switch tabs'),
      KeyStep.tap('tab-basket'),
      KeyStep.wait(Duration(milliseconds: 1200)),
      KeyStep.tap('tab-list'),
      KeyStep.caption('Two people, one list'),
      KeyStep.together([
        KeyStep.tap('item-rice/tick', cursor: 'ana'),
        KeyStep.tap('item-coffee/tick', cursor: 'ben'),
      ]),
      KeyStep.caption('Press "Show me" to watch again'),
      KeyStep.wait(Duration(milliseconds: 1500)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final keys = KeyFlow.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const KeyAnchor(id: 'demo-back', child: BackButton()),
        title: const Text('Phone demo'),
        actions: [
          if (_ended.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(_ended),
            ),
          const RecordButtons(),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: keys,
            builder: (context, _) => KeyAnchor(
              id: 'show-me',
              child: FilledButton.icon(
                onPressed: keys.isPlaying ? null : _play,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Show me'),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AspectRatio(
            aspectRatio: 9 / 17,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade600, width: 6),
                borderRadius: BorderRadius.circular(36),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Navigator(
                  key: _phone,
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => _HomePage(shop: _shop),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// "Record" (or "Stop") and "Play the recording": the controls of the
/// example's `help.record` and `help.replay` commands.
class RecordButtons extends StatelessWidget {
  const RecordButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final keys = KeyFlow.of(context);
    return ListenableBuilder(
      listenable: keys,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KeyHint(
            command: 'help.record',
            child: TextButton.icon(
              onPressed: keys.callbackFor(context, 'help.record'),
              icon: Icon(
                keys.recording == null ? Icons.fiber_manual_record : Icons.stop,
                color: Colors.red,
              ),
              label: Text(keys.recording == null ? 'Record' : 'Stop'),
            ),
          ),
          KeyHint(
            command: 'help.replay',
            child: TextButton.icon(
              onPressed: keys.callbackFor(context, 'help.replay'),
              icon: const Icon(Icons.replay),
              label: const Text('Play the recording'),
            ),
          ),
        ],
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _Item {
  final String id;
  final String name;
  var done = false;
  var amount = 1;
  var note = '';

  _Item(this.name) : id = name.toLowerCase().replaceAll(' ', '-');
}

/// The list, shared by the phone's pages.
class _Shop extends ChangeNotifier {
  static const _names = [
    'Milk', 'Eggs', 'Bread', 'Apples', 'Cheese', 'Rice', 'Tea', 'Coffee', //
    'Butter', 'Pasta', 'Tomatoes', 'Onions', 'Garlic', 'Lemons', 'Yogurt',
    'Honey', 'Oats', 'Carrots', 'Potatoes', 'Spinach', 'Bananas', 'Beans',
    'Flour', 'Sugar', 'Salt', 'Pepper', 'Olive oil', 'Soap', 'Toothpaste',
  ];

  var items = [for (final name in _names) _Item(name)];
  var tab = 0;

  void reset() {
    items = [for (final name in _names) _Item(name)];
    tab = 0;
    notifyListeners();
  }

  void changed() => notifyListeners();

  void toggle(_Item item) {
    item.done = !item.done;
    notifyListeners();
  }

  void remove(_Item item) {
    items.remove(item);
    notifyListeners();
  }

  void toTop(_Item item) {
    items
      ..remove(item)
      ..insert(0, item);
    notifyListeners();
  }

  void reorder(int from, int to) {
    final item = items.removeAt(from);
    items.insert(to > from ? to - 1 : to, item);
    notifyListeners();
  }

  void showTab(int index) {
    tab = index;
    notifyListeners();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _HomePage extends StatelessWidget {
  final _Shop shop;

  const _HomePage({required this.shop});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: shop,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Shopping')),
        body: IndexedStack(
          index: shop.tab,
          children: [
            _ListTab(shop: shop),
            _BasketTab(shop: shop),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: shop.tab,
          onDestinationSelected: shop.showTab,
          destinations: const [
            KeyAnchor(
              id: 'tab-list',
              child: NavigationDestination(
                icon: Icon(Icons.list),
                label: 'List',
              ),
            ),
            KeyAnchor(
              id: 'tab-basket',
              child: NavigationDestination(
                icon: Icon(Icons.shopping_basket_outlined),
                label: 'Basket',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  final _Shop shop;

  const _ListTab({required this.shop});

  @override
  Widget build(BuildContext context) {
    return KeyAnchor(
      id: 'list',
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: shop.items.length,
        // onReorderItem needs Flutter 3.41; the example runs on 3.32 and on.
        // ignore: deprecated_member_use
        onReorder: shop.reorder,
        itemBuilder: (context, index) {
          final item = shop.items[index];
          return KeyAnchor(
            key: ValueKey(item.id),
            id: 'item-${item.id}',
            label: item.name,
            child: Dismissible(
              key: ValueKey('swipe-${item.id}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => shop.remove(item),
              background: Container(
                color: Colors.red.shade400,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Material(
                child: ListTile(
                  leading: KeyAnchor(
                    id: 'tick',
                    child: Checkbox(
                      value: item.done,
                      onChanged: (_) => shop.toggle(item),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: item.done
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                          )
                        : null,
                  ),
                  subtitle: item.amount > 1 ? Text('× ${item.amount}') : null,
                  trailing: KeyAnchor(
                    id: 'handle',
                    child: ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _ItemPage(shop: shop, item: item),
                    ),
                  ),
                  onLongPress: () => _showMenu(context, item),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMenu(BuildContext context, _Item item) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(item.name)),
            KeyAnchor(
              id: 'to-top',
              child: ListTile(
                leading: const Icon(Icons.vertical_align_top),
                title: const Text('Move to top'),
                onTap: () {
                  shop.toTop(item);
                  Navigator.pop(context);
                },
              ),
            ),
            KeyAnchor(
              id: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () {
                  shop.remove(item);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasketTab extends StatelessWidget {
  final _Shop shop;

  const _BasketTab({required this.shop});

  @override
  Widget build(BuildContext context) {
    final done = [
      for (final item in shop.items)
        if (item.done) item,
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${done.length} of ${shop.items.length} in the basket',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final item in done)
          ListTile(leading: const Icon(Icons.check), title: Text(item.name)),
      ],
    );
  }
}

class _ItemPage extends StatefulWidget {
  final _Shop shop;
  final _Item item;

  const _ItemPage({required this.shop, required this.item});

  @override
  State<_ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<_ItemPage> {
  late final _note = TextEditingController(text: widget.item.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final item = widget.item;
    return ListenableBuilder(
      listenable: shop,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: const KeyAnchor(id: 'back', child: BackButton()),
          title: Text(item.name),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('How many: ${item.amount}'),
            KeyAnchor(
              id: 'amount',
              child: Slider(
                min: 1,
                max: 12,
                divisions: 11,
                value: item.amount.toDouble(),
                label: '${item.amount}',
                onChanged: (value) {
                  item.amount = value.round();
                  shop.changed();
                },
              ),
            ),
            const SizedBox(height: 16),
            KeyAnchor(
              id: 'note',
              child: TextField(
                controller: _note,
                onChanged: (text) => item.note = text,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
