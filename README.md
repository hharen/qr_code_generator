# QR Code Generator

A simple Ruby command-line tool to generate QR codes with optional custom colors and logo overlay.

## Installation

Install the required gems:

```bash
bundle install
```

## Usage

```bash
ruby qr_code_generator.rb --url=URL [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--url=URL` | URL to encode (required) | - |
| `--size=SIZE` | Size in pixels | 1200 |
| `--color=COLOR` or `--colour=COLOR` | QR code color in hex format | 000000 |
| `--background=COLOR` | Background color in hex format | FFFFFF |
| `--logo=PATH` | Path to logo image to place in center | - |
| `--level=LEVEL` | Error correction level: L, M, Q, H. Lower levels produce fewer/larger modules (squares) | Q |
| `--filename=NAME` or `-o=NAME` | Output filename | qr_code_TIMESTAMP.png |

## Examples

### Basic usage

```bash
ruby qr_code_generator.rb --url="https://hharen.com"
```

### Custom size

```bash
ruby qr_code_generator.rb --url="https://hharen.com" --size=1200
```

### Custom color (red QR code)

```bash
ruby qr_code_generator.rb --url="https://hharen.com" --colour=FF0000
```

### Custom color with background

```bash
ruby qr_code_generator.rb --url="https://hharen.com" --color=FFFFFF --background=000000
```

### With a logo in the center

```bash
ruby qr_code_generator.rb --url="https://hharen.com" --logo=logo.png
```

### Fewer squares (lower error correction level)

```bash
ruby qr_code_generator.rb --url="https://hharen.com" --level=L
```

### All options combined

```bash
ruby qr_code_generator.rb --url="https://hharen.com" --size=800 --colour=1a73e8 --logo=logo.png
```

### Custom output filename

```bash
ruby qr_code_generator.rb --url="https://hharen.com" --filename=my_qr_code
```

## Output

The generated QR code is saved as a PNG file in the `generated/` folder. By default, the filename includes a timestamp (e.g., `qr_code_20260202_120000.png`). Use `--filename` to specify a custom name.

## Notes

- The QR code uses error correction level Q by default.
- Use `--level` to change the error correction level (L, M, Q, H). Lower levels reduce the number of modules (squares) for a given URL, making each square larger for a given size. Avoid combining a low level with `--logo`, as it reduces the redundancy needed to keep the code scannable.
- The logo is automatically scaled to 20% of the QR code size.
- Colors should be specified in 6-digit hex format (e.g., `FF0000` for red).
