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

import 'dart:async';

import 'package:df_pod/df_pod.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// How long a partial sequence is remembered before resetting.
const _kDefaultSequenceTimeout = Duration(milliseconds: 1500);

/// A controller class for managing key events and callbacks.
class KeyFlowControl {
  //
  //
  //

  /// The registry holding all callbacks for this controller.
  CallbackRegistry registry;

  Map<Key, TContextCallback> get callbacks => registry.callbacks;
  set callbacks(Map<Key, TContextCallback> value) => registry.callbacks = value;

  /// Notifier for mappings of action keys to activator sequences.
  final mappingsNotifier = Pod<TMappingsMap>({});

  /// Public getter for mappings.
  TMappingsMap get mappings => mappingsNotifier.getValue();

  /// Callback invoked when focus changes.
  final TOnFocusChangeCallback? onFocusChange;

  /// How long to remember a partial sequence (e.g. `g` waiting for `i`)
  /// before resetting. Defaults to 1.5s, matching Superhuman.
  final Duration sequenceTimeout;

  /// If true (the default), single-key activators that have no modifiers
  /// are suppressed while focus is on an editable text field. Chorded and
  /// modifier-bearing activators always fire. Multi-step sequences are
  /// always allowed.
  final bool suppressBareKeysInTextFields;

  /// The focus node associated with this controller.
  @protected
  FocusNode? $focusNode;

  /// Public getter for the focus node.
  FocusNode? get focusNode => $focusNode;

  /// Current partial sequence buffer. Empty = no sequence in progress.
  final List<KeyEvent> _seqBuffer = [];

  Timer? _seqTimer;

  //
  //
  //

  KeyFlowControl({
    TMappingsMap? mappings,
    Map<Key, TContextCallback>? callbacks,
    this.onFocusChange,
    this.sequenceTimeout = _kDefaultSequenceTimeout,
    this.suppressBareKeysInTextFields = true,
  }) : registry = CallbackRegistry._(
          callbacks == null ? {} : Map.of(callbacks),
        ) {
    mappingsNotifier.set(mappings == null ? {} : Map.of(mappings));
  }

  //
  //
  //

  /// Returns the activator sequence associated with the given [key].
  List<KeyActivator>? getCombination(Key key) => mappings[key];

  //
  //
  //

  /// Invokes the callback associated with the given [key], passing the
  /// current registry.
  void call(BuildContext context, Key key) => registry.call(context, key);

  //
  //
  //

  /// Resets the controller with new mappings and callbacks.
  ///
  /// The supplied maps are copied into mutable storage so [dispose] (and
  /// in-flight mutations like [addCombination]) can clear them later.
  KeyFlowControl reset({
    Map<Key, TContextCallback> callbacks = const {},
    TMappingsMap mappings = const {},
  }) {
    registry = CallbackRegistry._(Map.of(callbacks));
    mappingsNotifier.set(Map.of(mappings));
    _resetSequence();
    return this;
  }

  //
  //
  //

  /// Merges additional mappings and callbacks into the current controller.
  ///
  /// When [mappings] is empty, the underlying [mappingsNotifier] is not
  /// touched — this lets `merge(callbacks: {...})` be called from inside
  /// `build()` without triggering "setState during build" on downstream
  /// `PodBuilder` / `PodListBuilder` listeners.
  KeyFlowControl merge({
    Map<Key, TContextCallback> callbacks = const {},
    TMappingsMap mappings = const {},
  }) {
    registry.callbacks.addAll(callbacks);
    if (mappings.isNotEmpty) {
      mappingsNotifier.update((e) => e..addAll(mappings));
    }
    return this;
  }

  //
  //
  //

  /// Creates a new controller with optionally updated properties.
  KeyFlowControl copyWith({
    TMappingsMap? mappings,
    Map<Key, TContextCallback>? callbacks,
    TOnFocusChangeCallback? onFocusChange,
    Duration? sequenceTimeout,
    bool? suppressBareKeysInTextFields,
  }) {
    return KeyFlowControl(
      mappings: mappings ?? Map.of(mappingsNotifier.getValue()),
      callbacks: callbacks ?? Map.of(registry.callbacks),
      onFocusChange: onFocusChange ?? this.onFocusChange,
      sequenceTimeout: sequenceTimeout ?? this.sequenceTimeout,
      suppressBareKeysInTextFields:
          suppressBareKeysInTextFields ?? this.suppressBareKeysInTextFields,
    );
  }

  //
  //
  //

  /// Creates a new controller by merging this controller with another.
  KeyFlowControl mergeWith(KeyFlowControl other) {
    return KeyFlowControl(
      mappings: Map.of(mappingsNotifier.getValue())
        ..addAll(other.mappingsNotifier.getValue()),
      callbacks: Map.of(registry.callbacks)..addAll(other.registry.callbacks),
      sequenceTimeout: sequenceTimeout,
      suppressBareKeysInTextFields: suppressBareKeysInTextFields,
    );
  }

  //
  //
  //

  /// Checks if a combination exists for the given [key].
  bool hasCombination(Key key) => mappingsNotifier.getValue().containsKey(key);

  //
  //
  //

  /// Adds a new key combination and its associated callback.
  void addCombination(
    Key key,
    List<KeyActivator> combination,
    TContextCallback callback,
  ) {
    if (mappingsNotifier.getValue().containsKey(key)) {
      throw ArgumentError('Combination for key $key already exists');
    }
    mappingsNotifier.update((e) => e..[key] = combination);
    registry.callbacks[key] = callback;
  }

  //
  //
  //

  /// Replaces the combination for an existing [key].
  void replaceCombination(Key key, List<KeyActivator> combination) {
    if (!mappingsNotifier.getValue().containsKey(key)) {
      throw ArgumentError('No existing combination for key: $key');
    }
    mappingsNotifier.update((e) => e..[key] = combination);
  }

  //
  //
  //

  /// Replaces the callback for an existing [key].
  void replaceCallback(Key key, TContextCallback newCallback) {
    if (registry.callbacks.containsKey(key)) {
      registry.callbacks[key] = newCallback;
    } else {
      throw ArgumentError('No existing callback for key: $key');
    }
  }

  //
  //
  //

  /// Removes the combination and callback for the given [key].
  void removeCombination(Key key) {
    mappingsNotifier.update((e) => e..remove(key));
    registry.callbacks.remove(key);
  }

  //
  //
  //

  /// Remaps an existing [key] to a new combination.
  void remap(Key key, List<KeyActivator> newCombination) {
    if (!mappingsNotifier.getValue().containsKey(key)) {
      throw ArgumentError('No existing combination for key: $key');
    }
    mappingsNotifier.update((e) => e..[key] = newCombination);
  }

  //
  //
  //

  /// Returns a list of all key mappings as maps with 'key' and 'combination'.
  List<Map<String, dynamic>> getAllKeyMappings() {
    return mappingsNotifier
        .getValue()
        .entries
        .map((entry) => {'key': entry.key, 'combination': entry.value})
        .toList();
  }

  //
  //
  //

  /// Process a [KeyEvent] dispatched by the surrounding [Focus] tree.
  ///
  /// [context] should be a [BuildContext] above this control's
  /// [KeyFlowScope]; that lets us walk up the ancestor chain of
  /// [KeyFlowScope]s and merge every ancestor control's bindings in, so
  /// a deeply nested child can fire a shortcut declared at the root.
  /// This is the load-bearing piece — passing a context below the scope
  /// here resolves to *self* and silently breaks cross-scope navigation.
  KeyEventResult handleKeyEvent(
    BuildContext context,
    FocusNode node,
    KeyEvent event,
  ) {
    final isRepeat = event is KeyRepeatEvent;
    if (event is! KeyDownEvent && !isRepeat) {
      return KeyEventResult.ignored;
    }

    // Let a deeper focused KeyFlowFocus handle it first — its own
    // onKeyEvent has already run via Flutter's focus dispatch and would
    // have walked the full ancestor chain itself.
    if (node.children.isNotEmpty) {
      for (final child in node.children) {
        if (child.parent == node &&
            child.hasFocus &&
            child.onKeyEvent != null) {
          return KeyEventResult.ignored;
        }
      }
    }

    final allMappings = <Key, List<KeyActivator>>{};
    final allCallbacks = <Key, TContextCallback>{};
    // Walk the ancestor chain root-first so closer scopes override
    // farther ones, then layer self on top.
    for (final ancestor in _gatherAncestorControls(context).reversed) {
      allMappings.addAll(ancestor.mappingsNotifier.getValue());
      allCallbacks.addAll(ancestor.registry.callbacks);
    }
    allMappings.addAll(mappingsNotifier.getValue());
    allCallbacks.addAll(registry.callbacks);

    final inTextField = _isFocusInEditableText();

    // Repeat events take the fast path: they only match single-key
    // activators (so held arrows auto-repeat for navigation), and they
    // never advance a multi-step sequence buffer.
    if (isRepeat) {
      for (final entry in allMappings.entries) {
        final activators = entry.value;
        if (activators.length != 1) continue;
        if (inTextField &&
            suppressBareKeysInTextFields &&
            activators.first.isBare) {
          continue;
        }
        if (activators.first.matches(event)) {
          final tempRegistry = CallbackRegistry._(allCallbacks);
          tempRegistry.callbacks[entry.key]?.call(context, tempRegistry);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    final candidateBuffer = [..._seqBuffer, event];

    Key? firedKey;
    var anyPartialMatch = false;

    for (final entry in allMappings.entries) {
      final activators = entry.value;
      if (activators.isEmpty) continue;

      // Bare-key activators don't fire (or start) while focus is on a
      // text field. Both single chords and multi-step sequences are
      // suppressed — typing "g" into search shouldn't start the "g i"
      // sequence either.
      if (inTextField &&
          suppressBareKeysInTextFields &&
          activators.first.isBare) {
        continue;
      }

      if (candidateBuffer.length > activators.length) continue;

      var matches = true;
      for (var i = 0; i < candidateBuffer.length; i++) {
        if (!activators[i].matches(candidateBuffer[i])) {
          matches = false;
          break;
        }
      }
      if (!matches) continue;

      if (candidateBuffer.length == activators.length) {
        firedKey = entry.key;
        break;
      } else {
        anyPartialMatch = true;
      }
    }

    if (firedKey != null) {
      final tempRegistry = CallbackRegistry._(allCallbacks);
      tempRegistry.callbacks[firedKey]?.call(context, tempRegistry);
      _resetSequence();
      return KeyEventResult.handled;
    }

    if (anyPartialMatch) {
      _seqBuffer
        ..clear()
        ..addAll(candidateBuffer);
      _seqTimer?.cancel();
      _seqTimer = Timer(sequenceTimeout, _resetSequence);
      return KeyEventResult.handled;
    }

    _resetSequence();
    return KeyEventResult.ignored;
  }

  /// Collect every [KeyFlowControl] visible up the [KeyFlowScope] chain
  /// above [context], nearest-first. Excludes `this` and dedupes by
  /// identity in case the same singleton control is referenced from
  /// multiple ancestor scopes.
  List<KeyFlowControl> _gatherAncestorControls(BuildContext context) {
    final controls = <KeyFlowControl>[];
    final seen = <KeyFlowControl>{};
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is KeyFlowScope) {
        final c = widget.control;
        if (c != null && !identical(c, this) && seen.add(c)) {
          controls.add(c);
        }
      }
      return true;
    });
    return controls;
  }

  //
  //
  //

  /// True if the active focus is inside a TextField, EditableText, or any
  /// node that has been marked as a text input.
  static bool _isFocusInEditableText() {
    final node = FocusManager.instance.primaryFocus;
    if (node == null) return false;
    final ctx = node.context;
    if (ctx == null) return false;
    if (ctx.widget is EditableText) return true;
    if (ctx.findAncestorWidgetOfExactType<EditableText>() != null) return true;
    return false;
  }

  void _resetSequence() {
    _seqBuffer.clear();
    _seqTimer?.cancel();
    _seqTimer = null;
  }

  //
  //
  //

  void dispose() {
    _resetSequence();
    registry.callbacks.clear();
    mappingsNotifier.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class CallbackRegistry {
  @protected
  Map<Key, TContextCallback> callbacks;

  void call(BuildContext context, Key key) {
    final function = callbacks[key];
    assert(function != null, 'No callback found for key: $key');
    if (function != null) {
      function(context, this);
    }
  }

  CallbackRegistry._(this.callbacks);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TContextCallback = void Function(
  BuildContext context,
  CallbackRegistry registry,
);
typedef TCallbackMap = Map<Key, TContextCallback>;
typedef TMappingsMap = Map<Key, List<KeyActivator>>;
typedef TOnFocusChangeCallback = void Function(
  BuildContext context,
  bool hasFocus,
);
