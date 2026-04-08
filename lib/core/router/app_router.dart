import 'package:go_router/go_router.dart';
import '../../presentation/splash_screen.dart';
import '../../presentation/home_screen.dart';
import '../../presentation/create_letter_screen.dart';
import '../../presentation/archive_screen.dart';
import '../../presentation/store_screen.dart';
import '../../presentation/view_letter_screen.dart';
import '../../presentation/settings_screen.dart';
import '../../presentation/legal_view_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/create',
      builder: (context, state) => const CreateLetterScreen(),
    ),
    GoRoute(
      path: '/archive',
      builder: (context, state) => const ArchiveScreen(),
    ),
    GoRoute(
      path: '/letter/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ViewLetterScreen(letterId: id);
      },
    ),
    GoRoute(
      path: '/store',
      builder: (context, state) => const StoreScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const LegalViewScreen(
        title: '利用規約',
        content: _dummyTerms,
      ),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const LegalViewScreen(
        title: 'プライバシーポリシー',
        content: _dummyPrivacy,
      ),
    ),
  ],
);

const _dummyTerms = '''
利用規約

第1条（適用）
本規約は、ユーザーと当チームとの間の本サービスの利用に関わる全ての関係に適用されるものとします。

第2条（禁止事項）
ユーザーは、本サービスの利用にあたり、以下の行為をしてはなりません。
1. 法令または公序良俗に違反する行為
2. 犯罪行為に関連する行為
3. 当チーム、ほかのユーザー、または第三者のサーバーまたはネットワークの機能を破壊したり、妨害したりする行為
4. 当チームのサービスの運営を妨害するおそれのある行為
5. ほかのユーザーに関する個人情報等を収集または蓄積する行為
6. 不正アクセスをし、またはこれを試みる行為
7. ほかのユーザーに成りすます行為
8. 当チームのサービスに関連して、反社会的勢力に対して直接または間接に利益を供与する行為
9. その他、当チームが不適切と判断する行為

...（中略）...

第3条（免責事項）
当チームの債務不履行責任は、当チームの故意または重過失によらない場合には免責されるものとします。
''';

const _dummyPrivacy = '''
プライバシーポリシー

当チームは、本サービスにおいてユーザーの個人情報の取扱いについて、以下のとおりプライバシーポリシーを定めます。

1. 個人情報の収集方法
当社は、ユーザーが利用登録をする際に氏名、生年月日、住所、電話番号、メールアドレスなどの個人情報をお尋ねすることがあります。

2. 個人情報を収集・利用する目的
当社が個人情報を収集・利用する目的は、以下のとおりです。
- 当社サービスの提供・運営のため
- ユーザーからのお問い合わせに回答するため
- ユーザーが利用中のサービスの新機能、更新情報、キャンペーン等及び当社が提供する他のサービスのご案内をメールにて送付するため
- メンテナンス、重要なお知らせなど必要に応じたご連絡のため

3. 個人情報の第三者提供
当社は、個人情報保護法その他の法令で認められる場合を除き、あらかじめユーザーの同意を得ることなく、第三者に個人情報を提供することはありません。
''';
