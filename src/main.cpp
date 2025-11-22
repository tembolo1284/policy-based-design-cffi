#include <iostream>
#include <vector>
#include <iomanip>

#include "Calculator.hpp"
#include "CalculationPolicies.hpp"

// ===========================================================================
// Helper Functions for Pretty Printing
// ===========================================================================

void print_header(const std::string& title) {
    std::cout << "\n" << std::string(70, '=') << "\n";
    std::cout << title << "\n";
    std::cout << std::string(70, '=') << "\n";
}

void print_section(const std::string& title) {
    std::cout << "\n" << std::string(70, '-') << "\n";
    std::cout << title << "\n";
    std::cout << std::string(70, '-') << "\n";
}

// ===========================================================================
// Main Function
// ===========================================================================

int main() {
    // Set output precision for floating point
    std::cout << std::fixed << std::setprecision(2);

    print_header("Policy-Based Design Calculator - C++ Example");

    // =======================================================================
    // 1. Present Value Calculator
    // =======================================================================
    print_section("1. Present Value Calculator");

    Calculator<PresentValuePolicy> pv_calc;

    // Example 1: Simple cash flow stream
    std::vector<double> cash_flows = {100.0, 200.0, 300.0};
    double discount_rate = 0.05;  // 5%

    try {
        double pv = pv_calc.calculate(discount_rate, cash_flows);
        
        std::cout << "Cash flows: [";
        for (size_t i = 0; i < cash_flows.size(); ++i) {
            std::cout << "$" << cash_flows[i];
            if (i < cash_flows.size() - 1) std::cout << ", ";
        }
        std::cout << "]\n";
        std::cout << "Discount rate: " << (discount_rate * 100) << "%\n";
        std::cout << "Present Value: $" << pv << "\n";
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }

    // Example 2: Bond-like cash flows
    std::vector<double> bond_cash_flows;
    for (int i = 0; i < 10; ++i) {
        bond_cash_flows.push_back(50.0);  // 10 coupon payments
    }
    bond_cash_flows.push_back(1050.0);  // Final payment with principal

    try {
        double pv_bond = pv_calc.calculate(0.04, bond_cash_flows);
        std::cout << "\nBond valuation (4% discount, 10 periods):\n";
        std::cout << "  Coupon payments: 10 × $50\n";
        std::cout << "  Final payment: $1050 (including principal)\n";
        std::cout << "  Present Value: $" << pv_bond << "\n";
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }

    // =======================================================================
    // 2. Future Value Calculator
    // =======================================================================
    print_section("2. Future Value Calculator");

    Calculator<FutureValuePolicy> fv_calc;

    // Example 1: Simple investment
    double principal = 1000.0;
    double interest_rate = 0.05;  // 5%
    int periods = 10;

    try {
        double fv = fv_calc.calculate(principal, interest_rate, periods);
        
        std::cout << "Principal: $" << principal << "\n";
        std::cout << "Interest rate: " << (interest_rate * 100) << "%\n";
        std::cout << "Periods: " << periods << "\n";
        std::cout << "Future Value: $" << fv << "\n";
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }

    // Example 2: Compare different investment scenarios
    std::cout << "\nInvestment Scenarios (10 years, $1000 principal):\n";
    
    struct Scenario {
        double rate;
        std::string label;
    };
    
    std::vector<Scenario> scenarios = {
        {0.05, "Conservative"},
        {0.08, "Moderate"},
        {0.12, "Aggressive"}
    };

    for (const auto& scenario : scenarios) {
        try {
            double fv_scenario = fv_calc.calculate(1000.0, scenario.rate, 10);
            std::cout << "  " << std::setw(12) << std::left << scenario.label 
                      << " (" << std::setw(2) << static_cast<int>(scenario.rate * 100) 
                      << "%): $" << fv_scenario << "\n";
        } catch (const std::exception& e) {
            std::cerr << "Error: " << e.what() << "\n";
            return 1;
        }
    }

    // =======================================================================
    // 3. Interest Rate Conversion Calculator
    // =======================================================================
    print_section("3. Interest Rate Conversion Calculator");

    Calculator<InterestRateConversionPolicy> ir_calc;

    // Example 1: Monthly compounding
    double nominal_rate = 0.12;  // 12% nominal
    int compounding_periods = 12;  // monthly

    try {
        double ear = ir_calc.calculate(nominal_rate, compounding_periods);
        
        std::cout << "Nominal rate: " << (nominal_rate * 100) << "%\n";
        std::cout << "Compounding: " << compounding_periods << " times per year (monthly)\n";
        std::cout << std::setprecision(4);
        std::cout << "Effective Annual Rate (EAR): " << (ear * 100) << "%\n";
        std::cout << std::setprecision(2);  // Reset precision
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }

    // Example 2: Compare different compounding frequencies
    std::cout << "\nCompounding Comparison (6% nominal rate):\n";
    
    struct CompoundingFreq {
        int periods;
        std::string label;
    };
    
    std::vector<CompoundingFreq> frequencies = {
        {1, "Annual"},
        {2, "Semi-annual"},
        {4, "Quarterly"},
        {12, "Monthly"},
        {365, "Daily"}
    };

    std::cout << std::setprecision(4);
    for (const auto& freq : frequencies) {
        try {
            double ear_result = ir_calc.calculate(0.06, freq.periods);
            std::cout << "  " << std::setw(12) << std::left << freq.label 
                      << ": " << (ear_result * 100) << "%\n";
        } catch (const std::exception& e) {
            std::cerr << "Error: " << e.what() << "\n";
            return 1;
        }
    }

    // =======================================================================
    // 4. Demonstrating Error Handling
    // =======================================================================
    print_section("4. Error Handling Demonstration");

    std::cout << "Testing invalid inputs to demonstrate error handling:\n\n";

    // Test 1: Empty cash flows
    std::cout << "Test 1: Empty cash flows for PV calculation\n";
    try {
        std::vector<double> empty_cf;
        pv_calc.calculate(0.05, empty_cf);
        std::cout << "  ERROR: Should have thrown exception!\n";
    } catch (const std::exception& e) {
        std::cout << "  ✓ Caught exception: " << e.what() << "\n";
    }

    // Test 2: Invalid discount rate
    std::cout << "\nTest 2: Invalid discount rate (≤ -1)\n";
    try {
        pv_calc.calculate(-1.5, {100.0});
        std::cout << "  ERROR: Should have thrown exception!\n";
    } catch (const std::exception& e) {
        std::cout << "  ✓ Caught exception: " << e.what() << "\n";
    }

    // Test 3: Negative principal
    std::cout << "\nTest 3: Negative principal for FV calculation\n";
    try {
        fv_calc.calculate(-1000.0, 0.05, 10);
        std::cout << "  ERROR: Should have thrown exception!\n";
    } catch (const std::exception& e) {
        std::cout << "  ✓ Caught exception: " << e.what() << "\n";
    }

    // Test 4: Invalid compounding periods
    std::cout << "\nTest 4: Invalid compounding periods (≤ 0)\n";
    try {
        ir_calc.calculate(0.12, 0);
        std::cout << "  ERROR: Should have thrown exception!\n";
    } catch (const std::exception& e) {
        std::cout << "  ✓ Caught exception: " << e.what() << "\n";
    }

    // =======================================================================
    // Summary
    // =======================================================================
    print_header("Example Complete");
    std::cout << "\nAll calculations completed successfully!\n";
    std::cout << "Policy-Based Design allows flexible, compile-time customization.\n\n";

    return 0;
}
