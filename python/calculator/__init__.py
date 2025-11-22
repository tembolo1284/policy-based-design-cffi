"""
Policy-Based Design Calculator for Financial Mathematics

This module provides financial calculators with real mathematical logic:
  - Present Value: Calculate PV of future cash flows
  - Future Value: Calculate FV of a principal amount
  - Interest Rate Conversion: Convert nominal to effective annual rate
"""

from .calculator_cffi import (
    PresentValueCalculator,
    FutureValueCalculator,
    InterestRateCalculator,
)

__all__ = [
    'PresentValueCalculator',
    'FutureValueCalculator',
    'InterestRateCalculator',
]

__version__ = '1.0.0'
