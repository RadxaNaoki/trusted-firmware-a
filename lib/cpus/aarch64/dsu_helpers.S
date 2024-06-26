/*
 * Copyright (c) 2019-2023, Arm Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <asm_macros.S>
#include <dsu_def.h>
#include <lib/cpus/errata.h>

	/* -----------------------------------------------------------------------
	 * DSU erratum 798953 check function
	 * Checks the DSU variant, revision and configuration to determine if
	 * the erratum applies. Erratum applies on all configurations of the
	 * DSU and if revision-variant is r0p0.
	 *
	 * The erratum was fixed in r0p1.
	 *
	 * This function is called from both assembly and C environment. So it
	 * follows AAPCS.
	 *
	 * Clobbers: x0-x3
	 * -----------------------------------------------------------------------
	 */
	.globl	check_errata_dsu_798953
	.globl	errata_dsu_798953_wa
	.globl	dsu_pwr_dwn

func check_errata_dsu_798953
	mov	x2, #ERRATA_APPLIES
	mov	x3, #ERRATA_NOT_APPLIES

	/* Check if DSU is equal to r0p0 */
	mrs	x1, CLUSTERIDR_EL1

	/* DSU variant and revision bitfields in CLUSTERIDR are adjacent */
	ubfx	x0, x1, #CLUSTERIDR_REV_SHIFT,\
			#(CLUSTERIDR_REV_BITS + CLUSTERIDR_VAR_BITS)
	mov	x1, #(0x0 << CLUSTERIDR_REV_SHIFT)
	cmp	x0, x1
	csel	x0, x2, x3, EQ
	ret
endfunc check_errata_dsu_798953

	/* --------------------------------------------------
	 * Errata Workaround for DSU erratum #798953.
	 *
	 * Can clobber only: x0-x8
	 * --------------------------------------------------
	 */
func errata_dsu_798953_wa
	mov	x8, x30
	bl	check_errata_dsu_798953
	cbz	x0, 1f

	/* If erratum applies, disable high-level clock gating */
	mrs	x0, CLUSTERACTLR_EL1
	orr	x0, x0, #CLUSTERACTLR_EL1_DISABLE_CLOCK_GATING
	msr	CLUSTERACTLR_EL1, x0
	isb
1:
	ret	x8
endfunc errata_dsu_798953_wa

	/* -----------------------------------------------------------------------
	 * DSU erratum 936184 check function
	 * Checks the DSU variant, revision and configuration to determine if
	 * the erratum applies. Erratum applies if ACP interface is present
	 * in the DSU and revision-variant < r2p0.
	 *
	 * The erratum was fixed in r2p0.
	 *
	 * This function is called from both assembly and C environment. So it
	 * follows AAPCS.
	 *
	 * Clobbers: x0-x4
	 * -----------------------------------------------------------------------
	 */
	.globl	check_errata_dsu_936184
	.globl	errata_dsu_936184_wa
	.weak	is_scu_present_in_dsu

	/* --------------------------------------------------------------------
	 * Default behaviour respresents SCU is always present with DSU.
	 * CPUs can override this definition if required.
	 *
	 * Can clobber only: x0-x3
	 * --------------------------------------------------------------------
	 */
func is_scu_present_in_dsu
	mov	x0, #1
	ret
endfunc is_scu_present_in_dsu

func check_errata_dsu_936184
	mov	x4, x30
	bl	is_scu_present_in_dsu
	cmp	x0, xzr
	/* Default error status */
	mov	x0, #ERRATA_NOT_APPLIES

	/* If SCU is not present, return without applying patch */
	b.eq	1f

	/* Erratum applies only if DSU has the ACP interface */
	mrs	x1, CLUSTERCFR_EL1
	ubfx	x1, x1, #CLUSTERCFR_ACP_SHIFT, #1
	cbz	x1, 1f

	/* If ACP is present, check if DSU is older than r2p0 */
	mrs	x1, CLUSTERIDR_EL1

	/* DSU variant and revision bitfields in CLUSTERIDR are adjacent */
	ubfx	x2, x1, #CLUSTERIDR_REV_SHIFT,\
			#(CLUSTERIDR_REV_BITS + CLUSTERIDR_VAR_BITS)
	cmp x2, #(0x2 << CLUSTERIDR_VAR_SHIFT)
	b.hs	1f
	mov	x0, #ERRATA_APPLIES
1:
	ret	x4
endfunc check_errata_dsu_936184

	/* --------------------------------------------------
	 * Errata Workaround for DSU erratum #936184.
	 *
	 * Can clobber only: x0-x8
	 * --------------------------------------------------
	 */
func errata_dsu_936184_wa
	mov	x8, x30
	bl	check_errata_dsu_936184
	cbz	x0, 1f

	/* If erratum applies, we set a mask to a DSU control register */
	mrs	x0, CLUSTERACTLR_EL1
	ldr	x1, =DSU_ERRATA_936184_MASK
	orr	x0, x0, x1
	msr	CLUSTERACTLR_EL1, x0
	isb
1:
	ret	x8
endfunc errata_dsu_936184_wa

	/* -----------------------------------------------------------------------
	 * DSU erratum 2313941 check function
	 * Checks the DSU variant, revision and configuration to determine if
	 * the erratum applies. Erratum applies on all configurations of the
	 * DSU and if revision-variant is r0p0, r1p0, r2p0, r2p1, r3p0, r3p1.
	 *
	 * The erratum is still open.
	 *
	 * This function is called from both assembly and C environment. So it
	 * follows AAPCS.
	 *
	 * Clobbers: x0-x4
	 * -----------------------------------------------------------------------
	 */
	.globl	check_errata_dsu_2313941
	.globl	errata_dsu_2313941_wa

func check_errata_dsu_2313941
	mov	x4, x30
	bl	is_scu_present_in_dsu
	cmp	x0, xzr
	/* Default error status */
	mov	x0, #ERRATA_NOT_APPLIES

	/* If SCU is not present, return without applying patch */
	b.eq	1f

	mov	x2, #ERRATA_APPLIES
	mov	x3, #ERRATA_NOT_APPLIES

	/* Check if DSU version is less than or equal to r3p1 */
	mrs	x1, CLUSTERIDR_EL1

	/* DSU variant and revision bitfields in CLUSTERIDR are adjacent */
	ubfx	x0, x1, #CLUSTERIDR_REV_SHIFT,\
			#(CLUSTERIDR_REV_BITS + CLUSTERIDR_VAR_BITS)
	mov	x1, #(0x31 << CLUSTERIDR_REV_SHIFT)
	cmp	x0, x1
	csel	x0, x2, x3, LS
1:
	ret	x4
endfunc check_errata_dsu_2313941

	/* --------------------------------------------------
	 * Errata Workaround for DSU erratum #2313941.
	 *
	 * Can clobber only: x0-x8
	 * --------------------------------------------------
	 */
func errata_dsu_2313941_wa
	mov	x8, x30
	bl	check_errata_dsu_2313941
	cbz	x0, 1f

	/* If erratum applies, disable high-level clock gating */
	mrs	x0, CLUSTERACTLR_EL1
	orr	x0, x0, #CLUSTERACTLR_EL1_DISABLE_SCLK_GATING
	msr	CLUSTERACTLR_EL1, x0
	isb
1:
	ret	x8
endfunc errata_dsu_2313941_wa

	/* ---------------------------------------------
	 * controls power features of the cluster
	 * 1. Cache portion power not request
	 * 2. Disable the retention circuit
	 * ---------------------------------------------
	 */
func dsu_pwr_dwn
	msr	CLUSTERPWRCTLR_EL1, xzr
	isb
	ret
endfunc dsu_pwr_dwn
