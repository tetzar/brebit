import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_aws_s3_client/flutter_aws_s3_client.dart';

class AwsS3Manager {
  static const String SECRET_KEY = "a/ToFJyS0nv49Kn+gOZx7cznpXy7nogXSRhmPkfO";
  static const String ACCESS_KEY = "AKIAZQXKKLENJFY2XFUP";
  static const String BUCKET_ID = "brebit-image-bucket";
  static const String REGION = "ap-northeast-1";
  static AwsS3Client client = AwsS3Client(
      secretKey: SECRET_KEY,
      accessKey: ACCESS_KEY,
      bucketId: BUCKET_ID,
      region: REGION);
  static Future<Uint8List> getImage(imageUrl) async {
    final response = await client.getObject(imageUrl);
    return Uint8List.fromList(response.bodyBytes);
  }

  static Future<Uint8List> getSvgBytes(imageUrl) async {
    final response = await client.getObject(imageUrl);
    return Uint8List.fromList(response.bodyBytes);
  }
}

class S3Image {
  String url;
  S3Image(this.url);
  Uint8List? image;
  Future<Uint8List> getImage() async {
    Uint8List? image = this.image;
    if (image != null) return image;
    image = await AwsS3Manager.getImage(this.url);
    this.image = image;
    return image;
  }

  Future<void> updateImage(String url) async {
    this.url = url;
    this.image = await AwsS3Manager.getImage(this.url);
  }

  void delete() {
    this.url = '';
    this.image = null;
  }
}


class S3SvgImage {
  String url;
  Uint8List? bytes;
  S3SvgImage(this.url);
  Future<Uint8List> getImage() async {
    Uint8List? bytes = this.bytes;
    if (bytes == null) {
      bytes = await AwsS3Manager.getSvgBytes(url);
    }
    return bytes;
  }
}

class S3ImageProvider extends ImageProvider<S3ImageProvider>{

  const S3ImageProvider(this.image, { this.scale = 1.0 });

  final S3Image image;

  final double scale;

  @override
  ImageStreamCompleter load(S3ImageProvider key, DecoderCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.image.url,
      informationCollector: () {
        return <DiagnosticsNode>[
          DiagnosticsProperty<ImageProvider>('Image provider', this),
          DiagnosticsProperty<S3ImageProvider>('Image key', key),
        ];
      },
    );
  }

  @override
  Future<S3ImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<S3ImageProvider>(this);
  }


  Future<ui.Codec> _loadAsync(
      S3ImageProvider key,
      StreamController<ImageChunkEvent> chunkEvents,
      DecoderCallback decode,
      ) async {
    try {
      assert(key == this);

      final Uint8List bytes = await key.image.getImage();
      if (bytes.lengthInBytes == 0)
        throw Exception('NetworkImage is an empty file: ${key.image.url}');

      return decode(bytes);
    } catch (e) {
      // Depending on where the exception was thrown, the image cache may not
      // have had a chance to track the key in the cache at all.
      // Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      chunkEvents.close();
    }
  }



  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is S3ImageProvider
        && other.image.url == image.url
        && other.scale == scale;
  }

  @override
  int get hashCode => ui.hashValues(image.url, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'NetworkImage')}("${image.url}", scale: $scale)';
}
