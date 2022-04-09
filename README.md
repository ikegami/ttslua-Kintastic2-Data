<a name="name-and-description"></a>
The Kintastic2 Lua Library for Tabletop Simulator
=================================================

Data Structure Classes
----------------------

Kinstastic2 is a collection of libraries designed for use with Tabletop Simulator (TTS).

ttslua-Kinstastic2-Data is a collection of data structure classes.
It contains no actual dependencies on TTS.


# TABLE OF CONTENTS

1. [NAME AND DESCRIPTION](#name-and-description)
2. [TABLE OF CONTENTS](#tableofcontents)
3. [DOCUMENTATION](#documentation)
4. [INSTALLATION](#installation)
    1. [Windows](#windows)
    2. ["Unix"](#unix)
    3. [Cygwin and MSYS](#cygwinandmsys)
5. [CONTRIBUTING](#contributing)
    1. [Testing](#testing)
        1. [Prerequisites](#prerequisites)
        2. [Instructions](#instructions)
    2. [Generating the Documentation](#generatingthedocumentation)
        1. [Prerequisites](#prerequisites)
        2. [Instructions](#instructions)


# DOCUMENTATION

* [Kintastic2.Data.Queue](doc/Kintastic2/Data/Queue.md#name-and-description) - Queue class
* [Kintastic2.Data.Set](doc/Kintastic2/Data/Set.md#name-and-description) - Set class


# INSTALLATION

To use this library in your TTS "mod", you will need
[luabundler](https://github.com/Benjamin-Dobell/luabundler#luabundler)
or similar.

This functionality is included
in the [Official TTS plugin](https://atom.io/packages/tabletopsimulator-lua)
for [Atom](https://atom.io/).

This functionality is included
in [rolandostar's TTS plugin](https://marketplace.visualstudio.com/items?itemName=rolandostar.tabletopsimulator-lua)
for [Visual Studio Code](https://code.visualstudio.com/).

## Windows

Say your TTS module's code is found in `lib`.

And say you placed this distribution in `ttslua-Kintastic2-Core`.

This will permit `luabundler` to correctly find this distribution:

```cmd
if not exist lib\Kintastic2 md lib\Kintastic2
mklink /j lib\Kintastic2\Core ttslua-Kintastic2-Core\lib\Kintastic2\Core
```

## "Unix"

Say your TTS module's code is found in `lib`.

And you placed this distribution in `ttslua-Kintastic2-Core`.

This will permit `luabundler` to correctly find this distribution:

```cmd
mkdir -p lib\Kintastic2
ln -s ttslua-Kintastic2-Core/lib/Kintastic2/Core lib/Kintastic2/Core
```

## Cygwin and MSYS

Following the instructions for Windows creates a directory structure
that works in both Windows and within the "unix" emulation.


# CONTRIBUTING

Details forthcoming.

## Testing

### Prerequisites

* Perl 5.14+
   * [AnyEvent](https://metacpan.org/dist/AnyEvent)
   * [Exporter](https://metacpan.org/dist/Exporter) (Part of Perl)
   * [Cpanel::JSON::XS](https://metacpan.org/dist/Cpanel-JSON-XS)
   * [File::Find::Rule](https://metacpan.org/dist/File-Find-Rule)
   * [Test::Deep](https://metacpan.org/dist/Test-Deep)
   * [Test::Harness](https://metacpan.org/dist/Test-Harness) (Part of Perl. Provides `prove`.)
   * [Test::More](https://metacpan.org/dist/Test-Simple) (Part of Perl)
* [`luabunder`](https://github.com/Benjamin-Dobell/luabundler)

### Instructions

The test suite can be run by following these instructions:

1. Launch TTS.
2. Create a game room in TTS.
    * It can be single-player.
    * You don't need to load any mods. In fact, it's best if you don't.
3. Run `prove` from the project's root directory.


## Generating the Documentation

The files in the `doc` directory are automatically generated.
And so are the DOCUMENTATION and TABLE OF CONTENTS sections
of this document.

It it planned to have the documentation generated automatically
on a pull request.

### Prerequisites

* Perl 5.14+
   * File::Basename (Part of Perl)
   * [File::Find::Rule](https://metacpan.org/dist/File-Find-Rule)
   * [File::Path](https://metacpan.org/dist/File-Path) (Part of Perl)
   * [FindBin](https://metacpan.org/dist/FindBin) (Part of Perl)

### Instructions

1. Run `perl gen_docs.pl`.
