from ffmpeg import nil
import sandboxpkg/results
from std/strutils import parseEnum

import macros

type
  FFmpegError {.pure.} = enum
    OperationNotPermitted = "Operation not permitted"
    NoSuchFileOrDirectory = "No such file or directory"
    NoSuchProcess = "No such process"
    InterruptedSystemCall = "Interrupted system call"
    InputOutputError = "Input/output error"
    DeviceNotConfigured = "Device not configured"
    ArgumentListTooLong = "Argument list too long"
    ExecFormatError = "Exec format error"
    BadFileDescriptor = "Bad file descriptor"
    NoChildProcesses = "No child processes"
    ResourceDeadlockAvoided = "Resource deadlock avoided"
    CannotAllocateMemory = "Cannot allocate memory"
    PermissionDenied = "Permission denied"
    BadAddress = "Bad address"
    BlockDeviceRequired = "Block device required"
    ResourceBusy = "Resource busy"
    FileExists = "File exists"
    CrossDeviceLink = "Cross-device link"
    OperationNotSupportedByDevice = "Operation not supported by device"
    NotADirectory = "Not a directory"
    IsADirectory = "Is a directory"
    InvalidArgument = "Invalid argument"
    TooManyOpenFilesInSystem = "Too many open files in system"
    TooManyOpenFiles = "Too many open files"
    InappropriateIoctlForDevice = "Inappropriate ioctl for device"
    TextFileBusy = "Text file busy"
    FileTooLarge = "File too large"
    NoSpaceLeftOnDevice = "No space left on device"
    IllegalSeek = "Illegal seek"
    ReadOnlyFileSystem = "Read-only file system"
    TooManyLinks = "Too many links"
    BrokenPipe = "Broken pipe"
    NumericalArgumentOutOfDomain = "Numerical argument out of domain"
    ResultTooLarge = "Result too large"
    ResourceTemporarilyUnavailable = "Resource temporarily unavailable"
    InterfaceOutputQueueIsFull = "Interface output queue is full"
    PreviousOwnerDied = "Previous owner died"
    StateNotRecoverable = "State not recoverable"
    PolicyNotFound = "Policy not found"
    OperationNotSupportedOnSocket = "Operation not supported on socket"
    STREAMIoctlTimeout = "STREAM ioctl timeout"
    ProtocolError = "Protocol error"
    NotASTREAM = "Not a STREAM"
    NoSTREAMResources = "No STREAM resources"
    ENOLINKReserved = "ENOLINK (Reserved)"
    NoMessageAvailableOnSTREAM = "No message available on STREAM"
    EMULTIHOPReserved = "EMULTIHOP (Reserved)"
    BadMessage = "Bad message"
    AttributeNotFound = "Attribute not found"
    IllegalByteSequence = "Illegal byte sequence"
    NoMessageOfDesiredType = "No message of desired type"
    IdentifierRemoved = "Identifier removed"
    OperationCanceled = "Operation canceled"
    MalformedMachOFile = "Malformed Mach-o file"
    SharedLibraryVersionMismatch = "Shared library version mismatch"
    BadCPUTypeInExecutable = "Bad CPU type in executable"
    BadExecutableOrSharedLibrary = "Bad executable (or shared library)"
    ValueTooLargeToBeStoredInDataType = "Value too large to be stored in data type"
    DeviceError = "Device error"
    DevicePowerIsOff = "Device power is off"
    NeedAuthenticator = "Need authenticator"
    AuthenticationError = "Authentication error"
    InappropriateFileTypeOrFormat = "Inappropriate file type or format"
    FunctionNotImplemented = "Function not implemented"
    NoLocksAvailable = "No locks available"
    BadProcedureForProgram = "Bad procedure for program"
    ProgramVersionWrong = "Program version wrong"
    RPCProgNotAvail = "RPC prog. not avail"
    RPCVersionWrong = "RPC version wrong"
    RPCStructIsBad = "RPC struct is bad"
    TooManyLevelsOfRemoteInPath = "Too many levels of remote in path"
    StaleNFSFileHandle = "Stale NFS file handle"
    DiscQuotaExceeded = "Disc quota exceeded"
    TooManyUsers = "Too many users"
    TooManyProcesses = "Too many processes"
    DirectoryNotEmpty = "Directory not empty"
    NoRouteToHost = "No route to host"
    HostIsDown = "Host is down"
    FileNameTooLong = "File name too long"
    TooManyLevelsOfSymbolicLinks = "Too many levels of symbolic links"
    ConnectionRefused = "Connection refused"
    OperationTimedOut = "Operation timed out"
    TooManyReferencesCanNotSplice = "Too many references: can't splice"
    CanNotSendAfterSocketShutdown = "Can't send after socket shutdown"
    SocketIsNotConnected = "Socket is not connected"
    SocketIsAlreadyConnected = "Socket is already connected"
    NoBufferSpaceAvailable = "No buffer space available"
    ConnectionResetByPeer = "Connection reset by peer"
    SoftwareCausedConnectionAbort = "Software caused connection abort"
    NetworkDroppedConnectionOnReset = "Network dropped connection on reset"
    NetworkIsUnreachable = "Network is unreachable"
    NetworkIsDown = "Network is down"
    CanNotAssignRequestedAddress = "Can't assign requested address"
    AddressAlreadyInUse = "Address already in use"
    AddressFamilyNotSupportedByProtocolFamily = "Address family not supported by protocol family"
    ProtocolFamilyNotSupported = "Protocol family not supported"
    OperationNotSupported = "Operation not supported"
    SocketTypeNotSupported = "Socket type not supported"
    ProtocolNotSupported = "Protocol not supported"
    ProtocolNotAvailable = "Protocol not available"
    ProtocolWrongTypeForSocket = "Protocol wrong type for socket"
    MessageTooLong = "Message too long"
    DestinationAddressRequired = "Destination address required"
    SocketOperationOnNonSocket = "Socket operation on non-socket"
    OperationAlreadyInProgress = "Operation already in progress"
    OperationNowInProgress = "Operation now in progress"
  
  FFmpegGetErrorError {.pure.} = enum
    Error = "Errnum cannot be found"

proc getError (errnum: int): Result[FFmpegError, FFmpegGetErrorError] =
  var errchar_arr: array[100, cchar]
  if ffmpeg.av_strerror(errnum.cint, errchar_arr[0].addr, 100) == 0:
    var errstr = ""
    for errchar in errchar_arr:
      if errchar != '\x00':
        errstr.add errchar
      else: ok(parseEnum[FFmpegError](errstr))
  else:
    err(FFmpegGetErrorError.Error)

type
  DecoderObj = object
    format_context: ptr ffmpeg.AVFormatContext
  
  Decoder = ref DecoderObj

  VideoObj = object
    decoder: Decoder

  Video = ref VideoObj

  FFmpegGetErrorPanic = object of Defect

proc open* (video: Video, src_path: string): Result[Video, FFmpegError] =
  let res = ffmpeg.avformat_open_input(video.decoder.format_context.addr, src_path, nil, nil)
  if res == 0:
    ok(video)
    return
  
  res.getError.match:
    Ok(errEnum):
      err(errEnum)
    Err(_):
      raise newException(FFmpegGetErrorPanic, "For some unknown reason FFmpeg did not return the correct error.")

let video = Video(decoder: Decoder(format_context: nil))


video.open("/Users/momeemt/develop/mock-up/assets/src.mp4").match:
  Ok(v):
    echo v[]
  Err(err):
    echo err
