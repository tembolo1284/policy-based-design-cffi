#!/usr/bin/env python3
"""
Example usage of the Policy-Based Design Calculator with CFFI bindings
"""

from calculator import (
    PresentValueCalculator,
    FutureValueCalculator,
    InterestRateCalculator,
)


def main():
    print("=" * 70)
    print("Policy-Based Design Calculator - CFFI Example")
    print("=" * 70)
    print()

    # =========================================================================
    # Present Value Calculator
    # =========================================================================
    print("1. Present Value Calculator")
    print("-" * 70)
    
    pv_calc = PresentValueCalculator()
    
    # Example 1: Simple cash flow stream
    discount_rate = 0.05  # 5%
    cash_flows = [100.0, 200.0, 300.0]
    pv = pv_calc.calculate(discount_rate, cash_flows)
    
    print(f"Cash flows: {cash_flows}")
    print(f"Discount rate: {discount_rate * 100:.1f}%")
    print(f"Present Value: ${pv:.2f}")
    print()
    
    # Example 2: Bond-like cash flows
    coupon_payments = [50.0] * 10 + [1050.0]  # 10 coupons + principal
    pv_bond = pv_calc.calculate(0.04, coupon_payments)
    print(f"Bond PV (4% discount, 10 periods): ${pv_bond:.2f}")
    print()

    # =========================================================================
    # Future Value Calculator
    # =========================================================================
    print("2. Future Value Calculator")
    print("-" * 70)
    
    fv_calc = FutureValueCalculator()
    
    # Example 1: Simple investment
    principal = 1000.0
    interest_rate = 0.05  # 5%
    periods = 10
    fv = fv_calc.calculate(principal, interest_rate, periods)
    
    print(f"Principal: ${principal:.2f}")
    print(f"Interest rate: {interest_rate * 100:.1f}%")
    print(f"Periods: {periods}")
    print(f"Future Value: ${fv:.2f}")
    print()
    
    # Example 2: Compare different scenarios
    scenarios = [
        (1000, 0.05, 10, "Conservative"),
        (1000, 0.08, 10, "Moderate"),
        (1000, 0.12, 10, "Aggressive"),
    ]
    
    print("Investment Scenarios (10 years, $1000 principal):")
    for p, r, n, label in scenarios:
        fv_scenario = fv_calc.calculate(p, r, n)
        print(f"  {label:12s} ({r*100:.0f}%): ${fv_scenario:,.2f}")
    print()

    # =========================================================================
    # Interest Rate Calculator
    # =========================================================================
    print("3. Interest Rate Conversion Calculator")
    print("-" * 70)
    
    ir_calc = InterestRateCalculator()
    
    # Example 1: Monthly compounding
    nominal_rate = 0.12  # 12% nominal
    periods_per_year = 12  # monthly
    ear = ir_calc.calculate(nominal_rate, periods_per_year)
    
    print(f"Nominal rate: {nominal_rate * 100:.1f}%")
    print(f"Compounding: {periods_per_year} times per year (monthly)")
    print(f"Effective Annual Rate (EAR): {ear * 100:.4f}%")
    print()
    
    # Example 2: Compare different compounding frequencies
    nominal = 0.06  # 6% nominal
    compounding_frequencies = [
        (1, "Annual"),
        (2, "Semi-annual"),
        (4, "Quarterly"),
        (12, "Monthly"),
        (365, "Daily"),
    ]
    
    print(f"Compounding Comparison (6% nominal rate):")
    for periods, label in compounding_frequencies:
        ear_result = ir_calc.calculate(nominal, periods)
        print(f"  {label:12s}: {ear_result * 100:.4f}%")
    print()

    # =========================================================================
    # Context Manager Example
    # =========================================================================
    print("4. Using Context Managers")
    print("-" * 70)
    
    with PresentValueCalculator() as calc:
        result = calc.calculate(0.10, [1000, 1000, 1000])
        print(f"PV with context manager: ${result:.2f}")
    
    print()
    print("=" * 70)
    print("All examples completed successfully!")
    print("=" * 70)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Error: {e}")
        import sys
        sys.exit(1)
