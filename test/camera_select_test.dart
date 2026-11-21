import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackcuack_studio/src/core/utils/camera_select.dart';

CameraDescription _cam(String name, CameraLensDirection dir) =>
    CameraDescription(name: name, lensDirection: dir, sensorOrientation: 0);

void main() {
  test('elige la trasera cuando hay frontal y trasera', () {
    final cams = [
      _cam('front', CameraLensDirection.front),
      _cam('back', CameraLensDirection.back),
    ];
    expect(pickBackCamera(cams).name, 'back');
  });

  test('con varias traseras elige la primera (principal)', () {
    final cams = [
      _cam('front', CameraLensDirection.front),
      _cam('back-main', CameraLensDirection.back),
      _cam('back-wide', CameraLensDirection.back),
    ];
    expect(pickBackCamera(cams).name, 'back-main');
  });

  test('sin trasera (webcam del Mac) usa la disponible, sin error', () {
    final cams = [_cam('facetime', CameraLensDirection.front)];
    expect(pickBackCamera(cams).name, 'facetime');
  });
}
