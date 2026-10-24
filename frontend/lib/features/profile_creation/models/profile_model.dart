class PartnerPreferenceModel {
  final int? ageMin;
  final int? ageMax;
  final int? heightMinCm;
  final int? heightMaxCm;
  final List<String> maritalStatus;
  final List<String> religion;
  final List<String> caste;
  final List<String> motherTongue;
  final String? country;
  final String? city;
  final List<String> education;
  final List<String> profession;
  final int? incomeMin;
  final int? incomeMax;
  final List<String> lifestyleDiet;
  final String? lifestyleSmoking;
  final String? lifestyleDrinking;
  final List<String> mustHaveFields;
  final bool hasNarrowCriteriaWarning;

  PartnerPreferenceModel({
    this.ageMin = 21,
    this.ageMax = 35,
    this.heightMinCm = 150,
    this.heightMaxCm = 190,
    this.maritalStatus = const [],
    this.religion = const [],
    this.caste = const [],
    this.motherTongue = const [],
    this.country = 'India',
    this.city,
    this.education = const [],
    this.profession = const [],
    this.incomeMin,
    this.incomeMax,
    this.lifestyleDiet = const [],
    this.lifestyleSmoking,
    this.lifestyleDrinking,
    this.mustHaveFields = const [],
    this.hasNarrowCriteriaWarning = false,
  });

  factory PartnerPreferenceModel.fromJson(Map<String, dynamic> json) {
    List<String> toList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return PartnerPreferenceModel(
      ageMin: json['age_min'] as int?,
      ageMax: json['age_max'] as int?,
      heightMinCm: json['height_min_cm'] as int?,
      heightMaxCm: json['height_max_cm'] as int?,
      maritalStatus: toList(json['marital_status']),
      religion: toList(json['religion']),
      caste: toList(json['caste']),
      motherTongue: toList(json['mother_tongue']),
      country: json['country'] as String? ?? 'India',
      city: json['city'] as String?,
      education: toList(json['education']),
      profession: toList(json['profession']),
      incomeMin: json['income_min'] as int?,
      incomeMax: json['income_max'] as int?,
      lifestyleDiet: toList(json['lifestyle_diet']),
      lifestyleSmoking: json['lifestyle_smoking'] as String?,
      lifestyleDrinking: json['lifestyle_drinking'] as String?,
      mustHaveFields: toList(json['must_have_fields']),
      hasNarrowCriteriaWarning: json['has_narrow_criteria_warning'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age_min': ageMin,
      'age_max': ageMax,
      'height_min_cm': heightMinCm,
      'height_max_cm': heightMaxCm,
      'marital_status': maritalStatus,
      'religion': religion,
      'caste': caste,
      'mother_tongue': motherTongue,
      'country': country,
      'city': city,
      'education': education,
      'profession': profession,
      'income_min': incomeMin,
      'income_max': incomeMax,
      'lifestyle_diet': lifestyleDiet,
      'lifestyle_smoking': lifestyleSmoking,
      'lifestyle_drinking': lifestyleDrinking,
      'must_have_fields': mustHaveFields,
    };
  }
}

class ProfileModel {
  final String id;
  final String? profileId;
  final String fullName;
  final String? displayName;
  final String displayNameFormat;
  final String? customUsername;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? maritalStatus;
  final int? heightCm;
  final String? religion;
  final String? motherTongue;
  final String? caste;
  final String? gotra;
  final String? city;
  final String? state;
  final String? country;
  final String? education;
  final String? occupation;
  final String? annualIncome;
  final String? aboutMe;
  final String? avatarUrl;
  final List<String> photos;
  final int primaryPhotoIndex;
  final String photoPrivacy;
  final bool isVerified;
  final bool isPhotoLocked;
  final String verificationStatus; // 'under_review', 'approved', 'rejected'
  final String? rejectionReason;
  final int estimatedScreeningHours;
  final String? screeningMessage;
  final List<String> hobbies;
  final String? hobbiesOther;
  final String hobbiesOtherStatus;
  final String? horoscopeUrl;
  final String horoscopePrivacy;
  final bool isHidden;
  final String membershipTier; // 'free', 'tier_1', 'tier_2'
  final String chatStatus; // 'online', 'invisible', 'offline'
  final String? phoneNumber;
  final String phonePrivacy;
  final String callPermissions;
  final String? specialCase;
  final PartnerPreferenceModel? partnerPreference;
  final String? matchReason;
  final bool isShortlisted;
  final bool isLimitedScreeningView;

  ProfileModel({
    required this.id,
    this.profileId,
    required this.fullName,
    this.displayName,
    this.displayNameFormat = 'full_name',
    this.customUsername,
    this.gender,
    this.dateOfBirth,
    this.maritalStatus = 'Never Married',
    this.heightCm,
    this.religion,
    this.motherTongue,
    this.caste,
    this.gotra,
    this.city,
    this.state,
    this.country = 'India',
    this.education,
    this.occupation,
    this.annualIncome,
    this.aboutMe,
    this.avatarUrl,
    this.photos = const [],
    this.primaryPhotoIndex = 0,
    this.photoPrivacy = 'all_members',
    this.isVerified = false,
    this.isPhotoLocked = false,
    this.verificationStatus = 'approved',
    this.rejectionReason,
    this.estimatedScreeningHours = 24,
    this.screeningMessage,
    this.hobbies = const [],
    this.hobbiesOther,
    this.hobbiesOtherStatus = 'approved',
    this.horoscopeUrl,
    this.horoscopePrivacy = 'all_members',
    this.isHidden = false,
    this.membershipTier = 'free',
    this.chatStatus = 'online',
    this.phoneNumber,
    this.phonePrivacy = 'accepted_premium',
    this.callPermissions = 'accepted_only',
    this.specialCase,
    this.partnerPreference,
    this.matchReason,
    this.isShortlisted = false,
    this.isLimitedScreeningView = false,
  });

  bool get isApproved => verificationStatus == 'approved';
  bool get isUnderReview => verificationStatus == 'under_review';
  bool get isRejected => verificationStatus == 'rejected';
  bool get isPremium => membershipTier == 'tier_1' || membershipTier == 'tier_2';
  bool get isTier2 => membershipTier == 'tier_2';

  String get effectiveName {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (displayNameFormat == 'first_name_initial') {
      final parts = fullName.trim().split(' ');
      if (parts.length > 1) return '${parts.first} ${parts.last[0]}.';
      return parts.first;
    } else if (displayNameFormat == 'custom_username' && customUsername != null && customUsername!.isNotEmpty) {
      return customUsername!;
    }
    return fullName.isNotEmpty ? fullName : 'Member';
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    List<String> toList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return ProfileModel(
      id: json['id']?.toString() ?? '',
      profileId: json['profile_id'] as String?,
      fullName: json['full_name'] as String? ?? '',
      displayName: json['display_name'] as String?,
      displayNameFormat: json['display_name_format'] as String? ?? 'full_name',
      customUsername: json['custom_username'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      maritalStatus: json['marital_status'] as String? ?? 'Never Married',
      heightCm: json['height_cm'] as int?,
      religion: json['religion'] as String?,
      motherTongue: json['mother_tongue'] as String?,
      caste: json['caste'] as String?,
      gotra: json['gotra'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String? ?? 'India',
      education: json['education'] as String?,
      occupation: json['occupation'] as String?,
      annualIncome: json['annual_income'] as String?,
      aboutMe: json['about_me'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      photos: toList(json['photos']),
      primaryPhotoIndex: json['primary_photo_index'] as int? ?? 0,
      photoPrivacy: json['photo_privacy'] as String? ?? 'all_members',
      isVerified: json['is_verified'] as bool? ?? false,
      isPhotoLocked: json['is_photo_locked'] as bool? ?? false,
      verificationStatus: json['verification_status'] as String? ?? 'approved',
      rejectionReason: json['rejection_reason'] as String?,
      estimatedScreeningHours: json['estimated_screening_hours'] as int? ?? 24,
      screeningMessage: json['screening_message'] as String?,
      hobbies: toList(json['hobbies']),
      hobbiesOther: json['hobbies_other'] as String?,
      hobbiesOtherStatus: json['hobbies_other_status'] as String? ?? 'approved',
      horoscopeUrl: json['horoscope_url'] as String?,
      horoscopePrivacy: json['horoscope_privacy'] as String? ?? 'all_members',
      isHidden: json['is_hidden'] as bool? ?? false,
      membershipTier: json['membership_tier'] as String? ?? 'free',
      chatStatus: json['chat_status'] as String? ?? 'online',
      phoneNumber: json['phone_number'] as String?,
      phonePrivacy: json['phone_privacy'] as String? ?? 'accepted_premium',
      callPermissions: json['call_permissions'] as String? ?? 'accepted_only',
      specialCase: json['special_case'] as String?,
      partnerPreference: json['partner_preference'] != null
          ? PartnerPreferenceModel.fromJson(json['partner_preference'] as Map<String, dynamic>)
          : null,
      matchReason: json['match_reason'] as String?,
      isShortlisted: json['is_shortlisted'] as bool? ?? false,
      isLimitedScreeningView: json['is_limited_screening_view'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'full_name': fullName,
      'display_name': displayName,
      'display_name_format': displayNameFormat,
      'custom_username': customUsername,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'marital_status': maritalStatus,
      'height_cm': heightCm,
      'religion': religion,
      'mother_tongue': motherTongue,
      'caste': caste,
      'gotra': gotra,
      'city': city,
      'state': state,
      'country': country,
      'education': education,
      'occupation': occupation,
      'annual_income': annualIncome,
      'about_me': aboutMe,
      'avatar_url': avatarUrl,
      'photos': photos,
      'primary_photo_index': primaryPhotoIndex,
      'photo_privacy': photoPrivacy,
      'is_verified': isVerified,
      'is_photo_locked': isPhotoLocked,
      'verification_status': verificationStatus,
      'hobbies': hobbies,
      'hobbies_other': hobbiesOther,
      'horoscope_url': horoscopeUrl,
      'horoscope_privacy': horoscopePrivacy,
      'is_hidden': isHidden,
      'membership_tier': membershipTier,
      'chat_status': chatStatus,
      'phone_number': phoneNumber,
      'phone_privacy': phonePrivacy,
      'call_permissions': callPermissions,
      'special_case': specialCase,
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    String? maritalStatus,
    int? heightCm,
    String? religion,
    String? motherTongue,
    String? caste,
    String? gotra,
    String? city,
    String? state,
    String? country,
    String? education,
    String? occupation,
    String? annualIncome,
    String? aboutMe,
    String? avatarUrl,
    List<String>? photos,
    bool? isVerified,
    bool? isPhotoLocked,
    String? verificationStatus,
    String? displayNameFormat,
    String? customUsername,
    String? membershipTier,
    bool? isHidden,
    bool? isShortlisted,
  }) {
    return ProfileModel(
      id: id,
      profileId: profileId,
      fullName: fullName ?? this.fullName,
      displayName: displayName,
      displayNameFormat: displayNameFormat ?? this.displayNameFormat,
      customUsername: customUsername ?? this.customUsername,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      heightCm: heightCm ?? this.heightCm,
      religion: religion ?? this.religion,
      motherTongue: motherTongue ?? this.motherTongue,
      caste: caste ?? this.caste,
      gotra: gotra ?? this.gotra,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      annualIncome: annualIncome ?? this.annualIncome,
      aboutMe: aboutMe ?? this.aboutMe,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      photos: photos ?? this.photos,
      primaryPhotoIndex: primaryPhotoIndex,
      photoPrivacy: photoPrivacy,
      isVerified: isVerified ?? this.isVerified,
      isPhotoLocked: isPhotoLocked ?? this.isPhotoLocked,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason,
      estimatedScreeningHours: estimatedScreeningHours,
      screeningMessage: screeningMessage,
      hobbies: hobbies,
      hobbiesOther: hobbiesOther,
      hobbiesOtherStatus: hobbiesOtherStatus,
      horoscopeUrl: horoscopeUrl,
      horoscopePrivacy: horoscopePrivacy,
      isHidden: isHidden ?? this.isHidden,
      membershipTier: membershipTier ?? this.membershipTier,
      chatStatus: chatStatus,
      phoneNumber: phoneNumber,
      phonePrivacy: phonePrivacy,
      callPermissions: callPermissions,
      specialCase: specialCase,
      partnerPreference: partnerPreference,
      matchReason: matchReason,
      isShortlisted: isShortlisted ?? this.isShortlisted,
      isLimitedScreeningView: isLimitedScreeningView,
    );
  }
}

