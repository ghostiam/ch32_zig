# Size benchmark

This document contains the size in bytes of the firmware for each optimize mode.

## [examples/adc_polling](examples/adc_polling)

### adc_polling_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1506 | 208 | 0 | 4 | 1872 |
| ReleaseFast | 156 | 2086 | 204 | 0 | 4 | 2448 |
| ReleaseSafe | 156 | 6536 | 532 | 0 | 4 | 7224 |


## [examples/adc_scan_dma](examples/adc_scan_dma)

### adc_scan_dma_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1874 | 216 | 0 | 20 | 2248 |
| ReleaseFast | 156 | 2662 | 208 | 0 | 20 | 3028 |
| ReleaseSafe | 156 | 7124 | 536 | 0 | 20 | 7816 |


## [examples/blink_delay](examples/blink_delay)

### blink_delay_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 432 | 0 | 0 | 4 | 588 |
| ReleaseFast | 156 | 430 | 0 | 0 | 4 | 586 |
| ReleaseSafe | 156 | 730 | 0 | 0 | 4 | 886 |
| Debug | 156 | 3190 | 236 | 0 | 4 | 3588 |

### blink_delay_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 444 | 0 | 0 | 4 | 836 |
| ReleaseFast | 392 | 428 | 0 | 0 | 4 | 820 |
| ReleaseSafe | 392 | 472 | 0 | 0 | 4 | 864 |
| Debug | 392 | 3118 | 244 | 0 | 4 | 3756 |

### blink_delay_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 448 | 0 | 0 | 4 | 864 |
| ReleaseFast | 416 | 432 | 0 | 0 | 4 | 848 |
| ReleaseSafe | 416 | 480 | 0 | 0 | 4 | 896 |
| Debug | 416 | 3312 | 244 | 0 | 4 | 3972 |


## [examples/blink_minimal](examples/blink_minimal)

### blink_minimal_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 298 | 0 | 0 | 0 | 454 |
| ReleaseFast | 156 | 332 | 0 | 0 | 0 | 488 |
| ReleaseSafe | 156 | 334 | 0 | 0 | 0 | 490 |
| Debug | 156 | 2468 | 224 | 0 | 0 | 2848 |

### blink_minimal_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 336 | 0 | 0 | 0 | 728 |
| ReleaseFast | 392 | 372 | 0 | 0 | 0 | 764 |
| ReleaseSafe | 392 | 374 | 0 | 0 | 0 | 766 |
| Debug | 392 | 2706 | 224 | 0 | 0 | 3328 |

### blink_minimal_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 340 | 0 | 0 | 0 | 756 |
| ReleaseFast | 416 | 376 | 0 | 0 | 0 | 792 |
| ReleaseSafe | 416 | 378 | 0 | 0 | 0 | 794 |
| Debug | 416 | 2900 | 224 | 0 | 0 | 3544 |


## [examples/blink_systick_interrupt](examples/blink_systick_interrupt)

### blink_systick_interrupt_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 396 | 8 | 0 | 0 | 560 |
| ReleaseFast | 156 | 446 | 8 | 0 | 0 | 612 |
| ReleaseSafe | 156 | 448 | 8 | 0 | 0 | 612 |
| Debug | 156 | 2572 | 232 | 0 | 0 | 2960 |

### blink_systick_interrupt_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 408 | 8 | 0 | 0 | 808 |
| ReleaseFast | 392 | 458 | 8 | 0 | 0 | 860 |
| ReleaseSafe | 392 | 460 | 8 | 0 | 0 | 860 |
| Debug | 392 | 2830 | 232 | 0 | 0 | 3456 |

### blink_systick_interrupt_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 424 | 8 | 0 | 0 | 848 |
| ReleaseFast | 416 | 474 | 8 | 0 | 0 | 900 |
| ReleaseSafe | 416 | 476 | 8 | 0 | 0 | 900 |
| Debug | 416 | 3184 | 232 | 0 | 0 | 3832 |


## [examples/blink_time_deadline](examples/blink_time_deadline)

### blink_time_deadline_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 864 | 0 | 0 | 8 | 1020 |
| ReleaseFast | 156 | 894 | 0 | 0 | 8 | 1050 |
| ReleaseSafe | 156 | 924 | 0 | 0 | 8 | 1080 |
| Debug | 156 | 4162 | 264 | 0 | 8 | 4584 |

### blink_time_deadline_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 586 | 0 | 0 | 8 | 978 |
| ReleaseFast | 392 | 578 | 0 | 0 | 8 | 970 |
| ReleaseSafe | 392 | 620 | 0 | 0 | 8 | 1012 |
| Debug | 392 | 4050 | 272 | 0 | 8 | 4720 |

### blink_time_deadline_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 598 | 0 | 0 | 8 | 1014 |
| ReleaseFast | 416 | 590 | 0 | 0 | 8 | 1006 |
| ReleaseSafe | 416 | 632 | 0 | 0 | 8 | 1048 |
| Debug | 416 | 4244 | 272 | 0 | 8 | 4936 |


## [examples/blink_time_delay](examples/blink_time_delay)

### blink_time_delay_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 492 | 0 | 0 | 8 | 648 |
| ReleaseFast | 156 | 474 | 0 | 0 | 8 | 630 |
| ReleaseSafe | 156 | 494 | 0 | 0 | 8 | 650 |
| Debug | 156 | 3028 | 236 | 0 | 8 | 3420 |

### blink_time_delay_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 530 | 0 | 0 | 8 | 922 |
| ReleaseFast | 392 | 514 | 0 | 0 | 8 | 906 |
| ReleaseSafe | 392 | 534 | 0 | 0 | 8 | 926 |
| Debug | 392 | 3258 | 244 | 0 | 8 | 3900 |

### blink_time_delay_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 534 | 0 | 0 | 8 | 950 |
| ReleaseFast | 416 | 518 | 0 | 0 | 8 | 934 |
| ReleaseSafe | 416 | 546 | 0 | 0 | 8 | 962 |
| Debug | 416 | 3452 | 244 | 0 | 8 | 4116 |


## [examples/debug_sdi_print](examples/debug_sdi_print)

### debug_sdi_print_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1056 | 26 | 0 | 4 | 1238 |
| ReleaseFast | 156 | 1478 | 26 | 0 | 4 | 1660 |
| ReleaseSafe | 156 | 6504 | 354 | 0 | 4 | 7014 |

### debug_sdi_print_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 694 | 26 | 0 | 4 | 1112 |
| ReleaseFast | 392 | 1064 | 26 | 0 | 4 | 1482 |
| ReleaseSafe | 392 | 4970 | 354 | 0 | 4 | 5718 |
| Debug | 392 | 16804 | 736 | 0 | 4 | 17936 |

### debug_sdi_print_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 710 | 26 | 0 | 4 | 1152 |
| ReleaseFast | 416 | 1080 | 26 | 0 | 4 | 1522 |
| ReleaseSafe | 416 | 4986 | 354 | 0 | 4 | 5758 |
| Debug | 416 | 16998 | 736 | 0 | 4 | 18152 |


## [examples/debug_sdi_print_logger](examples/debug_sdi_print_logger)

### debug_sdi_print_logger_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 2520 | 240 | 16 | 8 | 2936 |
| ReleaseFast | 156 | 6162 | 492 | 16 | 8 | 6828 |
| ReleaseSafe | 156 | 11368 | 764 | 16 | 8 | 12308 |

### debug_sdi_print_logger_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 2096 | 240 | 16 | 8 | 2744 |
| ReleaseFast | 392 | 5292 | 492 | 16 | 8 | 6196 |
| ReleaseSafe | 392 | 8986 | 764 | 16 | 8 | 10164 |
| Debug | 392 | 25384 | 1096 | 16 | 8 | 26888 |

### debug_sdi_print_logger_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 2152 | 240 | 16 | 8 | 2824 |
| ReleaseFast | 416 | 5348 | 492 | 16 | 8 | 6276 |
| ReleaseSafe | 416 | 9042 | 764 | 16 | 8 | 10244 |
| Debug | 416 | 25578 | 1096 | 16 | 8 | 27112 |


## [examples/i2c_blocking](examples/i2c_blocking)

### i2c_blocking_ch32v003_master.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 3404 | 1048 | 16 | 8 | 4624 |
| ReleaseFast | 156 | 6684 | 1036 | 16 | 8 | 7892 |
| ReleaseSafe | 156 | 12134 | 1340 | 16 | 8 | 13648 |

### i2c_blocking_ch32v003_slave.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 3878 | 1204 | 16 | 8 | 5256 |
| ReleaseFast | 156 | 7574 | 1392 | 16 | 8 | 9140 |
| ReleaseSafe | 156 | 13310 | 1496 | 16 | 8 | 14980 |


## [examples/i2c_bmi160](examples/i2c_bmi160)

### i2c_bmi160_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 5770 | 1316 | 16 | 12 | 7260 |
| ReleaseFast | 156 | 12434 | 1572 | 16 | 12 | 14180 |


## [examples/mco](examples/mco)

### mco_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 436 | 2 | 0 | 0 | 594 |
| ReleaseFast | 156 | 484 | 2 | 0 | 0 | 642 |
| ReleaseSafe | 156 | 558 | 168 | 0 | 0 | 884 |
| Debug | 156 | 5788 | 416 | 0 | 0 | 6360 |

### mco_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 458 | 2 | 0 | 0 | 852 |
| ReleaseFast | 392 | 506 | 2 | 0 | 0 | 900 |
| ReleaseSafe | 392 | 772 | 300 | 0 | 0 | 1464 |
| Debug | 392 | 7716 | 614 | 0 | 0 | 8726 |

### mco_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 468 | 2 | 0 | 0 | 886 |
| ReleaseFast | 416 | 514 | 2 | 0 | 0 | 932 |
| ReleaseSafe | 416 | 780 | 300 | 0 | 0 | 1496 |
| Debug | 416 | 7894 | 614 | 0 | 0 | 8926 |


## [examples/spi](examples/spi)

### spi_ch32v003_master.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 2098 | 912 | 0 | 8 | 3168 |
| ReleaseFast | 156 | 2848 | 872 | 0 | 8 | 3880 |
| ReleaseSafe | 156 | 7134 | 592 | 0 | 8 | 7888 |

### spi_ch32v003_slave.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 2142 | 924 | 0 | 8 | 3224 |
| ReleaseFast | 156 | 2870 | 872 | 0 | 8 | 3904 |
| ReleaseSafe | 156 | 7284 | 592 | 0 | 8 | 8032 |

### spi_ch32v20x_master.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 2046 | 1068 | 0 | 8 | 3508 |
| ReleaseFast | 392 | 2736 | 1028 | 0 | 8 | 4156 |
| ReleaseSafe | 392 | 5850 | 756 | 0 | 8 | 7004 |

### spi_ch32v20x_slave.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 2078 | 1084 | 0 | 8 | 3556 |
| ReleaseFast | 392 | 2764 | 1028 | 0 | 8 | 4188 |
| ReleaseSafe | 392 | 6062 | 756 | 0 | 8 | 7212 |

### spi_ch32v30x_master.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 2054 | 1068 | 0 | 8 | 3540 |
| ReleaseFast | 416 | 2744 | 1028 | 0 | 8 | 4188 |
| ReleaseSafe | 416 | 5858 | 756 | 0 | 8 | 7036 |
| Debug | 416 | 33910 | 2164 | 0 | 8 | 36492 |

### spi_ch32v30x_slave.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 2066 | 1084 | 0 | 8 | 3568 |
| ReleaseFast | 416 | 2772 | 1028 | 0 | 8 | 4220 |
| ReleaseSafe | 416 | 6070 | 756 | 0 | 8 | 7244 |
| Debug | 416 | 33806 | 2140 | 0 | 8 | 36364 |


## [examples/uart](examples/uart)

### uart_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1988 | 856 | 0 | 8 | 3000 |
| ReleaseFast | 156 | 2492 | 816 | 0 | 8 | 3464 |
| ReleaseSafe | 156 | 3124 | 240 | 0 | 8 | 3520 |

### uart_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 1832 | 1036 | 0 | 8 | 3260 |
| ReleaseFast | 392 | 2212 | 996 | 0 | 8 | 3600 |
| ReleaseSafe | 392 | 2638 | 420 | 0 | 8 | 3452 |
| Debug | 392 | 27676 | 1896 | 0 | 8 | 29968 |

### uart_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 1840 | 1036 | 0 | 8 | 3292 |
| ReleaseFast | 416 | 2222 | 996 | 0 | 8 | 3636 |
| ReleaseSafe | 416 | 2652 | 420 | 0 | 8 | 3488 |
| Debug | 416 | 27854 | 1896 | 0 | 8 | 30168 |


## [examples/uart_dma_tx](examples/uart_dma_tx)

### uart_dma_tx_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1356 | 212 | 0 | 4 | 1724 |
| ReleaseFast | 156 | 2182 | 792 | 0 | 4 | 3132 |
| ReleaseSafe | 156 | 3196 | 228 | 0 | 4 | 3580 |

### uart_dma_tx_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 1214 | 392 | 0 | 4 | 2000 |
| ReleaseFast | 392 | 1930 | 972 | 0 | 4 | 3296 |
| ReleaseSafe | 392 | 2568 | 408 | 0 | 4 | 3368 |
| Debug | 392 | 27572 | 1848 | 0 | 4 | 29816 |

### uart_dma_tx_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 1222 | 392 | 0 | 4 | 2032 |
| ReleaseFast | 416 | 1940 | 972 | 0 | 4 | 3328 |
| ReleaseSafe | 416 | 2578 | 408 | 0 | 4 | 3404 |
| Debug | 416 | 27750 | 1848 | 0 | 4 | 30016 |


## [examples/uart_dma_tx_irq](examples/uart_dma_tx_irq)

### uart_dma_tx_irq_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1484 | 220 | 0 | 4 | 1860 |
| ReleaseFast | 156 | 2334 | 820 | 0 | 4 | 3312 |
| ReleaseSafe | 156 | 3344 | 236 | 0 | 4 | 3736 |

### uart_dma_tx_irq_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 1354 | 400 | 0 | 4 | 2148 |
| ReleaseFast | 392 | 2122 | 1000 | 0 | 4 | 3516 |
| ReleaseSafe | 392 | 2754 | 416 | 0 | 4 | 3564 |

### uart_dma_tx_irq_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 1342 | 400 | 0 | 4 | 2160 |
| ReleaseFast | 416 | 2130 | 1000 | 0 | 4 | 3548 |
| ReleaseSafe | 416 | 2764 | 416 | 0 | 4 | 3596 |
| Debug | 416 | 30862 | 1888 | 0 | 4 | 33168 |


## [examples/uart_echo](examples/uart_echo)

### uart_echo_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1816 | 896 | 0 | 8 | 2868 |
| ReleaseFast | 156 | 1734 | 888 | 0 | 8 | 2780 |
| ReleaseSafe | 156 | 1796 | 240 | 0 | 8 | 2192 |

### uart_echo_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 1714 | 1076 | 0 | 8 | 3184 |
| ReleaseFast | 392 | 1644 | 1068 | 0 | 8 | 3104 |
| ReleaseSafe | 392 | 1730 | 420 | 0 | 8 | 2544 |

### uart_echo_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 1722 | 1076 | 0 | 8 | 3216 |
| ReleaseFast | 416 | 1652 | 1068 | 0 | 8 | 3136 |
| ReleaseSafe | 416 | 1740 | 420 | 0 | 8 | 2576 |
| Debug | 416 | 31228 | 2064 | 0 | 8 | 33712 |


## [examples/uart_logger](examples/uart_logger)

### uart_logger_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 3262 | 464 | 0 | 12 | 3888 |
| ReleaseFast | 156 | 6928 | 716 | 0 | 12 | 7804 |
| ReleaseSafe | 156 | 12106 | 1008 | 0 | 12 | 13272 |

### uart_logger_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 3040 | 648 | 0 | 12 | 4080 |
| ReleaseFast | 392 | 6338 | 900 | 0 | 12 | 7636 |
| ReleaseSafe | 392 | 10006 | 1188 | 0 | 12 | 11588 |

### uart_logger_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 3088 | 648 | 0 | 12 | 4152 |
| ReleaseFast | 416 | 6388 | 900 | 0 | 12 | 7708 |
| ReleaseSafe | 416 | 10056 | 1188 | 0 | 12 | 11660 |
| Debug | 416 | 34382 | 1564 | 0 | 12 | 36364 |



This document was generated by `size-benchmark.sh` script.
