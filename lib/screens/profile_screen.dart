import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import '../models/order.dart' as models;
import 'login_screen.dart';
import 'order_tracking_screen.dart';
import 'coupon_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          if (authService.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<OrderService>(context, listen: false)
                  .fetchUserOrders(authService.currentUserId);
            });
          }
          final displayName = authService.currentUserName.isNotEmpty
              ? authService.currentUserName
              : 'User';
          final email = authService.currentUserEmail.isNotEmpty
              ? authService.currentUserEmail
              : '-';
          final initial = displayName[0].toUpperCase();

          return CustomScrollView(
            slivers: [
              // ── Profile Header ──
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: IKASColors.primary,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  lang.profile,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  // Edit profile button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 16),
                    ),
                    onPressed: () =>
                        _showEditProfile(context, authService, displayName),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          IKASColors.primaryDark,
                          IKASColors.primary,
                          IKASColors.accent,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -40, right: -30,
                          child: Container(
                            width: 180, height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20, left: -40,
                          child: Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 90, height: 90,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 18,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          initial,
                                          style: GoogleFonts.poppins(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w800,
                                            color: IKASColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0, right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(displayName,
                                        style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                    const SizedBox(width: 6),
                                    Icon(Icons.verified_rounded, color: Colors.white.withOpacity(0.9), size: 18),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(email,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.82))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _quickAction(
                          context, 
                          Icons.confirmation_number_rounded, 
                          lang.isTurkish ? 'Kuponlar' : 'Coupons', 
                          Colors.orangeAccent,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponScreen())),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── İstatistik kartları ──
              SliverToBoxAdapter(
                child: Consumer<OrderService>(
                  builder: (ctx, orderService, _) {
                    final totalOrders = orderService.userOrders.length;
                    final totalSpent = orderService.userOrders.fold<double>(0, (sum, o) => sum + o.totalPrice);
                    final completedOrders = orderService.userOrders.where((o) => o.status == models.OrderStatus.completed).length;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          _statCard(
                            isDark: isDark,
                            icon: Icons.receipt_long_rounded,
                            value: '$totalOrders',
                            label: lang.isTurkish ? 'Sipariş' : 'Orders',
                            color: IKASColors.primary,
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            isDark: isDark,
                            icon: Icons.check_circle_rounded,
                            value: '$completedOrders',
                            label: lang.isTurkish ? 'Tamamlanan' : 'Completed',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            isDark: isDark,
                            icon: Icons.attach_money_rounded,
                            value: '₺${totalSpent.toStringAsFixed(0)}',
                            label: lang.isTurkish ? 'Harcama' : 'Spent',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Orders ──
              SliverToBoxAdapter(
                child: Consumer<OrderService>(
                  builder: (ctx, orderService, _) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            title: lang.myOrders,
                            trailing: orderService.userOrders.isNotEmpty
                                ? TextButton(
                                    onPressed: () => orderService
                                        .fetchUserOrders(authService.currentUserId),
                                    child: Text(lang.refresh,
                                        style: GoogleFonts.poppins(
                                            color: IKASColors.primary,
                                            fontWeight: FontWeight.w600)),
                                  )
                                : null,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          if (orderService.userOrders.isEmpty)
                            _emptyOrders(isDark, lang)
                          else
                            SizedBox(
                              height: 155,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: orderService.userOrders.length,
                                itemBuilder: (ctx, i) =>
                                    _orderCard(context, orderService.userOrders[i], isDark),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Preferences ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(title: lang.preferences, isDark: isDark),
                      const SizedBox(height: 12),

                      // Dark Mode toggle
                      _toggleItem(
                        context,
                        icon: themeService.isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        title: lang.darkMode,
                        subtitle: themeService.isDark ? lang.darkOn : lang.lightOn,
                        iconBg: const Color(0xFF263238),
                        iconColor: Colors.white,
                        value: themeService.isDark,
                        onChanged: (_) => themeService.toggle(),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      // Language toggle
                      _menuItem(
                        context,
                        icon: Icons.language_rounded,
                        title: lang.language,
                        subtitle: lang.languageName,
                        iconBg: const Color(0xFFE3F2FD),
                        iconColor: Colors.blue,
                        isDark: isDark,
                        onTap: () {
                          Provider.of<LanguageService>(context, listen: false).toggle();
                        },
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: IKASColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Consumer<LanguageService>(
                            builder: (_, l, __) => Text(l.isTurkish ? 'TR' : 'EN',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: IKASColors.primary)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Account ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(title: lang.settings, isDark: isDark),
                      const SizedBox(height: 12),
                      _menuItem(
                        context,
                        icon: Icons.person_outline_rounded,
                        title: lang.accountInfo,
                        subtitle: lang.accountSub,
                        iconBg: IKASColors.chipBg,
                        iconColor: IKASColors.primary,
                        isDark: isDark,
                        onTap: () => _showAccountInfo(context, displayName, email, lang),
                      ),
                      const SizedBox(height: 10),
                      _menuItem(
                        context,
                        icon: Icons.help_outline_rounded,
                        title: lang.helpSupport,
                        subtitle: lang.helpSub,
                        iconBg: const Color(0xFFFFF3E0),
                        iconColor: Colors.orange,
                        isDark: isDark,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(lang.comingSoon)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _menuItem(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: lang.about,
                        subtitle: lang.aboutSub,
                        iconBg: const Color(0xFFE8F5E9),
                        iconColor: Colors.green.shade700,
                        isDark: isDark,
                        onTap: () => _showAboutDialog(context, lang),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Sign out ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                  child: GestureDetector(
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(lang.signOut,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                          content: Text(lang.confirmSignOut,
                              style: GoogleFonts.poppins()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(lang.cancel,
                                  style: GoogleFonts.poppins(
                                      color: IKASColors.textMid)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(lang.signOut,
                                  style: GoogleFonts.poppins(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                      if (shouldLogout == true && context.mounted) {
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (r) => false,
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: isDark ? Colors.red.withOpacity(0.3) : Colors.red.shade100, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: Colors.red.shade400, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            lang.signOut,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(
      {required String title, Widget? trailing, required bool isDark}) {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [IKASColors.primaryDark, IKASColors.accent],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : IKASColors.textDark)),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _statCard({
    required bool isDark,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? IKASColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : IKASColors.textDark,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: IKASColors.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyOrders(bool isDark, LanguageService lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
                color: IKASColors.chipBg, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded,
                size: 28, color: IKASColors.primary),
          ),
          const SizedBox(height: 12),
          Text(lang.noOrdersYet,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : IKASColors.textDark)),
          Text(lang.noOrdersSub,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: IKASColors.textMid)),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? IKASColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : IKASColors.textDark)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: IKASColors.textMid)),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: IKASColors.textLight, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : IKASColors.textDark)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: IKASColors.textMid)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: IKASColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _orderCard(BuildContext context, models.Order order, bool isDark) {
    final statusColor = _statusColor(order.status);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(order: order)),
      ),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? IKASColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: IKASColors.chipBg,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: IKASColors.primary, size: 16),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '#${order.id.substring(0, 8)}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : IKASColors.textDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${order.items.length} items · ₺${order.totalPrice.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: IKASColors.textMid),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: IKASColors.textLight),
                ),
                const Spacer(),
                // Track arrow
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: IKASColors.chipBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.track_changes_rounded,
                      color: IKASColors.primary, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(models.OrderStatus status) {
    switch (status) {
      case models.OrderStatus.pending:
        return Colors.orange;
      case models.OrderStatus.preparing:
        return Colors.blue;
      case models.OrderStatus.ready:
        return IKASColors.primary;
      case models.OrderStatus.completed:
        return Colors.grey;
      case models.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // ── Edit profile ──────────────────────────────────────────────────────────
  void _showEditProfile(
      BuildContext context, AuthService authService, String currentName) {
    final controller = TextEditingController(text: currentName);
    final lang = Provider.of<LanguageService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(lang.editProfile,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: lang.displayName,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isEmpty) return;
                  await authService.updateDisplayName(newName);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated!')),
                    );
                  }
                },
                child: Text(lang.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountInfo(BuildContext context, String name, String email, LanguageService lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? IKASColors.darkSurface : Colors.white,
        title: Text(lang.accountInfo,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: isDark ? Colors.white : IKASColors.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(lang.displayName, name, isDark),
            const SizedBox(height: 12),
            _infoRow('Email', email, isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.close, style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark ? Colors.white54 : IKASColors.textLight,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : IKASColors.textDark)),
      ],
    );
  }

  void _showAboutDialog(BuildContext context, LanguageService lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? IKASColors.darkSurface : Colors.white,
        title: Text(lang.about,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: isDark ? Colors.white : IKASColors.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IKAS Super Market',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: IKASColors.primary)),
            const SizedBox(height: 4),
            Text('Version 1.0.0',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: isDark ? Colors.white54 : IKASColors.textLight)),
            const SizedBox(height: 12),
            Text(
              'IKAS Super Market app — browse products, order meals, and manage your account easily.',
              style:
                  GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.white70 : IKASColors.textMid),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.close, style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
