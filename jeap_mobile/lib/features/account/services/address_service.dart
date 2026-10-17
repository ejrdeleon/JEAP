import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/features/account/models/address.dart';

class AddressService {
  final ApiClient _api;

  AddressService({ApiClient? client}) : _api = client ?? const ApiClient();

  Future<List<Address>> fetchAddresses() async {
    final res = await _api.get('/addresses');
    final list = (res is Map && res.containsKey('addresses'))
        ? res['addresses'] as List
        : (res as List? ?? []);
    return list
        .map((e) => Address.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Address> addAddress(Address address) async {
    final res = await _api.post('/addresses', address.toJson());
    final data =
        (res is Map && res.containsKey('address')) ? res['address'] : res;
    return Address.fromJson(data as Map<String, dynamic>);
  }

  Future<Address> updateAddress(int id, Address address) async {
    final res = await _api.put('/addresses/$id', address.toJson());
    final data =
        (res is Map && res.containsKey('address')) ? res['address'] : res;
    return Address.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(int id) => _api.delete('/addresses/$id');
}
