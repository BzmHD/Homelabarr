import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';

class LunaColours {
  /// List of LunaSea colours in order that the should appear in a list.
  ///
  /// Use [byListIndex] to fetch the colour at the any index
  static const _LIST_COLOR_ICONS = [
    blue,
    accent,
    red,
    orange,
    purple,
    blueGrey,
  ];

  /// Core accent colour (Homelabarr crisp sage highlight)
  static const Color accent = Color(0xFF7FA88F);

  /// Core primary colour (background: deep dark olive-charcoal)
  static const Color primary = Color(0xFF14160F);

  /// Core secondary colour (appbar, cards, bottom bar: deep dark forest green)
  static const Color secondary = Color(0xFF1F2A24);

  static const Color blue = Color(0xFF7CA5B8);
  static const Color blueGrey = Color(0xFF4B4749);
  static const Color grey = Color(0xFFB2AEB6);
  static const Color orange = Color(0xFFD99B52);
  static const Color purple = Color(0xFFB095B8);
  static const Color red = Color(0xFFE05A5A);

  /// Shades of White (#E9E8ED mist off-white)
  static const Color white = Color(0xFFE9E8ED);
  static const Color white70 = Color(0xCCE9E8ED);
  static const Color white10 = Color(0x1FE9E8ED);

  /// Returns the correct colour for a graph by what layer it is on the graph canvas.
  Color byGraphLayer(int index) {
    switch (index) {
      case 0:
        return LunaColours.accent;
      case 1:
        return LunaColours.purple;
      case 2:
        return LunaColours.blue;
      default:
        return byListIndex(index);
    }
  }

  /// Return the correct colour for a list.
  /// If the index is greater than the list of colour's length, uses modulus to loop list.
  Color byListIndex(int index) {
    return _LIST_COLOR_ICONS[index % _LIST_COLOR_ICONS.length];
  }
}

extension LunaColor on Color {
  Color disabled([bool condition = true]) {
    if (condition) return this.withOpacity(LunaUI.OPACITY_DISABLED);
    return this;
  }

  Color enabled([bool condition = true]) {
    if (condition) return this;
    return this.withOpacity(LunaUI.OPACITY_DISABLED);
  }

  Color selected([bool condition = true]) {
    if (condition) return this.withOpacity(LunaUI.OPACITY_SELECTED);
    return this;
  }

  Color dimmed() => this.withOpacity(LunaUI.OPACITY_DIMMED);
}
