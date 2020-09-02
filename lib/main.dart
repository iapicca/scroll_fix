import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const MaterialApp(home: MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mouse Wheel with PageView'),
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        child: SmoothMouseListener(
          controller: _pageController,
          duration: const Duration(milliseconds: 200),
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: Colors.primaries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(color: Colors.primaries[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SmoothMouseListener extends StatefulWidget {
  const SmoothMouseListener({
    @required this.controller,
    @required this.child,
    @required this.duration,
    key,
  }) : super(key: key);
  final PageController controller;
  final Widget child;
  final Duration duration;

  @override
  _SmoothMouseListenerState createState() => _SmoothMouseListenerState();
}

class _SmoothMouseListenerState extends State<SmoothMouseListener> {
  StreamController<double> _controller;

  @override
  void initState() {
    super.initState();
    _controller = StreamController();
    _throttle(_controller.stream).listen(
      (double offset) => widget.controller.animateTo(
        offset,
        duration: widget.duration,
        curve: Curves.ease,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent && e.scrollDelta.dy.abs() > 0)
      _controller.sink.add(e.scrollDelta.dy);
  }

  Stream<double> _throttle(Stream<double> dy) async* {
    double _currentOffset() => widget.controller.position.pixels;
    double _offset = _currentOffset();
    Timer _setTimer() =>
        Timer(widget.duration, () => _offset = _currentOffset());
    Timer _timer = _setTimer();

    /// TODO make it prettier w/ RestartableTimer
    /// [https://api.flutter.dev/flutter/package-async_async/RestartableTimer-class.html]
    /// but doesn't seem to "exist" (?)

    await for (double delta in dy) {
      if (!_timer.isActive) {
        _offset = _currentOffset();
      }
      _timer = _setTimer();
      yield _offset += delta;
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerSignal: _handlePointerSignal,
        child: IgnorePointerSignal(child: widget.child),
      );
}

class IgnorePointerSignal extends SingleChildRenderObjectWidget {
  IgnorePointerSignal({Key key, Widget child}) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(_) => _IgnorePointerSignalRenderObject();
}

class _IgnorePointerSignalRenderObject extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    for (RenderPointerListener target in result.path
        .map(
          (HitTestEntry i) => i.target,
        )
        .where(
          (HitTestTarget j) => j is RenderPointerListener,
        )) {
      target.onPointerSignal = null;
    }
    return super.hitTest(result, position: position);
  }
}
