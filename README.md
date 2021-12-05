# RISC-V CPU 2021

![arch](https://img.shields.io/badge/Arch-Homework-orange) ![testcase](https://img.shields.io/badge/testcase-passed-green)

Architecture Homework CPU project based on RISC-V  with Verilog implementation

Passed all testcases provided on FPGA with frequent of 100MHz.

Project Device: `xc7a35ticpg236-1L`

Utilization usage: 83% usage of LUT

Worst Negative Slack: -1.756ns

## Overview

* Tomasulo algorithm with $16$ entries of Reservation Station and Load Store Buffer, and $32$ entries of Re-Order Buffer
* support a instruction fetch queue of $32$ entries to cushion issue pressure.
* provide an I-Cache with $2$K entries and $4$ Bytes of an instruction each entry
* enable a primitive branch predictor
  * Branch History Table with $1$K entries and $2$ bit saturated counter each entry

## Details

* MemCtrl takes turns to grant IF, Load or Store requests
* Load for address 0x30000 and Store instructions wait to operate until commit

* IF or LS-Buffer keep trying to request for mem operation until granted by MemCtrl

## Notes

* decreasing the size of RS and LSB from 32 to 16 entries slowers performance a little but effectively reduces LUT utilization.
* writing sequential circuits into one `always block` in a module activated by `posedge clk`. 
* notice unnecessary latch.
* think carefully about what to do or not to do when handling a branch jump.

## Heart

![heart](https://s3.bmp.ovh/imgs/2021/12/c442a1b8ea17178d.png)
