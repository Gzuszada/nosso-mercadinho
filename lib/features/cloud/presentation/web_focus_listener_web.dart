import 'dart:js_interop';

@JS('window')
external _WebWindow get _window;

@JS('document')
external _WebDocument get _document;

extension type _WebWindow(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

extension type _WebDocument(JSObject _) implements JSObject {
  external String get visibilityState;
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

/// Registers browser focus and visibility listeners without polling.
void Function()? addWebFocusListener(void Function() onFocus) {
  void focusListener(JSAny? _) => onFocus();
  void visibilityListener(JSAny? _) {
    if (_document.visibilityState == 'visible') onFocus();
  }

  final focus = focusListener.toJS;
  final visibility = visibilityListener.toJS;
  _window.addEventListener('focus', focus);
  _document.addEventListener('visibilitychange', visibility);
  return () {
    _window.removeEventListener('focus', focus);
    _document.removeEventListener('visibilitychange', visibility);
  };
}
