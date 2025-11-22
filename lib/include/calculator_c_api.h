#ifndef CALCULATOR_C_API_H
#define CALCULATOR_C_API_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// ===========================================================================
// Opaque Handle Types
// ===========================================================================
// We use opaque pointers to hide the C++ implementation from C/Python
typedef struct PVCalculator_t* PVCalculatorHandle;
typedef struct FVCalculator_t* FVCalculatorHandle;
typedef struct IRCalculator_t* IRCalculatorHandle;

// ===========================================================================
// Present Value Calculator API
// ===========================================================================

/**
 * Create a new Present Value calculator
 * Returns: Handle to calculator, or NULL on failure
 */
PVCalculatorHandle pv_calculator_create(void);

/**
 * Calculate present value of future cash flows
 * 
 * Args:
 *   calc: Calculator handle
 *   discount_rate: Discount rate (e.g., 0.05 for 5%)
 *   cash_flows: Array of future cash flows
 *   n_cash_flows: Number of cash flows
 *   result: Output parameter for the calculated PV
 * 
 * Returns: 0 on success, -1 on error
 */
int pv_calculator_calculate(
    PVCalculatorHandle calc,
    double discount_rate,
    const double* cash_flows,
    size_t n_cash_flows,
    double* result
);

/**
 * Get last error message for PV calculator
 * Returns: Error string (valid until next call or destroy)
 */
const char* pv_calculator_get_error(PVCalculatorHandle calc);

/**
 * Destroy PV calculator and free resources
 */
void pv_calculator_destroy(PVCalculatorHandle calc);

// ===========================================================================
// Future Value Calculator API
// ===========================================================================

/**
 * Create a new Future Value calculator
 * Returns: Handle to calculator, or NULL on failure
 */
FVCalculatorHandle fv_calculator_create(void);

/**
 * Calculate future value of a principal amount
 * 
 * Args:
 *   calc: Calculator handle
 *   principal: Initial investment
 *   interest_rate: Interest rate per period (e.g., 0.05 for 5%)
 *   periods: Number of compounding periods
 *   result: Output parameter for the calculated FV
 * 
 * Returns: 0 on success, -1 on error
 */
int fv_calculator_calculate(
    FVCalculatorHandle calc,
    double principal,
    double interest_rate,
    int periods,
    double* result
);

/**
 * Get last error message for FV calculator
 * Returns: Error string (valid until next call or destroy)
 */
const char* fv_calculator_get_error(FVCalculatorHandle calc);

/**
 * Destroy FV calculator and free resources
 */
void fv_calculator_destroy(FVCalculatorHandle calc);

// ===========================================================================
// Interest Rate Calculator API
// ===========================================================================

/**
 * Create a new Interest Rate Conversion calculator
 * Returns: Handle to calculator, or NULL on failure
 */
IRCalculatorHandle ir_calculator_create(void);

/**
 * Convert nominal interest rate to effective annual rate
 * 
 * Args:
 *   calc: Calculator handle
 *   nominal_rate: Nominal annual interest rate (e.g., 0.12 for 12%)
 *   compounding_periods: Number of compounding periods per year
 *   result: Output parameter for the calculated EAR
 * 
 * Returns: 0 on success, -1 on error
 */
int ir_calculator_calculate(
    IRCalculatorHandle calc,
    double nominal_rate,
    int compounding_periods,
    double* result
);

/**
 * Get last error message for IR calculator
 * Returns: Error string (valid until next call or destroy)
 */
const char* ir_calculator_get_error(IRCalculatorHandle calc);

/**
 * Destroy IR calculator and free resources
 */
void ir_calculator_destroy(IRCalculatorHandle calc);

#ifdef __cplusplus
}
#endif

#endif // CALCULATOR_C_API_H
