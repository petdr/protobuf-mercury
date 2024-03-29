% Protocol Buffers for Mercury
% Copyright 2008 Mission Critical Australia.
% http://code.google.com/p/protobuf-mercury/
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%     * Redistributions of source code must retain the above copyright
% notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above
% copyright notice, this list of conditions and the following disclaimer
% in the documentation and/or other materials provided with the
% distribution.
%     * Neither the name of Mission Critical Australia nor the names of its
% contributors may be used to endorse or promote products derived from
% this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
% A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
% LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
% DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
% THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%-----------------------------------------------------------------------------%
% File: protobuf_runtime.m.
% Author: Ian MacLarty (iml@missioncriticalit.com)
%
% The protocol buffer runtime.  This module contains code called by the
% generated code as well as stream instances that can be used to read
% and write messages in user code.
%
%-----------------------------------------------------------------------------%

:- module protobuf_runtime.

:- interface.

:- import_module bitmap.
:- import_module int.
:- import_module io.
:- import_module sparse_bitset.
:- import_module stream.

%-----------------------------------------------------------------------------%

    % A protocol buffer message.
    %
:- type pb_message(M)
    --->    pb_message(M).

    % An embdedded protocol buffer message.
    % This is the same as a pb_message, except that the length of
    % the message precedes it on the wire.  This is useful for
    % sending multiple messages down the same open connection, or
    % mixing protobuf messages with other data.
    %
:- type pb_embedded_message(M)
    --->    pb_embedded_message(M).

:- type limit == int.

    % A wrapper stream from which protocol buffer messages can be
    % read.
    % The limit argument is the maximum number of bytes that should be
    % read before a limit_exceeded error is returned.
    %
:- type pb_reader(S)
    --->    pb_reader(S, limit).

    % A wrapper stream to which protocol buffer messages can be
    % written.
    %
:- type pb_writer(S)
    --->    pb_writer(S).

:- instance stream.stream(pb_reader(S), io)
    <= ( stream.stream(S, io) ).

:- instance stream.input(pb_reader(S), io)
    <= ( stream.input(S, io) ).

:- instance stream.reader(pb_reader(S), pb_message(M), io, pb_read_error(E))
    <= ( stream.reader(S, bitmap.byte, io, E), pb_message(M), stream.error(E) ).

:- instance stream.reader(pb_reader(S), pb_embedded_message(M), io,
    pb_read_error(E))
    <= ( stream.reader(S, bitmap.byte, io, E), pb_message(M), stream.error(E) ).

:- instance stream.stream(pb_writer(S), io)
    <= ( stream.stream(S, io) ).

:- instance stream.output(pb_writer(S), io)
    <= ( stream.output(S, io) ).

:- instance stream.writer(pb_writer(S), pb_message(M), io)
    <= ( stream.writer(S, bitmap.byte, io), pb_message(M) ).

:- instance stream.writer(pb_writer(S), pb_embedded_message(M), io)
    <= ( stream.writer(S, bitmap.byte, io), pb_message(M) ).

    % Errors that could occur while reading from protocol buffer streams.
    %
:- type pb_read_error(E)
    --->    stream_error(E)
    ;       premature_eof(byte_pos)
    ;       incompatible_field_type(field_type, wire_type, field_id, byte_pos)
    ;       limit_exceeded
    ;       embedded_message_length_exceeded(byte_pos)
    ;       unsupported_field_type(field_type, byte_pos)
    ;       invalid_wiretype_tag(int, byte_pos)
    ;       unknown_endianess_on_this_platform
    ;       float_not_8_bytes_on_this_platform
    ;       some [En] unknown_enum_value(En, int)
    ;       some [M] missing_required_fields(M, sparse_bitset(field_id))
    .

    % Exceptions that could be thrown while writing to protocol buffer streams.
    %
:- type pb_write_error
    --->    number_of_bits_in_bitmap_not_divisible_by_8(bitmap.bitmap)
    ;       unknown_endianess_on_this_platform
    ;       float_not_8_bytes_on_this_platform
    .

:- instance stream.error(pb_read_error(E)) <= stream.error(E).

    % Generated message types are made instances of this typeclass.
    %
:- typeclass pb_message(M) where
[
    pred field_info(M, field_id, arg_num, field_type, field_cardinality),
    mode field_info(unused, in, out, out, out) is semidet,
    mode field_info(unused, out, in, out, out) is semidet,

    func init_message = M
].

%-----------------------------------------------------------------------------%
% The following are used by the generated code.
%

:- type byte_pos == int.

:- type field_id == int.

:- type arg_num == int.

:- type field_type
    --->    pb_double
    ;       pb_float
    ;       pb_int32
    ;       pb_int64
    ;       pb_uint32
    ;       pb_uint64
    ;       pb_sint32
    ;       pb_sint64
    ;       pb_fixed32
    ;       pb_fixed64
    ;       pb_sfixed32
    ;       pb_sfixed64
    ;       pb_bool
    ;       pb_string
    ;       pb_bytes
    ;       some [E] enumeration(E) => pb_enumeration(E)
    ;       some [E] embedded_message(E) => pb_message(E)
    .

:- type field_cardinality
    --->    optional
    ;       required
    ;       repeated
    .

:- type wire_type
    --->    varint
    ;       bit64
    ;       length_delimited
%   ;       start_group
%   ;       end_group
    ;       bit32
    .

:- typeclass pb_enumeration(T) where
[
    pred enum_int(T, int),
    mode enum_int(in, out) is det,
    mode enum_int(out, in) is semidet
].

    % Convert a string into a bitmap containing the same bytes as the string
    % (excluding the terminating null byte).  This is used for converting the
    % default values for bytes fields into bitmaps.
    %
:- func string_to_bitmap(string::in) = (bitmap.bitmap::uo) is det.

    % Convert a message to its binary representation as a bitmap.
    %
:- func message_to_bitmap(M::in) = (bitmap.bitmap::uo) is det <= pb_message(M).

    % Convert a binary representation of a message inside a bitmap
    % into a message.
    %
:- pred bitmap_to_message(bitmap.bitmap::bitmap_ui, io.res(M)::out) is det
    <= pb_message(M).

%-----------------------------------------------------------------------------%

:- implementation.

:- import_module bit_buffer.
:- import_module bit_buffer.write.
:- import_module bool.
:- import_module char.
:- import_module deconstruct.
:- import_module exception.
:- import_module list.
:- import_module maybe.
:- import_module require.
:- import_module store.
:- import_module string.
:- import_module type_desc.

%-----------------------------------------------------------------------------%

:- type key ---> key(field_id, wire_type).

:- type embedded_message(M)
    --->    embedded_message(are_more_bytes, M).

:- type are_more_bytes
    --->    more_bytes
    ;       no_more_bytes.

:- instance stream.error(pb_read_error(E)) <= stream.error(E)
where [
    ( error_message(Err) = Msg :-
        ( Err = stream_error(E) ->
            Msg = error_message(E)
        ;
            Msg = string(Err)
        )
    )
].

:- instance stream.stream(pb_reader(S), io)
    <= ( stream.stream(S, io) )
where [
    ( name(pb_reader(Stream, Limit), Name, !IO) :-
        stream.name(Stream, StreamName, !IO),
        Name = string.format(
            "Mercury Google protocol buffer reader with limit %i on " ++
            "underlying stream '%s'", [i(Limit), s(StreamName)])
    )
].

:- instance stream.stream(pb_writer(S), io)
    <= ( stream.stream(S, io) )
where [
    ( name(pb_writer(Stream), Name, !IO) :-
        stream.name(Stream, StreamName, !IO),
        Name = string.format(
            "Mercury Google protocol buffer writer on " ++
            "underlying stream '%s'", [s(StreamName)])
    )
].

:- instance stream.input(pb_reader(S), io)
    <= ( stream.input(S, io) ) where [].

:- instance stream.reader(pb_reader(S), pb_message(M), io, pb_read_error(E))
    <= ( stream.reader(S, byte, io, E), pb_message(M), stream.error(E) )
where [
    pred(get/4) is pb_get
].

:- instance stream.reader(pb_reader(S), pb_embedded_message(M), io,
    pb_read_error(E))
    <= ( stream.reader(S, byte, io, E), pb_message(M), stream.error(E) )
where [
    pred(get/4) is pb_get_embedded
].

:- pred pb_get(pb_reader(S)::in,
    stream.result(pb_message(M), pb_read_error(E))::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E), stream.error(E), pb_message(M) ).

pb_get(pb_reader(Stream, Limit), Result, !IO) :-
    % We copy the default value to make sure it is on the heap, since
    % we will be destructively updating it.
    copy(init_message, Message0),
    build_message(Stream, Limit, Message0, Result0, 0, _Pos,
        sparse_bitset.init, FoundFieldIds, !IO),
    RequiredFieldIds = required_fields(_:M),
    ( sparse_bitset.subset(RequiredFieldIds, FoundFieldIds) ->
        ( Result0 = ok(embedded_message(MoreBytes, Message)),
            ( MoreBytes = no_more_bytes,
                Result = ok(pb_message(Message))
            ; MoreBytes = more_bytes,
                Result = error(limit_exceeded)
            )
        ; Result0 = error(Err),
            Result = error(Err)
        ; Result0 = eof,
            Result = eof
        )
    ;
        Result = error('new missing_required_fields'(init_message:M,
            sparse_bitset.difference(RequiredFieldIds, FoundFieldIds)))
    ).

:- pred pb_get_embedded(pb_reader(S)::in,
    stream.result(pb_embedded_message(M),
    pb_read_error(E))::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E), stream.error(E), pb_message(M) ).

pb_get_embedded(pb_reader(Stream, Limit), Result, !IO) :-
    % We copy the default value to make sure it is on the heap, since
    % we will be destructively updating it.
    copy(init_message, Message0),
    read_embedded_message(Stream, Limit, Message0, Result0, 0, _Pos, !IO),
    ( Result0 = ok(Message),
        Result = ok(pb_embedded_message(Message))
    ; Result0 = error(Err),
        Result = error(Err)
    ; Result0 = eof,
        Result = eof
    ).

:- pred build_message(S::in, limit::in, M::di,
    stream.result(embedded_message(M), pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, sparse_bitset(field_id)::in,
    sparse_bitset(field_id)::out, IO::di, IO::uo)
    is det <= ( stream.reader(S, byte, IO, E), pb_message(M) ).

build_message(Stream, Limit, Message0, Result, !Pos, !FieldIds, !IO) :-
    ( Limit =< !.Pos ->
        Result = ok(embedded_message(more_bytes,
            reverse_message_lists(Message0)))
    ;
        read_key(Stream, Limit, KeyResult, !Pos, !IO),
        ( KeyResult = ok(key(FieldId, WireType)),
            sparse_bitset.insert(!.FieldIds, FieldId, !:FieldIds),
            ( field_info(Message0, FieldId, ArgNum, FieldType, Card) ->
                (
                    field_type_compatible_with_wire_type(FieldType, WireType)
                ->
                    read_field_value_and_continue(Stream, Limit,
                        ArgNum, FieldType, Card, Message0, Result, !Pos,
                            !FieldIds, !IO)
                ;
                    Result = error(incompatible_field_type(FieldType, WireType,
                        FieldId, !.Pos))
                )
            ;
                % The field is unknown, so ignore it.
                skip_field_and_continue(Stream, Limit, Message0, WireType,
                    Result, !Pos, !FieldIds, !IO)
            )
        ; KeyResult = error(Err),
            Result = error(Err)
        ; KeyResult = eof,
            Result = ok(embedded_message(no_more_bytes,
                reverse_message_lists(Message0)))
        )
    ).

:- pred read_field_value_and_continue(S::in, limit::in,
    arg_num::in, field_type::in, field_cardinality::in, M::di,
    stream.result(embedded_message(M), pb_read_error(E))::out,
    byte_pos::in, byte_pos::out,
    sparse_bitset(field_id)::in, sparse_bitset(field_id)::out, IO::di, IO::uo)
    is det
    <= ( stream.reader(S, byte, IO, E), pb_message(M) ).

read_field_value_and_continue(Stream, Limit, ArgNum, FieldType,
        Card, Message0, Result, !Pos, !FieldIds, !IO) :-
    ( FieldType = pb_double,
        read_pb_double(Stream, Limit, DblRes, !Pos, !IO),
        set_field_and_continue(Stream, Limit, Message0, DblRes,
            ArgNum, Card, Result, !Pos, !FieldIds, !IO)
    ; FieldType = pb_float,
        Result = error(unsupported_field_type(FieldType, !.Pos))
    ; FieldType = pb_int32,
        read_pb_int32(Stream, Limit, Int32Res, !Pos, !IO),
        set_field_and_continue(Stream, Limit, Message0, Int32Res,
            ArgNum, Card, Result, !Pos, !FieldIds, !IO)
    ; FieldType = pb_int64,
        Result = error(unsupported_field_type(FieldType, !.Pos))
    ; FieldType = pb_uint32,
        Result = error(unsupported_field_type(FieldType, !.Pos))
    ; FieldType = pb_uint64,
        Result = error(unsupported_field_type(FieldType, !.Pos))
    ; FieldType = pb_sint32,
        read_pb_sint32(Stream, Limit, SInt32Res, !Pos, !IO),
        set_field_and_continue(Stream, Limit, Message0, SInt32Res,
            ArgNum, Card, Result, !Pos, !FieldIds, !IO)
    ; FieldType = pb_sint64,
        Result = error(unsupported_field_type(FieldType, !.Pos))
    ; FieldType = pb_fixed32,
        Result = error(unsupported_field_type(FieldType, !.Pos))
    ; FieldType = pb_fixed64,
        Result = error(unsupported_field_type(FieldType, !.Pos))
    ; FieldType = pb_sfixed32,
        read_pb_sfixed32(Stream, Limit, SFixed32Res, !Pos, !IO),
        set_field_and_continue(Stream, Limit, Message0, SFixed32Res,
            ArgNum, Card, Result, !Pos, !FieldIds, !IO)
    ; FieldType = pb_sfixed64,
        Result = error(unsupported_field_type(FieldType, !.Pos))
    ; FieldType = pb_bool,
        read_pb_bool(Stream, Limit, BoolRes, !Pos, !IO),
        set_field_and_continue(Stream, Limit, Message0, BoolRes,
            ArgNum, Card, Result, !Pos, !FieldIds, !IO)
    ; FieldType = pb_string,
        read_pb_string(Stream, Limit, StrRes, !Pos, !IO),
        set_field_and_continue(Stream, Limit, Message0, StrRes,
            ArgNum, Card, Result, !Pos, !FieldIds, !IO)
    ; FieldType = pb_bytes,
        read_pb_bytes(Stream, Limit, BytesRes, !Pos, !IO),
        set_field_and_continue(Stream, Limit, Message0, BytesRes,
            ArgNum, Card, Result, !Pos, !FieldIds, !IO)
    ; FieldType = enumeration(Enum),
        read_enum(Stream, Limit, Enum, EnumRes, !Pos, !IO),
        set_field_and_continue(Stream, Limit, Message0, EnumRes,
            ArgNum, Card, Result, !Pos, !FieldIds, !IO)
    ; FieldType = embedded_message(EmbeddedMessage0),
        % We copy the value to make sure it is on the heap, since
        % we will be destructively updating it.
        copy(EmbeddedMessage0, EmbeddedMessage),
        read_embedded_message(Stream, Limit, EmbeddedMessage,
            EmbeddedMessageRes, !Pos, !IO),
        set_field_and_continue(Stream, Limit, Message0,
            EmbeddedMessageRes, ArgNum, Card, Result, !Pos, !FieldIds, !IO)
    ).

:- pred skip_field_and_continue(S::in, limit::in, M::di, wire_type::in,
    stream.result(embedded_message(M), pb_read_error(E))::out,
    byte_pos::in, byte_pos::out,
    sparse_bitset(field_id)::in, sparse_bitset(field_id)::out, IO::di, IO::uo)
    is det
    <= ( stream.reader(S, byte, IO, E), pb_message(M) ).

skip_field_and_continue(Stream, Limit, Message0, WireType, Result, !Pos,
        !FieldIds, !IO) :-
    ( Limit =< !.Pos ->
        Result = error(limit_exceeded)
    ;
        ( WireType = varint,
            get(Stream, ByteRes, !IO),
            !:Pos = !.Pos + 1,
            ( ByteRes = ok(Byte),
                ( Byte /\ 0b10000000 > 0 ->
                    skip_field_and_continue(Stream, Limit, Message0, WireType,
                        Result, !Pos, !FieldIds, !IO)
                ;
                    build_message(Stream, Limit, Message0, Result, !Pos,
                        !FieldIds, !IO)
                )
            ; ByteRes = error(Err),
                Result = error(stream_error(Err))
            ; ByteRes = eof,
                Result = error(premature_eof(!.Pos))
            )
        ; WireType = bit64,
            read_n_bytes(Stream, Limit, 8, BytesRes, !Pos, !IO),
            ( BytesRes = ok(_),
                build_message(Stream, Limit, Message0, Result, !Pos, !FieldIds,
                    !IO)
            ; BytesRes = error(Err),
                Result = error(Err)
            ; BytesRes = eof,
                Result = error(premature_eof(!.Pos))
            )
        ; WireType = length_delimited,
            read_uvarint(Stream, Limit, VarIntRes, !Pos, !IO),
            ( VarIntRes = ok(Length),
                read_n_bytes(Stream, Limit, Length, BytesRes, !Pos, !IO),
                ( BytesRes = ok(_),
                    build_message(Stream, Limit, Message0, Result, !Pos,
                        !FieldIds, !IO)
                ; BytesRes = error(Err),
                    Result = error(Err)
                ; BytesRes = eof,
                    Result = error(premature_eof(!.Pos))
                )
            ; VarIntRes = error(Err),
                Result = error(Err)
            ; VarIntRes = eof,
                Result = error(premature_eof(!.Pos))
            )
        ; WireType = bit32,
            read_n_bytes(Stream, Limit, 4, BytesRes, !Pos, !IO),
            ( BytesRes = ok(_),
                build_message(Stream, Limit, Message0, Result, !Pos,
                    !FieldIds, !IO)
            ; BytesRes = error(Err),
                Result = error(Err)
            ; BytesRes = eof,
                Result = error(premature_eof(!.Pos))
            )
        )
    ).

    % This returns the bytes in reverse order.
    %
:- pred read_n_bytes(S::in, limit::in, int::in,
    stream.result(list(byte), pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E) ).

read_n_bytes(Stream, Limit, N, Result, !Pos, !IO) :-
    ( N =< 0 ->
        Result = ok([])
    ;
        ( Limit =< !.Pos ->
            Result = error(limit_exceeded)
        ;
            get(Stream, ByteRes, !IO),
            !:Pos = !.Pos + 1,
            ( ByteRes = ok(Byte),
                read_n_bytes(Stream, Limit, N - 1, Result0, !Pos, !IO),
                ( Result0 = ok(Bytes0),
                    Result = ok([Byte | Bytes0])
                ; Result0 = error(Err),
                    Result = error(Err)
                ; Result0 = eof,
                    Result = error(premature_eof(!.Pos))
                )
            ; ByteRes = error(Err),
                Result = error(stream_error(Err))
            ; ByteRes = eof,
                Result = error(premature_eof(!.Pos))
            )
        )
    ).

:- pred set_field_and_continue(S::in, limit::in, M::di,
    stream.result(V, pb_read_error(E))::in, arg_num::in, field_cardinality::in,
    stream.result(embedded_message(M), pb_read_error(E))::out,
    byte_pos::in, byte_pos::out,
    sparse_bitset(field_id)::in, sparse_bitset(field_id)::out, IO::di, IO::uo)
    is det
    <= ( stream.reader(S, byte, IO, E), pb_message(M) ).

set_field_and_continue(Stream, Limit, Message0, ReadRes, ArgNum, Card,
        Result, !Pos, !FieldIds, !IO) :-
    ( ReadRes = ok(Value),
        set_message_field(ArgNum, Card, unsafe_promise_unique(Value):V,
            Message0, Message1),
        build_message(Stream, Limit, Message1, Result, !Pos, !FieldIds, !IO)
    ; ReadRes = error(Err),
        Result = error(Err)
    ; ReadRes = eof,
        Result = error(premature_eof(!.Pos))
    ).

:- pred read_key(S::in, limit::in, stream.result(key, pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E) ).

read_key(Stream, Limit, Result, !Pos, !IO) :-
    read_uvarint(Stream, Limit, VarIntRes, !Pos, !IO),
    ( VarIntRes = ok(VarInt),
        FieldId = VarInt `unsigned_right_shift` 3,
        WireTypeTag = VarInt /\ 0b111,
        ( tag_wire_type(WireTypeTag, WireType) ->
            Result = ok(key(FieldId, WireType))
        ;
            Result = error(invalid_wiretype_tag(WireTypeTag, !.Pos))
        )
    ; VarIntRes = error(Err),
        Result = error(Err)
    ; VarIntRes = eof,
        Result = eof
    ).

:- pred read_uvarint(S::in, limit::in,
    stream.result(int, pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E) ).

read_uvarint(Stream, Limit, Result, !Pos, !IO) :-
    read_uvarint_2(do_not_fail_on_eof, Stream, Limit, Result, !Pos, !IO).

    % If we encounter an eof with the first byte read then we return eof,
    % otherwise we return an error.
    %
:- type maybe_fail_on_eof
    --->    fail_on_eof
    ;       do_not_fail_on_eof.

:- pred read_uvarint_2(maybe_fail_on_eof::in, S::in, limit::in,
    stream.result(int, pb_read_error(E))::out, byte_pos::in, byte_pos::out,
    IO::di, IO::uo) is det <= ( stream.reader(S, byte, IO, E) ).

read_uvarint_2(MaybeFailOnEof, Stream, Limit, Result, !Pos, !IO) :-
    ( Limit =< !.Pos ->
        Result = error(limit_exceeded)
    ;
        stream.get(Stream, ByteResult, !IO),
        ( ByteResult = ok(Byte),
            !:Pos = !.Pos + 1,
            MoreFlag = Byte /\ 0b10000000,
            Val = Byte /\ 0b01111111,
            ( MoreFlag > 0 ->
                read_uvarint_2(fail_on_eof, Stream, Limit, HighResult, !Pos,
                    !IO),
                ( HighResult = ok(HighInt),
                    Result = ok(Val \/ (HighInt `unsigned_left_shift` 7))
                ; HighResult = error(Err),
                    Result = error(Err)
                ; HighResult = eof,
                    Result = eof
                )
            ;
                Result = ok(Val)
            )
        ; ByteResult = error(Err),
            Result = error(stream_error(Err))
        ; ByteResult = eof,
            ( MaybeFailOnEof = fail_on_eof,
                Result = error(premature_eof(!.Pos))
            ; MaybeFailOnEof = do_not_fail_on_eof,
                Result = eof
            )
        )
    ).

:- pred read_pb_int32(S::in, limit::in,
    stream.result(int, pb_read_error(E))::out, byte_pos::in, byte_pos::out,
    IO::di, IO::uo) is det <= ( stream.reader(S, byte, IO, E) ).

read_pb_int32(Stream, Limit, Result, !Pos, !IO) :-
    % Since negative ints are always stored in ten seven bit chunks, the
    % following should work for both 32bit and 64bit platforms.
    read_uvarint(Stream, Limit, Result, !Pos, !IO).

:- pred read_pb_sint32(S::in, limit::in,
    stream.result(int, pb_read_error(E))::out, byte_pos::in, byte_pos::out,
    IO::di, IO::uo) is det <= ( stream.reader(S, byte, IO, E) ).

read_pb_sint32(Stream, Limit, Result, !Pos, !IO) :-
    read_uvarint(Stream, Limit, VarIntRes, !Pos, !IO),
    ( VarIntRes = ok(UInt),
        ( UInt /\ 0b1 = 1 ->
            SInt = -(UInt `unsigned_right_shift` 1) - 1
        ;
            SInt = UInt `unsigned_right_shift` 1
        ),
        Result = ok(SInt)
    ; VarIntRes = error(Err),
        Result = error(Err)
    ; VarIntRes = eof,
        Result = eof
    ).

:- pred read_pb_sfixed32(S::in, limit::in,
    stream.result(int, pb_read_error(E))::out, byte_pos::in, byte_pos::out,
    IO::di, IO::uo) is det <= ( stream.reader(S, byte, IO, E) ).

read_pb_sfixed32(Stream, Limit, Result, !Pos, !IO) :-
    read_n_bytes(Stream, Limit, 4, BytesRes, !Pos, !IO),
    ( BytesRes = ok(Bytes),
        ( Bytes = [Byte0, Byte1, Byte2, Byte3] ->
            Int0 = Byte0 \/ (Byte1 `unchecked_left_shift` 8)
                \/ (Byte2 `unchecked_left_shift` 16)
                \/ (Byte3 `unchecked_left_shift` 24),
            % If the number is negative make sure we return a negative int
            % when the word size is > 32 bits.
            Int = sign_extend_32(Int0),
            Result = ok(Int)
        ;
            error("protobuf_runtime: internal error: " ++
                "read_pb_fixed32: read_n_bytes didn't return 4 bytes")
        )
    ; BytesRes = error(Err),
        Result = error(Err)
    ; BytesRes = eof,
        Result = error(premature_eof(!.Pos))
    ).

    % http://graphics.stanford.edu/~seander/bithacks.html#VariableSignExtend
:- func sign_extend_32(int) = int.

sign_extend_32(X) = R :-
    B = 32,
    M = (1 << (B - 1)),
    % X1 = X /\ ((1 << B) - 1), % not needed when higher bits are already clear
    R = (X `xor` M) - M.

:- pred read_enum(S::in, limit::in, En::in,
    stream.result(En, pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E), pb_enumeration(En) ).

read_enum(Stream, Limit, RefEnum, Result, !Pos, !IO) :-
    read_uvarint(Stream, Limit, VarIntRes, !Pos, !IO),
    ( VarIntRes = ok(Int),
        ( enum_int(Enum:En, Int) ->
            Result = ok(Enum)
        ;
            Result = error('new unknown_enum_value'(RefEnum, Int))
        )
    ; VarIntRes = error(Err),
        Result = error(Err)
    ; VarIntRes = eof,
        Result = error(premature_eof(!.Pos))
    ).

:- pred read_embedded_message(S::in, limit::in, M::di,
    stream.result(M, pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E), pb_message(M) ).

read_embedded_message(Stream, Limit, Message0, Result, !Pos, !IO) :-
    read_uvarint(Stream, Limit, VarIntRes, !Pos, !IO),
    ( VarIntRes = ok(Length),
        ( Length + !.Pos =< Limit ->
            StartPos = !.Pos,
            build_message(Stream, StartPos + Length, Message0, EmbeddedRes,
                !Pos, sparse_bitset.init, FoundFieldIds, !IO),
            RequiredFieldIds = required_fields(_:M),
            ( sparse_bitset.subset(RequiredFieldIds, FoundFieldIds) ->
                ( EmbeddedRes = ok(embedded_message(MoreBytes, Message)),
                    ( MoreBytes = more_bytes,
                        ( !.Pos = StartPos + Length ->
                            Result = ok(Message)
                        ; !.Pos < StartPos + Length ->
                            Result = error(premature_eof(!.Pos))
                        ;
                            Result = error(embedded_message_length_exceeded(
                                !.Pos))
                        )
                    ; MoreBytes = no_more_bytes,
                        % We hit eof while reading the embedded message.
                        Result = error(premature_eof(!.Pos))
                    )
                ; EmbeddedRes = error(Err),
                    ( Err = limit_exceeded ->
                        Result = error(embedded_message_length_exceeded(!.Pos))
                    ;
                        Result = error(Err)
                    )
                ; EmbeddedRes = eof,
                    Result = error(premature_eof(!.Pos))
                )
            ;
                Result = error('new missing_required_fields'(init_message:M,
                    sparse_bitset.difference(RequiredFieldIds, FoundFieldIds)))
            )
        ;
            Result = error(embedded_message_length_exceeded(!.Pos))
        )
    ; VarIntRes = error(Err),
        Result = error(Err)
    ; VarIntRes = eof,
        Result = eof
    ).

:- pred read_pb_string(S::in, limit::in,
    stream.result(string, pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E) ).

read_pb_string(Stream, Limit, Result, !Pos, !IO) :-
    read_uvarint(Stream, Limit, VarIntRes, !Pos, !IO),
    ( VarIntRes = ok(Length),
        read_n_bytes_into_string(Stream, Limit, Length, Result, !Pos, !IO)
    ; VarIntRes = error(Err),
        Result = error(Err)
    ; VarIntRes = eof,
        Result = error(premature_eof(!.Pos))
    ).

:- pred allocate_string(int::in, string::uo) is det.

:- pragma foreign_proc("C", allocate_string(Len::in, Str::uo),
    [will_not_call_mercury, promise_pure, thread_safe, terminates],
"
    MR_allocate_aligned_string_msg(Str, Len + 1,
        \"protobuf_runtime.allocate_string\");
    Str[Len] = '\\0';
").

:- pred set_char_in_string(int::in, int::in, string::di, string::uo) is det.

:- pragma foreign_proc("C",
    set_char_in_string(I::in, Chr::in, Str0::di, Str::uo),
    [will_not_call_mercury, promise_pure, thread_safe, terminates],
"
    Str0[I] = (char)Chr;
    Str = Str0;
").

:- pred read_n_bytes_into_string(S::in, limit::in, int::in,
    stream.result(string, pb_read_error(E))::out, byte_pos::in, byte_pos::out,
    IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E) ).

read_n_bytes_into_string(Stream, Limit, N, Result, !Pos, !IO) :-
    allocate_string(N, Str0),
    read_n_bytes_into_string_2(Stream, Limit, 0, N, Str0, Result, !Pos, !IO).
    
:- pred read_n_bytes_into_string_2(S::in, limit::in, int::in, int::in,
    string::di, stream.result(string, pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E) ).

read_n_bytes_into_string_2(Stream, Limit, I, N, Str0, Result, !Pos, !IO) :-
    ( I = N ->
        Result = ok(Str0)
    ;
        ( Limit =< !.Pos ->
            Result = error(limit_exceeded)
        ;
            get(Stream, ByteRes, !IO),
            !:Pos = !.Pos + 1,
            ( ByteRes = ok(Byte),
                set_char_in_string(I, Byte, Str0, Str),
                read_n_bytes_into_string_2(Stream, Limit, I + 1, N, Str, Result,
                    !Pos, !IO)
            ; ByteRes = error(Err),
                Result = error(stream_error(Err))
            ; ByteRes = eof,
                Result = error(premature_eof(!.Pos))
            )
        )
    ).

:- pred read_pb_bool(S::in, limit::in,
    stream.result(bool, pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E) ).

read_pb_bool(Stream, Limit, Result, !Pos, !IO) :-
    read_uvarint(Stream, Limit, VarIntRes, !Pos, !IO),
    ( VarIntRes = ok(Int),
        % http://code.google.com/apis/protocolbuffers/docs/encoding.html
        % doesn't actually say how bools are encoded.  This is just a guess.
        ( Int = 0 ->
            Bool = no
        ;
            Bool = yes
        ),
        Result = ok(Bool)
    ; VarIntRes = error(Err),
        Result = error(Err)
    ; VarIntRes = eof,
        Result = eof
    ).

:- pred read_pb_double(S::in, limit::in,
    stream.result(float, pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E) ).

read_pb_double(Stream, Limit, Result, !Pos, !IO) :-
    ( float_is_8_bytes ->
        ( platform_endianess_known ->
            read_n_bytes(Stream, Limit, 8, BytesRes, !Pos, !IO),
            ( BytesRes = ok(Bytes),
                ( Bytes = [Byte1, Byte2, Byte3, Byte4, Byte5, Byte6, Byte7, Byte8] ->
                    construct_float_from_bytes(Byte1, Byte2, Byte3, Byte4, Byte5,
                        Byte6, Byte7, Byte8, Float),
                    Result = ok(Float)
                ;
                    error("protobuf_runtime: internal error: " ++
                        "read_pb_double: read_n_bytes didn't return 8 bytes")
                )
            ; BytesRes = error(Err),
                Result = error(Err)
            ; BytesRes = eof,
                Result = error(premature_eof(!.Pos))
            )
        ;
            Result = error(unknown_endianess_on_this_platform)
        )
    ;
        Result = error(float_not_8_bytes_on_this_platform)
    ).

:- pred construct_float_from_bytes(byte::in, byte::in, byte::in, byte::in,
    byte::in, byte::in, byte::in, byte::in, float::out) is det.

:- pragma foreign_proc("C",
    construct_float_from_bytes(B1::in, B2::in, B3::in, B4::in, B5::in, B6::in,
        B7::in, B8::in, Flt::out),
    [promise_pure, will_not_call_mercury, thread_safe],
"
    char *buf;

    MR_offset_incr_hp_atomic_msg(Flt, 0, sizeof(MR_Float),
        \"protobuf_runtime.construct_float_from_bytes\", \"float\");

    buf = (char*)&Flt;

    /*
     * We expect Mercury floats to always be 8 bytes.
     * This is checked by float_is_8_bytes/0.
     * We also expect either MR_LITTLE_ENDIAN or MR_BIG_ENDIAN to be defined.
     * This is checked by platform_endianess_known/0.
     */
#ifdef MR_LITTLE_ENDIAN
    buf[0] = (char)B1;
    buf[1] = (char)B2;
    buf[2] = (char)B3;
    buf[3] = (char)B4;
    buf[4] = (char)B5;
    buf[5] = (char)B6;
    buf[6] = (char)B7;
    buf[7] = (char)B8;
#endif
#ifdef MR_BIG_ENDIAN
    buf[7] = (char)B1;
    buf[6] = (char)B2;
    buf[5] = (char)B3;
    buf[4] = (char)B4;
    buf[3] = (char)B5;
    buf[2] = (char)B6;
    buf[1] = (char)B7;
    buf[0] = (char)B8;
#endif

    Flt = *((MR_Float*)buf);
").

:- pred break_float_into_bytes(float::in, byte::out, byte::out, byte::out,
    byte::out, byte::out, byte::out, byte::out, byte::out) is det.

:- pragma foreign_proc("C",
    break_float_into_bytes(Flt::in, B1::out, B2::out, B3::out, B4::out,
        B5::out, B6::out, B7::out, B8::out),
    [promise_pure, will_not_call_mercury, thread_safe],
"
    /*
     * We expect Mercury floats to always be 8 bytes.
     * This is checked by float_is_8_bytes/0.
     */

    char *buf = (char*)&Flt;

    /*
     * We expect either MR_LITTLE_ENDIAN or MR_BIG_ENDIAN to be defined.
     * This is checked by platform_endianess_known/0.
     */
#ifdef MR_LITTLE_ENDIAN
    B1 = (MR_Integer)buf[0];
    B2 = (MR_Integer)buf[1];
    B3 = (MR_Integer)buf[2];
    B4 = (MR_Integer)buf[3];
    B5 = (MR_Integer)buf[4];
    B6 = (MR_Integer)buf[5];
    B7 = (MR_Integer)buf[6];
    B8 = (MR_Integer)buf[7];
#endif
#ifdef MR_BIG_ENDIAN
    B1 = (MR_Integer)buf[7];
    B2 = (MR_Integer)buf[6];
    B3 = (MR_Integer)buf[5];
    B4 = (MR_Integer)buf[4];
    B5 = (MR_Integer)buf[3];
    B6 = (MR_Integer)buf[2];
    B7 = (MR_Integer)buf[1];
    B8 = (MR_Integer)buf[0];
#endif
").

:- pred float_is_8_bytes is semidet.

:- pragma foreign_proc("C", float_is_8_bytes,
    [will_not_call_mercury, promise_pure, thread_safe],
"
    SUCCESS_INDICATOR = sizeof(MR_Float) == 8;
").

:- pred platform_endianess_known is semidet.

:- pragma foreign_proc("C", platform_endianess_known,
    [will_not_call_mercury, promise_pure, thread_safe],
"
#if defined(MR_LITTLE_ENDIAN) || defined(MR_BIG_ENDIAN)
    SUCCESS_INDICATOR = MR_TRUE;
#else
    SUCCESS_INDICATOR = MR_FALSE:
#endif
").

:- pred read_pb_bytes(S::in, limit::in,
    stream.result(bitmap.bitmap, pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E) ).

read_pb_bytes(Stream, Limit, Result, !Pos, !IO) :-
    read_uvarint(Stream, Limit, VarIntRes, !Pos, !IO),
    ( VarIntRes = ok(Length),
        read_n_bytes_into_bitmap(Stream, Limit, Length, Result, !Pos, !IO)
    ; VarIntRes = error(Err),
        Result = error(Err)
    ; VarIntRes = eof,
        Result = eof
    ).

:- pred read_n_bytes_into_bitmap(S::in, limit::in, int::in,
    stream.result(bitmap.bitmap, pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E) ).

read_n_bytes_into_bitmap(Stream, Limit, N, Result, !Pos, !IO) :-
    BM0 = bitmap.new(8 * N, no),
    read_n_bytes_into_bitmap_2(Stream, Limit, 0, N, BM0, Result, !Pos, !IO).
    
:- pred read_n_bytes_into_bitmap_2(S::in, limit::in, int::in, int::in,
    bitmap::bitmap_di, stream.result(bitmap, pb_read_error(E))::out,
    byte_pos::in, byte_pos::out, IO::di, IO::uo) is det
    <= ( stream.reader(S, byte, IO, E) ).

read_n_bytes_into_bitmap_2(Stream, Limit, I, N, BM0, Result, !Pos, !IO) :-
    ( I = N ->
        Result = ok(BM0)
    ;
        ( Limit =< !.Pos ->
            Result = error(limit_exceeded)
        ;
            get(Stream, ByteRes, !IO),
            !:Pos = !.Pos + 1,
            ( ByteRes = ok(Byte),
                BM = BM0 ^ unsafe_byte(I) := Byte,
                read_n_bytes_into_bitmap_2(Stream, Limit, I + 1, N, BM, Result,
                    !Pos, !IO)
            ; ByteRes = error(Err),
                Result = error(stream_error(Err))
            ; ByteRes = eof,
                Result = error(premature_eof(!.Pos))
            )
        )
    ).

%-----------------------------------------------------------------------------%

:- pred set_message_field(arg_num::in, field_cardinality::in, V::di,
    M::di, M::uo) is det.

set_message_field(ArgNum, Card, Value, !Message) :-
    ( Card = required,
        set_arg(ArgNum, Value, !Message)
    ; Card = optional,
        set_arg(ArgNum, yes(Value), !Message)
    ; Card = repeated,
        set_list_arg(ArgNum, Value, !Message)
    ).

:- pred set_arg(int::in, V::di, T::di, T::uo) is det.

set_arg(ArgNum, ArgVal, !Term) :-
    some [!Store] (
        store.new(!:Store),
        store.new_ref(!.Term, Ref, !Store),
        store.arg_ref(Ref, ArgNum, ArgRef, !Store),
        store.set_ref_value(ArgRef, ArgVal, !Store),
        store.extract_ref_value(!.Store, Ref, !:Term),
        unsafe_promise_unique(!Term)
    ).

:- pred set_list_arg(int::in, V::di, T::di, T::uo) is det.

set_list_arg(ArgNum, ArgVal, !Term) :-
    get_list_arg(ArgNum, !.Term, List0),
    unsafe_promise_unique(!Term),
    % The list will be in reverse order to the order the messages are
    % sent down the wire.  We reverse the list after the entire message
    % has been read.  See build_message.
    unsafe_promise_unique([ArgVal | List0], List),
    set_arg(ArgNum, List, !Term).

:- pred get_list_arg(int::in, T::in, list(V)::out) is det.

get_list_arg(ArgNum, Term, List) :-
    ( deconstruct.arg(Term, do_not_allow, ArgNum, Arg) ->
        det_dynamic_cast(Arg, List)
    ;
        error("protobuf_runtime: internal error: get_list_arg: " ++
            "arg has incorrect type")
    ).

    % Reverse all the list arguments in a message.  We need to do this
    % after building a message, because the list fields are built in reverse
    % order to the order the elements come down the wire.
    %
:- func reverse_message_lists(M::di) = (M::uo) <= pb_message(M).

reverse_message_lists(Message0) = Message :-
    reverse_message_lists_2(0, Message0, Message).

:- pred reverse_message_lists_2(arg_num::in, M::di, M::uo) is det
    <= pb_message(M).

reverse_message_lists_2(ArgNum, !M) :-
    ( field_info(!.M, _, ArgNum, _, Card) ->
        ( Card = repeated,
            (
                deconstruct.arg(!.M, do_not_allow, ArgNum, Arg0),
                [ArgTypeDesc] = type_args(type_of(Arg0)),
                (_ `with_type` ArgType) `has_type` ArgTypeDesc,
                dynamic_cast(Arg0, List0 `with_type` list(ArgType))
            ->
                list.reverse(List0, List),
                unsafe_promise_unique(!M),
                unsafe_promise_unique(List, Arg),
                set_arg(ArgNum, Arg, !M)
            ;
                error("protobuf_runtime: internal error: " ++
                    "reverse_message_lists_2: missing arg or wrong type")
            )
        ;
            ( Card = optional
            ; Card = required
            )
        ),
        reverse_message_lists_2(ArgNum + 1, !M)
    ;
        true
    ).

%-----------------------------------------------------------------------------%

:- instance stream.output(pb_writer(S), io) <= ( stream.output(S, io) ) 
    where
[
    ( flush(pb_writer(Stream), !IO) :-
        stream.flush(Stream, !IO)
    )
].

:- instance stream.writer(pb_writer(S), pb_message(M), io)
    <= ( stream.writer(S, byte, io), pb_message(M) ) where
[
    ( put(pb_writer(Stream), pb_message(Message), !IO) :-
        write_message(Stream, Message, !IO)
        %table_reset_for_message_size_1(!IO)
    )
].

:- instance stream.writer(pb_writer(S), pb_embedded_message(M), io)
    <= ( stream.writer(S, byte, io), pb_message(M) ) where
[
    ( put(pb_writer(Stream), pb_embedded_message(Message), !IO) :-
        write_embedded_message(Stream, Message, !IO)
        %table_reset_for_message_size_1(!IO)
    )
].

    % This stream is used to count the number of bytes in a message
    % which is then compared to the result of message_size when assertion
    % checking is enabled.
    %
:- type byte_counter
    --->    byte_counter(io_mutvar(int)).

:- instance stream.stream(byte_counter, io)
    where
[
    ( name(_, "byte_counter", !IO) )
].

:- instance stream.output(byte_counter, io)
    where
[
    ( flush(_, !IO) )
].

:- instance stream.writer(byte_counter, byte, io)
    where
[
    ( put(byte_counter(MutVar), _, !IO) :-
        store.get_mutvar(MutVar, N, !IO),
        store.set_mutvar(MutVar, N + 1, !IO)
    )
].

:- pred write_message(S::in, M::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO), pb_message(M) ).

write_message(Stream, Message, !IO) :-
    write_message_arg_and_continue(Stream, Message, 0, !IO).

:- pred write_message_arg_and_continue(S::in, M::in, arg_num::in,
    IO::di, IO::uo) is det <= ( stream.writer(S, byte, IO), pb_message(M) ).

write_message_arg_and_continue(Stream, Message, ArgNum, !IO) :-
    ( field_info(Message, FieldId, ArgNum, FieldType, Card) ->
        ( deconstruct.arg(Message, do_not_allow, ArgNum, Arg) ->
            field_type_compatible_with_wire_type(FieldType, WireType),
            write_field(Stream, key(FieldId, WireType), FieldType, Card, Arg,
                !IO),
            write_message_arg_and_continue(Stream, Message, ArgNum + 1, !IO)
        ;
            error("protobuf_runtime: internal error: " ++
                "write_message_arg_and_continue: missing arg")
        )
    ;
        % No more arguments to write.
        true
    ).

:- pred write_field(S::in, key::in, field_type::in, field_cardinality::in,
    T::in, IO::di, IO::uo) is det <= ( stream.writer(S, byte, IO) ).

write_field(Stream, Key, FieldType, Card, Arg, !IO) :-
    ( FieldType = pb_double,
        arg_to_value_list(Arg, Card, Values),
        list.foldl(write_pb_double(Stream, Key), Values, !IO)
    ; FieldType = pb_float,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_int32,
        arg_to_value_list(Arg, Card, Values),
        list.foldl(write_pb_int32(Stream, Key), Values, !IO)
    ; FieldType = pb_int64,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_uint32,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_uint64,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_sint32,
        arg_to_value_list(Arg, Card, Values),
        list.foldl(write_pb_sint32(Stream, Key), Values, !IO)
    ; FieldType = pb_sint64,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_fixed32,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_fixed64,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_sfixed32,
        arg_to_value_list(Arg, Card, Values),
        list.foldl(write_pb_sfixed32(Stream, Key), Values, !IO)
    ; FieldType = pb_sfixed64,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_bool,
        arg_to_value_list(Arg, Card, Values),
        list.foldl(write_pb_bool(Stream, Key), Values, !IO)
    ; FieldType = pb_string,
        arg_to_value_list(Arg, Card, Values),
        list.foldl(write_pb_string(Stream, Key), Values, !IO)
    ; FieldType = pb_bytes,
        arg_to_value_list(Arg, Card, Values),
        list.foldl(write_pb_bytes(Stream, Key), Values, !IO)
    ; FieldType = enumeration(_:En),
        arg_to_value_list(Arg, Card, Values),
        list.foldl(write_enum(Stream, Key), Values:list(En), !IO)
    ; FieldType = embedded_message(_:M),
        arg_to_value_list(Arg, Card, Values),
        list.foldl(write_embedded_message_and_key(Stream, Key),
            Values:list(M), !IO)
    ).

:- pred write_pb_string(S::in, key::in, string::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO) ).

write_pb_string(Stream, Key, String, !IO) :-
    write_key(Stream, Key, !IO),
    write_uvarint(Stream, string.length(String), !IO),
    string.foldl(
        ( pred(Char::in, IO0::di, IO1::uo) is det :-
            stream.put(Stream, char.to_int(Char), IO0, IO1)
        ), String, !IO).

:- pred write_pb_bool(S::in, key::in, bool::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO) ).

write_pb_bool(Stream, Key, Bool, !IO) :-
    write_key(Stream, Key, !IO),
    ( Bool = yes,
        write_uvarint(Stream, 1, !IO)
    ; Bool = no,
        write_uvarint(Stream, 0, !IO)
    ).

:- pred write_key(S::in, key::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO) ).

write_key(Stream, key(FieldId, WireType), !IO) :-
    tag_wire_type(Tag, WireType),
    write_uvarint(Stream, (FieldId << 3) \/ Tag, !IO).

    % This treats the int as unsigned.
:- pred write_uvarint(S::in, int::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO) ).

write_uvarint(Stream, N, !IO) :-
    ( N `unsigned_less_than` 0b10000000 ->
        put(Stream, N, !IO)
    ;
        put(Stream, (N /\ 0b01111111) \/ 0b10000000, !IO),
        write_uvarint(Stream, N `unsigned_right_shift` 7, !IO)
    ).

:- pred unsigned_less_than(int::in, int::in) is semidet.

:- pragma foreign_proc("C", unsigned_less_than(I1::in, I2::in),
    [will_not_call_mercury, promise_pure, thread_safe, terminates],
"
    SUCCESS_INDICATOR = (MR_Unsigned)I1 < (MR_Unsigned)I2;
").

:- func unsigned_right_shift(int, int) = int.

:- pragma foreign_proc("C", unsigned_right_shift(I0::in, N::in) = (I::out),
    [will_not_call_mercury, promise_pure, thread_safe, terminates],
"
    I = (MR_Integer)((MR_Unsigned)I0 >> N);
").

:- func unsigned_left_shift(int, int) = int.

:- pragma foreign_proc("C", unsigned_left_shift(I0::in, N::in) = (I::out),
    [will_not_call_mercury, promise_pure, thread_safe, terminates],
"
    I = (MR_Integer)((MR_Unsigned)I0 << N);
").

:- func unsigned_minus(int, int) = int.

:- pragma foreign_proc("C", unsigned_minus(X::in, Y::in) = (Z::out),
    [will_not_call_mercury, promise_pure, thread_safe, terminates],
"
    Z = (MR_Integer)((MR_Unsigned)X - (MR_Unsigned)Y);
").

:- pred write_pb_int32(S::in, key::in, int::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO) ).

write_pb_int32(Stream, Key, Int, !IO) :-
    write_key(Stream, Key, !IO),
    ( Int >= 0 ->
        write_uvarint(Stream, Int, !IO)
    ;
        write_neg_varint(Stream, Int, !IO)
    ).

:- pred write_neg_varint(S::in, int::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO) ).

write_neg_varint(Stream, N, !IO) :-
    write_neg_varint_2(Stream, 1, N, !IO).

:- pred write_neg_varint_2(S::in, int::in, int::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO) ).

write_neg_varint_2(Stream, Chunk, N, !IO) :-
    % http://code.google.com/apis/protocolbuffers/docs/encoding.html
    % says that negative int32 and int64 values are both always encoded
    % in exactly 10 bytes.
    ( Chunk < 10 ->
        put(Stream, (N /\ 0b01111111) \/ 0b10000000, !IO),
        write_neg_varint_2(Stream, Chunk + 1, N >> 7, !IO)
    ;
        put(Stream, N /\ 0b01111111, !IO)
    ).

:- pred write_pb_sint32(S::in, key::in, int::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO) ).

write_pb_sint32(Stream, Key, N, !IO) :-
    write_key(Stream, Key, !IO),
    ZigZagN = zigzag_encode(N),
    write_uvarint(Stream, ZigZagN, !IO).

:- func zigzag_encode(int) = int.

zigzag_encode(N) = ZigZagN :-
    ( N >= 0 ->
        ZigZagN = N `unsigned_left_shift` 1
    ;
        ZigZagN = (int.abs(N) `unsigned_left_shift` 1) `unsigned_minus` 1
    ).

:- pred write_pb_sfixed32(S::in, key::in, int::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO) ).

write_pb_sfixed32(Stream, Key, Int, !IO) :-
    write_key(Stream, Key, !IO),
    put(Stream, Int /\ 0xFF, !IO),
    put(Stream, (Int >> 8) /\ 0xFF, !IO),
    put(Stream, (Int >> 16) /\ 0xFF, !IO),
    put(Stream, (Int >> 24) /\ 0xFF, !IO).

:- pred write_enum(S::in, key::in, E::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO), pb_enumeration(E) ).

write_enum(Stream, Key, EnumVal, !IO) :-
    write_key(Stream, Key, !IO),
    enum_int(EnumVal, Int),
    write_uvarint(Stream, Int, !IO).

:- pred arg_to_value_list(T::in, field_cardinality::in, list(U)::out)
    is det.

arg_to_value_list(Arg, Card, Values) :-
    ( Card = required,
        det_dynamic_cast([Arg], Values)
    ; Card = optional,
        det_dynamic_cast(Arg, MaybeArg),
        ( MaybeArg = yes(Val),
            Values = [Val]
        ; MaybeArg = no,
            Values = []
        )
    ; Card = repeated,
        det_dynamic_cast(Arg, Values)
    ).

:- pred det_dynamic_cast(T::in, U::out) is det.

det_dynamic_cast(T, U) :-
    ( dynamic_cast(T, U0) ->
        U = U0
    ;
        error("protobuf_runtime: internal error: det_dynamic_cast: " ++
            "type mismatch")
    ).

:- pred write_embedded_message_and_key(S::in, key::in, M::in, IO::di, IO::uo)
    is det <= ( stream.writer(S, byte, IO), pb_message(M) ).

write_embedded_message_and_key(Stream, Key, Message, !IO) :-
    write_key(Stream, Key, !IO),
    write_embedded_message(Stream, Message, !IO).

:- pred write_embedded_message(S::in, M::in, IO::di, IO::uo)
    is det <= ( stream.writer(S, byte, IO), pb_message(M) ).

write_embedded_message(Stream, Message, !IO) :-
    Length = message_size(Message),
    trace [compile_time(flag("pb_assertions")), io(!TIO)] (
        store.new_mutvar(0, MutVar, !TIO),
        write_message(byte_counter(MutVar), Message, !TIO),
        store.get_mutvar(MutVar, RealLength, !TIO),
        ( RealLength \= Length ->
            error("write_embedded_message: assertion failure")
        ;
            true
        )
    ),
    write_uvarint(Stream, Length, !IO),
    write_message(Stream, Message, !IO).

:- pred write_pb_double(S::in, key::in, float::in, IO::di, IO::uo) is det
    <= ( stream.writer(S, byte, IO) ).

write_pb_double(Stream, Key, Flt, !IO) :-
    write_key(Stream, Key, !IO),
    ( float_is_8_bytes ->
        ( platform_endianess_known ->
            break_float_into_bytes(Flt, B1, B2, B3, B4, B5, B6, B7, B8),
            put(Stream, B1, !IO),
            put(Stream, B2, !IO),
            put(Stream, B3, !IO),
            put(Stream, B4, !IO),
            put(Stream, B5, !IO),
            put(Stream, B6, !IO),
            put(Stream, B7, !IO),
            put(Stream, B8, !IO)
        ;
            throw(unknown_endianess_on_this_platform:pb_write_error)
        )
    ;
        throw(float_not_8_bytes_on_this_platform:pb_write_error)
    ).

:- pred write_pb_bytes(S::in, key::in, bitmap.bitmap::in, IO::di, IO::uo)
    is det <= ( stream.writer(S, byte, IO) ).

write_pb_bytes(Stream, Key, BitMap, !IO) :-
    write_key(Stream, Key, !IO),
    ( NumBytes = bitmap.num_bytes(BitMap) ->
        write_uvarint(Stream, NumBytes, !IO),
        int.fold_up(
            ( pred(I::in, IO0::di, IO1::uo) is det :-
                put(Stream, BitMap ^ unsafe_byte(I), IO0, IO1)
            ), 0, NumBytes - 1, !IO)
    ;
        throw(number_of_bits_in_bitmap_not_divisible_by_8(BitMap))
    ).

%-----------------------------------------------------------------------------%

    % Get the number of bytes required to serialize a message.
    %
:- func message_size(M) = int <= pb_message(M).

% The pragma memo may help with performance where there is
% a lot of nested messages, but I haven't verified this with
% any benchmarking yet, so it's disabled for now.
%:- pragma memo(message_size/1, [fast_loose, allow_reset]).

message_size(Message) = Size :-
    add_arg_sizes(Message, 0, 0, Size).

:- pred add_arg_sizes(M::in, arg_num::in, int::in, int::out) is det
    <= pb_message(M).

add_arg_sizes(Message, ArgNum, !Size) :-
    ( field_info(Message, FieldId, ArgNum, FieldType, Card) ->
        ( deconstruct.arg(Message, do_not_allow, ArgNum, Arg) ->
            add_arg_size(FieldId, FieldType, Card, Arg, !Size),
            add_arg_sizes(Message, ArgNum + 1, !Size)
        ;
            error("protobuf_runtime: internal error: " ++
                "add_arg_sizes: missing arg")
        )
    ;
        % No more arguments.
        true
    ).

:- func key_size(field_id) = int.

key_size(FieldId) = Size :-
    add_uvarint_size(FieldId << 3, 0, Size).

:- pred add_arg_size(field_id::in, field_type::in, field_cardinality::in,
    T::in, int::in, int::out) is det.

add_arg_size(FieldId, FieldType, Card, Arg, !Size) :-
    ( FieldType = pb_double,
        arg_to_value_list(Arg, Card, Values:list(float)),
        NumVals = list.length(Values),
        !:Size = !.Size + (NumVals * 8)
    ; FieldType = pb_float,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_int32,
        arg_to_value_list(Arg, Card, Values),
        NumVals = list.length(Values),
        list.foldl(add_pb_int32_size, Values, !Size)
    ; FieldType = pb_int64,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_uint32,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_uint64,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_sint32,
        arg_to_value_list(Arg, Card, Values),
        NumVals = list.length(Values),
        list.foldl(add_pb_sint32_size, Values, !Size)
    ; FieldType = pb_sint64,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_fixed32,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_fixed64,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_sfixed32,
        arg_to_value_list(Arg, Card, Values:list(int)),
        NumVals = list.length(Values),
        !:Size = !.Size + (NumVals * 4)
    ; FieldType = pb_sfixed64,
        error("unsupported field type: " ++ string(FieldType))
    ; FieldType = pb_bool,
        arg_to_value_list(Arg, Card, Values:list(bool)),
        NumVals = list.length(Values),
        !:Size = !.Size + NumVals
    ; FieldType = pb_string,
        arg_to_value_list(Arg, Card, Values),
        NumVals = list.length(Values),
        list.foldl(add_pb_string_size, Values, !Size)
    ; FieldType = pb_bytes,
        arg_to_value_list(Arg, Card, Values),
        NumVals = list.length(Values),
        list.foldl(add_pb_bytes_size, Values, !Size)
    ; FieldType = enumeration(_:En),
        arg_to_value_list(Arg, Card, Values),
        NumVals = list.length(Values),
        list.foldl(add_pb_enum_size, Values:list(En), !Size)
    ; FieldType = embedded_message(_:M),
        arg_to_value_list(Arg, Card, Values),
        NumVals = list.length(Values),
        list.foldl(add_pb_embedded_message_size, Values:list(M), !Size)
    ),
    % Add the space required by the keys.
    !:Size = !.Size + (NumVals * key_size(FieldId)).

:- pred add_pb_int32_size(int::in, int::in, int::out) is det.

add_pb_int32_size(Int, !Size) :-
    ( Int < 0 ->
        % Negative int32s are always ten bytes long.
        !:Size = !.Size + 10
    ;
        add_uvarint_size(Int, !Size)
    ).

:- pred add_uvarint_size(int::in, int::in, int::out) is det.

add_uvarint_size(Int, !Size) :-
    !:Size = !.Size + 1,
    ( Int `unsigned_less_than` 0b10000000 ->
        true
    ;
        add_uvarint_size(Int `unsigned_right_shift` 7, !Size)
    ).

:- pred add_pb_sint32_size(int::in, int::in, int::out) is det.

add_pb_sint32_size(Int, !Size) :-
    ZigZagInt = zigzag_encode(Int),
    add_uvarint_size(ZigZagInt, !Size).

:- pred add_pb_string_size(string::in, int::in, int::out) is det.

add_pb_string_size(Str, !Size) :-
    Length = string.length(Str),
    add_uvarint_size(Length, !Size),
    !:Size = !.Size + Length.

:- pred add_pb_bytes_size(bitmap::in, int::in, int::out) is det.

add_pb_bytes_size(BitMap, !Size) :-
    Length = bitmap.det_num_bytes(BitMap),
    add_uvarint_size(Length, !Size),
    !:Size = !.Size + Length.

:- pred add_pb_enum_size(E::in, int::in, int::out) is det
    <= pb_enumeration(E).

add_pb_enum_size(EnumVal, !Size) :-
    enum_int(EnumVal, Int),
    add_uvarint_size(Int, !Size).

:- pred add_pb_embedded_message_size(M::in, int::in, int::out) is det
    <= pb_message(M).

add_pb_embedded_message_size(Message, !Size) :-
    Length = message_size(Message),
    add_uvarint_size(Length, !Size),
    !:Size = !.Size + Length.

%-----------------------------------------------------------------------------%

:- pred field_type_compatible_with_wire_type(field_type, wire_type).
:- mode field_type_compatible_with_wire_type(in, in) is semidet.
:- mode field_type_compatible_with_wire_type(in, out) is det.

field_type_compatible_with_wire_type(pb_double, bit64).
field_type_compatible_with_wire_type(pb_float, bit32).
field_type_compatible_with_wire_type(pb_int32, varint).
field_type_compatible_with_wire_type(pb_int64, varint).
field_type_compatible_with_wire_type(pb_uint32, varint).
field_type_compatible_with_wire_type(pb_uint64, varint).
field_type_compatible_with_wire_type(pb_sint32, varint).
field_type_compatible_with_wire_type(pb_sint64, varint).
field_type_compatible_with_wire_type(pb_fixed32, bit32).
field_type_compatible_with_wire_type(pb_fixed64, bit64).
field_type_compatible_with_wire_type(pb_sfixed32, bit32).
field_type_compatible_with_wire_type(pb_sfixed64, bit64).
field_type_compatible_with_wire_type(pb_bool, varint).
field_type_compatible_with_wire_type(pb_string, length_delimited).
field_type_compatible_with_wire_type(pb_bytes, length_delimited).
field_type_compatible_with_wire_type(enumeration(_), varint).
field_type_compatible_with_wire_type(embedded_message(_), length_delimited).

:- pred tag_wire_type(int, wire_type).
:- mode tag_wire_type(in, out) is semidet.
:- mode tag_wire_type(out, in) is det.

tag_wire_type(0, varint).
tag_wire_type(1, bit64).
tag_wire_type(2, length_delimited).
%tag_wire_type(3, start_group).
%tag_wire_type(4, end_group).
tag_wire_type(5, bit32).

%-----------------------------------------------------------------------------%

string_to_bitmap(Str) = BitMap :-
    BitMap0 = bitmap.new(string.length(Str) * 8),
    string.foldl2(set_byte_in_bitmap, Str, 0, _, BitMap0, BitMap1),
    unsafe_promise_unique(BitMap1, BitMap).

:- pred set_byte_in_bitmap(char::in, int::in, int::out,
    bitmap.bitmap::bitmap_di, bitmap.bitmap::bitmap_uo) is det.

set_byte_in_bitmap(Chr, !I, !BitMap) :-
    !BitMap ^ unsafe_byte(!.I) := char.to_int(Chr),
    !:I = !.I + 1.

%-----------------------------------------------------------------------------%

message_to_bitmap(Message) = Bitmap :-
    WriteBuffer0 = new_bitmap_builder(8),
    % We use a mutvar essentially to avoid problem with uniqueness,
    % otherwise we could thread the write_buffer through as the state.
    some [!Store] (
        !:Store = wb_store,
        store.new_mutvar(WriteBuffer0, Mutvar, !Store),
        write_message(write_buffer_mutvar(Mutvar), Message, !Store),
        store.get_mutvar(Mutvar, WriteBuffer, !.Store, _Store)
    ),
    Bitmap0 = finalize_to_bitmap(WriteBuffer),
    Bitmap = unsafe_promise_unique(Bitmap0).

:- type wb_store ---> wb_store.

:- instance store(wb_store) where [].

:- type write_buffer_mutvar
    --->    write_buffer_mutvar(generic_mutvar(write_buffer, wb_store)).

:- instance stream.stream(write_buffer_mutvar, wb_store) where [
    (name(_, "write_buffer_mutvar", !Store))
].

:- instance stream.output(write_buffer_mutvar, wb_store) where [
    (flush(write_buffer_mutvar(Mutvar), !Store) :-
        get_mutvar(Mutvar, WriteBuffer0, !Store),
        flush(WriteBuffer0, WriteBuffer),
        set_mutvar(Mutvar, WriteBuffer, !Store)
    )
].

:- instance stream.writer(write_buffer_mutvar, bitmap.byte, wb_store) where [
    (put(write_buffer_mutvar(Mutvar), Byte, !Store) :-
        get_mutvar(Mutvar, WriteBuffer0, !Store),
        put_byte(Byte, WriteBuffer0, WriteBuffer),
        set_mutvar(Mutvar, WriteBuffer, !Store)
    )
].

%-----------------------------------------------------------------------------%

bitmap_to_message(Bitmap, Result) :-
    pb_get(pb_reader(bitmap_stream(Bitmap), det_num_bytes(Bitmap) + 1),
        GetRes, 0, _Offset),
    (
        GetRes = ok(pb_message(M)),
        Result = ok(M)
    ;
        GetRes = eof,
        Result = error(make_io_error("unexpected eof"))
    ;
        GetRes = error(Error),
        Result = error(make_io_error(error_message(Error)))
    ).

:- type bitmap_stream
    --->    bitmap_stream(bitmap.bitmap).

:- instance stream.stream(bitmap_stream, int) where [
    (name(_, "bitmap_stream", !Offset))
].

:- instance stream.input(bitmap_stream, int) where [].

:- instance stream.reader(bitmap_stream, bitmap.byte, int, io.error) where [
    (get(bitmap_stream(Bitmap), Result, !Offset) :-
        ( !.Offset < num_bytes(Bitmap) ->
            Result = ok(Bitmap ^ unsafe_byte(!.Offset)),
            !:Offset = !.Offset + 1
        ;
            Result = eof
        )
    )
].

%-----------------------------------------------------------------------------%

% This doesn't work for arguments with mode 'unused'.
% :- pragma memo(required_fields/1).

    % Return all the required field ids for a message type.
    %
:- func required_fields(M::unused) = (sparse_bitset(field_id)::out) is det
    <= pb_message(M).

required_fields(Message) = FieldIds :-
    required_fields_2(Message, 0, sparse_bitset.init, FieldIds).

:- pred required_fields_2(M::unused, int::in,
    sparse_bitset(field_id)::in, sparse_bitset(field_id)::out) is det
    <= pb_message(M).

required_fields_2(Message, ArgNum, !FieldIds) :-
    ( field_info(Message, FieldId, ArgNum, _, Card) ->
        ( Card = required,
            sparse_bitset.insert(!.FieldIds, FieldId, !:FieldIds)
        ;
            ( Card = optional
            ; Card = repeated
            )
        ),
        required_fields_2(Message, ArgNum + 1, !FieldIds)
    ;
        true
    ).

%-----------------------------------------------------------------------------%
:- end_module protobuf_runtime.
%-----------------------------------------------------------------------------%
% vim: ft=mercury ts=4 sw=4 et encoding=utf8 fileencoding=utf8
% -*- coding:utf8; -*-
