import ffmpeg

type
  VideoObj = object
  Video = ref VideoObj
    io_context: ptr ffmpeg.AVIOContext

proc init* (_: typedesc[Video], src_path, dist_path: string): Video =
  result = Video(io_context: nil)
  if ffmpeg.avio_open(result.io_context.addr,)