# G2 BLE Protocol Notes

Reference for understanding SDK behavior and diagnosing hangs. Source material:
https://github.com/i-soxi/even-g2-protocol

## UUIDs

Base UUID: `00002760-08c2-11e1-9073-0e8ac72e{xxxx}`

| Suffix | Purpose |
|---|---|
| `0000` | Main service |
| `5401` | Write, phone to glasses |
| `5402` | Notify, glasses to phone |
| `6402` | Display rendering |

## Packet Shape

Packets use:

```text
[AA] [Type] [Seq] [Len] [PktTot] [PktSer] [SvcHi] [SvcLo] [Payload...] [CRC_Lo] [CRC_Hi]
```

- Type `0x21`: command from phone to glasses
- Type `0x12`: response from glasses to phone
- CRC: CRC-16/CCITT, init `0xFFFF`, poly `0x1021`, little-endian, calculated over payload
- MTU-sized messages are split with `PktTot` and `PktSer`

## Services

| Service | Purpose |
|---|---|
| `0x80-00` | Auth control and sync |
| `0x80-20` | Auth data |
| `0x04-20` | Display wake |
| `0x06-20` | Teleprompter text |
| `0x07-20` | Dashboard widgets |
| `0x09-00` | Device info |
| `0x0B-20` | Conversate audio transcript |
| `0x0C-20` | Tasks |
| `0x0D-00` | Device configuration |
| `0x0E-20` | Display configuration |
| `0x20-20` | Commit |

## Teleprompter Detail

The teleprompter service is `0x06-20`. Mid-stream marker messages use type
`255` and are required in long content streams. Payloads are protobuf encoded.
