import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

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
                child: CustomText("""*Conditions d'utilisation de Messagyre*

*1. Acceptation*
En utilisant Messagyre, l'utilisateur confirme avoir lu et accepté intégralement les présentes conditions. Messagyre applique une politique de tolérance zéro envers les contenus illégaux, abusifs ou contraires aux lois applicables.

*2. Contenu généré par les utilisateurs*
L'utilisateur est seul responsable de l'ensemble des contenus qu'il partage. Tout contenu illégal, diffamatoire, haineux, incitant à la violence, sexuellement explicite impliquant des mineurs, ou contraire aux lois et règlements est strictement interdit. Tout manquement peut entraîner la suspension ou la suppression définitive du compte.

*3. Chiffrement et limites techniques*
Les messages privés et les messages des conversations de classe échangés sur Messagyre sont chiffrés de bout en bout. En raison de ce chiffrement, ils ne peuvent pas être lus, filtrés ou analysés par Messagyre. Par conséquent, le filtrage automatique s'applique uniquement aux contenus non chiffrés, tels que les pseudonymes, les biographies, les images de profil, les noms de groupes, la conversation générale et les autres informations publiques ou semi-publiques.

*4. Système automatique de détection*
Messagyre utilise un système automatique minimal de détection pour empêcher la publication de contenus non chiffrés potentiellement offensants, illégaux ou contraires à ces conditions.

*5. Conversation générale*
La conversation générale est ouverte à tous les utilisateurs de Messagyre : ses messages ne sont pas chiffrés de bout en bout et peuvent être lus par tous. Pour éviter les abus, le nombre de messages et de photos que chacun peut y envoyer est limité, et les fichiers n'y sont pas acceptés. Un utilisateur signalé par trois personnes différentes ne peut plus y écrire pendant trois jours ; signalé par cinq personnes, il en est exclu. Chacun peut rendre cette conversation silencieuse.

*6. Signalement du contenu illicite ou abusif*
Les utilisateurs disposent d'un mécanisme clair pour signaler tout contenu ou comportement problématique. Tout signalement est examiné dans un délai maximal de 24 heures. En cas de violation avérée, Messagyre peut supprimer le contenu, restreindre les fonctionnalités ou suspendre le compte concerné.

*7. Blocage des utilisateurs*
Chaque utilisateur peut bloquer d'autres utilisateurs à tout moment afin d'empêcher toute communication non désirée. Le blocage est immédiat et reste actif tant que l'utilisateur ne le retire pas.

*8. Comportements interdits*
Il est strictement interdit de :
- harceler, menacer ou intimider d'autres utilisateurs ;
- partager des contenus illégaux ou inappropriés ;
- chercher à contourner les systèmes de modération ;
- usurper l'identité d'autrui ;
- utiliser Messagyre à des fins frauduleuses ou criminelles.

Toute violation peut entraîner des mesures disciplinaires immédiates, y compris la suppression définitive du compte.

*9. Responsabilité*
Messagyre ne peut être tenu responsable des contenus générés par les utilisateurs. Toutefois, Messagyre s'engage à intervenir rapidement en cas de signalement et à supprimer tout contenu violant les présentes conditions.

*10. Protection des données et analyses*
Messagyre collecte et traite certaines données techniques et d'utilisation à des fins analytiques, notamment pour comprendre l'utilisation de l'application, améliorer les performances, la stabilité, la sécurité et l'expérience utilisateur.

Ces données analytiques peuvent inclure, de manière non exhaustive :
- la durée de connexion et le temps d'utilisation ;
- le nombre de messages, de notes et de devoirs enregistrés ;
- l'activité générale dans l'application ;
- les statistiques d'utilisation des fonctionnalités.

Le contenu des messages privés reste exclu de toute analyse.

*11. Modification des conditions*
Messagyre se réserve le droit de modifier les présentes conditions afin de respecter les obligations légales et les politiques des plateformes de distribution. Toute modification importante sera notifiée à l'utilisateur.

*12. Acceptation finale*
En continuant à utiliser Messagyre, l'utilisateur confirme accepter sans réserve l'ensemble de ces conditions et s'engage à adopter un comportement responsable, légal et respectueux envers les autres membres de la plateforme.

*Messagyre* – *Pietro Gravina*""", style: AppStyles.primaryText(context).copyWith(fontWeight: .w300)),
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
                  trailing: hasScrolledToEnd ? CupertinoSwitch(activeTrackColor: AppColors.accent, value: accepted, onChanged: (v) => setState(() => accepted = v)) : null,
                ),
              ],
            ),

            if (accepted) Button(text: "Continuer", onTap: _acceptTermsOfService),
          ],
          BottomSpacing(),
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
