class FieldValidators {
  bool validatePhoneNumber(String phone) {
    final RegExp phoneRegExp = RegExp(r'^\d{8,11}$');
    return phoneRegExp.hasMatch(phone);
  }

  String? validateNric(String? nric) {
    final RegExp nricRegExp = RegExp(r'^\d{12}$');
    if (nric != null && nric.isEmpty) {
      if (!nricRegExp.hasMatch(nric)) {
        return 'Invalid mykad number';
      }
      return 'Mykad number is empty';
    } else {
      return null;
    }
  }

  String? validateEmail(String? email) {
    final RegExp emailRegExp =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(email!)) {
      return 'Invalid email address';
    } else if (email.isEmpty) {
      return 'Email address is empty';
    } else {
      return null;
    }
  }

  bool validatePassword(String password) {
    return password.isNotEmpty;
  }

  String? validateAddress(String address) {
    if (address.isEmpty) {
      return 'Address is required';
    }
    return null;
  }

  String? validateCity(String city) {
    if (city.isEmpty) {
      return 'City is required';
    }
    return null;
  }

  String? validatePostcode(String postcode) {
    final RegExp postCodeRegex = RegExp(r'^\d{5}$');
    if (postcode.isEmpty) {
      return 'Postcode is required';
    } else if (!postCodeRegex.hasMatch(postcode)) {
      return 'Postcode must be 5 digits';
    }
    return null;
  }

  String? validateEmploymentStatus(String? value) {
    if (value == null) return 'Employment status is required';
    return null;
  }

  String? validateOccupation(String? value) {
    if (value == null) return 'Occupation is required';
    return null;
  }

  String? validateNatureOfBusiness(String? value) {
    if (value == null) return 'Nature of business is required';
    return null;
  }

  String? validateAccountCreationPurpose(String? value) {
    if (value == null) return 'Purpose of creating account is required';
    return null;
  }

  String? validateBusinessName(String? value) {
    if (value == null) return 'Business name is required';
    return null;
  }

  String? validateFullName(String? value) {
    if (value == null) return 'Full name is required';
    return null;
  }

  String? validateTransferAmount({
    required String amount,
    required String spentLimit,
    required String accountBalance,
  }) {
    print('SPENT LIMIT: $spentLimit');
    final limit = double.parse(spentLimit);
    final amountDouble = double.parse(amount);
    final balanceDouble = double.parse(accountBalance);
    if (amountDouble > limit) return '';
    if (amountDouble > balanceDouble) return 'Insufficient wallet balance';
    if (amountDouble <= 0.0) return 'Invalid transfer amount';
    return null;
  }

  String? validateTransferNotes(String? value) {
    if (value == null || value.isEmpty) return 'Transfer notes is required';
    return null;
  }

  String validateNricErr(bool isValid) {
    return !isValid ? 'Invalid nric' : '';
  }

  String validatePhoneNumberErr(bool isValid) {
    return !isValid ? 'Invalid phone number' : '';
  }

  String validateUsernameErr(bool isValid) {
    return !isValid ? 'Invalid username' : '';
  }

  String validateEmailErr(bool isValid) {
    return !isValid ? 'Invalid email address' : '';
  }

  String validatePasswordErr(bool isValid) {
    return !isValid ? 'Invalid password' : '';
  }

  /// Performs the Luhn algorithm to verify a credit card number.
  bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    // Loop over the card number digits from right to left.
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// Validates the credit card number ensuring it's 16 digits long,
  /// belongs to Visa or Mastercard, and passes the Luhn check.
  String? validateCard(String card) {
    if (card.isEmpty) {
      return 'Card is required';
    }

    // Ensure the card is exactly 16 digits.
    final RegExp cardRegex = RegExp(r'^\d{16}$');
    if (!cardRegex.hasMatch(card)) {
      return 'Card must be 16 digits';
    }

    // Validate using the Luhn algorithm.
    if (!_luhnCheck(card)) {
      return 'Invalid card number';
    }

    return null;
  }

  String? validateCardExpiry(String card) {
    // Trim any extra spaces
    card = card.trim();

    // First, check if it's empty
    if (card.isEmpty) {
      return 'Date is required';
    }

    // Check basic format: two digits, slash, two digits
    final RegExp cardRegex = RegExp(r'^\d{2}/\d{2}$');
    if (!cardRegex.hasMatch(card)) {
      return 'Invalid date format';
    }

    // Split into month and year
    final parts = card.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    // Make sure month/year parsed properly
    if (month == null || year == null) {
      return 'Invalid date format';
    }

    // Validate month range
    if (month < 1 || month > 12) {
      return 'Invalid month';
    }

    // For year, we interpret YY as 20YY.
    final currentDate = DateTime.now();
    final currentYear =
        currentDate.year % 100; // last two digits of current year
    final currentMonth = currentDate.month;

    // If the YY is less than the current YY, it’s definitely expired
    if (year < currentYear) {
      return 'Expired card';
    }

    // If same year, check the month
    if (year == currentYear && month < currentMonth) {
      return 'Expired card';
    }

    // Passed all checks
    return null;
  }

  String? validateCvv(String card) {
    final RegExp cardRegex = RegExp(r'^\d{3}$');
    if (card.isEmpty) {
      return 'CVV is required';
    } else if (!cardRegex.hasMatch(card)) {
      return 'CVV must be 3 digits';
    }
    return null;
  }
}
