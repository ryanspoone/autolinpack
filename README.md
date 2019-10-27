# autolinpack

This harness performs LINPACK benchmarking using GCC or ICC.

## Contents

- [autolinpack](#autolinpack)
  - [Contents](#contents)
  - [Setup](#setup)
  - [Usage](#usage)

## Setup

Install git:

```bash
yum install git
# Or if you are using a Debian-based distribution:
apt-get install git
```

Clone this repository and setup:

```bash
git clone https://github.com/ryanspoone/autolinpack.git
cd autolinpack/
chmod +x autolinpack
```

## Usage

Change to directory where this automation is located are, then start benchmarking by issuing the following command:

```bash
./autolinpack
```
