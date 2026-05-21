import 'dart:ui';
import 'liquid.dart';

/// 试管类
class Tube {
  // region 【属性】
  final int id; /// 试管ID
  final int capacity; /// 试管容量
  List<Liquid> liquids; /// 试管中的液体列表
  // endregion

  // region 【公共访问器】
  int get currentVolume => liquids.fold(0, (sum, liquid) => sum + liquid.volume);
  int get remainingCapacity => capacity - currentVolume;
  bool get isEmpty => liquids.isEmpty;
  bool get isFull => currentVolume >= capacity;
  Liquid? get topLiquid => liquids.isEmpty ? null : liquids.last;
  // endregion

  // region 【构造函数】
  /// 构造函数
  Tube({required this.id, required this.capacity,List<Liquid>? liquids,}): liquids = liquids ?? [];
  // endregion

  // region 【状态管理】
  /// 判断试管是否可以接受指定颜色的液体
  bool canAcceptLiquid(Color color) {
    if (isFull) return false;
    if (isEmpty) return true;
    return topLiquid!.color == color;
  }

  /// 向试管中添加液体
  void addLiquid(Liquid liquid) {
    if (isFull) {
      throw StateError("无法添加液体到试管");
    }

    if (isEmpty || topLiquid!.color != liquid.color) {
      liquids.add(liquid);
    }
    else {
      topLiquid!.merge(liquid);
    }
  }

  /// 从试管中移除液体
  Liquid? removeLiquid(int amount) {
    if (isEmpty || amount <= 0) return null;
    if (amount > topLiquid!.volume) return null;

    final top = topLiquid!;
    if (amount == top.volume) {
      return liquids.removeLast();
    } else {
      return top.split(amount);
    }
  }

  /// 判断试管是否已完成（单一颜色且满）
  bool get isCompleted {
    if (!isFull) return false;
    if (liquids.length != 1) return false;
    return true;
  }
  // endregion

  // region 【辅助方法】
  /// 复制试管
  Tube copy() {
    final newTube = Tube(id: id, capacity: capacity);
    newTube.liquids.addAll(liquids.map((l) => l.copy()));
    return newTube;
  }

  /// 转换为 JSON 格式
  Map<String, dynamic> toJson() => {
    'id': id,
    'capacity': capacity,
    'liquids': liquids.map((l) => l.toJson()).toList(),
  };

  /// 从 JSON 格式还原
  factory Tube.fromJson(Map<String, dynamic> json) {
    final tube = Tube(
      id: json['id'] as int,
      capacity: json['capacity'] as int,
    );
    tube.liquids.addAll(
      (json['liquids'] as List).map((l) => Liquid.fromJson(l)),
    );
    return tube;
  }
  // endregion
}