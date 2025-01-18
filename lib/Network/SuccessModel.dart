class SuccessModel {
  String? st;
  String? msg;

  SuccessModel({this.st,this.msg, required String message});

  SuccessModel.fromJson(Map<String, dynamic> json) {
    st = json['st'];
    msg = json['msg'];
  }

}