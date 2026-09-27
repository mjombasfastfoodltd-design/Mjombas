import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';

class LocationService {
  static double distance(double lat1,double lon1,double lat2,double lon2){const r=6371000.0;final p1=lat1*math.pi/180,p2=lat2*math.pi/180;final dl=(lat2-lat1)*math.pi/180,dg=(lon2-lon1)*math.pi/180;final a=math.pow(math.sin(dl/2),2)+math.cos(p1)*math.cos(p2)*math.pow(math.sin(dg/2),2);return r*2*math.atan2(math.sqrt(a),math.sqrt(1-a));}
  static double deliveryFee(double m){if(m<=600)return 0;if(m<=1000)return 100;if(m<=2000)return 200;return 200+((m-2000)/1000).ceil()*100.0;}
  static int estimatedMinutes(double m)=>m<=1000?20:m<=3000?30:m<=5000?40:50;
  static Future<Position> currentPosition() async {if(!await Geolocator.isLocationServiceEnabled())throw Exception('Location services are turned off. Turn on GPS and try again.');var p=await Geolocator.checkPermission();if(p==LocationPermission.denied)p=await Geolocator.requestPermission();if(p==LocationPermission.denied)throw Exception('Location permission was denied.');if(p==LocationPermission.deniedForever)throw Exception('Location permission is permanently denied. Enable location permission in phone Settings.');return Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high));}
  static Future<List<Branch>> branches() async {final s=await FirebaseFirestore.instance.collection('branches').get();final out=s.docs.map(Branch.fromDoc).where((b)=>b.active&&b.latitude.isFinite&&b.longitude.isFinite&&b.latitude>=-90&&b.latitude<=90&&b.longitude>=-180&&b.longitude<=180).toList();if(out.isEmpty)throw Exception('No active MJOMBAS branches with valid coordinates were found in Firebase.');return out;}
  static Branch nearest(List<Branch> bs,double lat,double lng)=>bs.reduce((a,b)=>distance(lat,lng,a.latitude,a.longitude)<=distance(lat,lng,b.latitude,b.longitude)?a:b);
  static Future<String> reverseGeocode(double lat,double lng) async {final u=Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&zoom=18&addressdetails=1');final r=await http.get(u,headers:{'User-Agent':'MJOMBAS/1.0 (delivery app)'});if(r.statusCode!=200)throw Exception('Address lookup failed');final x=jsonDecode(r.body) as Map<String,dynamic>;return '${x['display_name']??'Selected location'}';}
  static Future<List<LatLng>> route(double aLat,double aLng,double bLat,double bLng) async {final u=Uri.parse('https://router.project-osrm.org/route/v1/driving/$aLng,$aLat;$bLng,$bLat?overview=full&geometries=geojson');final r=await http.get(u);if(r.statusCode!=200)return [];final x=jsonDecode(r.body) as Map<String,dynamic>;final routes=x['routes'] as List?;if(routes==null||routes.isEmpty)return [];final geo=((routes.first as Map)['geometry'] as Map)['coordinates'] as List;return geo.map((p){final a=p as List;return LatLng((a[1] as num).toDouble(),(a[0] as num).toDouble());}).toList();}
}

class ProfileService {
  static const _key='mjombas_customer_profile';
  static Future<CustomerProfile> load() async {final p=await SharedPreferences.getInstance();return CustomerProfile(fullName:p.getString('full_name')??'',phone:p.getString('phone')??'',email:p.getString('email')??'',buildingName:p.getString('building_name')??'',deliveryAddress:p.getString('delivery_address')??'');}
  static Future<void> save(CustomerProfile x) async {final p=await SharedPreferences.getInstance();await p.setString('full_name',x.fullName.trim());await p.setString('phone',x.phone.trim());await p.setString('email',x.email.trim());await p.setString('building_name',x.buildingName.trim());await p.setString('delivery_address',x.deliveryAddress.trim());}
  static Future<void> clear() async {(await SharedPreferences.getInstance()).remove('full_name');final p=await SharedPreferences.getInstance();for(final k in ['phone','email','building_name','delivery_address']){await p.remove(k);}}
}

class NotificationService {
  static const _key='mjombas_notifications';
  static Future<List<AppNotification>> load() async {final p=await SharedPreferences.getInstance();final raw=p.getString(_key);if(raw==null)return [];final list=(jsonDecode(raw) as List).map((e)=>AppNotification.fromJson(Map<String,dynamic>.from(e))).toList();return list;}
  static Future<void> save(List<AppNotification> list) async {final p=await SharedPreferences.getInstance();await p.setString(_key,jsonEncode(list.map((e)=>e.toJson()).toList()));}
}

class PhoneService {static Future<void> callMjombas() async {final u=Uri.parse('tel:0704646628');if(await canLaunchUrl(u))await launchUrl(u);}}
