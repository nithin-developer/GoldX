import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/tradingview_embedded_chart.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/section_header.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  static const List<_MarketCoin> _coins = [
    _MarketCoin(
      symbol: 'BTC',
      pair: 'BTCUSDT',
      tradingViewSymbol: 'BITSTAMP:BTCUSD',
      label: 'BITCOIN / USDT',
      logoAsset: 'assets/coins/btc.png',
    ),
    _MarketCoin(
      symbol: 'ETH',
      pair: 'ETHUSDT',
      tradingViewSymbol: 'BINANCE:ETHUSDT',
      label: 'ETHEREUM / USDT',
      logoAsset: 'assets/coins/eth.png',
    ),
    _MarketCoin(
      symbol: 'SOL',
      pair: 'SOLUSDT',
      tradingViewSymbol: 'BINANCE:SOLUSDT',
      label: 'SOLANA / USDT',
      logoAsset: 'assets/coins/sol.png',
    ),
    _MarketCoin(
      symbol: 'AVAX',
      pair: 'AVAXUSDT',
      tradingViewSymbol: 'BINANCE:AVAXUSDT',
      label: 'AVALANCHE / USDT',
      logoAsset: 'assets/coins/avax.png',
    ),
  ];

  final NumberFormat _priceFormat = NumberFormat('#,##0.00');

  WebViewController? _chartController;
  WebSocketChannel? _tickerChannel;
  StreamSubscription<dynamic>? _tickerSubscription;
  Timer? _reconnectTimer;

  int _selectedIndex = 0;
  bool _chartLoading = true;
  String? _chartError;
  String? _streamError;
  bool _isDisposed = false;
  bool _isActiveInTree = true;

  double? _selectedPrice;

  final Map<String, double> _latestPrices = {};
  final Map<String, double> _dailyChangePercent = {};

  bool get _supportsEmbeddedChart {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();

    _initializeChart();
    _connectTickerStream();
  }

  void _initializeChart() {
    if (kIsWeb) {
      _chartLoading = false;
      _chartError = null;
      return;
    }

    if (!_supportsEmbeddedChart) {
      _chartLoading = false;
      _chartError = 'Chart is not supported on this platform.';
      return;
    }

    try {
      _chartController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (error) {
              if (!mounted || error.isForMainFrame != true) {
                return;
              }

              setState(() {
                _chartLoading = false;
                _chartError = 'Unable to load chart.';
              });
            },
            onPageFinished: (_) {
              if (!mounted) {
                return;
              }

              setState(() {
                _chartLoading = false;
                _chartError = null;
              });
            },
          ),
        );

      _loadTradingViewChart();
    } catch (_) {
      _chartController = null;
      _chartLoading = false;
      _chartError = 'Unable to initialize chart on this platform.';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _tickerSubscription?.cancel();
    _tickerChannel?.sink.close();
    super.dispose();
  }

  @override
  void deactivate() {
    _isActiveInTree = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _isActiveInTree = true;
  }

  _MarketCoin get _selectedCoin => _coins[_selectedIndex];

  void _onSelectCoin(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
      _selectedPrice = _latestPrices[_coins[index].pair];
      _chartLoading = !kIsWeb && _chartController != null;
      _chartError = kIsWeb ? null : (_chartController == null ? 'Chart is not supported on this platform.' : null);
    });

    if (!kIsWeb && _chartController != null) {
      _loadTradingViewChart();
    }
  }

  Future<void> _loadTradingViewChart() async {
    final controller = _chartController;
    if (controller == null) {
      return;
    }

    final coin = _selectedCoin;
    final html = '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      html, body {
        margin: 0;
        padding: 0;
        background: #0A1220;
        height: 100%;
        width: 100%;
        overflow: hidden;
      }
      .tradingview-widget-container {
        height: 100%;
        width: 100%;
      }
      .tradingview-widget-copyright {
        font-family: Arial, sans-serif;
        font-size: 11px;
        line-height: 32px;
        text-align: center;
      }
      .blue-text {
        color: #7CA9FF;
      }
      .trademark {
        color: #A7B0C0;
      }
    </style>
  </head>
  <body>
    <div class="tradingview-widget-container" style="height:100%;width:100%">
      <div class="tradingview-widget-container__widget" style="height:calc(100% - 32px);width:100%"></div>
      <div class="tradingview-widget-copyright">
        <a href="https://www.tradingview.com/symbols/${coin.tradingViewSymbol.replaceAll(':', '/')}" rel="noopener nofollow" target="_blank">
          <span class="blue-text">${coin.symbol} price</span>
        </a>
        <span class="trademark"> by TradingView</span>
      </div>
      <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js" async>
      {
        "allow_symbol_change": false,
        "calendar": false,
        "details": false,
        "hide_side_toolbar": true,
        "hide_top_toolbar": false,
        "hide_legend": false,
        "hide_volume": false,
        "hotlist": false,
        "interval": "D",
        "locale": "en",
        "save_image": true,
        "style": "1",
        "symbol": "${coin.tradingViewSymbol}",
        "theme": "dark",
        "timezone": "Etc/UTC",
        "backgroundColor": "#0A1220",
        "gridColor": "rgba(242, 242, 242, 0.06)",
        "watchlist": [],
        "withdateranges": false,
        "compareSymbols": [],
        "studies": [],
        "autosize": true
      }
      </script>
    </div>
  </body>
</html>
''';

    await controller.loadHtmlString(html);
  }

  void _connectTickerStream() {
    if (_isDisposed) {
      return;
    }

    _reconnectTimer?.cancel();
    _tickerSubscription?.cancel();
    _tickerChannel?.sink.close();

    final streams = _coins.map((coin) => '${coin.pair.toLowerCase()}@kline_1d').join('/');
    _tickerChannel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/stream?streams=$streams'),
    );

    _tickerSubscription = _tickerChannel!.stream.listen(
      (message) {
        final parsed = jsonDecode(message as String);
        final data = parsed['data'];

        if (data is! Map<String, dynamic>) {
          return;
        }

        final kline = data['k'];
        if (kline is! Map<String, dynamic>) {
          return;
        }

        final pair = kline['s']?.toString();
        final openPrice = double.tryParse(kline['o'].toString());
        final lastPrice = double.tryParse(kline['c'].toString());

        if (pair == null || openPrice == null || openPrice <= 0 || lastPrice == null || !_canMutateState) {
          return;
        }

        final dayPercent = ((lastPrice - openPrice) / openPrice) * 100;

        setState(() {
          _latestPrices[pair] = lastPrice;
          _dailyChangePercent[pair] = dayPercent;

          if (pair == _selectedCoin.pair) {
            _selectedPrice = lastPrice;
          }

          _streamError = null;
        });
      },
      onError: (_) {
        if (!_canMutateState) {
          return;
        }

        setState(() {
          _streamError = 'Live price stream disconnected. Reconnecting...';
        });

        _scheduleReconnect();
      },
      onDone: () {
        if (!_canMutateState) {
          return;
        }

        setState(() {
          _streamError = 'Live price stream disconnected. Reconnecting...';
        });

        _scheduleReconnect();
      },
      cancelOnError: true,
    );
  }

  bool get _canMutateState => mounted && !_isDisposed && _isActiveInTree;

  void _scheduleReconnect() {
    if (_isDisposed) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (!_canMutateState) {
        return;
      }
      _connectTickerStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _coins.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final coin = _coins[index];
              final selected = index == _selectedIndex;
              return GestureDetector(
                onTap: () => _onSelectCoin(index),
                child: _chip(coin, selected),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedCoin.label, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                _formatPrice(_selectedPrice),
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700),
              ),
              Text(
                '${_formatPrice(_selectedPrice)} USD',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              _LiveDelta(
                dailyPercent: _dailyChangePercent[_selectedCoin.pair],
              ),
              if (_streamError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _streamError!,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Candlestick Chart'),
        const SizedBox(height: 8),
        GlassCard(
          child: SizedBox(
            height: 340,
            child: Stack(
              children: [
                if (kIsWeb)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: TradingViewEmbeddedChart(
                      key: ValueKey(_selectedCoin.tradingViewSymbol),
                      symbol: _selectedCoin.tradingViewSymbol,
                    ),
                  )
                else if (_chartController != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: WebViewWidget(controller: _chartController!),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _chartError ?? 'Chart is not available on this platform.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                if (_chartLoading) const Center(child: CircularProgressIndicator()),
                if (_chartError != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger),
                      ),
                      child: Text(
                        _chartError!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Live Prices', actionText: 'Today'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: _coins
                .map(
                  (coin) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PriceRow(
                      asset: coin.symbol,
                      pair: coin.label,
                      logoAsset: coin.logoAsset,
                      price: _formatPrice(_latestPrices[coin.pair]),
                      change: _formatDayChange(_dailyChangePercent[coin.pair]),
                      selected: coin == _selectedCoin,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  String _formatPrice(double? price) {
    if (price == null) {
      return '\$ --';
    }
    return '\$${_priceFormat.format(price)}';
  }

  String _formatDayChange(double? percent) {
    if (percent == null) {
      return '--';
    }
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(2)}%';
  }

  Widget _chip(_MarketCoin coin, bool selected) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.28) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _CoinAvatar(logoAsset: coin.logoAsset, size: 16),
            const SizedBox(width: 6),
            Text(
              coin.symbol,
              style: TextStyle(
                color: selected ? AppColors.primaryBright : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketCoin {
  const _MarketCoin({
    required this.symbol,
    required this.pair,
    required this.tradingViewSymbol,
    required this.label,
    required this.logoAsset,
  });

  final String symbol;
  final String pair;
  final String tradingViewSymbol;
  final String label;
  final String logoAsset;
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.asset,
    required this.pair,
    required this.logoAsset,
    required this.price,
    required this.change,
    required this.selected,
  });

  final String asset;
  final String pair;
  final String logoAsset;
  final String price;
  final String change;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final positive = change.startsWith('+');
    final negative = change.startsWith('-');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
      ),
      child: Row(
        children: [
          _CoinAvatar(logoAsset: logoAsset, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(pair, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Text(
            change,
            style: TextStyle(
              color: positive
                  ? AppColors.success
                  : (negative ? AppColors.danger : AppColors.textSecondary),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinAvatar extends StatelessWidget {
  const _CoinAvatar({required this.logoAsset, required this.size});

  final String logoAsset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        logoAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.token_rounded,
            size: size * 0.55,
            color: AppColors.textMuted,
          );
        },
      ),
    );
  }
}

class _LiveDelta extends StatelessWidget {
  const _LiveDelta({required this.dailyPercent});

  final double? dailyPercent;

  @override
  Widget build(BuildContext context) {
    if (dailyPercent == null) {
      return const Text(
        'Waiting for today\'s change...',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }

    final positive = dailyPercent! >= 0;
    final sign = positive ? '+' : '';

    return Row(
      children: [
        Icon(
          positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 16,
          color: positive ? AppColors.success : AppColors.danger,
        ),
        const SizedBox(width: 4),
        Text(
          '$sign${dailyPercent!.toStringAsFixed(2)}% today',
          style: TextStyle(
            color: positive ? AppColors.success : AppColors.danger,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
