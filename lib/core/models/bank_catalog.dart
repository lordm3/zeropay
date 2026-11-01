class BankCatalogEntry {
  final String name;
  final String code;
  final String colorHex;

  const BankCatalogEntry(this.name, this.code, this.colorHex);

  String get assetPath => 'assets/banks/$code.png';
}

/// Banks with a bundled logo. A profile whose name matches one shows its logo; any other name
/// is treated as a custom bank and shows a coloured badge.
class BankCatalog {
  static const all = <BankCatalogEntry>[
    BankCatalogEntry('State Bank of India', 'sbin', '#22409A'),
    BankCatalogEntry('HDFC Bank', 'hdfc', '#004C8F'),
    BankCatalogEntry('ICICI Bank', 'icic', '#B02A28'),
    BankCatalogEntry('Axis Bank', 'utib', '#97144D'),
    BankCatalogEntry('Kotak Mahindra Bank', 'kkbk', '#003874'),
    BankCatalogEntry('Punjab National Bank', 'punb', '#A2173A'),
    BankCatalogEntry('Bank of Baroda', 'barb', '#F15A29'),
    BankCatalogEntry('Canara Bank', 'cnrb', '#0091D5'),
    BankCatalogEntry('Union Bank of India', 'ubin', '#E31E24'),
    BankCatalogEntry('Bank of India', 'bkid', '#F47B20'),
    BankCatalogEntry('Indian Bank', 'idib', '#F7BC4B'),
    BankCatalogEntry('Indian Overseas Bank', 'ioba', '#0B4EA2'),
    BankCatalogEntry('Central Bank of India', 'cbin', '#D2153D'),
    BankCatalogEntry('UCO Bank', 'ucba', '#0A4DA2'),
    BankCatalogEntry('Bank of Maharashtra', 'mahb', '#1B9AD6'),
    BankCatalogEntry('Punjab & Sind Bank', 'psib', '#B5202E'),
    BankCatalogEntry('IDBI Bank', 'ibkl', '#F58220'),
    BankCatalogEntry('IndusInd Bank', 'indb', '#7F1416'),
    BankCatalogEntry('Yes Bank', 'yesb', '#2B60AB'),
    BankCatalogEntry('IDFC FIRST Bank', 'idfb', '#9C1D26'),
    BankCatalogEntry('Federal Bank', 'fdrl', '#003A80'),
    BankCatalogEntry('South Indian Bank', 'sibl', '#B5121B'),
    BankCatalogEntry('RBL Bank', 'ratn', '#21317D'),
    BankCatalogEntry('Bandhan Bank', 'bdbl', '#C8261E'),
    BankCatalogEntry('AU Small Finance Bank', 'aubl', '#EF6719'),
    BankCatalogEntry('Karur Vysya Bank', 'kvbl', '#1F7A3D'),
    BankCatalogEntry('City Union Bank', 'ciub', '#2E3192'),
    BankCatalogEntry('Tamilnad Mercantile Bank', 'tmbl', '#C42A8B'),
    BankCatalogEntry('Karnataka Bank', 'karb', '#7E3F98'),
    BankCatalogEntry('Dhanlaxmi Bank', 'dlxb', '#5B1460'),
    BankCatalogEntry('Jammu & Kashmir Bank', 'jaka', '#0A82C4'),
    BankCatalogEntry('Equitas Small Finance Bank', 'esfb', '#1F3B8C'),
    BankCatalogEntry('Ujjivan Small Finance Bank', 'ujvn', '#1FA085'),
    BankCatalogEntry('Utkarsh Small Finance Bank', 'utks', '#4F2683'),
  ];

  static BankCatalogEntry? find(String bankName) {
    final key = bankName.trim().toLowerCase();
    for (final bank in all) {
      if (bank.name.toLowerCase() == key) return bank;
    }
    return null;
  }
}
