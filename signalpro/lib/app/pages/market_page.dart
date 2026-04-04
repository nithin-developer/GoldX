import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/section_header.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  static const List<String> _intervals = <String>['1m', '5m', '15m'];

  static const List<_MarketCoin> _coins = [
    _MarketCoin(
      symbol: 'BTC',
      pair: 'BTCUSDT',
      label: 'BITCOIN / USDT',
      logoAsset: 'assets/coins/btc.png',
    ),
    _MarketCoin(
      symbol: 'ETH',
      pair: 'ETHUSDT',
      label: 'ETHEREUM / USDT',
      logoAsset: 'assets/coins/eth.png',
    ),
    _MarketCoin(
      symbol: 'SOL',
      pair: 'SOLUSDT',
      label: 'SOLANA / USDT',
      logoAsset: 'assets/coins/sol.png',
    ),
    _MarketCoin(
      symbol: 'AVAX',
      pair: 'AVAXUSDT',
      label: 'AVALANCHE / USDT',
      logoAsset: 'assets/coins/avax.png',
    ),
  ];

  final NumberFormat _priceFormat = NumberFormat('#,##0.00');
  final NumberFormat _axisPriceFormat = NumberFormat('#,##0.00');
  final Dio _binanceHttp = Dio(BaseOptions(baseUrl: 'https://api.binance.com'));

  WebSocketChannel? _tickerChannel;
  StreamSubscription<dynamic>? _tickerSubscription;
  Timer? _tickerReconnectTimer;

  WebSocketChannel? _candleChannel;
  StreamSubscription<dynamic>? _candleSubscription;
  Timer? _candleReconnectTimer;

  int _selectedIndex = 0;
  String _selectedInterval = _intervals.first;

  bool _candlesLoading = true;
  bool _isCurrentCandleClosed = false;
  String? _candlesError;
  String? _streamError;
  bool _isDisposed = false;
  bool _isActiveInTree = true;
  int _candleRequestId = 0;

    String get _candleReconnectMessage =>
      context.l10n.tr('Live candle stream disconnected. Reconnecting...');

    String get _tickerReconnectMessage =>
      context.l10n.tr('Live price stream disconnected. Reconnecting...');

  double? _selectedPrice;

  final Map<String, double> _latestPrices = {};
  final Map<String, double> _dailyChangePercent = {};
  final List<Candle> _candles = <Candle>[];

  @override
  void initState() {
    super.initState();
    _connectTickerStream();
    _reloadCandlesForSelection();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tickerReconnectTimer?.cancel();
    _candleReconnectTimer?.cancel();
    _tickerSubscription?.cancel();
    _candleSubscription?.cancel();
    _tickerChannel?.sink.close();
    _candleChannel?.sink.close();
    _binanceHttp.close(force: true);
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
    });
    _reloadCandlesForSelection();
  }

  void _onSelectInterval(String interval) {
    if (_selectedInterval == interval) {
      return;
    }

    setState(() {
      _selectedInterval = interval;
    });
    _reloadCandlesForSelection();
  }

  Future<void> _reloadCandlesForSelection() async {
    final requestId = ++_candleRequestId;
    final pair = _selectedCoin.pair;
    final interval = _selectedInterval;

    if (_canMutateState) {
      setState(() {
        _candlesLoading = true;
        _candlesError = null;
        _isCurrentCandleClosed = false;
      });
    }

    await _loadHistoricalCandles(
      pair: pair,
      interval: interval,
      requestId: requestId,
    );

    if (!_shouldApplyCandleUpdate(requestId, pair, interval)) {
      return;
    }

    _connectCandleStream(pair: pair, interval: interval, requestId: requestId);
  }

  bool _shouldApplyCandleUpdate(int requestId, String pair, String interval) {
    return _canMutateState &&
        requestId == _candleRequestId &&
        pair == _selectedCoin.pair &&
        interval == _selectedInterval;
  }

  Future<void> _loadHistoricalCandles({
    required String pair,
    required String interval,
    required int requestId,
  }) async {
    try {
      final response = await _binanceHttp.get<List<dynamic>>(
        '/api/v3/klines',
        queryParameters: {'symbol': pair, 'interval': interval, 'limit': 120},
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );

      final rows = response.data ?? const <dynamic>[];
      final candles = rows
          .whereType<List<dynamic>>()
          .map((row) {
            try {
              return Candle.fromRest(row);
            } catch (_) {
              return null;
            }
          })
          .whereType<Candle>()
          .toList(growable: false);

      if (!_shouldApplyCandleUpdate(requestId, pair, interval)) {
        return;
      }

      setState(() {
        _candles
          ..clear()
          ..addAll(candles);
        _candlesLoading = false;
        _candlesError = candles.isEmpty
            ? context.l10n.tr(
                'No candle data received for {symbol} ({interval}).',
                params: <String, String>{
                  'symbol': _selectedCoin.symbol,
                  'interval': _selectedInterval,
                },
              )
            : null;
        _isCurrentCandleClosed = candles.isNotEmpty
            ? candles.last.isClosed
            : false;
      });
    } catch (_) {
      if (!_shouldApplyCandleUpdate(requestId, pair, interval)) {
        return;
      }

      setState(() {
        _candlesLoading = false;
        _candlesError = context.l10n.tr(
          'Unable to load historical candles. Please try again.',
        );
      });
    }
  }

  void _connectCandleStream({
    required String pair,
    required String interval,
    required int requestId,
  }) {
    if (!_shouldApplyCandleUpdate(requestId, pair, interval)) {
      return;
    }

    _candleReconnectTimer?.cancel();
    _candleSubscription?.cancel();
    _candleChannel?.sink.close();

    _candleChannel = WebSocketChannel.connect(
      Uri.parse(
        'wss://stream.binance.com:9443/ws/${pair.toLowerCase()}@kline_$interval',
      ),
    );

    _candleSubscription = _candleChannel!.stream.listen(
      (message) {
        Map<String, dynamic> payload;
        try {
          final decoded = jsonDecode(message as String);
          if (decoded is! Map<String, dynamic>) {
            return;
          }
          payload = decoded;
        } catch (_) {
          return;
        }

        Candle candle;
        try {
          candle = Candle.fromBinance(payload);
        } catch (_) {
          return;
        }

        if (!_shouldApplyCandleUpdate(requestId, pair, interval)) {
          return;
        }

        setState(() {
          _candlesLoading = false;
          _candlesError = null;
          _isCurrentCandleClosed = candle.isClosed;

          if (_candles.isNotEmpty && _candles.last.time == candle.time) {
            _candles[_candles.length - 1] = candle;
          } else {
            _candles.add(candle);
            if (_candles.length > 300) {
              _candles.removeAt(0);
            }
          }
        });
      },
      onError: (_) {
        if (!_shouldApplyCandleUpdate(requestId, pair, interval)) {
          return;
        }

        setState(() {
          _candlesError = _candleReconnectMessage;
        });

        _scheduleCandleReconnect(
          pair: pair,
          interval: interval,
          requestId: requestId,
        );
      },
      onDone: () {
        if (!_shouldApplyCandleUpdate(requestId, pair, interval)) {
          return;
        }

        setState(() {
          _candlesError = _candleReconnectMessage;
        });

        _scheduleCandleReconnect(
          pair: pair,
          interval: interval,
          requestId: requestId,
        );
      },
      cancelOnError: true,
    );
  }

  void _scheduleCandleReconnect({
    required String pair,
    required String interval,
    required int requestId,
  }) {
    if (_isDisposed) {
      return;
    }

    _candleReconnectTimer?.cancel();
    _candleReconnectTimer = Timer(const Duration(seconds: 2), () {
      if (!_shouldApplyCandleUpdate(requestId, pair, interval)) {
        return;
      }

      _connectCandleStream(
        pair: pair,
        interval: interval,
        requestId: requestId,
      );
    });
  }

  void _connectTickerStream() {
    if (_isDisposed) {
      return;
    }

    _tickerReconnectTimer?.cancel();
    _tickerSubscription?.cancel();
    _tickerChannel?.sink.close();

    final streams = _coins
        .map((coin) => '${coin.pair.toLowerCase()}@kline_1d')
        .join('/');
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

        if (pair == null ||
            openPrice == null ||
            openPrice <= 0 ||
            lastPrice == null ||
            !_canMutateState) {
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
          _streamError = _tickerReconnectMessage;
        });

        _scheduleTickerReconnect();
      },
      onDone: () {
        if (!_canMutateState) {
          return;
        }

        setState(() {
          _streamError = _tickerReconnectMessage;
        });

        _scheduleTickerReconnect();
      },
      cancelOnError: true,
    );
  }

  bool get _canMutateState => mounted && !_isDisposed && _isActiveInTree;

  void _scheduleTickerReconnect() {
    if (_isDisposed) {
      return;
    }

    _tickerReconnectTimer?.cancel();
    _tickerReconnectTimer = Timer(const Duration(seconds: 2), () {
      if (!_canMutateState) {
        return;
      }
      _connectTickerStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
              Text(
                l10n.tr(_selectedCoin.label),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                _formatPrice(_selectedPrice),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_formatPrice(_selectedPrice)} USD',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              _LiveDelta(dailyPercent: _dailyChangePercent[_selectedCoin.pair]),
              if (_streamError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _streamError!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionHeader(
          title: l10n.tr('Candlestick Chart'),
          actionText: l10n.tr('LIVE'),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _intervals.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final interval = _intervals[index];
              return _IntervalChip(
                label: interval,
                selected: interval == _selectedInterval,
                onTap: () => _onSelectInterval(interval),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          child: SizedBox(
            height: 340,
            child: Stack(
              children: [
                if (_candles.isNotEmpty)
                  SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    primaryXAxis: DateTimeAxis(
                      edgeLabelPlacement: EdgeLabelPlacement.shift,
                      intervalType: DateTimeIntervalType.minutes,
                      dateFormat: DateFormat('HH:mm'),
                      labelStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                      majorGridLines: MajorGridLines(
                        color: AppColors.border.withValues(alpha: 0.35),
                        width: 0.6,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      opposedPosition: true,
                      numberFormat: _axisPriceFormat,
                      axisLine: const AxisLine(width: 0),
                      labelStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                      majorGridLines: MajorGridLines(
                        color: AppColors.border.withValues(alpha: 0.35),
                        width: 0.6,
                      ),
                    ),
                    zoomPanBehavior: ZoomPanBehavior(
                      enablePinching: true,
                      enablePanning: true,
                      enableMouseWheelZooming: true,
                      enableDoubleTapZooming: true,
                      zoomMode: ZoomMode.x,
                    ),
                    trackballBehavior: TrackballBehavior(
                      enable: true,
                      activationMode: ActivationMode.singleTap,
                      tooltipDisplayMode: TrackballDisplayMode.floatAllPoints,
                    ),
                    series: <CandleSeries<Candle, DateTime>>[
                      CandleSeries<Candle, DateTime>(
                        dataSource: _candles,
                        xValueMapper: (candle, _) => candle.time,
                        lowValueMapper: (candle, _) => candle.low,
                        highValueMapper: (candle, _) => candle.high,
                        openValueMapper: (candle, _) => candle.open,
                        closeValueMapper: (candle, _) => candle.close,
                        bullColor: AppColors.success,
                        bearColor: AppColors.danger,
                        enableSolidCandles: true,
                        width: 0.8,
                        spacing: 0.25,
                      ),
                    ],
                  )
                else if (!_candlesLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _candlesError ??
                            l10n.tr(
                              'No chart data available for the selected coin.',
                            ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                if (_candlesLoading)
                  const Center(child: CircularProgressIndicator()),
                if (_candlesError != null && _candles.isNotEmpty)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger),
                      ),
                      child: Text(
                        _candlesError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_candles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _isCurrentCandleClosed
                    ? Icons.check_circle_outline_rounded
                    : Icons.timelapse_rounded,
                size: 14,
                color: _isCurrentCandleClosed
                    ? AppColors.success
                    : AppColors.highlight,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _isCurrentCandleClosed
                      ? l10n.tr(
                          'Latest {interval} candle closed',
                          params: <String, String>{
                            'interval': _selectedInterval,
                          },
                        )
                      : l10n.tr(
                          'Current {interval} candle is forming with live updates',
                          params: <String, String>{
                            'interval': _selectedInterval,
                          },
                        ),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        SectionHeader(
          title: l10n.tr('Live Prices'),
          actionText: l10n.tr('Today'),
        ),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: _coins
                .map(
                  (coin) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PriceRow(
                      asset: coin.symbol,
                      pair: l10n.tr(coin.label),
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
        color: selected
            ? AppColors.primary.withValues(alpha: 0.28)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
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
                color: selected
                    ? AppColors.primaryBright
                    : AppColors.textSecondary,
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
    required this.label,
    required this.logoAsset,
  });

  final String symbol;
  final String pair;
  final String label;
  final String logoAsset;
}

class _IntervalChip extends StatelessWidget {
  const _IntervalChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.24)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: selected ? AppColors.primaryBright : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class Candle {
  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.isClosed,
  });

  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final bool isClosed;

  factory Candle.fromBinance(Map<String, dynamic> data) {
    final klineRaw = data['k'];
    if (klineRaw is! Map) {
      throw const FormatException('Invalid Binance kline payload');
    }

    final kline = Map<String, dynamic>.from(klineRaw);
    final time = DateTime.fromMillisecondsSinceEpoch(
      _asInt(kline['t']),
      isUtc: true,
    ).toLocal();

    return Candle(
      time: time,
      open: _asDouble(kline['o']),
      high: _asDouble(kline['h']),
      low: _asDouble(kline['l']),
      close: _asDouble(kline['c']),
      isClosed: kline['x'] == true,
    );
  }

  factory Candle.fromRest(List<dynamic> row) {
    if (row.length < 5) {
      throw const FormatException('Invalid kline row');
    }

    final time = DateTime.fromMillisecondsSinceEpoch(
      _asInt(row[0]),
      isUtc: true,
    ).toLocal();

    return Candle(
      time: time,
      open: _asDouble(row[1]),
      high: _asDouble(row[2]),
      low: _asDouble(row[3]),
      close: _asDouble(row[4]),
      isClosed: true,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }
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
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          _CoinAvatar(logoAsset: logoAsset, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  pair,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
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
      final l10n = context.l10n;

      return Text(
        l10n.tr("Waiting for today's change..."),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
