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
                    child: CustomText("""*Bienvenue sur Messagyre*

Messagyre est une plateforme de messagerie dont l'utilisation est strictement soumise aux presentes conditions. Tout utilisateur doit les lire attentivement et les accepter integralement avant d'acceder au service. Messagyre applique une politique rigoureuse concernant la securite, la moderation et le respect des regles imposees par l'App Store.

*1. Contenu genere par l'utilisateur*  
L'utilisateur est entierement et exclusivement responsable de tout contenu qu'il transmet dans l'application. La publication ou la transmission de contenus illegaux, offensants, diffamatoires, discriminatoires, violents, menaçants, abusifs, obscenes, nuisibles ou contraires aux lois en vigueur est strictement interdite. Messagyre applique une tolerance zero : tout contenu non conforme peut etre supprime immediatement, sans preavis, et peut entrainer la suspension ou la fermeture definitive du compte.

*2. Systeme de filtrage et de moderation*  
Messagyre met en place des mecanismes destines a prevenir la diffusion de contenu inapproprie, incluant des outils automatises, des verifications manuelles et une equipe de moderation chargee de veiller au respect des regles. Messagyre se reserve le droit de renforcer ou d'adapter ces mesures a tout moment afin de maintenir un environnement securise et conforme.

*3. Signalement du contenu et traitement sous 24 heures*  
L'utilisateur peut signaler n'importe quel contenu ou comportement non conforme via une fonctionnalite dediee. Chaque signalement est examine individuellement et traite dans un delai maximum de vingt-quatre heures. Messagyre peut supprimer immediatement tout contenu signale et appliquer des sanctions a l'utilisateur concerne, pouvant aller jusqu'a la desactivation de son compte.

*4. Blocage des utilisateurs*  
L'application permet de bloquer tout utilisateur adoptant un comportement problematique. Une fois bloque, l'utilisateur ne peut plus envoyer de messages ni interagir avec la personne qui l'a bloque. Messagyre peut appliquer des mesures supplementaires si un abus est constate.

*5. Comportement exige et infractions graves*  
Un comportement strictement respectueux est exige de tous les utilisateurs. Toute forme de harcelement, menace, intimidation, incitation a la haine, tentative de nuire ou comportement perturbant la securite de la communaute constitue une infraction grave. Messagyre peut prendre des mesures immediates et definitives sans avertissement.

*6. Confidentialite et securite des donnees*  
Messagyre assure la confidentialite des communications grace au chiffrement et a des protocoles de securite conformes aux normes actuelles. Les messages ne sont accessibles ni aux developpeurs ni a des tiers non autorises. Les donnees personnelles sont traitees exclusivement dans le cadre legal et selon la politique de confidentialite de Messagyre.

*7. Propriete intellectuelle*  
L'utilisateur garantit que tout contenu partage ne viole pas de droits de propriete intellectuelle. En cas d'infraction, l'utilisateur en assume l'entiere responsabilite. Messagyre se reserve le droit de supprimer tout contenu litigieux et de suspendre immediatement le compte associe.

*8. Informations du profil public*  
Le pseudonyme, la biographie et la photo de profil, lorsqu'ils sont fournis, sont visibles par les autres utilisateurs. Ces informations servent uniquement a l'identification au sein de Messagyre et ne sont jamais exploitees a des fins commerciales externes ni transmises a des tiers non autorises.

*9. Donnees locales*  
Les donnees stockees localement, telles que notes ou devoirs, restent exclusivement sur l'appareil de l'utilisateur et ne sont jamais envoyees aux serveurs de Messagyre.

*10. Acceptation des conditions*  
L'utilisation de Messagyre implique l'acceptation totale, sans reserve, de l'ensemble des conditions definies dans ce document. Tout manquement expose l'utilisateur a des sanctions immediates pouvant aller jusqu'a la suppression definitive du compte. Messagyre peut modifier ou mettre a jour ces conditions a tout moment pour des raisons legales, techniques ou de securite.

Messagyre - Pietro Gravina

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
