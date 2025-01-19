# fpga_chacha20

> [!WARNING]
> This project is under development.

This project was not tested against other implementations. Currently, this simulation runs a `Hello, World!` test using a PRBS and the ChaCha20 cipher.



## Tools

- Verilator
- GtkWave
- Make

The tools can be installed using any package provider like `pacman` or `apt`

Arch:
```bash
sudo pacman -S verilator gtkwave
```
Debian/Ubuntu:
```bash
sudo apt install verilator gtkwave
```


## Makefile

1) Run Simulation

```bash
make sim
```
2) Display Waveform

```bash
make waves
```

3) delete simulation files

```bash
make clean
```

4) Help message

```bash
make help
```

## Notes


#### Block Function

<u>Keystream elements:</u>

- __Constants (128 bits)__: Fixed values to make the algorithm secure (often "expand 32-byte k" encoded as four 32-bit words).
- __Key (256 bits)__: The encryption key used to derive the keystream.
- __Nonce (96 bits)__: A unique number to ensure unique keystreams for different messages or sessions.
- ~~__Counter (32 bits)__: A counter that identifies the block number within the stream.~~


<u>State matrix:</u>

Each cell is 32-bit wide.

| 1         | 2        | 3        | 4        |
| :-------  | :------- | :--      | :--      |
| Constant  | Constant | Constant | Constant |
| Key       | Key      | Key      | Key      |
| Key       | Key      | Key      | Key      |
| Counter   | Nonce    | Nonce    | Nonce    |


#### Simulation

1) Use a Test vectors and different input combinations. (ref. [poly1305])

[poly1305]: https://datatracker.ietf.org/doc/html/draft-agl-tls-chacha20poly1305-04#section-7

2) Correlation analysis. Correlation between plaintext and cipher

3) Use tools like dieharder or testU01 to analyze randomness of the output

4) Avalanche Effect, single bit effect in key and plaintext. (ref. [Avalanche effect])

[Avalanche effect]: https://www.geeksforgeeks.org/avalanche-effect-in-cryptography/
