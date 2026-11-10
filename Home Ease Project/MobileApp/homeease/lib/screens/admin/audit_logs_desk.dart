import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';
import '../../services/localization_service.dart';
import '../../theme/home_ease_theme.dart';
import 'admin_filter_chip.dart';

class AuditLogsDesk extends StatefulWidget {
  const AuditLogsDesk({
    super.key,
    required this.auditService,
    required this.isWide,
  });

  final AuditLogService auditService;
  final bool isWide;

  @override
  State<AuditLogsDesk> createState() => _AuditLogsDeskState();
}

class _AuditLogsDeskState extends State<AuditLogsDesk> {
  String _auditFilter = 'all'; // 'all', 'auth', 'verification', 'dispute', 'payment'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.auditService,
      builder: (context, _) {
        final logs = widget.auditService.getLogs(actionType: _auditFilter);
        final totalLogsCount = widget.auditService.getLogs().length;

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isWide ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips (Touch targets >= 48dp)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AdminFilterChip(
                      label:
                          '${LocalizationService.tr("allTab")} ($totalLogsCount)',
                      isSelected: _auditFilter == 'all',
                      onTap: () => setState(() => _auditFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    AdminFilterChip(
                      label: LocalizationService.tr('auditFilterAuth'),
                      isSelected: _auditFilter == 'auth',
                      onTap: () => setState(() => _auditFilter = 'auth'),
                    ),
                    const SizedBox(width: 8),
                    AdminFilterChip(
                      label:
                          LocalizationService.tr('auditFilterVerification'),
                      isSelected: _auditFilter == 'verification',
                      onTap: () =>
                          setState(() => _auditFilter = 'verification'),
                    ),
                    const SizedBox(width: 8),
                    AdminFilterChip(
                      label: LocalizationService.tr('auditFilterDispute'),
                      isSelected: _auditFilter == 'dispute',
                      onTap: () => setState(() => _auditFilter = 'dispute'),
                    ),
                    const SizedBox(width: 8),
                    AdminFilterChip(
                      label: LocalizationService.tr('auditFilterPayment'),
                      isSelected: _auditFilter == 'payment',
                      onTap: () => setState(() => _auditFilter = 'payment'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              if (logs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.list_alt_rounded,
                          size: 54, color: HomeEaseTheme.muted),
                      const SizedBox(height: 12),
                      Text(LocalizationService.tr('noAuditLogsFound'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildAuditLogCard(log);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuditLogCard(AuditLogEntry log) {
    IconData icon = Icons.info_outline_rounded;
    Color color = HomeEaseTheme.brand;

    switch (log.actionType.toLowerCase()) {
      case 'auth':
        icon = Icons.lock_open_rounded;
        color = const Color(0xFF0284C7);
        break;
      case 'verification':
        icon = Icons.verified_user_rounded;
        color = HomeEaseTheme.statusVerified;
        break;
      case 'dispute':
        icon = Icons.gavel_rounded;
        color = const Color(0xFFD97706);
        break;
      case 'payment':
        icon = Icons.account_balance_wallet_rounded;
        color = HomeEaseTheme.statusVerified;
        break;
      case 'system':
        icon = Icons.dns_rounded;
        color = HomeEaseTheme.muted;
        break;
    }

    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, "0")}:${log.timestamp.minute.toString().padLeft(2, "0")} • ${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeEaseTheme.card,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        log.title,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: const TextStyle(
                          fontSize: 11, color: HomeEaseTheme.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  log.description,
                  style: const TextStyle(
                      fontSize: 12, color: HomeEaseTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${LocalizationService.tr("actorLabel")}: ${log.actor}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: HomeEaseTheme.brand),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
