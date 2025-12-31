# pa-simple-cpu

Made by Víctor Castilla and Alfonso Amorós.

## Notes on the design

The access type sent to memory is defined by 4 byte enable signals, defined in the `access_t` struct.

Memory will return a word from memory when reading. The arbitrer is in charge of ignoring useless data depending on the type of access.

### IMPORTANT NOTES:

* The default `PC_EXCEPTION_ADDR` is `0x8000`. However, to make it easy for verilator, our memory size is of just 1KB (which does not reach the address `0x8000`). So, if working with them, you should:
  * Set the `MEM_LEN` parameter inside the memory module to an appropiate size OR
  * Change the `PC_EXCEPTION_ADDR` so that it fits inside the memory.
Memory will return a word from memory when reading. The arbitrer is in charge of ignoring useless data depending on the
type of access.

## TODO Prioritario
- [x] Caches!!!
        - [x] Cambiar memoria para implementar interfaz de 128 bits
        - [x] Cambiar arbitrer para implementar interfaz de 128 bits
        - [x] MM stage tiene que enviar el tipo de acceso (WORD,BYTE,HALF,...) a la cache en sus peticiones
        - [x] Implementar MISS para la cache
- [ ] Multiciclo (historyfile) + excepciones
- [ ] True multiplicacion

## TODO No tan prioritario pero estaria bien
- [ ] Memoria virtual
