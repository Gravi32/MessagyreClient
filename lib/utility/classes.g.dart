// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classes.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 0;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      content: fields[0] as String,
      sentAt: fields[1] as DateTime,
      isOwned: fields[2] as bool,
    ).._status = fields[4] as int;
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatAdapter extends TypeAdapter<Chat> {
  @override
  final int typeId = 1;

  @override
  Chat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chat(
      recipientUsername: fields[0] as String,
    )
      ..content = (fields[1] as List).cast<Message>()
      ..unreadMessages = fields[2] as int;
  }

  @override
  void write(BinaryWriter writer, Chat obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.recipientUsername)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.unreadMessages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HomeworkAdapter extends TypeAdapter<Homework> {
  @override
  final int typeId = 2;

  @override
  Homework read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Homework()
      ..subject = fields[0] as Subject
      ..content = fields[1] as String
      ..dueDate = fields[2] as DateTime
      ..creationDate = fields[3] as DateTime
      ..isGraded = fields[4] as bool
      ..isTest = fields[5] as bool
      ..isMarkedAsDone = fields[6] as bool;
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GradeAdapter extends TypeAdapter<Grade> {
  @override
  final int typeId = 4;

  @override
  Grade read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Grade()
      ..subject = fields[0] as Subject
      ..title = fields[1] as String
      ..grade = fields[2] as double
      ..date = fields[3] as DateTime
      ..details = fields[4] as String?
      ..weight = fields[5] as double
      ..groupName = fields[6] as String?;
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
