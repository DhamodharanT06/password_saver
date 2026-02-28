import 'dart:math';

class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static const String _ambiguous = 'il1Lo0O'; // Characters that look similar

  /// Generate a random password
  static String generate({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool excludeAmbiguous = true,
  }) {
    if (length < 4) length = 4;

    final random = Random.secure();
    String characters = '';

    if (includeLowercase) characters += _lowercase;
    if (includeUppercase) characters += _uppercase;
    if (includeNumbers) characters += _numbers;
    if (includeSymbols) characters += _symbols;

    if (characters.isEmpty) {
      characters = _lowercase + _numbers;
    }

    // Remove ambiguous characters if requested
    if (excludeAmbiguous) {
      characters = characters.replaceAll(RegExp('[' + RegExp.escape(_ambiguous) + ']'), '');
    }

    final password = <String>[];

    // Ensure at least one character from each selected type
    var types = <String>[];
    if (includeLowercase) types.add(_filterAmbiguous(_lowercase, excludeAmbiguous));
    if (includeUppercase) types.add(_filterAmbiguous(_uppercase, excludeAmbiguous));
    if (includeNumbers) types.add(_filterAmbiguous(_numbers, excludeAmbiguous));
    if (includeSymbols) types.add(_filterAmbiguous(_symbols, excludeAmbiguous));

    for (var type in types) {
      if (type.isNotEmpty) {
        password.add(type[random.nextInt(type.length)]);
      }
    }

    // Fill the rest with random characters
    while (password.length < length) {
      password.add(characters[random.nextInt(characters.length)]);
    }

    // Shuffle the password
    password.shuffle(random);

    return password.join('');
  }

  static String _filterAmbiguous(String characters, bool exclude) {
    if (!exclude) return characters;
    return characters.replaceAll(RegExp('[' + RegExp.escape(_ambiguous) + ']'), '');
  }

  /// Generate a memorable password (Passphrase)
  static String generatePassphrase({
    int wordCount = 4,
    String separator = '-',
    bool capitalize = true,
  }) {
    const words = [
      'apple', 'banana', 'cherry', 'dragon', 'eagle', 'forest', 'guitar', 'harmony',
      'island', 'journey', 'kingdom', 'liberty', 'mountain', 'nature', 'ocean', 'palace',
      'quest', 'river', 'sunset', 'temple', 'universe', 'valley', 'wizard', 'crystal',
      'diamond', 'emerald', 'weather', 'thunder', 'shadow', 'silver', 'golden', 'bronze',
      'twilight', 'phantom', 'quantum', 'stellar', 'cosmic', 'titan', 'sphinx', 'sphinx'
    ];

    final random = Random.secure();
    final selected = <String>[];

    for (int i = 0; i < wordCount; i++) {
      selected.add(words[random.nextInt(words.length)]);
    }

    var passphrase = selected.join(separator);
    if (capitalize) {
      passphrase = selected.map((w) => w[0].toUpperCase() + w.substring(1)).join(separator);
    }

    // Add a random number at the end
    passphrase += separator + random.nextInt(100).toString();

    return passphrase;
  }

  /// Generate a PIN code
  static String generatePin({int length = 4}) {
    if (length < 4) length = 4;
    final random = Random.secure();
    return List<String>.generate(
      length,
      (index) => random.nextInt(10).toString(),
    ).join('');
  }

  /// Validate generated password strength
  static int validatePasswordStrength(String password) {
    int score = 0;

    if (password.length >= 12) score += 2;
    else if (password.length >= 8) score += 1;

    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'''[!@#$%^&*()_+\-=\[\]{};:'",.<>?/\\|`~]'''))) score++;

    return (score / 2).ceil();
  }
}
