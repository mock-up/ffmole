import ffmpeg
import std/options

type
  CodecContextObj = object
    codec_context: ptr AVCodecContext

  CodecContext = ref CodecContextObj

proc newCodecContext (codec: ptr AVCodec): Option[CodecContext] =
  # 本当はEitherが欲しいが一旦Optionで
  # この関数は無条件で呼べる
  let codec_context = ffmpeg.avcodec_alloc_context3(codec)
  if codec_context == nil:
    result = none(CodecContext)
  else:
    result = some(
      CodecContext(codec_context: codec_context)
    )

proc avcodec_alloc_context3* (codec: ptr AVCodec): ptr AVCodecContext =
  ## AVCodecContextを割り当ててフィールドにデフォルト値を設定
  ## avcodec_free_contextで解放できる
  ## 失敗した時にはnullが返る
  ffmpeg.avcodec_alloc_context3(codec)

proc avcodec_open2* (avctx: ptr AVCodecContext, codec: ptr AVCodec, options: ptr ptr AVDictionary): cint =
  ## codecを使用するようにavctxを初期化する
  ## この関数を使用する前にコンテキストをavcodec_alloc_context3で割り当てる必要がある
  ## https://ffmpeg.org/doxygen/trunk/group__lavc__core.html#ga11f785a188d7d9df71621001465b0f1d
  ffmpeg.avcodec_open2(avctx, codec, options)

