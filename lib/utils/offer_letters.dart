Map<int, String> buildOfferLetterMap(Set<int> selectedOffers) {
  final sorted = selectedOffers.toList()..sort();
  final map = <int, String>{};
  final shouldAssignLetters = sorted.length > 1;
  for (var i = 0; i < sorted.length; i++) {
    map[sorted[i]] = shouldAssignLetters ? _letterForIndex(i) : '';
  }
  return map;
}

String _letterForIndex(int position) {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  var index = position;
  var result = '';
  while (index >= 0) {
    result = letters[index % 26] + result;
    index = (index ~/ 26) - 1;
  }
  return result;
}
