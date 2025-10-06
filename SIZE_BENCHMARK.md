# Size benchmark

This document contains the size in bytes of the firmware for each optimize mode.

## [examples/adc_polling](examples/adc_polling)

### adc_polling_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1502 | 208 | 0 | 4 | 1868 |
| ReleaseFast | 156 | 2082 | 204 | 0 | 4 | 2444 |
| ReleaseSafe | 156 | 6532 | 532 | 0 | 4 | 7220 |


## [examples/adc_scan_dma](examples/adc_scan_dma)

### adc_scan_dma_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1870 | 216 | 0 | 20 | 2244 |
| ReleaseFast | 156 | 2658 | 208 | 0 | 20 | 3024 |
| ReleaseSafe | 156 | 7120 | 536 | 0 | 20 | 7812 |


## [examples/blink_delay](examples/blink_delay)

### blink_delay_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 428 | 0 | 0 | 4 | 584 |
| ReleaseFast | 156 | 426 | 0 | 0 | 4 | 582 |
| ReleaseSafe | 156 | 726 | 0 | 0 | 4 | 882 |
| Debug | 156 | 3174 | 236 | 0 | 4 | 3572 |

### blink_delay_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 436 | 0 | 0 | 4 | 828 |
| ReleaseFast | 392 | 420 | 0 | 0 | 4 | 812 |
| ReleaseSafe | 392 | 464 | 0 | 0 | 4 | 856 |
| Debug | 392 | 3094 | 244 | 0 | 4 | 3732 |

### blink_delay_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 444 | 0 | 0 | 4 | 860 |
| ReleaseFast | 416 | 428 | 0 | 0 | 4 | 844 |
| ReleaseSafe | 416 | 476 | 0 | 0 | 4 | 892 |
| Debug | 416 | 3294 | 244 | 0 | 4 | 3956 |


## [examples/blink_minimal](examples/blink_minimal)

### blink_minimal_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 294 | 0 | 0 | 0 | 450 |
| ReleaseFast | 156 | 328 | 0 | 0 | 0 | 484 |
| ReleaseSafe | 156 | 330 | 0 | 0 | 0 | 486 |
| Debug | 156 | 2452 | 224 | 0 | 0 | 2832 |

### blink_minimal_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 328 | 0 | 0 | 0 | 720 |
| ReleaseFast | 392 | 364 | 0 | 0 | 0 | 756 |
| ReleaseSafe | 392 | 366 | 0 | 0 | 0 | 758 |
| Debug | 392 | 2682 | 224 | 0 | 0 | 3304 |

### blink_minimal_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 336 | 0 | 0 | 0 | 752 |
| ReleaseFast | 416 | 372 | 0 | 0 | 0 | 788 |
| ReleaseSafe | 416 | 374 | 0 | 0 | 0 | 790 |
| Debug | 416 | 2882 | 224 | 0 | 0 | 3528 |


## [examples/blink_systick_interrupt](examples/blink_systick_interrupt)

### blink_systick_interrupt_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 392 | 8 | 0 | 0 | 556 |
| ReleaseFast | 156 | 442 | 8 | 0 | 0 | 608 |
| ReleaseSafe | 156 | 444 | 8 | 0 | 0 | 608 |
| Debug | 156 | 2556 | 232 | 0 | 0 | 2944 |

### blink_systick_interrupt_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 400 | 8 | 0 | 0 | 800 |
| ReleaseFast | 392 | 450 | 8 | 0 | 0 | 852 |
| ReleaseSafe | 392 | 452 | 8 | 0 | 0 | 852 |
| Debug | 392 | 2806 | 232 | 0 | 0 | 3432 |

### blink_systick_interrupt_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 420 | 8 | 0 | 0 | 844 |
| ReleaseFast | 416 | 470 | 8 | 0 | 0 | 896 |
| ReleaseSafe | 416 | 472 | 8 | 0 | 0 | 896 |
| Debug | 416 | 3166 | 232 | 0 | 0 | 3816 |


## [examples/blink_time_deadline](examples/blink_time_deadline)

### blink_time_deadline_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 860 | 0 | 0 | 8 | 1016 |
| ReleaseFast | 156 | 890 | 0 | 0 | 8 | 1046 |
| ReleaseSafe | 156 | 920 | 0 | 0 | 8 | 1076 |
| Debug | 156 | 4146 | 264 | 0 | 8 | 4568 |

### blink_time_deadline_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 578 | 0 | 0 | 8 | 970 |
| ReleaseFast | 392 | 570 | 0 | 0 | 8 | 962 |
| ReleaseSafe | 392 | 612 | 0 | 0 | 8 | 1004 |
| Debug | 392 | 4026 | 272 | 0 | 8 | 4696 |

### blink_time_deadline_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 594 | 0 | 0 | 8 | 1010 |
| ReleaseFast | 416 | 586 | 0 | 0 | 8 | 1002 |
| ReleaseSafe | 416 | 628 | 0 | 0 | 8 | 1044 |
| Debug | 416 | 4226 | 272 | 0 | 8 | 4920 |


## [examples/blink_time_delay](examples/blink_time_delay)

### blink_time_delay_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 488 | 0 | 0 | 8 | 644 |
| ReleaseFast | 156 | 470 | 0 | 0 | 8 | 626 |
| ReleaseSafe | 156 | 490 | 0 | 0 | 8 | 646 |
| Debug | 156 | 3012 | 236 | 0 | 8 | 3404 |

### blink_time_delay_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 522 | 0 | 0 | 8 | 914 |
| ReleaseFast | 392 | 506 | 0 | 0 | 8 | 898 |
| ReleaseSafe | 392 | 526 | 0 | 0 | 8 | 918 |
| Debug | 392 | 3234 | 244 | 0 | 8 | 3876 |

### blink_time_delay_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 530 | 0 | 0 | 8 | 946 |
| ReleaseFast | 416 | 514 | 0 | 0 | 8 | 930 |
| ReleaseSafe | 416 | 542 | 0 | 0 | 8 | 958 |
| Debug | 416 | 3434 | 244 | 0 | 8 | 4100 |


## [examples/debug_sdi_print](examples/debug_sdi_print)

### debug_sdi_print_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1052 | 26 | 0 | 4 | 1234 |
| ReleaseFast | 156 | 1474 | 26 | 0 | 4 | 1656 |
| ReleaseSafe | 156 | 6500 | 354 | 0 | 4 | 7010 |

### debug_sdi_print_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 686 | 26 | 0 | 4 | 1104 |
| ReleaseFast | 392 | 1056 | 26 | 0 | 4 | 1474 |
| ReleaseSafe | 392 | 4962 | 354 | 0 | 4 | 5710 |
| Debug | 392 | 16780 | 736 | 0 | 4 | 17912 |

### debug_sdi_print_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 706 | 26 | 0 | 4 | 1148 |
| ReleaseFast | 416 | 1076 | 26 | 0 | 4 | 1518 |
| ReleaseSafe | 416 | 4982 | 354 | 0 | 4 | 5754 |
| Debug | 416 | 16980 | 736 | 0 | 4 | 18136 |


## [examples/debug_sdi_print_logger](examples/debug_sdi_print_logger)

### debug_sdi_print_logger_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 2496 | 240 | 16 | 8 | 2912 |
| ReleaseFast | 156 | 6158 | 492 | 16 | 8 | 6828 |
| ReleaseSafe | 156 | 11366 | 764 | 16 | 8 | 12308 |

### debug_sdi_print_logger_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 2070 | 240 | 16 | 8 | 2720 |
| ReleaseFast | 392 | 5284 | 492 | 16 | 8 | 6188 |
| ReleaseSafe | 392 | 8980 | 764 | 16 | 8 | 10156 |
| Debug | 392 | 25360 | 1096 | 16 | 8 | 26864 |

### debug_sdi_print_logger_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 2130 | 240 | 16 | 8 | 2808 |
| ReleaseFast | 416 | 5344 | 492 | 16 | 8 | 6268 |
| ReleaseSafe | 416 | 9040 | 764 | 16 | 8 | 10236 |
| Debug | 416 | 25560 | 1096 | 16 | 8 | 27088 |


## [examples/i2c_blocking](examples/i2c_blocking)

### i2c_blocking_ch32v003_master.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 3400 | 1028 | 16 | 8 | 4600 |
| ReleaseFast | 156 | 6680 | 1016 | 16 | 8 | 7868 |
| ReleaseSafe | 156 | 12130 | 1320 | 16 | 8 | 13624 |

### i2c_blocking_ch32v003_slave.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 3874 | 1184 | 16 | 8 | 5232 |
| ReleaseFast | 156 | 7570 | 1372 | 16 | 8 | 9116 |
| ReleaseSafe | 156 | 13306 | 1476 | 16 | 8 | 14956 |


## [examples/i2c_bmi160](examples/i2c_bmi160)

### i2c_bmi160_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 5744 | 1300 | 16 | 12 | 7220 |
| ReleaseFast | 156 | 12426 | 1556 | 16 | 12 | 14156 |


## [examples/mco](examples/mco)

### mco_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 432 | 2 | 0 | 0 | 590 |
| ReleaseFast | 156 | 480 | 2 | 0 | 0 | 638 |
| ReleaseSafe | 156 | 554 | 168 | 0 | 0 | 880 |
| Debug | 156 | 5772 | 416 | 0 | 0 | 6344 |

### mco_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 450 | 2 | 0 | 0 | 844 |
| ReleaseFast | 392 | 498 | 2 | 0 | 0 | 892 |
| ReleaseSafe | 392 | 764 | 300 | 0 | 0 | 1456 |
| Debug | 392 | 7692 | 614 | 0 | 0 | 8702 |

### mco_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 464 | 2 | 0 | 0 | 882 |
| ReleaseFast | 416 | 510 | 2 | 0 | 0 | 928 |
| ReleaseSafe | 416 | 776 | 300 | 0 | 0 | 1492 |
| Debug | 416 | 7876 | 614 | 0 | 0 | 8910 |


## [examples/spi](examples/spi)

### spi_ch32v003_master.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 2094 | 416 | 0 | 8 | 2672 |
| ReleaseFast | 156 | 2844 | 368 | 0 | 8 | 3368 |
| ReleaseSafe | 156 | 7130 | 592 | 0 | 8 | 7880 |

### spi_ch32v003_slave.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 2138 | 428 | 0 | 8 | 2724 |
| ReleaseFast | 156 | 2866 | 368 | 0 | 8 | 3392 |
| ReleaseSafe | 156 | 7280 | 592 | 0 | 8 | 8032 |

### spi_ch32v20x_master.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 2038 | 572 | 0 | 8 | 3004 |
| ReleaseFast | 392 | 2728 | 532 | 0 | 8 | 3652 |
| ReleaseSafe | 392 | 5842 | 756 | 0 | 8 | 6996 |

### spi_ch32v20x_slave.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 2070 | 588 | 0 | 8 | 3052 |
| ReleaseFast | 392 | 2756 | 532 | 0 | 8 | 3684 |
| ReleaseSafe | 392 | 6054 | 756 | 0 | 8 | 7204 |

### spi_ch32v30x_master.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 2050 | 572 | 0 | 8 | 3044 |
| ReleaseFast | 416 | 2740 | 532 | 0 | 8 | 3692 |
| ReleaseSafe | 416 | 5854 | 756 | 0 | 8 | 7028 |
| Debug | 416 | 33892 | 2148 | 0 | 8 | 36460 |

### spi_ch32v30x_slave.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 2062 | 588 | 0 | 8 | 3068 |
| ReleaseFast | 416 | 2768 | 532 | 0 | 8 | 3716 |
| ReleaseSafe | 416 | 6066 | 756 | 0 | 8 | 7244 |
| Debug | 416 | 33788 | 2124 | 0 | 8 | 36332 |


## [examples/uart](examples/uart)

### uart_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1984 | 360 | 0 | 8 | 2500 |
| ReleaseFast | 156 | 2488 | 316 | 0 | 8 | 2960 |
| ReleaseSafe | 156 | 3120 | 240 | 0 | 8 | 3516 |

### uart_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 1824 | 540 | 0 | 8 | 2756 |
| ReleaseFast | 392 | 2204 | 496 | 0 | 8 | 3092 |
| ReleaseSafe | 392 | 2630 | 420 | 0 | 8 | 3444 |
| Debug | 392 | 27652 | 1880 | 0 | 8 | 29928 |

### uart_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 1836 | 540 | 0 | 8 | 2792 |
| ReleaseFast | 416 | 2218 | 496 | 0 | 8 | 3132 |
| ReleaseSafe | 416 | 2648 | 420 | 0 | 8 | 3484 |
| Debug | 416 | 27836 | 1880 | 0 | 8 | 30136 |


## [examples/uart_dma_tx](examples/uart_dma_tx)

### uart_dma_tx_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1352 | 212 | 0 | 4 | 1720 |
| ReleaseFast | 156 | 2178 | 792 | 0 | 4 | 3128 |
| ReleaseSafe | 156 | 3192 | 228 | 0 | 4 | 3576 |

### uart_dma_tx_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 1206 | 392 | 0 | 4 | 1992 |
| ReleaseFast | 392 | 1922 | 972 | 0 | 4 | 3288 |
| ReleaseSafe | 392 | 2560 | 408 | 0 | 4 | 3360 |
| Debug | 392 | 27548 | 1848 | 0 | 4 | 29792 |

### uart_dma_tx_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 1218 | 392 | 0 | 4 | 2028 |
| ReleaseFast | 416 | 1936 | 972 | 0 | 4 | 3324 |
| ReleaseSafe | 416 | 2574 | 408 | 0 | 4 | 3400 |
| Debug | 416 | 27732 | 1848 | 0 | 4 | 30000 |


## [examples/uart_dma_tx_irq](examples/uart_dma_tx_irq)

### uart_dma_tx_irq_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1480 | 220 | 0 | 4 | 1856 |
| ReleaseFast | 156 | 2330 | 820 | 0 | 4 | 3308 |
| ReleaseSafe | 156 | 3340 | 236 | 0 | 4 | 3732 |

### uart_dma_tx_irq_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 1346 | 400 | 0 | 4 | 2140 |
| ReleaseFast | 392 | 2114 | 1000 | 0 | 4 | 3508 |
| ReleaseSafe | 392 | 2746 | 416 | 0 | 4 | 3556 |

### uart_dma_tx_irq_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 1338 | 400 | 0 | 4 | 2156 |
| ReleaseFast | 416 | 2126 | 1000 | 0 | 4 | 3544 |
| ReleaseSafe | 416 | 2760 | 416 | 0 | 4 | 3592 |
| Debug | 416 | 30844 | 1888 | 0 | 4 | 33152 |


## [examples/uart_echo](examples/uart_echo)

### uart_echo_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 1804 | 400 | 0 | 8 | 2360 |
| ReleaseFast | 156 | 1730 | 392 | 0 | 8 | 2280 |
| ReleaseSafe | 156 | 1792 | 240 | 0 | 8 | 2188 |

### uart_echo_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 1698 | 580 | 0 | 8 | 2672 |
| ReleaseFast | 392 | 1636 | 572 | 0 | 8 | 2600 |
| ReleaseSafe | 392 | 1722 | 420 | 0 | 8 | 2536 |

### uart_echo_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 1710 | 580 | 0 | 8 | 2708 |
| ReleaseFast | 416 | 1648 | 572 | 0 | 8 | 2636 |
| ReleaseSafe | 416 | 1736 | 420 | 0 | 8 | 2572 |
| Debug | 416 | 31208 | 2040 | 0 | 8 | 33664 |


## [examples/uart_logger](examples/uart_logger)

### uart_logger_ch32v003.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 156 | 3238 | 464 | 0 | 12 | 3864 |
| ReleaseFast | 156 | 6924 | 716 | 0 | 12 | 7796 |
| ReleaseSafe | 156 | 12102 | 1008 | 0 | 12 | 13272 |

### uart_logger_ch32v20x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 392 | 3014 | 648 | 0 | 12 | 4056 |
| ReleaseFast | 392 | 6330 | 900 | 0 | 12 | 7628 |
| ReleaseSafe | 392 | 9998 | 1188 | 0 | 12 | 11580 |

### uart_logger_ch32v30x.elf 

| Mode | .init | .text | .rodata | .data | .bss | Total |
|--------|--------|--------|--------|--------|--------|--------|
| ReleaseSmall | 416 | 3066 | 648 | 0 | 12 | 4136 |
| ReleaseFast | 416 | 6384 | 900 | 0 | 12 | 7700 |
| ReleaseSafe | 416 | 10052 | 1188 | 0 | 12 | 11660 |
| Debug | 416 | 34364 | 1564 | 0 | 12 | 36348 |



This document was generated by `size-benchmark.sh` script.
