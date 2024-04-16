class DataState {
  final bool isLoading;
  final bool hasError;
  final String errorMessage;

  DataState({
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage = '',
  });

  factory DataState.loading() {
    return DataState(isLoading: true);
  }

  factory DataState.error(String message) {
    return DataState(hasError: true, errorMessage: message);
  }

  factory DataState.normal() {
    return DataState();
  }
}
