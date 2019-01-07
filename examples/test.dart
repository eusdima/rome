Stream<num> getStream() => Stream.periodic(Duration(milliseconds: 1),
    (num value) => (DateTime.now().millisecondsSinceEpoch));

Stream<num> convertToBinary(Stream<num> inputStream) =>
    inputStream.as((num value) {
      num result = 0;

      for (num i = 12; i >= 0; i--) {
        result *= 10;
        result += ((1 << i) & value) != 0 ? 1 : 0;
      }

      return result;
    });

void main() {
  Stream<num> dateStream = getStream();

  convertToBinary(dateStream).listen((num data) => print(data));
}
