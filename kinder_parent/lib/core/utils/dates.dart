/// Daty po polsku i klucze używane w Firestore.
/// - miesiąc płatności: "RRRR-MM" (children.paidMonths, jak w panelu),
/// - dzień jadłospisu: "RRRR-MM-DD" (ID dokumentu w menu/).
class Dates {
  static const _months = [
    'styczeń',
    'luty',
    'marzec',
    'kwiecień',
    'maj',
    'czerwiec',
    'lipiec',
    'sierpień',
    'wrzesień',
    'październik',
    'listopad',
    'grudzień',
  ];

  // Dopełniacz: "10 listopada"
  static const _monthsOf = [
    'stycznia',
    'lutego',
    'marca',
    'kwietnia',
    'maja',
    'czerwca',
    'lipca',
    'sierpnia',
    'września',
    'października',
    'listopada',
    'grudnia',
  ];

  static const weekdaysShort = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];
  static const weekdays = [
    'Poniedziałek',
    'Wtorek',
    'Środa',
    'Czwartek',
    'Piątek',
    'Sobota',
    'Niedziela',
  ];

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String monthKey(DateTime d) => '${d.year}-${_two(d.month)}';

  static String dayKey(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  /// "Listopad 2026"
  static String monthLabel(DateTime d) {
    final name = _months[d.month - 1];
    return '${name[0].toUpperCase()}${name.substring(1)} ${d.year}';
  }

  /// "10 listopada"
  static String dayMonth(DateTime d) => '${d.day} ${_monthsOf[d.month - 1]}';

  /// "01.11.2026 20:50"
  static String dateTime(DateTime d) =>
      '${_two(d.day)}.${_two(d.month)}.${d.year} ${_two(d.hour)}:${_two(d.minute)}';

  /// Poniedziałek tygodnia, w którym jest [d] (bez godziny)
  static DateTime mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
