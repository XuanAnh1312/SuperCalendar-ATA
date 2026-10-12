import 'package:flutter/material.dart';

void main() => runApp(const SuperCalendarApp());

class SuperCalendarApp extends StatelessWidget {
  const SuperCalendarApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Super Calendar · Sign in',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff3478f6),
        surface: Colors.white,
      ),
    ),
    home: const SignInFlow(),
  );
}

enum SignInStep {
  notifications,
  chooseAccount,
  profile,
  permissions,
  ready,
  settings,
}

class SignInFlow extends StatefulWidget {
  const SignInFlow({super.key});

  @override
  State<SignInFlow> createState() => _SignInFlowState();
}

class _SignInFlowState extends State<SignInFlow> {
  SignInStep _step = SignInStep.notifications;
  bool _allowNotifications = true;
  bool _selectedAccount = false;
  bool _calendarPermission = false;
  bool _contactsPermission = false;
  final _email = 'mia.chen@gmail.com';

  void _go(SignInStep step) => setState(() => _step = step);

  void _next() {
    switch (_step) {
      case SignInStep.notifications:
        _go(SignInStep.chooseAccount);
        break;
      case SignInStep.chooseAccount:
        _go(SignInStep.profile);
        break;
      case SignInStep.profile:
        _go(SignInStep.permissions);
        break;
      case SignInStep.permissions:
        _go(SignInStep.ready);
        break;
      case SignInStep.ready:
      case SignInStep.settings:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox.expand(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_step) {
              SignInStep.notifications => _NotificationsPage(
                key: const ValueKey('notifications'),
                allowed: _allowNotifications,
                onAllow: () {
                  setState(() => _allowNotifications = true);
                  _next();
                },
                onDeny: () {
                  setState(() => _allowNotifications = false);
                  _next();
                },
              ),
              SignInStep.chooseAccount => _AccountPage(
                key: const ValueKey('account'),
                email: _email,
                selected: _selectedAccount,
                onSelect: () {
                  setState(() => _selectedAccount = true);
                  _next();
                },
                onAdd: _next,
              ),
              SignInStep.profile => _ProfilePage(
                key: const ValueKey('profile'),
                email: _email,
                onCancel: () => _go(SignInStep.chooseAccount),
                onContinue: _next,
              ),
              SignInStep.permissions => _PermissionsPage(
                key: const ValueKey('permissions'),
                email: _email,
                calendar: _calendarPermission,
                contacts: _contactsPermission,
                onCalendar: (v) => setState(() => _calendarPermission = v),
                onContacts: (v) => setState(() => _contactsPermission = v),
                onContinue: _next,
              ),
              SignInStep.ready => _ReadyPage(
                key: const ValueKey('ready'),
                email: _email,
                notifications: _allowNotifications,
                calendar: _calendarPermission,
                onContinue: () => _go(SignInStep.settings),
              ),
              SignInStep.settings => _LoggedInSettingsPage(email: _email),
            },
          ),
        ),
      ),
    );
  }
}

const _blue = Color(0xff3478f6);
const _ink = Color(0xff202124);
const _muted = Color(0xff5f6368);

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage({
    super.key,
    required this.allowed,
    required this.onAllow,
    required this.onDeny,
  });
  final bool allowed;
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: const Color(0xfff7f7fa),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .09),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xff08749a),
              size: 32,
            ),
            const SizedBox(height: 18),
            const Text(
              'Cho phép Super Calendar\ngửi thông báo cho bạn?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 19,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: onAllow,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xffc9e9fb),
                  foregroundColor: _ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Cho phép'),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: TextButton(
                onPressed: onDeny,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xffc9e9fb),
                  foregroundColor: _ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Không cho phép'),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              allowed
                  ? 'Thông báo nhắc lịch giúp bạn không bỏ lỡ sự kiện.'
                  : 'Bạn có thể bật thông báo sau trong phần Cài đặt.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GoogleHeader extends StatelessWidget {
  const _GoogleHeader();
  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xffdadce0))),
    ),
    child: Row(
      children: [
        const _GoogleG(),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Đăng nhập bằng Google',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Color(0xff4285f4),
      height: 1,
    ),
  );
}

class _PhonePage extends StatelessWidget {
  const _PhonePage({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 460),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffe7e9ed)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _GoogleHeader(),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

class _AccountPage extends StatelessWidget {
  const _AccountPage({
    super.key,
    required this.email,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
  });
  final String email;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => _PhonePage(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: _AppMark()),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Chọn một tài khoản',
              style: TextStyle(
                fontSize: 22,
                color: _ink,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'để tiếp tục đến Super Calendar',
              style: TextStyle(color: _muted, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          _AccountRow(email: email, name: 'Mia Chen', onTap: onSelect),
          const Divider(height: 1),
          InkWell(
            onTap: onAdd,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.person_add_alt_1, size: 20, color: _muted),
                  SizedBox(width: 15),
                  Text(
                    'Thêm tài khoản khác',
                    style: TextStyle(fontSize: 14, color: _ink),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 18),
          const Text(
            'Để tiếp tục, Google sẽ chia sẻ tên, địa chỉ email và ảnh hồ sơ của bạn với Super Calendar. Trước khi sử dụng ứng dụng, hãy xem chính sách quyền riêng tư và điều khoản dịch vụ.',
            style: TextStyle(fontSize: 13, height: 1.55, color: _muted),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Tài khoản đã chọn',
                style: TextStyle(color: Color(0xff188038), fontSize: 12),
              ),
            ),
        ],
      ),
    ),
  );
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.email,
    required this.name,
    required this.onTap,
  });
  final String email;
  final String name;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xfff1f3f4),
            foregroundColor: _muted,
            child: Text(
              name.characters.first,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: _ink, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _muted),
        ],
      ),
    ),
  );
}

class _AppMark extends StatelessWidget {
  const _AppMark();
  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 58,
    decoration: BoxDecoration(
      color: _blue,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: _blue.withValues(alpha: .22),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: const Icon(
      Icons.calendar_month_rounded,
      color: Colors.white,
      size: 34,
    ),
  );
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    super.key,
    required this.email,
    required this.onCancel,
    required this.onContinue,
  });
  final String email;
  final VoidCallback onCancel;
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) => _PhonePage(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AppMark(),
          const SizedBox(height: 24),
          const Text(
            'Đăng nhập vào\nSuper Calendar',
            style: TextStyle(
              color: _ink,
              fontSize: 31,
              height: 1.22,
              fontWeight: FontWeight.w400,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Icon(
                Icons.account_circle_outlined,
                color: _muted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  email,
                  style: const TextStyle(color: _ink, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Google sẽ cho phép Super Calendar truy cập thông tin này về bạn',
            style: TextStyle(color: _ink, fontSize: 20, height: 1.35),
          ),
          const SizedBox(height: 24),
          const _InfoRow(
            icon: Icons.person_outline,
            title: 'Mia Chen',
            subtitle: 'Tên và ảnh hồ sơ',
          ),
          const SizedBox(height: 18),
          _InfoRow(
            icon: Icons.mail_outline,
            title: email,
            subtitle: 'Địa chỉ email',
          ),
          const SizedBox(height: 30),
          const Text(
            'Hãy xem Chính sách quyền riêng tư và Điều khoản dịch vụ của Super Calendar để hiểu cách ứng dụng xử lý và bảo vệ dữ liệu của bạn.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn có thể thay đổi quyền truy cập bất kỳ lúc nào trong Tài khoản Google.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onContinue,
                  child: const Text('Tiếp tục'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 24, color: _muted),
      const SizedBox(width: 15),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: _ink, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 13)),
          ],
        ),
      ),
    ],
  );
}

class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({
    super.key,
    required this.email,
    required this.calendar,
    required this.contacts,
    required this.onCalendar,
    required this.onContacts,
    required this.onContinue,
  });
  final String email;
  final bool calendar;
  final bool contacts;
  final ValueChanged<bool> onCalendar;
  final ValueChanged<bool> onContacts;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => _PhonePage(
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 20),
            children: [
              const _AppMark(),
              const SizedBox(height: 24),
              const Text(
                'Super Calendar muốn truy cập Tài khoản Google của bạn',
                style: TextStyle(
                  color: _ink,
                  fontSize: 30,
                  height: 1.22,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 20),
              Text(email, style: const TextStyle(color: _ink, fontSize: 14)),
              const SizedBox(height: 30),
              const Text(
                'Chọn dữ liệu Super Calendar có thể truy cập',
                style: TextStyle(color: _ink, fontSize: 18, height: 1.35),
              ),
              const SizedBox(height: 18),
              _PermissionTile(
                icon: Icons.calendar_month,
                title: 'Xem, chỉnh sửa, chia sẻ và xóa vĩnh viễn các lịch bạn có thể truy cập bằng Google Calendar',
                selected: calendar,
                onChanged: onCalendar,
              ),
              const Divider(height: 1),
              _PermissionTile(
                icon: Icons.contacts_outlined,
                title: 'Xem thông tin hồ sơ cơ bản của bạn',
                selected: contacts,
                onChanged: onContacts,
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),
              const Text(
                'Quyền truy cập lịch cho phép Super Calendar đồng bộ sự kiện Google của bạn. Bạn có thể thu hồi quyền này trong cài đặt Tài khoản Google.',
                style: TextStyle(color: _muted, fontSize: 13, height: 1.55),
              ),
              const SizedBox(height: 10),
              const Text(
                'Chính sách quyền riêng tư  ·  Điều khoản dịch vụ',
                style: TextStyle(color: _blue, fontSize: 13, height: 1.7),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: calendar ? onContinue : null,
              child: const Text('Cho phép'),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final bool selected;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!selected),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff4285f4), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, color: _ink, height: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Checkbox(
            value: selected,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: _blue,
          ),
        ],
      ),
    ),
  );
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage({
    super.key,
    required this.email,
    required this.notifications,
    required this.calendar,
    required this.onContinue,
  });
  final String email;
  final bool notifications;
  final bool calendar;
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  color: Color(0xffe7f4ea),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xff188038),
                  size: 42,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Bạn đã sẵn sàng!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 27,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Tài khoản đã được kết nối với Super Calendar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xfff7f8fa),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      icon: Icons.account_circle_outlined,
                      title: 'Tài khoản',
                      value: email,
                    ),
                    const Divider(height: 22),
                    _SummaryRow(
                      icon: Icons.calendar_month_outlined,
                      title: 'Google Calendar',
                      value: calendar
                          ? 'Đã cho phép truy cập'
                          : 'Chưa cấp quyền',
                    ),
                    const Divider(height: 22),
                    _SummaryRow(
                      icon: Icons.notifications_none,
                      title: 'Thông báo',
                      value: notifications ? 'Đã bật' : 'Đang tắt',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Vào Super Calendar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoggedInSettingsPage extends StatelessWidget {
  const _LoggedInSettingsPage({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xfff5f6fa),
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        color: _ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Make SuperCalendar yours',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: const Color(0xffffe1ed),
                foregroundColor: const Color(0xff65415a),
                child: Text(
                  'MC',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff8439e8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond_outlined, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mia Chen · VIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Synced across 3 devices',
                        style: TextStyle(
                          color: Color(0xffeadcff),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                _SettingsRow(
                  icon: Icons.person_outline,
                  title: 'Account',
                  value: 'Mia Chen',
                ),
                _SettingsRow(
                  icon: Icons.light_mode_outlined,
                  title: 'Appearance',
                  value: 'Light',
                ),
                _SettingsRow(
                  icon: Icons.translate,
                  title: 'Language',
                  value: 'English',
                ),
                _SettingsRow(
                  icon: Icons.access_time,
                  title: 'Date & Time',
                  value: 'Automatic',
                ),
                _SettingsRow(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  value: 'On',
                ),
                _SettingsRow(
                  icon: Icons.calendar_month_outlined,
                  title: 'Calendar',
                  value: 'Edit',
                ),
                _SettingsRow(
                  icon: Icons.lock_outline,
                  title: 'Mobile Screen',
                  value: 'Edit',
                ),
                _SettingsRow(icon: Icons.help_outline, title: 'Help'),
                _SettingsRow(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  value: '1.0.0',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Signed in as $email',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.title, this.value});
  final IconData icon;
  final String title;
  final String? value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 54),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xffeceef2))),
    ),
    child: Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xff414754)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 13, color: _ink)),
        ),
        if (value != null)
          Text(value!, style: const TextStyle(fontSize: 11, color: _muted)),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 17, color: Color(0xffa5a9b1)),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: _muted),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
