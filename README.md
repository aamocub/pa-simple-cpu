# pa-simple-cpu

Made by Víctor Castilla and Alfonso Amorós.

## Notes on the design

The access type sent to memory is defined by 4 byte enable signals, defined in the `access_t` struct.

Memory will return a word from memory when reading. The arbitrer is in charge of ignoring useless data depending on the type of access.