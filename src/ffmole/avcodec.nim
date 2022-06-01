import ffmpeg
import std/options
import results

type
  borrowingObj [T] = object
    value: T
  
  borrowing [T] = ref borrowingObj[T]

  containedObj [T] = object
    value: T
  
  contained [T] = ref containedObj[T]

  VideoCodec {.pure.} = enum
    MPEG_1, MPEG_2, H261, H263

  ffCodecKind = enum
    ckDecoder
    ckEncoder

  ffCodecObj [
    kind: static ffCodecKind,
  ] = object
    codec: ptr AVCodec
  
  ffCodecRef [
    kind: static ffCodecKind,
  ] = ref ffCodecObj[
            kind,
          ]
  
  Decoder* = ffCodecRef[ckDecoder]
  Encoder* = ffCodecRef[ckEncoder]

  GetCodecError* {.pure.} = enum
    Error = "The specified decoder could not be found"

  ffCodecContextObj [
    alloced_context: static bool,
  ] = object
    codec_context: ptr AVCodecContext
    codec: ptr AVCodec

  ffCodecContextRef [
    alloced_context: static bool,
  ] = ref ffCodecContextObj[
            alloced_context,
          ]
  
  CodecContext* = ffCodecContextRef[false]

  AllocCodecContextError* {.pure.} = enum
    Error = "Failed to alloc an AVCodecContext and set default values for its fields"
  
  ffAVClassObj = object
    avclass: ptr AVClass

  ffAVClassRef = ref ffAVClassObj

proc `&` [T] (value: T): borrowing[T] =
  result = borrowing(value: value)

proc `&!` [T] (value: T): var borrowing[T] =
  result = borrowing(value: value)

converter VideoCodecToAVCodecID* (codec: VideoCodec): AVCodecID =
  result = case codec
           of MPEG_1: AVCodecID.AV_CODEC_ID_MPEG1VIDEO
           of MPEG_2: AVCodecID.AV_CODEC_ID_MPEG2VIDEO
           of H261: AVCodecID.AV_CODEC_ID_H261
           of H263: AVCodecID.AV_CODEC_ID_H263

proc init* [K: static ffCodecKind] (_: typedesc[CodecContext], codec: ffCodecRef[K]): Result[ffCodecContextRef[true, false], AllocCodecContextError] =
  ## AVCodecContextを割り当ててフィールドにデフォルト値を設定する
  let codec_context = ffmpeg.avcodec_alloc_context3(codec.codec)
  if codec_context == nil:
    result = err(AllocCodecContextError.Error)
  else:
    result = ok(CodecContextRef[true](
      codec_context: codec_context,
      codec: codec
    ))

proc free (codec_context: ffCodecContextRef[true, false]) =
  ffmpeg.avcodec_free_context(codec_context.codec_context.addr)

proc open* (codec_context: ffCodecContextRef[true, false], options: ptr ptr AVDictionary): Result[ffCodecContextRef[true, false], string] =
  # avcodec_open2に対応
  # if ffmpeg.avcodec_open2(codec_context.codec_context, codec_context.codec, options) == 0:
  #   result = codec_context.some()
  # else:
  #   # エラーを返したい Resultで
  #   result = CodecContextRef[true].none()
  discard

proc toResultCodecRef [K: static ffCodecKind] (codec: ptr AVCodec): Result[ffCodecRef[K], GetCodecError] =
  if codec == nil:
    result = err(GetCodecError.Error)
  else:
    result = ok(CodecRef[K, false](
      codec: codec
    ))

proc init* (_: typedesc[Decoder], id: AVCodecID): Result[ffCodecRef[ckDecoder], GetCodecError] =
  result = avcodec_find_decoder(id).toResultCodecRef[ckDecoder]()

proc init* (_: typedesc[Encoder], id: AVCodecID): Result[ffCodecRef[ckDecoder], GetCodecError] =
  result = avcodec_find_encoder(id).toResultCodecRef[ckEncoder]()

proc class* [K: static ffCodecKind] (_: typedesc[ffCodecRef[K]]): ffAVClassRef =
  result = ffAVClassRef(avclass: avcodec_get_class())

proc class* [K: static ffCodecKind] (_: ffCodecRef[K]): ffAVClassRef =
  result = ffCodecRef[K].class

proc bitsPerSample* [K: static ffCodecKind] (codec: ffCodecRef[K], exact = false): Option[int] =
  let bits_per_sample = if exact:
                          av_get_exact_bits_per_sample(codec.codec.id)
                        else:
                          av_get_bits_per_sample(codec.codec.id)
  result = if bits_per_sample == 0:
             none(int)
           else:
             some(bits_per_sample)
  codec.free()

proc avcodec_open2* (avctx: ptr AVCodecContext, codec: ptr AVCodec, options: ptr ptr AVDictionary): cint =
  ## codecを使用するようにavctxを初期化する
  ## この関数を使用する前にコンテキストをavcodec_alloc_context3で割り当てる必要がある
  ## https://ffmpeg.org/doxygen/trunk/group__lavc__core.html#ga11f785a188d7d9df71621001465b0f1d
  ffmpeg.avcodec_open2(avctx, codec, options)

template `&` (T: typedesc): typedesc =
  borrowing[T]

proc use* [K: static ffCodecKind] (_: typedesc[CodecContext], codec: ffCodecRef[K], fn: proc (codec_context: var `&`CodecContext)) =
  var codec_context = CodecContext.init(codec)
  fn(&codec_context)
  codec_context.free()

type t1[T] = var T

proc `~` [T] (value: T): contained[T] =
  result = contained(value: value)

template `@` (T: typedesc): typedesc =
  t1[contained[T]]

proc a (v: @int) =
  discard

echo @int