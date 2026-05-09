import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';

class TermsOfServicePage extends StatefulWidget {
  final bool readOnly;
  const TermsOfServicePage({super.key, this.readOnly = false});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  final globals = GlobalsService();

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

  Future<void> _acceptTermsOfService() async {
    if (!widget.readOnly) {
      globals.persistent.setBool("UserAcceptedToS", true);
    }
    final mountedContext = context;
    if (context.mounted) Navigator.of(mountedContext).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      topBar: TopBar.tab(context, title: "Conditions d'utilisation"),
      child: Column(
        spacing: 16,
        children: [
          Expanded(
            child: RoundContainer(
              child: SingleChildScrollView(
                controller: scrollController,
                child: CustomText(
                  """*Conditions d'utilisation de Messagyre*

*1. Acceptation*
En utilisant Messagyre, l'utilisateur confirme avoir lu et accepte integralement les presentes conditions. Messagyre applique une politique de tolerance zero envers les contenus illegaux, abusifs ou contraires aux lois applicables.

*2. Contenu genere par les utilisateurs*
L'utilisateur est seul responsable de l'ensemble des contenus qu'il partage. Tout contenu illegal, diffamatoire, haineux, incitant a la violence, sexuellement explicite impliquant des mineurs, ou contraire aux lois et reglements est strictement interdit. Tout manquement peut entrainer la suspension ou la suppression definitive du compte.

*3. Chiffrement et limites techniques*
Les messages prives echanges sur Messagyre sont chiffrés de bout en bout. En raison de ce chiffrement, les messages prives ne peuvent pas etre lus, filtres ou analyses par Messagyre. Par consequent, le filtrage automatique s'applique uniquement aux contenus non chiffrés tels que pseudonymes, biographies, images de profil, noms de groupes et autres informations publiques ou semi-publiques.

*4. Systeme automatique de detection*
Messagyre utilise un systeme automatique minimal de detection pour empecher la publication de contenus non chiffrés potentiellement offensants, illegaux ou contraires a ces conditions. Ce systeme vise uniquement a prevenir la diffusion de contenus manifestement problematiques et ne s'applique pas aux messages prives.

*5. Signalement du contenu illicite ou abusif*
Les utilisateurs disposent d'un mecanisme clair pour signaler tout contenu ou comportement problematique. Tout signalement est examine dans un delai maximal de 24 heures. En cas de violation averee, Messagyre peut supprimer le contenu, restreindre les functionalities ou suspendre le compte concerne.

*6. Blocage des utilisateurs*
Chaque utilisateur peut bloquer d'autres utilisateurs a tout moment afin d'empecher toute communication non desiree. Le blocage est immediat et irreversible tant que l'utilisateur ne le retire pas.

*7. Comportements interdits*
Il est strictement interdit de:
- harceler, menacer ou intimider d'autres utilisateurs;
- partager des contenus illegaux ou inappropries;
- chercher a contourner les systemes de moderation;
- usurper l'identite d'autrui;
- utiliser Messagyre a des fins frauduleuses ou criminelles.

Toute violation peut entrainer des mesures disciplinaires immediates, y compris la suppression definitive du compte.

*8. Responsabilite*
Messagyre ne peut etre tenu responsable des contenus generes par les utilisateurs. Toutefois, Messagyre s'engage a intervenir rapidement en cas de signalement et a supprimer tout contenu violant les presentes conditions.

*9. Protection des donnees*
Les donnees personnelles sont traitees conformement aux lois en vigueur et a la politique de confidentialite de Messagyre. Les contenus prives chiffrés ne sont jamais accessibles aux developpeurs ou a des tiers.

*10. Modification des conditions*
Messagyre se reserve le droit de modifier les presentes conditions afin de respecter les obligations legales et les politiques des plateformes de distribution. Toute modification importante sera notifiee a l'utilisateur.

*11. Acceptation finale*
En continuant a utiliser Messagyre, l'utilisateur confirme accepter sans reserve l'ensemble de ces conditions et s'engage a respecter un comportement responsable, legal et respectueux envers les autres membres de la plateforme.



*Messagyre* - *Pietro Gravina*
""",
                  style: AppStyles.primaryText(context),
                  boldWeight: .w800,
                ),
              ),
            ),
          ),

          if (!widget.readOnly) ...[
            ListSection(
              children: [
                ListTile.simple(
                  context,
                  title: hasScrolledToEnd ? "J'ai lu et j'accepte les conditions" : "Lire le document pour continuer",
                  buildChevron: false,
                  trailing: hasScrolledToEnd ? CupertinoSwitch(value: accepted, onChanged: (v) => setState(() => accepted = v)) : null,
                ),
              ],
            ),

            if (accepted) Button(text: "Continuer", onTap: _acceptTermsOfService),
          ],
          SizedBox(),
        ],
      ),
    );
  }
}

Future<void> askUserToAcceptTermsOfService(BuildContext context) async {
  final globals = GlobalsService();

  if (globals.persistent.getBool("UserAcceptedToS") == true) return;
  if (!context.mounted) return;

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) => TermsOfServicePage(),
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
