/*
 * mp.d
 *
 * This module contains the abstraction for the Multiprocessor module
 *
 */

module architecture.multiprocessor;

import architecture.cpu;

import kernel.arch.x86_64.core.gdt;
import kernel.arch.x86_64.core.tss;
import kernel.arch.x86_64.core.idt;
import kernel.arch.x86_64.core.ioapic;
import kernel.arch.x86_64.core.lapic;

// MP Spec
import kernel.arch.x86_64.specs.mp;
import kernel.arch.x86_64.specs.acpi;

// Import helpful routines
import kernel.core.error;	// ErrorVal
import kernel.core.log;		// logging

struct Multiprocessor {
static:
public:

	// This module will conform to the interface
	ErrorVal initialize() {
		// 1. Look for the ACPI tables (preferred method)
		if(ACPI.Tables.findTable() == ErrorVal.Success) {
			// ACPI tables found
			return ACPI.Tables.readTable();
		}

		// 2. Fall back on looking for the MP tables

		// 2a. Locate the MP Tables
		if (MP.findTable() == ErrorVal.Fail) {
			// If the MP table is missing, fail.
			return ErrorVal.Fail;
		}

		// 2b. Read MP Table
		if (MP.readTable() != ErrorVal.Success) {
			return ErrorVal.Fail;
		}

		// 3a. Initialize Local APIC
		ErrorVal LAPICInitialized = printToLog("LocalAPIC: initialize()", LocalAPIC.initialize());
		if (LAPICInitialized != ErrorVal.Success) {
			return ErrorVal.Fail;
		}

		// 3b. Initialize IOAPIC
		ErrorVal IOAPICInitialized = printToLog("IOAPIC: initialize()", IOAPIC.initialize());
		if (IOAPICInitialized != ErrorVal.Success) {
			return ErrorVal.Fail;
		}

		// Enable Interrupts
		asm {
			sti;
		}
//		enableInterrupts();

		// If it got this far, it has succeeded
		return ErrorVal.Success;
	}

	ErrorVal installCore(uint codeID) {
		// Enable this core's Local APIC
		LocalAPIC.install();

		return ErrorVal.Success;
	}
private:
}
