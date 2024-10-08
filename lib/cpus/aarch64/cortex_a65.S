/*
 * Copyright (c) 2019-2024, Arm Limited. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */
#include <arch.h>

#include <asm_macros.S>
#include <common/bl_common.h>
#include <common/debug.h>
#include <cortex_a65.h>
#include <cpu_macros.S>
#include <plat_macros.S>

/* Hardware handled coherency */
#if !HW_ASSISTED_COHERENCY
#error "Cortex-A65 must be compiled with HW_ASSISTED_COHERENCY enabled"
#endif

/* 64-bit only core */
#if CTX_INCLUDE_AARCH32_REGS
#error "Cortex-A65 supports only AArch64. Compile with CTX_INCLUDE_AARCH32_REGS=0"
#endif

/* -------------------------------------------------
 * The CPU Ops reset function for Cortex-A65.
 * Shall clobber: x0-x19
 * -------------------------------------------------
 */
func cortex_a65_reset_func
	mov	x19, x30

#if ERRATA_DSU_936184
	bl	errata_dsu_936184_wa
#endif

	ret	x19
endfunc cortex_a65_reset_func

func cortex_a65_cpu_pwr_dwn
	mrs	x0, CORTEX_A65_CPUPWRCTLR_EL1
	orr	x0, x0, #CORTEX_A65_CPUPWRCTLR_EL1_CORE_PWRDN_BIT
	msr	CORTEX_A65_CPUPWRCTLR_EL1, x0
	isb
	ret
endfunc cortex_a65_cpu_pwr_dwn


.section .rodata.cortex_a65_regs, "aS"
cortex_a65_regs:  /* The ascii list of register names to be reported */
	.asciz	"cpuectlr_el1", ""

func cortex_a65_cpu_reg_dump
	adr	x6, cortex_a65_regs
	mrs	x8, CORTEX_A65_ECTLR_EL1
	ret
endfunc cortex_a65_cpu_reg_dump

declare_cpu_ops cortex_a65, CORTEX_A65_MIDR, \
	cortex_a65_reset_func, \
	cortex_a65_cpu_pwr_dwn
