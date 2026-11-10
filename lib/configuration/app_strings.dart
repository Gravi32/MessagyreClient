import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// The app's texts (in French). Shared wording lives here so that the same action is named the same way
/// everywhere; `*text*` is shown in bold by CustomText.
class AppStrings {
  // #region -> Common
  static const ok = "OK";
  static const cancel = "Annuler";
  static const close = "Fermer";
  static const confirm = "Confirmer";
  static const delete = "Supprimer";
  static const retry = "Réessayer";
  static const copy = "Copier";
  static const search = "Rechercher";
  static const connecting = "Connexion en cours";
  static const connectedToLocalhost = "Connecté au serveur local";
  static const confirmTitle = "Confirmer l'action";
  static const confirmCancel = "Voulez-vous vraiment *annuler* ? Cette action est irréversible.";
  static const thanks = "Merci !";
  // #endregion

  // #region -> Errors
  static const errorTitle = "Oups !";
  static const offlineError = "Impossible de joindre le serveur. Vérifiez votre connexion internet.";
  static const timeoutError = "Le serveur met trop de temps à répondre. Réessayez dans un instant.";
  static const serverError = "Le serveur a rencontré un problème. Réessayez plus tard.";
  static String fileTypeRefused(String name) =>
      "« $name » ne peut pas être envoyé : seuls les documents, les photos, les sons et les vidéos sont acceptés. Les programmes, les scripts et les archives sont refusés pour protéger les autres utilisateurs.";
  static const fileBlocked = "Ce type de fichier est bloqué par Messagyre : il pourrait contenir un programme dangereux. Il ne peut pas être ouvert ni enregistré.";
  static const sessionExpired = "Votre session a expiré. Reconnectez-vous.";
  static const pageError = "Cette page n'a pas pu être affichée : le contenu envoyé par le serveur est illisible.";
  static const fileMissing = "Le fichier n'est plus sur ce téléphone (il a peut-être été supprimé ou déplacé). Choisissez-le à nouveau.";

  /// A sentence for the user explaining a failed request. Never a vague "something went wrong": always what
  /// happened (and the code, so that a screenshot tells the developer what to look at).
  static String errorFor(http.Response response) {
    final code = response.statusCode;
    final body = response.body.trim();
    // A short, plain answer of the server is a reason ("NoClass", "TooLong"): worth showing
    final reason = body.isNotEmpty && body.length <= 60 && !body.contains("<") ? body.replaceAll('"', '') : null;
    final withReason = reason != null ? " : $reason" : "";

    return switch (code) {
      408 => timeoutError,
      401 || 403 => sessionExpired,
      404 => "Le serveur ne trouve pas ce qui est demandé (erreur 404$withReason).",
      405 || 501 => "Cette version de Messagyre et le serveur ne se comprennent pas (erreur $code). Mettez l'application à jour.",
      413 => "C'est trop lourd pour le serveur (erreur 413). Choisissez un fichier plus petit.",
      429 => "Trop de tentatives. Patientez quelques minutes.",
      507 => "Le serveur est plein pour le moment. Réessayez plus tard.",
      >= 500 => body == "Internal error" ? offlineError : "$serverError (erreur $code)",
      _ => "Le serveur a refusé la demande (erreur $code$withReason).",
    };
  }

  /// A sentence for the user explaining an exception: what failed, in words, with the system's own message
  static String describe(Object error) => switch (error) {
    SocketException() || http.ClientException() => offlineError,
    TimeoutException() => timeoutError,
    FileSystemException(:final message, :final osError) => "Le fichier n'a pas pu être lu ou enregistré sur ce téléphone (${osError?.message ?? message}).",
    PlatformException(:final code, :final message) =>
      code.contains("denied") || code.contains("access") ? permissionDenied : "Le téléphone a refusé l'opération : ${message ?? code}.",
    FormatException(:final message) => "Des données sont illisibles : $message.",
    _ => "Problème inattendu : $error",
  };
  // #endregion

  // #region -> Tabs
  static const tabGrades = "Notes";
  static const tabAssignments = "Devoirs";
  static const tabChats = "Conversations";
  static const tabSearch = "Recherche";
  static const tabSettings = "Réglages";
  // #endregion

  // #region -> Chats list
  static const chatsEmptyTitle = "Silence total…";
  static const chatsEmptySubtitle = "Messagyre est faite aussi pour discuter !";
  static const chatsEmptyAction = "Briser la glace";
  static const chatsNoMessage = "Envoyez un message…";
  static const deletedMessage = "Message supprimé";
  static const pinChat = "Épingler";
  static const unpinChat = "Désépingler";
  static const deleteChat = "Supprimer la conversation";
  static String deleteChatConfirm(String name) => "La conversation avec *$name* sera supprimée de cet appareil. Cette action est irréversible.";
  // #endregion

  // #region -> Chat
  static const messagePlaceholder = "Message";
  static const deleted = "Supprimé";
  static const today = "Aujourd'hui";
  static const yesterday = "Hier";
  static const blockHint = "Pour bloquer un utilisateur, allez sur son profil → Bloquer cet utilisateur.";
  static String encryptionOn(String name) => "Les messages et les fichiers de cette conversation sont chiffrés de bout en bout : seuls vous et $name pouvez les lire.";
  static const encryptionOff = "Cet utilisateur a une ancienne version de Messagyre qui ne prend pas en charge le chiffrement de bout en bout. L'envoi de photos et de fichiers est désactivé.";
  static const encryptionUnknown = "Vérification du chiffrement… Vos messages partiront dès que possible.";
  static const waitingForConnection = "En attente de connexion…";

  // Class chats
  static const classChatSubtitle = "Chat de la classe";
  static String classMembersCount(int count) => count == 1 ? "1 membre" : "$count membres";
  static const classChatLeft = "Vous n'êtes plus dans cette classe";
  static const classChatReadOnly = "Vous n'êtes plus dans cette classe : la conversation reste lisible, mais vous ne pouvez plus y écrire.";
  static const classChatHint = "Tous ceux qui ont choisi cette classe pour cette année scolaire en font partie. Vous pouvez changer de classe dans *Réglages → Ma classe*.";
  static const classMembersHint = "Tous ceux qui ont choisi cette classe cette année. Un nouveau membre ne voit que les messages écrits après son arrivée.";
  static const classEncryption = "Les messages et les fichiers de la classe sont chiffrés de bout en bout : seuls ses membres peuvent les lire.";
  static const supportWelcome =
      "Salut👋 !\n\nTu as une *question* sur *Messagyre* ou tu as rencontré un *problème* ? Je suis là pour t'aider !\n\nÉcris ici ce dont tu as besoin et je ferai de mon mieux pour te répondre le plus vite possible ! 😄\n\nLe support de Messagyre";

  static const deleteMessageTitle = "Supprimer le message";
  static const deleteMessageContent = "Choisissez *comment supprimer ce message*. Cette action est irréversible !";
  static const deleteForMe = "Supprimer pour moi";
  static const deleteForEveryone = "Supprimer pour tout le monde";


  static const report = "Signaler";
  static const reportTitle = "Signaler le message";
  static const reportContent =
      "Le message signalé sera envoyé à l'équipe de Messagyre pour évaluation. S'il est jugé inapproprié, des mesures seront prises.";
  static String reportAndBlock(String username) => "Signaler et bloquer $username";
  static const reportSent = "Signalement envoyé. Merci de nous aider à garder Messagyre sûre.";
  static const reportFailed = "Le signalement n'a pas pu être envoyé. Réessayez plus tard.";
  // #endregion

  // #region -> Attachments
  static const attachPhoto = "Photothèque";
  static const attachCamera = "Appareil photo";
  static const attachFile = "Fichier";
  static const photo = "Photo";
  static const saveToDevice = "Enregistrer sur l'appareil";
  static const saved = "Enregistré";
  static const tapToDownload = "Toucher pour télécharger";
  static const downloading = "Téléchargement…";
  static const uploading = "Envoi…";
  static const fileExpired = "Fichier expiré";
  static const fileExpiredContent = "Ce fichier n'est plus disponible sur le serveur : les fichiers sont gardés 30 jours au maximum.";
  static const fileOpenFailed = "Aucune application ne peut ouvrir ce fichier.";
  static String fileTooBig(int maxMegabytes) => "Ce fichier est trop volumineux : la taille maximale est de $maxMegabytes Mo.";
  static const permissionDenied = "Messagyre n'a pas accès à vos photos ou à l'appareil photo. Autorisez-le dans les réglages de l'appareil.";
  // #endregion

  // #region -> Assignments
  static const assignmentsSearch = "Chercher un devoir…";
  static const assignmentsEmptyTitle = "Rien pour le moment…";
  static const assignmentsEmptySubtitle = "Vos devoirs s'afficheront ici";
  static const assignmentsNoResults = "Aucun devoir ne correspond à votre recherche";
  static const addAssignment = "Ajouter un devoir";
  static const sectionShared = "Partagés avec la classe";
  static const sectionToday = "Pour aujourd'hui";
  static const sectionTomorrow = "Pour demain";
  static const sectionUpcoming = "À venir";
  static const sectionPast = "Passés";
  static const sharedNoClass = "Choisissez votre classe dans *Réglages → Ma classe* pour voir les devoirs partagés par vos camarades.";
  static const tagTest = "TEST";
  static const tagLeave = "CONGÉ";
  static const untitledTest = "Test sans titre";
  static const thisWeek = "Cette semaine";
  static const nextWeek = "La semaine d'après";
  static String sharedBy(String name) => "Partagé par $name";
  // #endregion

  // #region -> Search
  static const searchPlaceholder = "Rechercher un·e gymnasien·ne";
  static const searchEmptyTitle = "Recherchez un utilisateur";
  static const searchEmptySubtitle = "Et appuyez sur son profil\npour entamer une conversation !";
  static const searchNoResults = "Aucun utilisateur trouvé.";
  static const shortcuts = "Raccourcis";
  static const announcements = "Annonces";
  static const leaveReview = "Laisser un avis";
  static String leaveReviewContent(bool isAndroid) => "Soutenez Messagyre en laissant un avis sur ${isAndroid ? "Google Play" : "l'App Store"} !";
  // #endregion

  // #region -> Grades
  // #endregion

  // #region -> Locked page
  static const lockedTitle = "Page bloquée";
  static const lockedContent = "Cette page est confidentielle :\nidentifiez-vous avec Face ID pour continuer.";
  static const lockedHint = "Vous pouvez désactiver cet écran dans les réglages.";
  static const unlock = "Déverrouiller";
  // #endregion

  // #region -> Formatting

  /// "1,2 Mo", "350 Ko"
  static String fileSize(int bytes) {
    if (bytes < 1024) return "$bytes o";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).round()} Ko";
    final megabytes = bytes / (1024 * 1024);
    return "${megabytes.toStringAsFixed(megabytes < 10 ? 1 : 0).replaceAll('.', ',')} Mo";
  }

  // #endregion
}
