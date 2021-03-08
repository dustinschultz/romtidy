# RomTidy
A simple Powershell Script that tidies up rom sets.

## Supported Features
* Remove \[BIOS\] files
* Remove roms of a certain type (e.g. Beta, Unl, Sample, etc)
* Prefer one region over another and remove similar roms that differ only by region (keeping the preferred) (e.g. `Foo (USA).zip` & `Foo (Japan).zip`)
* Unzip all roms and delete zip files
* Create top level \[0-9\] and \[A-Z\] directories
* Organize files into top level directories by first character
* Check and display any directories which contain > X number of files (default: 1024) as some carts have this limitation
* Removes any empty directories

## Defaults
By default, the following are removed. Modify the script to change.

### Types:
* BIOS
* Proto releases
* Beta releases
* Sample releases
* Demo releases
* Test releases
* Unl releases

### Similar Regions
Prefers Region1 to Region2 for (Region1)/(Region2)

* (USA)/(Japan) releases
* (USA)/(Europe) releases
* (USA)/(Germany) releases
* (USA)/(France) releases
* (USA)/(Italy) releases
* (USA)/(Australia) releases
* (USA)/(Sweden) releases
* (USA)/(Spain) releases
* (USA)/(Japan, Europe) releases
* (USA)/(Japan, Korea) releases
* (USA)/(Asia, Korea) releases
* (USA)/(Asia) (En) releases
* (USA)/(Europe, Korea) releases
* (USA)/(Japan) (En) releases
* (USA)/(Europe) (En,Fr,De) releases
* (USA)/(Europe) (En,Fr,De,Es,It) releases
* (USA)/(Korea) (En,Ko) releases
* (USA)/(Europe) (En,Fr,De,Es) releases
* (USA, Europe)/(Japan) releases
* (USA, Europe)/(Brazil) releases
* (USA, Europe)/(Europe) releases
* (USA, Europe)/(Japan, Korea) releases
* (USA, Europe) (En,Fr,De,Es)/(Korea) (En,Fr,De,Es) releases
* (USA, Europe) (En,Fr,De,Es)/(Japan) (En,Ja) releases
* (USA, Korea)/(Europe) releases
* (USA, Europe, Korea)/(Brazil) releases
* (Europe)/(Japan) releases
* (Europe)/(Germany) releases
* (Europe)/(Korea) releases
* (Europe)/(Spain) releases
* (Europe)/(Japan) (En) releases
* (Europe)/(Brazil) releases
* (Europe)/(France) releases
* (Europe)/(Australia) releases
* (Europe)/(Japan, Korea) releases
* (Europe) (En,Fr,De,Es,It)/(Brazil) releases

## Running / Using
```
C:\ .\rom_tidy.ps1

cmdlet main at command pipeline position 1
Supply values for the following parameters:
RomDir: <root_of_rom_dir>

...
...

<Done>
```

## Future Features
* More configurable
* "Fuzzier" matching (e.g. Roman <--> English numerals - `Foo 2 (USA).zip` & `Foo II (Japan).zip` would match assuming similar USA/Japan releases are removed (the default) )