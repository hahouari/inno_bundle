library inno_setup;


/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}


void main(List<String> args) {
  if (args.isNotEmpty && args[0] == 'create') {
    print('Hello, World!'); // Replace with your desired functionality
  } else {
    print('Invalid command. Use: dart run inno_setup:create');
  }
}