/// 游戏相关异常基类
class GameException implements Exception {
  final String message;
  const GameException(this.message);

  @override
  String toString() => 'GameException: $message';
}

/// 游戏数据异常
class GameDataException extends GameException {
  const GameDataException(super.message);
}

/// 游戏状态异常
class GameStateException extends GameException {
  const GameStateException(super.message);
}

/// 游戏操作异常
class GameOperationException extends GameException {
  const GameOperationException(super.message);
}