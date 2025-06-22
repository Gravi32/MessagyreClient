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
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.sentAt)
      ..writeByte(2)
      ..write(obj.isOwned);
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
      ..title = fields[0] as String
      ..subject = fields[1] as Subject
      ..dueDate = fields[2] as DateTime
      ..description = fields[3] as String?
      ..creationDate = fields[4] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Homework obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.subject)
      ..writeByte(2)
      ..write(obj.dueDate)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.creationDate);
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
