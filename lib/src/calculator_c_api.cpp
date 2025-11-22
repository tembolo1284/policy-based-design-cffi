#include "calculator_c_api.h"
#include "Calculator.hpp"
#include "CalculationPolicies.hpp"
#include <string>
#include <cstring>

// ===========================================================================
// Internal Wrapper Structs (implementation of opaque handles)
// ===========================================================================

struct PVCalculator_t {
    Calculator<PresentValuePolicy> calc;
    std::string last_error;
};

struct FVCalculator_t {
    Calculator<FutureValuePolicy> calc;
    std::string last_error;
};

struct IRCalculator_t {
    Calculator<InterestRateConversionPolicy> calc;
    std::string last_error;
};

// ===========================================================================
// Present Value Calculator Implementation
// ===========================================================================

PVCalculatorHandle pv_calculator_create(void) {
    try {
        return new PVCalculator_t();
    } catch (...) {
        return nullptr;
    }
}

int pv_calculator_calculate(
    PVCalculatorHandle calc,
    double discount_rate,
    const double* cash_flows,
    size_t n_cash_flows,
    double* result
) {
    if (!calc || !cash_flows || !result || n_cash_flows == 0) {
        if (calc) {
            calc->last_error = "Invalid arguments: null pointer or empty cash flows";
        }
        return -1;
    }

    try {
        // Convert C array to std::vector
        std::vector<double> cf_vec(cash_flows, cash_flows + n_cash_flows);
        *result = calc->calc.calculate(discount_rate, cf_vec);
        calc->last_error.clear();
        return 0;
    } catch (const std::exception& e) {
        calc->last_error = e.what();
        return -1;
    } catch (...) {
        calc->last_error = "Unknown error occurred";
        return -1;
    }
}

const char* pv_calculator_get_error(PVCalculatorHandle calc) {
    if (!calc) {
        return "Invalid calculator handle";
    }
    return calc->last_error.c_str();
}

void pv_calculator_destroy(PVCalculatorHandle calc) {
    delete calc;
}

// ===========================================================================
// Future Value Calculator Implementation
// ===========================================================================

FVCalculatorHandle fv_calculator_create(void) {
    try {
        return new FVCalculator_t();
    } catch (...) {
        return nullptr;
    }
}

int fv_calculator_calculate(
    FVCalculatorHandle calc,
    double principal,
    double interest_rate,
    int periods,
    double* result
) {
    if (!calc || !result) {
        if (calc) {
            calc->last_error = "Invalid arguments: null pointer";
        }
        return -1;
    }

    try {
        *result = calc->calc.calculate(principal, interest_rate, periods);
        calc->last_error.clear();
        return 0;
    } catch (const std::exception& e) {
        calc->last_error = e.what();
        return -1;
    } catch (...) {
        calc->last_error = "Unknown error occurred";
        return -1;
    }
}

const char* fv_calculator_get_error(FVCalculatorHandle calc) {
    if (!calc) {
        return "Invalid calculator handle";
    }
    return calc->last_error.c_str();
}

void fv_calculator_destroy(FVCalculatorHandle calc) {
    delete calc;
}

// ===========================================================================
// Interest Rate Calculator Implementation
// ===========================================================================

IRCalculatorHandle ir_calculator_create(void) {
    try {
        return new IRCalculator_t();
    } catch (...) {
        return nullptr;
    }
}

int ir_calculator_calculate(
    IRCalculatorHandle calc,
    double nominal_rate,
    int compounding_periods,
    double* result
) {
    if (!calc || !result) {
        if (calc) {
            calc->last_error = "Invalid arguments: null pointer";
        }
        return -1;
    }

    try {
        *result = calc->calc.calculate(nominal_rate, compounding_periods);
        calc->last_error.clear();
        return 0;
    } catch (const std::exception& e) {
        calc->last_error = e.what();
        return -1;
    } catch (...) {
        calc->last_error = "Unknown error occurred";
        return -1;
    }
}

const char* ir_calculator_get_error(IRCalculatorHandle calc) {
    if (!calc) {
        return "Invalid calculator handle";
    }
    return calc->last_error.c_str();
}

void ir_calculator_destroy(IRCalculatorHandle calc) {
    delete calc;
}
