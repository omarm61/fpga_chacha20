# fpga_chacha20

__NOTE__: This project is still in the works. (very early stage)

This is a derivative ChaCha20 algorithm implementation in RTL.



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
