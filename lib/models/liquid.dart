import 'dart:ui';

/// 液体类
class Liquid {
  /// 液体的颜色（使用 [Color] 类型表示）
  final Color color;
  /// 液体的体积（单位：游戏自定义单位，如"滴"或"毫升"）
  int volume;

  /// 构造函数
  Liquid({required this.color, required this.volume}) {
    if (volume <= 0) throw ArgumentError("液体体积必须大于0");
  }

  /// 拷贝
  Liquid copy() => Liquid(color: color, volume: volume);

  /// 将当前液体拆分为两个指定体积的液体
  /// 返回新创建的液体实例，原实例体积减少
  Liquid split(int amount) {
    if (amount <= 0) throw ArgumentError("拆分量必须大于0");
    if (amount >= volume) throw ArgumentError("拆分量不能超过当前体积");

    final newLiquid = Liquid(color: color, volume: amount);
    volume -= amount;
    return newLiquid;
  }

  /// 判断是否可以合并
  bool canMerge(Liquid other) => color == other.color;

  /// 合并另一个同颜色的液体（生成新实例，原实例不变）
  void merge(Liquid other) {
    if (!canMerge(other)) throw ArgumentError("无法合并不同颜色的液体");
    volume += other.volume;
  }

  /// 转换为 JSON 格式
  Map<String, dynamic> toJson() => {
    'color': color.toARGB32(),
    'volume': volume,
  };

  /// 从 JSON 格式还原
  factory Liquid.fromJson(Map<String, dynamic> json) => Liquid(
    color: Color(json['color'] as int),
    volume: json['volume'] as int,
  );
}