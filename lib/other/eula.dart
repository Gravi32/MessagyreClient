import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';

class EulaPage extends StatefulWidget {
  final bool readOnly;
  const EulaPage({super.key, this.readOnly = false});

  @override
  State<EulaPage> createState() => _EulaPageState();
}

class _EulaPageState extends State<EulaPage> {
  bool accepted = false;
  bool hasScrolledToEnd = false;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (!hasScrolledToEnd && scrollController.offset >= scrollController.position.maxScrollExtent) {
        setState(() => hasScrolledToEnd = true);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _acceptEula() async {
    if (!widget.readOnly) {
      final box = await Hive.openBox('Misc');
      await box.put('eulaAccepted', true);
    }
    final mountedContext = context;
    if (context.mounted) Navigator.of(mountedContext).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("Conditions d'utilisation", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: CupertinoColors.secondarySystemBackground.resolveFrom(context), borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: CustomText("""*Bienvenue sur Messagyre !*

Messagyre est une plateforme de messagerie sécurisée qui vise à offrir une expérience de communication fluide et respectueuse pour tous ses utilisateurs. Avant d'utiliser nos services, nous vous demandons de lire attentivement et d'accepter les conditions suivantes :

*1. Contenu généré par l'utilisateur*  
Vous êtes seul responsable du contenu que vous envoyez sur Messagyre. Les messages, images ou autres contenus offensants, illégaux, diffamatoires ou abusifs sont strictement interdits. Tout manquement peut entraîner la suspension ou la suppression immédiate de votre compte.

*2. Signalement et blocage*  
Vous avez la possibilité de signaler ou de bloquer tout utilisateur qui enfreint ces règles. Tous les signalements sont examinés avec attention et traités dans un délai maximal de 24 heures par notre équipe de modération afin d'assurer un environnement sûr et respectueux pour tous.

*3. Confidentialité et sécurité*  
La confidentialité de vos communications est primordiale. Tous les messages sont chiffrés et ne sont pas accessibles aux développeurs ou à des tiers. Messagyre s'engage à protéger vos données personnelles conformément à sa politique de confidentialité et aux lois applicables sur la protection des données.

*4. Respect et absence de tolérance*  
Tout comportement abusif, harcèlement ou tentative de nuire à la communauté peut entraîner des mesures disciplinaires, y compris la suspension ou la suppression de votre compte. Nous encourageons un usage respectueux et responsable de la plateforme.

*5. Propriété intellectuelle*  
Vous garantissez que tout contenu que vous partagez ne viole pas les droits de propriété intellectuelle d'autrui. Messagyre ne saurait être tenu responsable des infractions commises par ses utilisateurs.

*6. Acceptation des conditions*  
En acceptant ces conditions, vous vous engagez à respecter toutes les règles énoncées ci-dessus et à contribuer à maintenir une communauté sécurisée, respectueuse et agréable pour tous les utilisateurs.
""", style: TextStyle(fontSize: 16, color: CupertinoColors.label.resolveFrom(context))),
                  ),
                ),
              ),
              SizedBox(height: 16),

              if (!widget.readOnly) ...[
                CupertinoListSection.insetGrouped(
                  backgroundColor: CupertinoColors.transparent,
                  children: [
                    CupertinoListTile(
                      title: Text("J'ai lu et j'accepte les conditions", style: TextStyle(color: CupertinoColors.white)),
                      trailing: CupertinoSwitch(value: accepted, onChanged: hasScrolledToEnd ? (v) => setState(() => accepted = v) : null),
                      onTap: null,
                    ),
                  ],
                ),
                if (accepted)
                  CupertinoListSection.insetGrouped(
                    backgroundColor: CupertinoColors.transparent,
                    children: [
                      CupertinoListTile(
                        title: Center(child: Text("Continuer", style: TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.white))),
                        onTap: _acceptEula,
                      ),
                    ],
                  ),
              ],

              if (widget.readOnly)
                CupertinoListSection.insetGrouped(
                  backgroundColor: CupertinoColors.transparent,
                  children: [
                    CupertinoListTile(
                      title: Center(child: Text("Fermer", style: TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.white))),
                      onTap: _acceptEula,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> askUserToAcceptEula(BuildContext context) async {
  final box = await Hive.openBox('Misc');
  if (box.get('eulaAccepted') == true) return;
  if (!context.mounted) return;

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) => EulaPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return CupertinoFullscreenDialogTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: true,
          child: child,
        );
      },
    ),
  );
}

Future<void> showEulaReadOnly(BuildContext context) async {
  if (!context.mounted) return;

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) => EulaPage(readOnly: true),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return CupertinoFullscreenDialogTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: true,
          child: child,
        );
      },
    ),
  );
}
