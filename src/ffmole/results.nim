import macros

type
  ResultKind* {.pure.} = enum
    kOk, kErr

  Result* [T, E] = object
    case kind*: ResultKind
    of kOk:
      ok*: T
    of kErr:
      err*: E
  
  UnwrapPanic* = object of ValueError

proc `?`* [T, E] (value: Result[T, E]): T =
  case value.kind:
  of ResultKind.kOk:
    value.ok
  of ResultKind.kErr:
    return

# proc `?.`* [T, E] (left: T, fn: proc: Result[T, E]): Result[T, E] =
#   fn(?left)

template `?.`* [T] (left: T, right: proc): untyped =
  right(?(left))

template expect* [T, E] (value: Result[T, E], message: string): T =
  case value.kind:
  of ResultKind.kOk:
    value.ok
  of ResultKind.kErr:
    raise newException(UnwrapPanic, message)

template unwrap* [T, E] (value: Result[T, E]): T =
  expect(value, "")

proc ok2* [T, E] (value: T): Result[T, E] =
  result = Result[T, E](kind: kOk, ok: value)
  
proc err2* [T, E] (err: E): Result[T, E] =
  result = Result[T, E](kind: kErr, err: err)

macro ok* (value: untyped): untyped =
  result = quote do:
    proc inner_ok [T, E] (res: Result[T, E], value: T): Result[T, E] =
      result = Result[T, E](kind: ResultKind.kOk, ok: value)
    result = result.inner_ok(`value`)

macro err* (err1: untyped): untyped =
  result = quote do:
    proc inner_err [T, E] (res: Result[T, E], err1: E): Result[T, E] =
      result = Result[T, E](kind: ResultKind.kErr, err: err1)
    result = result.inner_err(`err1`)

macro match* (value, body: untyped): untyped =
  expectLen(body, 2)
  let branches = [body[0][0], body[1][0]]
  var (okExists, errExists) = (0, 0)
  expectKind(branches[0], {nnkIdent, nnkOpenSymChoice})
  expectKind(branches[1], {nnkIdent, nnkOpenSymChoice})
  for branch in branches:
    if branch.repr == "Ok": okExists += 1
    elif branch.repr == "Err": errExists += 1
    else: error("Unexpect Identify " & branch.repr, branch)
  if okExists == 2: error("You describes two Ok clauses.", branches[1])
  elif errExists == 2:  error("You describes two Err clauses.", branches[1])
  result = quote:
    block:
      var res = `value`
      template Ok (okName, okBody: untyped): untyped =
        if res.kind == ResultKind.kOk:
          let okName = res.ok
          okBody
      template Err (errName, errBody: untyped): untyped =
        if res.kind == ResultKind.kErr:
          let errName = res.err
          errBody
      `body`
