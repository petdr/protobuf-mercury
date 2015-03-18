# Introduction #

The program mprotoc generates a Mercury API for a binary protocol defined in a .proto file.  This guide explains how to use mprotoc and the generated API.

# Installation #

Download http://protobuf-mercury.googlecode.com/files/protobuf-mercury-0.1.tar.gz, do `tar -xzf protobuf-mercury-0.1.tar.gz` and follow the instructions in the README file.

# Using mprotoc #

To generate a Mercury API for a protocol defined in myproto.proto, execute the command `mprotoc --out . myproto.proto`.  This will cause the file `myproto.m` to be generated in the current directory.  At the moment the generated module always has the same name as the .proto file.

# The generated module #

For each message and enumeration in the .proto file, mprotoc generates a Mercury type.

For an enumeration such as:
```
enum Colour {
    RED = 0;
    BLUE = 1;
    GREEN = 2;
    MAGENTA = 3;
    CYAN = 4;
    YELLOW = 5;
}
```
the following Mercury type will be generated:
```
:- type colour
    --->    colour_red
    ;       colour_blue
    ;       colour_green
    ;       colour_magenta
    ;       colour_cyan
    ;       colour_yellow.
```
Note that each value has the enumeration name as a prefix.  This is to avoid ambiguities.

For a message such as:
```
message Person {
    required int32 id = 1;
    required string name = 2;
    required Gender gender = 3;
    required double double= 4;
    optional string email = 5;
    optional MaritalStatus marital_status = 6 [default = SINGLE];
    repeated Person children = 7;
}
```
the following type is generated:
```
:- type person
    --->    person(
                person_id :: int,
                person_name :: string,
                person_gender :: gender,
                person_double :: float,
                person_email :: maybe(string),
                person_marital_status :: maybe(marital_status),
                person_children :: list(person)
            ).
```

The generated type has the same name as the message except that camel case identifiers are converted to lowercase with underscores.  Nested messages have their ancestor message names prepended to the generated type name.  Fields are similarly named with the message name and any ancestor message names prepended to the field name.  Again this is to avoid ambiguities.

Protobuf types are mapped to Mercury types according to the following table:

| **protobuf type** | **Mercury type** |
|:------------------|:-----------------|
| double          | float          |
| int32           | int            |
| sint32          | int            |
| sfixed32        | int            |
| bool            | bool           |
| string          | string         |
| bytes           | bitmap         |

Repeated fields are wrapped in the `list` type and optional fields are wrapped in the `maybe` type.

In addition a function is generated for each optional field.  This function takes the message type as its sole input and returns the value of the optional field if it is set, or the default value if it is not set.  The function has the same name as the field, but with the added suffix '_or\_default'._

# `protobuf_runtime.m` #

Generated enumeration types are made instances of the `pb_enumeration` typeclass and generated message types are made instances of the `pb_message` typeclass.  These typeclasses are defined in `protobuf_runtime.m` which is imported by all generated modules.

Most of the methods of these typeclasses are of no interest to users of the API.  There is however one method on the `pb_message` typeclass that may be useful in user code.  This is the `init_message` method which returns a message with all optional fields set to `no`, all repeated fields set to `[]` and all required fields set to an appropriate default value for the type (numeric fields are initialized to zero, string fields are initialized to the empty string and embedded messages are initialized with their `init_message` method).

`protobuf_runtime.m` also contains instances of the standard `stream.reader` and `stream.writer` typeclasses which can be used to read and write messages to and from binary streams.

```
:- type limit == int.

:- type pb_reader(S)
    --->    pb_reader(S, limit).
```

`pb_reader/1` is an instance of `stream.reader`.  The first argument is the underlying stream to read from.  This stream should be able to read bytes.  The second argument is how many bytes to read before giving up.  This can be used to limit the size of read messages.

Here is an example of how to read a message from a byte stream with a limit of 10000 bytes:
```
    stream.get(pb_reader(Stream, 10000), GetRes, !IO),
    (
        GetRes = ok(pb_message(Person)),
        % Do something with Person...
    ;
        GetRes = error(Error),
        % Handle read error ...
    ;
        GetRes = eof,
        % Handle eof...
    )
```
Note that the read message is wrapped in a `pb_message` functor.

```
:- type pb_writer(S)
    --->    pb_writer(S).
```

`pb_writer` is an instance of `stream.writer`.  It wraps the underlying byte stream to be written to.

Here is an example of its use:
```
stream.put(pb_writer(Stream), pb_message(Person), !IO)
```

Note again that the message needs to be wrapped in a `pb_message` functor before being written.

For more examples see the `samples` directory in the source distribution.

# Limitations of the current implementation #

The following scalar field types are not yet supported:

| float |
|:------|
| int64 |
| uint32 |
| uint64 |
| sint64 |
| fixed32 |
| fixed64 |
| sfixed64 |

Services are not supported yet.

Imports are not supported yet.

Extension fields are not handled yet.

Unknown fields are ignored by the current implementation, so if you serialize a previously parsed messaged, the unknown fields in the original message are lost.