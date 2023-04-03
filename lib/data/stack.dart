class MyStack<T> {
  final List<T> _stack = [];

  void push(T item) {
    _stack.add(item);
  }

  T pop() {
    if (isEmpty) {
      throw Exception('Stack is empty');
    }
    return _stack.removeLast();
  }

  T peek() {
    if (isEmpty) {
      throw Exception('Stack is empty');
    }
    return _stack.last;
  }

  bool get isEmpty => _stack.isEmpty;
}
