import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id, name, description, category, imageName;
  final double price, rating;
  final bool available;
  const FoodItem({this.id='',this.name='',this.description='',this.category='Others',this.imageName='',this.price=0,this.rating=0,this.available=true});
  factory FoodItem.fromDoc(DocumentSnapshot d) {
    final x=(d.data() as Map<String,dynamic>?)??{};
    double n(dynamic v)=>v is num?v.toDouble():double.tryParse('$v')??0;
    return FoodItem(id:d.id,name:'${x['name']??''}'.trim(),description:'${x['description']??''}'.trim(),category:'${x['category']??'Others'}',imageName:'${x['imageName']??''}',price:n(x['price']),rating:n(x['rating']),available:x['available'] is bool?x['available'] as bool:true);
  }
}

class CartLine {
  FoodItem food; int qty;
  CartLine(this.food,[this.qty=1]);
  double get total=>food.price*qty;
}

class Branch {
  final String id,name; final double latitude,longitude; final bool active;
  const Branch({required this.id,required this.name,required this.latitude,required this.longitude,this.active=true});
  factory Branch.fromDoc(DocumentSnapshot d){
    final x=(d.data() as Map<String,dynamic>?)??{};
    double n(dynamic v)=>v is num?v.toDouble():double.tryParse('$v')??double.nan;
    return Branch(id:d.id,name:'${x['name']??d.id}'.trim().isEmpty?d.id:'${x['name']??d.id}'.trim(),latitude:n(x['latitude']),longitude:n(x['longitude']),active:_active(x['active']));
  }
  static bool _active(dynamic v){if(v==null)return true;if(v is bool)return v;if(v is num)return v!=0;return '$v'.trim().toLowerCase()=='true';}
}

class DeliveryLocation {
  final double latitude,longitude,distanceMeters,deliveryFee;
  final String address,branchId,branchName;
  final double branchLatitude,branchLongitude;
  final int estimatedMinutes;
  const DeliveryLocation({required this.latitude,required this.longitude,required this.distanceMeters,required this.deliveryFee,required this.address,required this.branchId,required this.branchName,required this.branchLatitude,required this.branchLongitude,required this.estimatedMinutes});
}

class CustomerProfile {
  final String fullName,phone,email,buildingName,deliveryAddress;
  const CustomerProfile({this.fullName='',this.phone='',this.email='',this.buildingName='',this.deliveryAddress=''});
  bool get complete=>fullName.trim().isNotEmpty&&phone.trim().isNotEmpty;
}

class AppNotification {
  final String id,title,message,time; final bool read;
  const AppNotification({required this.id,required this.title,required this.message,required this.time,this.read=false});
  AppNotification copyWith({bool? read})=>AppNotification(id:id,title:title,message:message,time:time,read:read??this.read);
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'message':message,'time':time,'read':read};
  factory AppNotification.fromJson(Map<String,dynamic> x)=>AppNotification(id:'${x['id']??DateTime.now().microsecondsSinceEpoch}',title:'${x['title']??''}',message:'${x['message']??''}',time:'${x['time']??''}',read:x['read']==true);
}

class OrderSummary {
  final String id,status,paymentStatus,customerName,deliveryAddress,branchName,mpesaCode;
  final double subtotal,deliveryFee,total,distanceMeters;
  final int estimatedMinutes;
  final DateTime? createdAt;
  const OrderSummary({required this.id,required this.status,required this.paymentStatus,required this.customerName,required this.deliveryAddress,required this.branchName,required this.mpesaCode,required this.subtotal,required this.deliveryFee,required this.total,required this.distanceMeters,required this.estimatedMinutes,this.createdAt});
  factory OrderSummary.fromDoc(DocumentSnapshot d){final x=(d.data() as Map<String,dynamic>?)??{};double n(dynamic v)=>v is num?v.toDouble():double.tryParse('$v')??0;DateTime? dt;final ts=x['createdAt'];if(ts is Timestamp)dt=ts.toDate();else if(ts is num)dt=DateTime.fromMillisecondsSinceEpoch(ts.toInt());return OrderSummary(id:'${x['orderNumber']??d.id}',status:'${x['status']??'Payment Pending'}',paymentStatus:'${x['paymentStatus']??'PENDING'}',customerName:'${x['customerName']??x['fullName']??''}',deliveryAddress:'${x['deliveryAddress']??''}',branchName:'${x['branchName']??''}',mpesaCode:'${x['mpesaCode']??''}',subtotal:n(x['subtotal']),deliveryFee:n(x['deliveryFee']),total:n(x['grandTotal']??x['totalPrice']),distanceMeters:n(x['distanceMeters']),estimatedMinutes:(x['estimatedMinutes'] as num?)?.toInt()??30,createdAt:dt);}
}
