part of 'classes.dart';

extension FieldsHelper on Map<int, dynamic> {
  T get<T>(int key, T defaultValue) {
    final value = this[key];
    if (value is T) return value;
    return defaultValue;
  }

  List<T> getList<T>(int key, [List<T> defaultValue = const []]) {
    final value = this[key];
    if (value is List) return value.cast<T>();
    return defaultValue;
  }
}

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 0;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};

    return Message(content: fields.get(0, "Une erreur s'est produite."), sentAt: fields.get(1, DateTime(0)), isOwned: fields.get(2, false))
      .._status = fields.get(4, 0);
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.sentAt)
      ..writeByte(2)
      ..write(obj.isOwned)
      ..writeByte(4)
      ..write(obj._status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MessageAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class ChatAdapter extends TypeAdapter<Chat> {
  @override
  final int typeId = 1;

  @override
  Chat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};

    return Chat(recipientUsername: fields.get(0, "Unknown"))
      ..content = fields.getList<Message>(1)
      ..unreadMessages = fields.get(2, 0)
      ..recipientDisplayUsername = fields.get(3, null)
      ..isPinned = fields.get(4, false);
  }

  @override
  void write(BinaryWriter writer, Chat obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.recipientUsername)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.unreadMessages)
      ..writeByte(3)
      ..write(obj.recipientDisplayUsername)
      ..writeByte(4)
      ..write(obj.isPinned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChatAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class HomeworkAdapter extends TypeAdapter<Homework> {
  @override
  final int typeId = 2;

  @override
  Homework read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};

    return Homework()
      ..subject = fields.get(0, Subject.Other)
      ..content = fields.get(1, "")
      ..dueDate = fields.get(2, DateTime(0))
      ..creationDate = fields.get(3, DateTime(0))
      ..isGraded = fields.get(4, false)
      ..isTest = fields.get(5, false)
      ..isMarkedAsDone = fields.get(6, false);
  }

  @override
  void write(BinaryWriter writer, Homework obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.subject)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.dueDate)
      ..writeByte(3)
      ..write(obj.creationDate)
      ..writeByte(4)
      ..write(obj.isGraded)
      ..writeByte(5)
      ..write(obj.isTest)
      ..writeByte(6)
      ..write(obj.isMarkedAsDone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HomeworkAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class GradeAdapter extends TypeAdapter<Grade> {
  @override
  final int typeId = 4;

  @override
  Grade read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};

    return Grade()
      ..subject = fields.get(0, Subject.Other)
      ..title = fields.get(1, "")
      ..grade = fields.get(2, 0)
      ..date = fields.get(3, DateTime(0))
      ..details = fields.get<String?>(4, null)
      ..weight = fields.get(5, 0)
      ..groupName = fields.get<String?>(6, null);
  }

  @override
  void write(BinaryWriter writer, Grade obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.subject)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.grade)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.details)
      ..writeByte(5)
      ..write(obj.weight)
      ..writeByte(6)
      ..write(obj.groupName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GradeAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 5;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};

    return Settings()
      ..includeWeekends = fields.get(0, false)
      ..useDefaultWallpaper = fields.get(1, true);
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.includeWeekends)
      ..writeByte(1)
      ..write(obj.useDefaultWallpaper); 
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GradeAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}