class CancelToken {
  bool isCancelled = false;
  
  void cancel() {
    isCancelled = true;
  }
}