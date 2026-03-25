import 'package:flutter/material.dart';
import 'package:signalpro/app/theme/app_colors.dart';

class SupportChatPage extends StatelessWidget {
  const SupportChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Support Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('AGENT ONLINE', style: TextStyle(fontSize: 10, color: AppColors.success, letterSpacing: 1.3)),
          ],
        ),
        actions: const [
          CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
          SizedBox(width: 8),
          Icon(Icons.more_vert_rounded),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT REPRESENTATIVE', style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: AppColors.textSecondary)),
                      SizedBox(height: 2),
                      Text('Sarah Jenkins', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Chip(label: Text('AVG. 2M RESPONSE')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Center(child: _DatePill('TODAY')),
                SizedBox(height: 12),
                _Bubble(text: 'Hello! I\'m Sarah from the SignalPro team. How can I help clarify your recent data spikes?', support: true, meta: 'SARAH • 10:42 AM'),
                SizedBox(height: 12),
                _Bubble(text: 'I\'m seeing a discrepancy between the 1h and 4h RSI on BTC/USDT. Is this delayed?', support: false, meta: 'YOU • 10:44 AM • READ'),
                SizedBox(height: 12),
                _Bubble(text: 'Great observation. Our Pro feeds run with sub-50ms latency. I can share the technical docs.', support: true, meta: 'SARAH • 10:45 AM'),
                SizedBox(height: 10),
                Text('••• SARAH IS TYPING', style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 1.3)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: AppColors.surface,
            child: Row(
              children: [
                IconButton(onPressed: null, icon: const Icon(Icons.add)),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.send_rounded, color: AppColors.background),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(999)),
      child: Text(value, style: const TextStyle(fontSize: 10, letterSpacing: 1.2, color: AppColors.textSecondary)),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.support, required this.meta});

  final String text;
  final bool support;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: support ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: support ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: support ? AppColors.surfaceSoft : AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(text, style: TextStyle(color: support ? AppColors.textPrimary : AppColors.background)),
          ),
          const SizedBox(height: 4),
          Text(meta, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 1.1)),
        ],
      ),
    );
  }
}
