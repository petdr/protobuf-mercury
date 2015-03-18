This is a Mercury backend for the Google protocol buffers compiler.

# What it does #

Protocol buffers allow you to define an extensible binary protocol format in a language-independent .proto file.  The protocol buffer compiler then compiles your .proto file into one of several target languages.  The generated API gives you a type-safe way to read or write messages in your protocol using your preferred language(s).

This extension generates a Mercury API for a protocol defined in a .proto file.

# Example #

Say you define the following protocol in person.proto:

```
enum Gender {
    MALE = 0;
    FEMALE = 1;
}

enum MaritalStatus {
    MARRIED = 0;
    SINGLE = 1;
}

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

Then you can generate the Mercury module person.m with the command:

```
mprotoc person.proto --out .
```

The generated module will contain the following types and functions:

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

:- func person_email_or_default(person) = string.

:- func person_marital_status_or_default(person) = marital_status.

:- type gender
    --->    gender_male
    ;       gender_female.

:- type marital_status
    --->    marital_status_married
    ;       marital_status_single.
```

You can write values of type person to binary streams.  For example:

```
    Person = person( 
        1, "Peter Pan", gender_male, 1.8, yes("pp@neverland.org"), no,
            [
                person(2, "Peter Pan Jnr.", gender_male, 0.5, no,
                    yes(marital_status_single), [])
            ]),
    stream.put(pb_writer(Stream), pb_message(Person), !IO),
```

You can also read values of type person from binary streams.  For example:

```
    stream.get(pb_reader(Stream, 10000), GetRes, !IO),
    ( GetRes = ok(pb_message(Person)),
        % Do something with Person...
```