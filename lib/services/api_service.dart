import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../constants/order_status.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/address_model.dart';
import '../models/category_model.dart';
import '../models/store_model.dart';
import '../models/bill_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../utils/category_matcher.dart';
import '../utils/area_helper.dart';
import 'store_service.dart';
import 'storage_service.dart';

class ApiService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;
  static final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: Platform.isAndroid ? null : AppConstants.webClientId,
    serverClientId: AppConstants.webClientId,
    scopes: ['email', 'profile'],
  );

 

  static Future<Map<String, dynamic>> checkEmailBanStatus(String email) async {
    if (email.trim().isEmpty) return {'isBanned': false, 'banReason': ''};
    try {
      final cleanEmail = email.trim().toLowerCase();
      final query = await firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .get();

      for (var doc in query.docs) {
        final data = doc.data();
        final isBanned = data['isBanned'] == true ||
            data['is_banned'] == true ||
            data['status'] == 'banned';
        if (isBanned) {
          return {
            'isBanned': true,
            'banReason': data['banReason'] ??
                data['ban_reason'] ??
                'Your account has been suspended by an administrator.',
          };
        }
      }
      return {'isBanned': false, 'banReason': ''};
    } catch (e) {
      return {'isBanned': false, 'banReason': ''};
    }
  }

  static Future<List<Map<String, dynamic>>> getKnownGoogleAccounts() async {
    try {
      final stored = await StorageService.getData(AppConstants.googleAccounts);
      if (stored is List) {
        final accounts = stored.map((e) => Map<String, dynamic>.from(e)).toList();
        for (var acc in accounts) {
          final email = acc['email']?.toString();
          if (email != null && email.isNotEmpty) {
            final banStatus = await checkEmailBanStatus(email);
            acc['isBanned'] = banStatus['isBanned'];
            acc['banReason'] = banStatus['banReason'];
          }
        }
        await StorageService.storeData(AppConstants.googleAccounts, accounts);
        return accounts;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveKnownGoogleAccount(Map<String, dynamic> account) async {
    final email = account['email']?.toString().trim().toLowerCase();
    if (email == null || email.isEmpty) return;
    try {
      final stored = await getKnownGoogleAccounts();
      final filtered = stored.where((a) => a['email']?.toString().trim().toLowerCase() != email).toList();
      final updated = [
        {
          'email': email,
          'name': account['name'] ?? email.split('@')[0],
          'photo': account['photo'] ?? account['photoUrl'],
          'isBanned': account['isBanned'] == true,
          'banReason': account['banReason'] ?? '',
          'lastUsed': DateTime.now().toIso8601String(),
        },
        ...filtered,
      ].take(5).toList();
      await StorageService.storeData(AppConstants.googleAccounts, updated);
    } catch (_) {}
  }

  static Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    UserCredential? credential;
    UserModel? existingProfile;

    try {
      credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          credential = await auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          final snap = await firestore.collection('users').doc(credential.user!.uid).get();
          if (snap.exists && snap.data() != null) {
            existingProfile = UserModel.fromMap(snap.data()!, docId: snap.id);
          }
        } on FirebaseAuthException catch (signInErr) {
          if (signInErr.code == 'invalid-credential' || signInErr.code == 'wrong-password') {
            throw Exception('This email is already registered with a different password. Please sign up with your existing password.');
          }
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final user = credential.user!;

    if (existingProfile != null) {
      final currentTypes = List<String>.from(existingProfile.types);
      if (!currentTypes.contains('customer')) {
        currentTypes.add('customer');
      }
      await firestore.collection('users').doc(user.uid).update({
        'types': currentTypes,
      });
      final profile = UserModel(
        id: user.uid,
        uid: user.uid,
        email: email,
        name: existingProfile.name,
        phone: existingProfile.phone,
        type: 'customer',
        types: currentTypes,
        avatar: existingProfile.avatar,
        addresses: existingProfile.addresses,
      );
      await StorageService.storeData(AppConstants.authToken, user.uid);
      await StorageService.storeData(AppConstants.userData, profile.toMap());
      return profile;
    }

    final profile = UserModel(
      id: user.uid,
      uid: user.uid,
      email: email.trim(),
      name: name.trim().isEmpty ? 'Customer' : name.trim(),
      phone: phone.trim(),
      type: 'customer',
      types: ['customer'],
      addresses: [],
      createdAt: DateTime.now().toIso8601String(),
    );

    await firestore.collection('users').doc(user.uid).set(profile.toMap());
    await StorageService.storeData(AppConstants.authToken, user.uid);
    await StorageService.storeData(AppConstants.userData, profile.toMap());
    return profile;
  }

  static Future<UserModel> login(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    UserModel profile;

    if (!userDoc.exists || userDoc.data() == null) {
      profile = UserModel(
        id: user.uid,
        uid: user.uid,
        email: user.email ?? email,
        name: 'Customer',
        phone: '',
        type: 'customer',
        types: ['customer'],
        addresses: [],
      );
      await firestore.collection('users').doc(user.uid).set(profile.toMap());
    } else {
      profile = UserModel.fromMap(userDoc.data()!, docId: userDoc.id);
    }

    
    bool isBanned = profile.isBanned;
    String banReason = profile.banReason;

    if (!isBanned && email.isNotEmpty) {
      final banCheck = await checkEmailBanStatus(email);
      if (banCheck['isBanned'] == true) {
        isBanned = true;
        banReason = banCheck['banReason'] ?? 'Your account has been suspended by an administrator.';
      }
    }

    if (isBanned) {
      await auth.signOut();
      try { await googleSignIn.signOut(); } catch (_) {}
      await StorageService.removeData(AppConstants.authToken);
      await StorageService.removeData(AppConstants.userData);
      throw Exception('BANNED:${banReason.isEmpty ? 'Your account has been suspended by an administrator.' : banReason}');
    }

    final types = List<String>.from(profile.types);
    if (!types.contains('customer')) {
      types.add('customer');
      await firestore.collection('users').doc(user.uid).update({'types': types});
    }

    final updatedProfile = UserModel(
      id: profile.id,
      uid: profile.uid,
      email: profile.email,
      name: profile.name,
      phone: profile.phone,
      type: 'customer',
      types: types,
      avatar: profile.avatar,
      addresses: profile.addresses,
    );

    await StorageService.storeData(AppConstants.authToken, user.uid);
    await StorageService.storeData(AppConstants.userData, updatedProfile.toMap());
    return updatedProfile;
  }

  static Future<UserModel> signInWithGoogle() async {
    try {
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final User user = userCredential.user!;

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      UserModel profile;

      if (!userDoc.exists || userDoc.data() == null) {
        profile = UserModel(
          id: user.uid,
          uid: user.uid,
          email: user.email ?? googleUser.email,
          name: user.displayName ?? googleUser.displayName ?? 'Customer',
          phone: user.phoneNumber ?? '',
          type: 'customer',
          types: ['customer'],
          avatar: user.photoURL ?? googleUser.photoUrl,
          addresses: [],
        );
        await firestore.collection('users').doc(user.uid).set(profile.toMap());
      } else {
        profile = UserModel.fromMap(userDoc.data()!, docId: userDoc.id);
      }

   
      bool isBanned = profile.isBanned;
      String banReason = profile.banReason;

      final email = googleUser.email.trim().toLowerCase();
      if (!isBanned && email.isNotEmpty) {
        final banCheck = await checkEmailBanStatus(email);
        if (banCheck['isBanned'] == true) {
          isBanned = true;
          banReason = banCheck['banReason'] ?? 'Your account has been suspended by an administrator.';
        }
      }

      if (isBanned) {
        await saveKnownGoogleAccount({
          'email': email,
          'name': googleUser.displayName ?? 'Customer',
          'photo': googleUser.photoUrl,
          'isBanned': true,
          'banReason': banReason,
        });

        await auth.signOut();
        try { await googleSignIn.signOut(); } catch (_) {}
        await StorageService.removeData(AppConstants.authToken);
        await StorageService.removeData(AppConstants.userData);
        throw Exception('BANNED:${banReason.isEmpty ? 'Your account has been suspended by an administrator.' : banReason}');
      }

      await saveKnownGoogleAccount({
        'email': email,
        'name': googleUser.displayName ?? 'Customer',
        'photo': googleUser.photoUrl,
        'isBanned': false,
        'banReason': '',
      });

      final types = List<String>.from(profile.types);
      if (!types.contains('customer')) {
        types.add('customer');
        await firestore.collection('users').doc(user.uid).update({'types': types});
      }

      final updatedProfile = UserModel(
        id: profile.id,
        uid: profile.uid,
        email: profile.email.isNotEmpty ? profile.email : email,
        name: profile.name,
        phone: profile.phone,
        type: 'customer',
        types: types,
        avatar: profile.avatar ?? googleUser.photoUrl,
        addresses: profile.addresses,
      );

      await StorageService.storeData(AppConstants.authToken, user.uid);
      await StorageService.storeData(AppConstants.userData, updatedProfile.toMap());
      return updatedProfile;
    } catch (e) {
      rethrow;
    }
  }

  static Future<UserModel?> getMe() async {
    final user = auth.currentUser;
    if (user == null) return null;

    final doc = await firestore.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;

    final profile = UserModel.fromMap(doc.data()!, docId: doc.id);

    if (profile.isBanned) {
      await logout();
      throw Exception('BANNED:${profile.banReason}');
    }

    return profile;
  }

  static Future<void> logout() async {
    try { await auth.signOut(); } catch (_) {}
    try { await googleSignIn.signOut(); } catch (_) {}
    await StorageService.removeData(AppConstants.authToken);
    await StorageService.removeData(AppConstants.userData);
  }

  static Future<void> sendOTPCode(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final code = (100000 + Random().nextInt(900000)).toString();

    await firestore.collection('otps').doc(cleanEmail).set({
      'email': cleanEmail,
      'code': code,
      'createdAt': DateTime.now().toIso8601String(),
    });

   
    try {
      http.post(
        Uri.parse('https://formsubmit.co/ajax/$cleanEmail'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'https://robotinn.com',
          'Referer': 'https://robotinn.com/',
        },
        body: jsonEncode({
          'name': 'RobotInn Password Reset',
          'message': 'Your password reset verification code is: $code. Please enter this code in the app to reset your password.',
          '_subject': 'RobotInn Password Reset Verification Code',
        }),
      );
    } catch (_) {}
  }

  static Future<void> verifyOTPAndResetPassword(String email, String code, String newPassword) async {
    final cleanEmail = email.trim().toLowerCase();
    final snap = await firestore.collection('otps').doc(cleanEmail).get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Verification code has not been sent or has expired.');
    }

    final data = snap.data()!;
    if (data['code']?.toString().trim() != code.trim()) {
      throw Exception('Invalid verification code.');
    }

    await auth.sendPasswordResetEmail(email: cleanEmail);
    await firestore.collection('otps').doc(cleanEmail).delete();
  }

  

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Authentication required');
    await firestore.collection('users').doc(user.uid).update(data);
    
    final updated = await getMe();
    if (updated != null) {
      await StorageService.storeData(AppConstants.userData, updated.toMap());
    }
  }

  static Future<List<AddressModel>> getAddresses() async {
    final user = auth.currentUser;
    if (user == null) return [];
    final snap = await firestore.collection('users').doc(user.uid).get();
    if (snap.exists && snap.data()?['addresses'] is List) {
      return (snap.data()!['addresses'] as List)
          .map((a) => AddressModel.fromMap(Map<String, dynamic>.from(a)))
          .toList();
    }
    return [];
  }

  static Future<AddressModel> addAddress(AddressModel address) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final existing = await getAddresses();
    final updated = [address, ...existing.where((a) => a.id != address.id)];
    await firestore.collection('users').doc(user.uid).update({
      'addresses': updated.map((a) => a.toMap()).toList(),
    });
    return address;
  }

  static Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final existing = await getAddresses();
    final updated = existing.map((a) {
      if (a.id == id) {
        final merged = a.toMap()..addAll(data);
        return AddressModel.fromMap(merged);
      }
      return a;
    }).toList();

    await firestore.collection('users').doc(user.uid).update({
      'addresses': updated.map((a) => a.toMap()).toList(),
    });
  }

  static Future<void> deleteAddress(String id) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final existing = await getAddresses();
    final updated = existing.where((a) => a.id != id).toList();
    await firestore.collection('users').doc(user.uid).update({
      'addresses': updated.map((a) => a.toMap()).toList(),
    });
  }



  static Future<OrderModel> createOrder(Map<String, dynamic> orderData) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final payload = {
      ...orderData,
      'orderId': orderId,
      'status': OrderStatus.pending,
      'customer': {
        'id': user.uid,
        'uid': user.uid,
        'name': orderData['customerName'] ?? user.displayName ?? 'Customer',
        'phone': orderData['customerPhone'] ?? user.phoneNumber ?? '',
        'location': orderData['location'],
      },
      'rider': null,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final docRef = await firestore.collection('orders').add(payload);

    
    await firestore.collection('notifications').add({
      'recipient': 'admin',
      'title': 'New Order Placed',
      'message': 'Order $orderId has been placed.',
      'type': 'order',
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
      'data': {'orderId': docRef.id},
    });

    return OrderModel.fromMap(payload, docId: docRef.id);
  }

  static Stream<List<OrderModel>> streamCustomerOrders(String userId) {
    return firestore
        .collection('orders')
        .where('customer.id', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final orders = snap.docs
              .map((doc) => OrderModel.fromMap(doc.data(), docId: doc.id))
              .toList();
          orders.sort((a, b) {
            final tA = a.createdAt?.toString() ?? '';
            final tB = b.createdAt?.toString() ?? '';
            return tB.compareTo(tA);
          });
          return orders;
        });
  }

  static Stream<OrderModel?> streamOrder(String orderId) {
    return firestore.collection('orders').doc(orderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return OrderModel.fromMap(doc.data()!, docId: doc.id);
    });
  }

  static Future<void> cancelOrder(String orderId, String reason) async {
    final update = {
      'status': OrderStatus.cancelled,
      'cancellationReason': reason,
      'cancelledAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final docRef = firestore.collection('orders').doc(orderId);
    final snap = await docRef.get();
    if (snap.exists) {
      await docRef.update(update);
    } else {
      final q = await firestore.collection('orders').where('orderId', isEqualTo: orderId).limit(1).get();
      if (q.docs.isNotEmpty) {
        await q.docs.first.reference.update(update);
      }
    }
  }

  static Future<void> submitOrderRating(String orderId, String riderId, double rating, String review) async {
    final orderRef = firestore.collection('orders').doc(orderId);
    final riderRef = firestore.collection('users').doc(riderId);

    await firestore.runTransaction((transaction) async {
      final riderDoc = await transaction.get(riderRef);

      transaction.update(orderRef, {
        'rating': {
          'score': rating,
          'review': review,
          'createdAt': DateTime.now().toIso8601String(),
        }
      });

      if (riderDoc.exists && riderDoc.data() != null) {
        final currentRating = (riderDoc.data()!['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingCount = (riderDoc.data()!['ratingCount'] as num?)?.toInt() ?? 0;
        final newCount = ratingCount + 1;
        final newRating = ((currentRating * ratingCount) + rating) / newCount;

        transaction.update(riderRef, {
          'rating': newRating,
          'ratingCount': newCount,
        });
      }
    });
  }

  static Future<void> respondPriceAdjustment(String orderId, {required bool accept, String paymentMethod = 'COD'}) async {
    final nextStatus = accept ? OrderStatus.billApproved : OrderStatus.adjustmentRejected;
    final update = <String, dynamic>{
      'status': nextStatus,
      'adjustmentNegotiation.customerApproved': accept,
      'adjustmentNegotiation.decisionTimestamp': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (accept) {
      update['financials.paymentStatus'] = 'ADJUSTMENT_APPROVED';
      update['financials.paymentMethodId'] = paymentMethod;
    }

    await firestore.collection('orders').doc(orderId).update(update);
  }

  static Future<void> rejectPriceAdjustment(String orderId, {required double requestedPrice, required String reason}) async {
    await firestore.collection('orders').doc(orderId).update({
      'status': OrderStatus.adjustmentPending,
      'billDispute': {
        'requestedPrice': requestedPrice,
        'reason': reason,
        'status': 'pending_admin_review',
        'submittedAt': DateTime.now().toIso8601String(),
      },
      'adjustmentNegotiation.customerApproved': false,
      'adjustmentNegotiation.customerDemandPrice': requestedPrice,
      'adjustmentNegotiation.customerDemandReason': reason,
      'adjustmentNegotiation.status': 'disputed',
      'adjustmentNegotiation.decisionTimestamp': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    
    try {
      final doc = await firestore.collection('orders').doc(orderId).get();
      final code = doc.data()?['orderId'] ?? orderId.substring(max(0, orderId.length - 6));
      await firestore.collection('notifications').add({
        'recipient': 'admin',
        'title': '⚠️ Bill Dispute & Counter-Offer',
        'message': 'Order #$code: Customer rejected bill and offered Rs $requestedPrice. Reason: $reason',
        'type': 'bill_dispute',
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': {'orderId': orderId, 'requestedPrice': requestedPrice, 'reason': reason},
      });
    } catch (_) {}
  }

 

  static Stream<List<CategoryModel>> streamCategories() {
    return firestore.collection('categories').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), docId: doc.id))
          .where((c) => c.active)
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  static Stream<List<CategoryModel>> streamServiceCategories() {
    return firestore.collection('serviceCategories').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), docId: doc.id))
          .where((c) => c.active)
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  static Stream<List<StoreModel>> streamStoresByAreaAndCategory({
    required String areaName,
    String? categoryIdOrName,
    String? categoryName,
  }) {
    final cleanArea = AreaHelper.cleanSectorName(areaName);
    final catFilter = categoryName ?? categoryIdOrName ?? '';

    return firestore.collection('stores').snapshots().map((snap) {
      final list = <StoreModel>[];
      final seenNames = <String>{};

      for (var doc in snap.docs) {
        final data = doc.data();
        if (data['active'] == false) continue;

        final storeArea = (data['area'] ?? '').toString().trim();
        final areaMatches = cleanArea.isEmpty ||
            data['allAreas'] == true ||
            storeArea.toLowerCase() == cleanArea.toLowerCase() ||
            AreaHelper.cleanSectorName(storeArea).toLowerCase() == cleanArea.toLowerCase();

        final catMatches = catFilter.isEmpty ||
            CategoryMatcher.doesStoreMatchCategory(data, catFilter);

        if (areaMatches && catMatches) {
          final name = (data['name'] ?? data['storeName'] ?? '').toString().trim();
          final key = name.toLowerCase();
          if (name.isNotEmpty && !seenNames.contains(key)) {
            seenNames.add(key);
            list.add(StoreModel.fromMap(data, docId: doc.id));
          }
        }
      }

      // If empty, add local sector fallback stores
      if (list.isEmpty && cleanArea.isNotEmpty) {
        final fallbacks = AreaHelper.getFallbackStoresForAreaAndCategory(cleanArea, catFilter);
        for (final m in fallbacks) {
          list.add(StoreModel.fromMap(m, docId: m['id']));
        }
      }

      return list;
    });
  }

  static Future<List<StoreModel>> getStoresByAreaAndCategory({
    required String areaName,
    String? categoryIdOrName,
    String? categoryName,
    double? userLat,
    double? userLng,
  }) async {
    return await StoreService.getAllStoresForAreaAndCategory(
      areaName: areaName,
      categoryId: categoryIdOrName,
      categoryName: categoryName,
      userLat: userLat,
      userLng: userLng,
    );
  }



  static Stream<List<BillModel>> streamMyBills(String userId) {
    return firestore.collection('orders').snapshots().map((snap) {
      final bills = <BillModel>[];
      for (var doc in snap.docs) {
        final data = doc.data();
        final custId = data['customer']?['id'] ?? data['customer']?['uid'] ?? data['customerId'] ?? data['userId'];
        if (custId == userId && data['bill'] != null) {
          final bill = BillModel.fromOrderMap(data, doc.id);
          if (OrderStatusHelper.isBillVisibleToCustomer(bill.status)) {
            bills.add(bill);
          }
        }
      }
      bills.sort((a, b) {
        final tA = a.createdAt?.toString() ?? '';
        final tB = b.createdAt?.toString() ?? '';
        return tB.compareTo(tA);
      });
      return bills;
    });
  }

  static Future<String> uploadPaymentProof({required String billId, required File file}) async {
    final fileName = 'bill-proof-$billId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = storage.ref().child('bills/$fileName');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  static Future<void> submitPaymentProof(String billId, String proofUrl) async {
    await firestore.collection('orders').doc(billId).update({
      'bill.paymentProofImage': proofUrl,
      'bill.status': BillStatus.submitted,
      'bill.submittedAt': DateTime.now().toIso8601String(),
    });
  }


  static Stream<List<ConversationModel>> streamConversations(String userId) {
    return firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => ConversationModel.fromMap(doc.data(), docId: doc.id, currentUserId: userId))
              .toList();
        });
  }

  static Stream<List<MessageModel>> streamMessages(String conversationId, String currentUserId) {
    return firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => MessageModel.fromMap(doc.data(), docId: doc.id, currentUserId: currentUserId))
              .toList();
        });
  }

  static Future<String> startConversation({required String participantId, String? orderId}) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final query = await firestore
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .get();

    for (var doc in query.docs) {
      final parts = List<String>.from(doc.data()['participants'] ?? []);
      if (parts.contains(participantId)) {
        return doc.id;
      }
    }

    final docRef = await firestore.collection('conversations').add({
      'participants': [user.uid, participantId],
      'orderId': orderId,
      'createdAt': DateTime.now().toIso8601String(),
      'lastMessage': null,
    });
    return docRef.id;
  }

  static Future<void> sendMessage({required String conversationId, required String text}) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    await firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderId': user.uid,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    });

    await firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': {
        'text': text,
        'senderId': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
      }
    });
  }

  static Future<void> sendMediaMessage({
    required String conversationId,
    required File file,
    required String fileName,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'chat_media/$conversationId/${timestamp}_$fileName';
    final ref = storage.ref(path);
    await ref.putFile(file);
    final mediaUrl = await ref.getDownloadURL();

    await firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderId': user.uid,
      'text': '',
      'mediaUrl': mediaUrl,
      'mediaType': 'image/jpeg',
      'mediaName': fileName,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    });

    await firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': {
        'text': '📷 Photo',
        'senderId': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
      }
    });
  }


  static Stream<List<NotificationModel>> streamNotifications(String userId) {
    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), docId: doc.id))
              .toList();
          list.sort((a, b) {
            final tA = a.createdAt?.toString() ?? '';
            final tB = b.createdAt?.toString() ?? '';
            return tB.compareTo(tA);
          });
          return list;
        });
  }

  static Future<void> markNotificationAsRead(String id) async {
    await firestore.collection('notifications').doc(id).update({'read': true});
  }

  static Future<void> markAllNotificationsAsRead(String userId) async {
    final snap = await firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  static Future<void> registerFCMToken(String token) async {
    final user = auth.currentUser;
    if (user != null) {
      await firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'deviceType': Platform.isAndroid ? 'android' : 'ios',
      });
    }
  }

  static Future<String> uploadProfileAvatar(File file) async {
    final user = auth.currentUser;
    final uid = user?.uid ?? 'anon';
    final fileName = '$uid-profile-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = storage.ref('profiles/$fileName');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    if (user != null) {
      await updateProfile({'avatar': url});
    }
    return url;
  }
}
