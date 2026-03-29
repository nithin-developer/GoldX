import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class TradingViewEmbeddedChart extends StatefulWidget {
  const TradingViewEmbeddedChart({super.key, required this.symbol});

  final String symbol;

  @override
  State<TradingViewEmbeddedChart> createState() => _TradingViewEmbeddedChartState();
}

class _TradingViewEmbeddedChartState extends State<TradingViewEmbeddedChart> {
  static int _viewCounter = 0;

  late final String _viewType;

  @override
  void initState() {
    super.initState();

    _viewType = 'tradingview-chart-${widget.symbol.replaceAll(':', '-').toLowerCase()}-${_viewCounter++}';
    _registerIframeFactory();
  }

  void _registerIframeFactory() {
    final encodedSymbol = Uri.encodeComponent(widget.symbol);
    final src = 'https://s.tradingview.com/widgetembed/?symbol=$encodedSymbol&interval=D&hidesidetoolbar=1&symboledit=0&saveimage=1&toolbarbg=0A1220&theme=dark&style=1&timezone=Etc%2FUTC&hidelegend=0&hidevolume=0&withdateranges=0&locale=en';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src = src
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'fullscreen';

        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
