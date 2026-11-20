"""Removes the ModuleHashes attribute from a module-info.class: jlink cannot hash exploded modules
(see cut.sh)."""
import struct, sys

def strip(path):
    b = open(path, 'rb').read()
    pos = 8
    count = struct.unpack('>H', b[pos:pos+2])[0]; pos += 2
    names = {}
    i = 1
    while i < count:
        tag = b[pos]; pos += 1
        if tag == 1:
            n = struct.unpack('>H', b[pos:pos+2])[0]; names[i] = b[pos+2:pos+2+n].decode('utf-8', 'replace'); pos += 2 + n
        elif tag in (3, 4): pos += 4
        elif tag in (5, 6): pos += 8; i += 1
        elif tag in (7, 8, 16, 19, 20): pos += 2
        elif tag in (9, 10, 11, 12, 17, 18): pos += 4
        elif tag == 15: pos += 3
        else: raise SystemExit(f'unknown tag {tag}')
        i += 1
    pos += 6  # access, this, super
    for _ in range(3):  # interfaces, fields, methods (all empty in module-info)
        n = struct.unpack('>H', b[pos:pos+2])[0]; pos += 2
        if n: raise SystemExit('unexpected members')
    head = b[:pos]
    n = struct.unpack('>H', b[pos:pos+2])[0]; pos += 2
    kept = []
    for _ in range(n):
        name, length = struct.unpack('>HI', b[pos:pos+6])
        chunk = b[pos:pos+6+length]; pos += 6 + length
        if names.get(name) != 'ModuleHashes':
            kept.append(chunk)
    open(path, 'wb').write(head + struct.pack('>H', len(kept)) + b''.join(kept))
    print(path, n, '->', len(kept))

if __name__ == "__main__":
    for p in sys.argv[1:]:
        strip(p)
