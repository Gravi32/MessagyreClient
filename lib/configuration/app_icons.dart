import 'package:hugeicons/hugeicons.dart';

/// Every icon of the interface, by meaning. One icon set (HugeIcons, stroke rounded) for the whole app:
/// pick from here rather than from HugeIcons, CupertinoIcons or Material Icons directly.
/// (The icons users choose for their subjects are data, not interface: they stay in the subjects' pickers.)
class AppIcons {
  // Navigation
  static const back = HugeIcons.strokeRoundedArrowLeft01;
  static const close = HugeIcons.strokeRoundedCancel01;
  static const chevronRight = HugeIcons.strokeRoundedArrowRight01;
  static const chevronDown = HugeIcons.strokeRoundedArrowDown01;
  static const scrollDown = HugeIcons.strokeRoundedArrowDown01;

  // Tabs
  static const grades = HugeIcons.strokeRoundedCheckmarkBadge04;
  static const assignments = HugeIcons.strokeRoundedWork;
  static const chats = HugeIcons.strokeRoundedMessageMultiple02;
  static const search = HugeIcons.strokeRoundedSearch01;
  static const settings = HugeIcons.strokeRoundedSettings05;

  // Actions
  static const add = HugeIcons.strokeRoundedAdd01;
  static const edit = HugeIcons.strokeRoundedPencilEdit02;
  static const delete = HugeIcons.strokeRoundedDelete02;
  static const copy = HugeIcons.strokeRoundedCopy01;
  static const save = HugeIcons.strokeRoundedDownload04;
  static const share = HugeIcons.strokeRoundedShare08;
  static const retry = HugeIcons.strokeRoundedRefresh;
  static const done = HugeIcons.strokeRoundedTick02;
  static const pin = HugeIcons.strokeRoundedPin;
  static const unpin = HugeIcons.strokeRoundedPinOff;
  static const report = HugeIcons.strokeRoundedFlag02;
  static const block = HugeIcons.strokeRoundedUserBlock01;
  static const profile = HugeIcons.strokeRoundedUser;
  static const newChat = HugeIcons.strokeRoundedBubbleChatAdd;
  static const clear = HugeIcons.strokeRoundedCancel01;
  static const more = HugeIcons.strokeRoundedMoreHorizontal;

  // Chat
  static const send = HugeIcons.strokeRoundedSent;
  static const attach = HugeIcons.strokeRoundedAttachment01;
  static const photo = HugeIcons.strokeRoundedImage02;
  static const camera = HugeIcons.strokeRoundedCamera01;
  static const file = HugeIcons.strokeRoundedFile02;
  static const download = HugeIcons.strokeRoundedDownload01;
  static const fileMissing = HugeIcons.strokeRoundedFileNotFound;
  static const imageMissing = HugeIcons.strokeRoundedImageNotFound01;
  static const encrypted = HugeIcons.strokeRoundedSquareLock02;
  static const notEncrypted = HugeIcons.strokeRoundedSquareUnlock02;
  static const deleted = HugeIcons.strokeRoundedUnavailable;
  static const blocked = HugeIcons.strokeRoundedUnavailable;
  static const date = HugeIcons.strokeRoundedCalendar04;

  // Message status
  static const statusSending = HugeIcons.strokeRoundedClock01;
  static const statusSent = HugeIcons.strokeRoundedTick02;
  static const statusDelivered = HugeIcons.strokeRoundedTickDouble02;
  static const statusFailed = HugeIcons.strokeRoundedAlertCircle;

  // File types
  static const pdf = HugeIcons.strokeRoundedPdf01;
  static const archive = HugeIcons.strokeRoundedFileZip;
  static const text = HugeIcons.strokeRoundedTxt01;
  static const document = HugeIcons.strokeRoundedDoc01;
  static const spreadsheet = HugeIcons.strokeRoundedXls01;
  static const presentation = HugeIcons.strokeRoundedPpt01;
  static const video = HugeIcons.strokeRoundedVideo01;
  static const audio = HugeIcons.strokeRoundedMusicNote01;

  // Forms and grades
  static const missing = HugeIcons.strokeRoundedAlertCircle;
  static const locked = HugeIcons.strokeRoundedLock;
  static const goalPass = HugeIcons.strokeRoundedFirstAidKit;
  static const goalUp = HugeIcons.strokeRoundedArrowUpRight01;
  static const goalKeep = HugeIcons.strokeRoundedMinusSign;
  static const goalDown = HugeIcons.strokeRoundedArrowDownRight01;

  // Information
  static const info = HugeIcons.strokeRoundedInformationCircle;
  static const warning = HugeIcons.strokeRoundedAlert02;
  static const offline = HugeIcons.strokeRoundedWifiDisconnected01;
  static const notification = HugeIcons.strokeRoundedNotification01;

  // Empty states
  static const emptyChats = HugeIcons.strokeRoundedSleeping;
  static const emptyList = HugeIcons.strokeRoundedDashedLine02;
  static const noResults = HugeIcons.strokeRoundedSearchRemove;
}
