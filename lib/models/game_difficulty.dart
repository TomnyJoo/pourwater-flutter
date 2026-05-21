
/// 游戏难度
class  GameDifficulty {
  final String displayName; ///难度名称（如"简单"）
  final int numberOfTubes; /// 试管数量
  final int tubeCapacity; /// 每个试管的大容量（可容纳的液体单位数）
  final int numberOfColors; /// 液体颜色种类数量

  const GameDifficulty({
    required this.displayName,
    required this.numberOfTubes,
    required this.tubeCapacity,
    required this.numberOfColors,
  });

  static const easy = GameDifficulty(
    displayName: "简单",
    numberOfTubes: 6,
    tubeCapacity: 4,
    numberOfColors: 4,
  );

  static const medium = GameDifficulty(
    displayName: "中等",
    numberOfTubes: 8,
    tubeCapacity: 5,
    numberOfColors: 5,
  );

  static const hard = GameDifficulty(
    displayName: "困难",
    numberOfTubes: 10,
    tubeCapacity: 6,
    numberOfColors: 7,
  );

  static const expert = GameDifficulty(
    displayName: "专家",
    numberOfTubes: 12,
    tubeCapacity: 7,
    numberOfColors: 9,
  );
}