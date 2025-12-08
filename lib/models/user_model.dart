/// 用户模型
class UserModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final int? avatarId;
  final String? phone;
  final String? email;
  final double? coin;
  final int? isVip;
  final int? vipExpiredTime;
  final String? invitationCode;

  UserModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.avatarId,
    this.phone,
    this.email,
    this.coin,
    this.isVip,
    this.vipExpiredTime,
    this.invitationCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      avatarId: json['avatar_id'] ?? json['avatarId'],
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      coin: json['coin']?.toDouble(),
      isVip: json['is_vip'] ?? json['isVip'],
      vipExpiredTime: json['vip_expired_time'] ?? json['vipExpiredTime'],
      invitationCode: json['invitation_code']?.toString() ?? json['invitationCode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'avatar_id': avatarId,
      'phone': phone,
      'email': email,
      'coin': coin,
      'is_vip': isVip,
      'vip_expired_time': vipExpiredTime,
      'invitation_code': invitationCode,
    };
  }
}

/// 登录响应模型
class LoginResponse {
  final int code;
  final String msg;
  final String? token;

  LoginResponse({
    required this.code,
    required this.msg,
    this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      code: json['code'] ?? 0,
      msg: json['msg']?.toString() ?? '',
      token: json['data']?['token']?.toString(),
    );
  }

  bool get isSuccess => code == 1;
}

