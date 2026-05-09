import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';

class PrivacyPolicyPage extends StatefulWidget {
  final bool readOnly;
  const PrivacyPolicyPage({super.key, this.readOnly = false});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background.adaptTo(context),
      navigationBar: CupertinoNavigationBar(middle: Text("Politique de confidentialité")),
      child: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 10, vertical: 10),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: .circular(12)),
                  padding: .all(10),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: CustomText("""*Politique de confidentialité de Messagyre*

*1. Objet*
La présente politique de confidentialité a pour objet d'informer les utilisateurs de l'application Messagyre des modalités de collecte, d'utilisation, de conservation et de protection de leurs données personnelles, conformément à la Loi fédérale sur la protection des données (LPD, RS 235.1), telle que révisée (nLPD), ainsi qu'aux législations suisses applicables.

*2. Responsable du traitement*
Le responsable du traitement des données personnelles est:
Pietro Gravina

*3. Données personnelles collectées*
Messagyre traite des données personnelles selon trois catégories distinctes: données conservées exclusivement en local sur l'appareil de l'utilisateur, données transmises au backend sous forme chiffrée, et données transmises au backend en clair.

*3.1 Données conservées exclusivement en local*
Les données suivantes sont stockées uniquement sur l'appareil de l'utilisateur et ne sont jamais transmises aux serveurs de Messagyre:
- notes scolaires;
- devoirs et tâches;
- messages privés après leur réception;
- paramètres et réglages de l'application.

*3.2 Données transmises au backend sous forme chiffrée*
Les données suivantes sont transmises aux serveurs de Messagyre sous une forme sécurisée:
- mot de passe, stocké exclusivement sous forme hachée;
- messages privés envoyés mais non encore reçus par le destinataire.

*3.3 Données transmises au backend en clair*
Les données suivantes sont transmises et traitées en clair par le backend de Messagyre:
- pseudonyme;
- adresse e-mail scolaire;
- biographie, lorsqu'elle est renseignée;
- photo de profil, lorsqu'elle est fournie;
- date du dernier accès;
- date de création du compte;
- classe de l'utilisateur, définie exclusivement par le serveur.

*4. Messages privés et chiffrement*
Les messages privés échangés sur Messagyre sont chiffrés de bout en bout lors de leur transmission.
En conséquence:
- le contenu des messages n'est accessible qu'aux participants de la conversation;
- Messagyre et ses développeurs ne peuvent ni lire, ni intercepter, ni analyser les messages privés;
- les messages reçus sont conservés uniquement en local sur l'appareil de l'utilisateur.

*5. Contenus non chiffrés*
Certains contenus visibles publiquement ou semi-publiquement ne sont pas chiffrés, notamment:
- pseudonymes;
- biographies;
- photos de profil;
- informations de profil visibles.

Ces contenus peuvent faire l'objet d'un filtrage automatique limité destiné à prévenir la diffusion de contenus manifestement illégaux, abusifs ou contraires aux règles de la plateforme, conformément au droit suisse.

*6. Hébergement des données*
Les données personnelles traitées par le backend de Messagyre sont hébergées dans un data center situé à Milan, en Italie, chez le prestataire OVH. OVH s'engage à respecter le RGPD et garantit la sécurité physique et logique du data center.  
Messagyre prend toutes les mesures nécessaires pour garantir la sécurité et la confidentialité des données stockées sur ce serveur, conformément au droit suisse et aux exigences de la nLPD.

*7. Finalités du traitement*
Les données personnelles sont traitées exclusivement afin de:
- fournir, exploiter et maintenir le service Messagyre;
- permettre la communication entre utilisateurs;
- assurer la sécurité, la stabilité et le bon fonctionnement de l'application;
- respecter les obligations légales applicables en Suisse.

Aucune donnée n'est vendue, louée ou utilisée à des fins commerciales ou publicitaires.

*8. Partage des données*
Les données personnelles ne sont jamais transmises à des tiers, sauf:
- en cas d'obligation légale prévue par le droit suisse;
- sur demande légitime des autorités compétentes, dans le respect des procédures légales.

*9. Conservation des données*
Les données personnelles sont conservées uniquement pendant la durée nécessaire à la fourniture du service.
En cas de suppression du compte utilisateur:
- les données associées sont supprimées ou rendues anonymes dans un délai raisonnable;
- les messages chiffrés demeurent définitivement inaccessibles à Messagyre.

*10. Droits des utilisateurs*
Conformément à la nLPD, chaque utilisateur dispose notamment des droits suivants:
- droit d'accès à ses données personnelles;
- droit de rectification des données inexactes;
- droit à la suppression, lorsque cela est légalement possible;
- droit à la limitation du traitement dans les cas prévus par la loi.

Les demandes relatives à l'exercice de ces droits peuvent être effectuées via les moyens de contact proposés dans l'application.

*11. Sécurité des données*
Messagyre met en œuvre des mesures techniques et organisationnelles appropriées afin de protéger les données personnelles contre tout accès non autorisé, perte, altération ou divulgation.

*12. Modification de la politique*
Messagyre se réserve le droit de modifier la présente politique de confidentialité afin d'assurer sa conformité au droit suisse ou d'améliorer la transparence.
Toute modification substantielle sera communiquée aux utilisateurs via l'application.

*13. Contact*
Pour toute question relative à la protection des données personnelles ou à la présente politique de confidentialité, l'utilisateur peut contacter Messagyre via l'application.

*Messagyre* - *Pietro Gravina*
""", style: TextStyle(fontSize: 14, fontWeight: .w300, color: AppColors.text.adaptTo(context))),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
