#!/usr/bin/env python3
"""
Comprehensive tests for the CFFI-based Calculator bindings
"""

import unittest
import math
from calculator import (
    PresentValueCalculator,
    FutureValueCalculator,
    InterestRateCalculator,
)


class TestPresentValueCalculator(unittest.TestCase):
    """Tests for Present Value Calculator"""
    
    def setUp(self):
        """Create calculator instance before each test"""
        self.calc = PresentValueCalculator()
    
    def test_basic_calculation(self):
        """Test basic PV calculation"""
        # Single cash flow of $100 in 1 period at 5% discount
        result = self.calc.calculate(0.05, [100.0])
        expected = 100.0 / 1.05
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_multiple_cash_flows(self):
        """Test PV with multiple cash flows"""
        # Three cash flows
        cash_flows = [100.0, 200.0, 300.0]
        discount_rate = 0.05
        result = self.calc.calculate(discount_rate, cash_flows)
        
        # Manual calculation
        expected = (100.0 / 1.05 + 
                   200.0 / (1.05**2) + 
                   300.0 / (1.05**3))
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_zero_discount_rate(self):
        """Test PV with zero discount rate"""
        cash_flows = [100.0, 200.0, 300.0]
        result = self.calc.calculate(0.0, cash_flows)
        # With 0% discount, PV should equal sum of cash flows
        expected = sum(cash_flows)
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_high_discount_rate(self):
        """Test PV with high discount rate"""
        cash_flows = [1000.0]
        result = self.calc.calculate(0.50, cash_flows)
        expected = 1000.0 / 1.50
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_empty_cash_flows_error(self):
        """Test that empty cash flows raises ValueError"""
        with self.assertRaises(ValueError):
            self.calc.calculate(0.05, [])
    
    def test_invalid_discount_rate_error(self):
        """Test that discount_rate <= -1 raises ValueError"""
        with self.assertRaises(ValueError):
            self.calc.calculate(-1.0, [100.0])
        
        with self.assertRaises(ValueError):
            self.calc.calculate(-2.0, [100.0])
    
    def test_negative_cash_flows(self):
        """Test that negative cash flows are handled correctly"""
        # Mix of positive and negative cash flows (e.g., costs and revenues)
        cash_flows = [-100.0, 200.0, -50.0, 300.0]
        result = self.calc.calculate(0.10, cash_flows)
        
        expected = (-100.0 / 1.10 + 
                   200.0 / (1.10**2) + 
                   -50.0 / (1.10**3) +
                   300.0 / (1.10**4))
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_context_manager(self):
        """Test calculator works as context manager"""
        with PresentValueCalculator() as calc:
            result = calc.calculate(0.05, [100.0])
            self.assertAlmostEqual(result, 100.0 / 1.05, places=6)


class TestFutureValueCalculator(unittest.TestCase):
    """Tests for Future Value Calculator"""
    
    def setUp(self):
        """Create calculator instance before each test"""
        self.calc = FutureValueCalculator()
    
    def test_basic_calculation(self):
        """Test basic FV calculation"""
        result = self.calc.calculate(1000.0, 0.05, 10)
        expected = 1000.0 * (1.05 ** 10)
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_zero_interest_rate(self):
        """Test FV with zero interest rate"""
        result = self.calc.calculate(1000.0, 0.0, 10)
        # With 0% interest, FV should equal principal
        self.assertAlmostEqual(result, 1000.0, places=6)
    
    def test_zero_periods(self):
        """Test FV with zero periods"""
        result = self.calc.calculate(1000.0, 0.05, 0)
        # With 0 periods, FV should equal principal
        self.assertAlmostEqual(result, 1000.0, places=6)
    
    def test_high_interest_rate(self):
        """Test FV with high interest rate"""
        result = self.calc.calculate(100.0, 1.0, 5)  # 100% interest
        expected = 100.0 * (2.0 ** 5)  # Doubles each period
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_fractional_interest_rate(self):
        """Test FV with fractional interest rate"""
        result = self.calc.calculate(5000.0, 0.0325, 8)
        expected = 5000.0 * (1.0325 ** 8)
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_negative_principal_error(self):
        """Test that negative principal raises ValueError"""
        with self.assertRaises(ValueError):
            self.calc.calculate(-1000.0, 0.05, 10)
    
    def test_negative_periods_error(self):
        """Test that negative periods raises ValueError"""
        with self.assertRaises(ValueError):
            self.calc.calculate(1000.0, 0.05, -1)
    
    def test_invalid_interest_rate_error(self):
        """Test that interest_rate <= -1 raises ValueError"""
        with self.assertRaises(ValueError):
            self.calc.calculate(1000.0, -1.0, 10)
        
        with self.assertRaises(ValueError):
            self.calc.calculate(1000.0, -1.5, 10)
    
    def test_large_periods(self):
        """Test FV with large number of periods"""
        result = self.calc.calculate(1.0, 0.01, 100)
        expected = 1.0 * (1.01 ** 100)
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_context_manager(self):
        """Test calculator works as context manager"""
        with FutureValueCalculator() as calc:
            result = calc.calculate(1000.0, 0.05, 10)
            expected = 1000.0 * (1.05 ** 10)
            self.assertAlmostEqual(result, expected, places=6)


class TestInterestRateCalculator(unittest.TestCase):
    """Tests for Interest Rate Conversion Calculator"""
    
    def setUp(self):
        """Create calculator instance before each test"""
        self.calc = InterestRateCalculator()
    
    def test_annual_compounding(self):
        """Test with annual compounding (should return nominal rate)"""
        result = self.calc.calculate(0.05, 1)
        # With n=1, EAR should equal nominal rate
        self.assertAlmostEqual(result, 0.05, places=6)
    
    def test_monthly_compounding(self):
        """Test with monthly compounding"""
        result = self.calc.calculate(0.12, 12)
        expected = (1.0 + 0.12/12) ** 12 - 1.0
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_quarterly_compounding(self):
        """Test with quarterly compounding"""
        result = self.calc.calculate(0.08, 4)
        expected = (1.0 + 0.08/4) ** 4 - 1.0
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_daily_compounding(self):
        """Test with daily compounding"""
        result = self.calc.calculate(0.06, 365)
        expected = (1.0 + 0.06/365) ** 365 - 1.0
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_continuous_compounding_approximation(self):
        """Test that high frequency approaches e^r - 1"""
        result = self.calc.calculate(0.05, 10000)
        # For very high n, should approach e^r - 1
        continuous = math.exp(0.05) - 1.0
        self.assertAlmostEqual(result, continuous, places=3)
    
    def test_zero_nominal_rate(self):
        """Test with zero nominal rate"""
        result = self.calc.calculate(0.0, 12)
        # 0% nominal should give 0% effective
        self.assertAlmostEqual(result, 0.0, places=6)
    
    def test_invalid_compounding_periods_error(self):
        """Test that compounding_periods <= 0 raises ValueError"""
        with self.assertRaises(ValueError):
            self.calc.calculate(0.05, 0)
        
        with self.assertRaises(ValueError):
            self.calc.calculate(0.05, -1)
    
    def test_invalid_nominal_rate_error(self):
        """Test that nominal_rate <= -1 raises ValueError"""
        with self.assertRaises(ValueError):
            self.calc.calculate(-1.0, 12)
        
        with self.assertRaises(ValueError):
            self.calc.calculate(-2.0, 12)
    
    def test_semi_annual_compounding(self):
        """Test with semi-annual compounding"""
        result = self.calc.calculate(0.10, 2)
        expected = (1.0 + 0.10/2) ** 2 - 1.0
        self.assertAlmostEqual(result, expected, places=6)
    
    def test_context_manager(self):
        """Test calculator works as context manager"""
        with InterestRateCalculator() as calc:
            result = calc.calculate(0.12, 12)
            expected = (1.0 + 0.12/12) ** 12 - 1.0
            self.assertAlmostEqual(result, expected, places=6)


class TestCalculatorIntegration(unittest.TestCase):
    """Integration tests combining multiple calculators"""
    
    def test_pv_fv_round_trip(self):
        """Test that FV -> PV returns to original principal"""
        fv_calc = FutureValueCalculator()
        pv_calc = PresentValueCalculator()
        
        principal = 1000.0
        rate = 0.05
        periods = 10
        
        # Calculate future value
        fv = fv_calc.calculate(principal, rate, periods)
        
        # Calculate present value of that future amount
        pv = pv_calc.calculate(rate, [0.0] * (periods - 1) + [fv])
        
        # Should get back to original principal
        self.assertAlmostEqual(pv, principal, places=6)
    
    def test_interest_rate_impact(self):
        """Test how different compounding affects returns"""
        ir_calc = InterestRateCalculator()
        fv_calc = FutureValueCalculator()
        
        nominal = 0.12
        principal = 1000.0
        periods = 1
        
        # Annual compounding
        ear_annual = ir_calc.calculate(nominal, 1)
        fv_annual = fv_calc.calculate(principal, ear_annual, periods)
        
        # Monthly compounding
        ear_monthly = ir_calc.calculate(nominal, 12)
        fv_monthly = fv_calc.calculate(principal, ear_monthly, periods)
        
        # Monthly compounding should yield higher return
        self.assertGreater(fv_monthly, fv_annual)


if __name__ == "__main__":
    unittest.main()
