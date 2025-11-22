"""
CFFI-based Python bindings for the Policy-Based Design Calculator
"""
import os
from cffi import FFI

ffi = FFI()

# Define the C API - this must match calculator_c_api.h
ffi.cdef("""
    // Opaque handle types
    typedef struct PVCalculator_t* PVCalculatorHandle;
    typedef struct FVCalculator_t* FVCalculatorHandle;
    typedef struct IRCalculator_t* IRCalculatorHandle;

    // Present Value Calculator
    PVCalculatorHandle pv_calculator_create(void);
    int pv_calculator_calculate(
        PVCalculatorHandle calc,
        double discount_rate,
        const double* cash_flows,
        size_t n_cash_flows,
        double* result
    );
    const char* pv_calculator_get_error(PVCalculatorHandle calc);
    void pv_calculator_destroy(PVCalculatorHandle calc);

    // Future Value Calculator
    FVCalculatorHandle fv_calculator_create(void);
    int fv_calculator_calculate(
        FVCalculatorHandle calc,
        double principal,
        double interest_rate,
        int periods,
        double* result
    );
    const char* fv_calculator_get_error(FVCalculatorHandle calc);
    void fv_calculator_destroy(FVCalculatorHandle calc);

    // Interest Rate Calculator
    IRCalculatorHandle ir_calculator_create(void);
    int ir_calculator_calculate(
        IRCalculatorHandle calc,
        double nominal_rate,
        int compounding_periods,
        double* result
    );
    const char* ir_calculator_get_error(IRCalculatorHandle calc);
    void ir_calculator_destroy(IRCalculatorHandle calc);
""")

# Load the shared library
# The library path will be set by Bazel or can be discovered dynamically
def _load_library():
    """Load the calculator shared library"""
    # Try common locations
    possible_paths = [
        # Bazel runfiles location
        os.path.join(os.path.dirname(__file__), "libcalculator_c_api.so"),
        # Alternative Bazel location
        "bazel-bin/lib/libcalculator_c_api.so",
        # System install location
        "libcalculator_c_api.so",
    ]
    
    for path in possible_paths:
        if os.path.exists(path):
            return ffi.dlopen(path)
    
    # Last resort - let the system find it
    try:
        return ffi.dlopen("libcalculator_c_api.so")
    except OSError as e:
        raise RuntimeError(
            f"Could not find libcalculator_c_api.so. Tried: {possible_paths}"
        ) from e

lib = _load_library()


class PresentValueCalculator:
    """
    Calculator for Present Value of future cash flows
    
    Formula: PV = Σ(CF_t / (1 + r)^t) for t = 1 to n
    
    Example:
        >>> calc = PresentValueCalculator()
        >>> pv = calc.calculate(0.05, [100.0, 200.0, 300.0])
        >>> print(f'Present Value: {pv:.2f}')
    """
    
    def __init__(self):
        """Create a Present Value calculator"""
        self._handle = lib.pv_calculator_create()
        if self._handle == ffi.NULL:
            raise RuntimeError("Failed to create PV calculator")
    
    def calculate(self, discount_rate: float, cash_flows: list[float]) -> float:
        """
        Calculate present value of future cash flows
        
        Args:
            discount_rate: The discount rate (e.g., 0.05 for 5%)
            cash_flows: List of future cash flows
        
        Returns:
            The present value of all cash flows
        
        Raises:
            ValueError: If cash_flows is empty or discount_rate <= -1
        
        Example:
            >>> calc.calculate(0.10, [100, 100, 100])
            248.69
        """
        if not cash_flows:
            raise ValueError("cash_flows must not be empty")
        
        # Convert Python list to C array
        n = len(cash_flows)
        c_cash_flows = ffi.new("double[]", cash_flows)
        result = ffi.new("double*")
        
        # Call C function
        ret = lib.pv_calculator_calculate(
            self._handle, discount_rate, c_cash_flows, n, result
        )
        
        if ret != 0:
            error_msg = ffi.string(lib.pv_calculator_get_error(self._handle)).decode('utf-8')
            raise ValueError(error_msg)
        
        return result[0]
    
    def __del__(self):
        """Cleanup calculator resources"""
        if hasattr(self, '_handle') and self._handle != ffi.NULL:
            lib.pv_calculator_destroy(self._handle)
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.__del__()


class FutureValueCalculator:
    """
    Calculator for Future Value of a principal amount
    
    Formula: FV = PV * (1 + r)^n
    
    Example:
        >>> calc = FutureValueCalculator()
        >>> fv = calc.calculate(1000.0, 0.05, 10)
        >>> print(f'Future Value: {fv:.2f}')
    """
    
    def __init__(self):
        """Create a Future Value calculator"""
        self._handle = lib.fv_calculator_create()
        if self._handle == ffi.NULL:
            raise RuntimeError("Failed to create FV calculator")
    
    def calculate(self, principal: float, interest_rate: float, periods: int) -> float:
        """
        Calculate future value of a principal amount
        
        Args:
            principal: Initial investment amount
            interest_rate: Interest rate per period (e.g., 0.05 for 5%)
            periods: Number of compounding periods
        
        Returns:
            The future value after all periods
        
        Raises:
            ValueError: If principal < 0, periods < 0, or interest_rate <= -1
        
        Example:
            >>> calc.calculate(1000, 0.08, 5)
            1469.33
        """
        result = ffi.new("double*")
        
        # Call C function
        ret = lib.fv_calculator_calculate(
            self._handle, principal, interest_rate, periods, result
        )
        
        if ret != 0:
            error_msg = ffi.string(lib.fv_calculator_get_error(self._handle)).decode('utf-8')
            raise ValueError(error_msg)
        
        return result[0]
    
    def __del__(self):
        """Cleanup calculator resources"""
        if hasattr(self, '_handle') and self._handle != ffi.NULL:
            lib.fv_calculator_destroy(self._handle)
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.__del__()


class InterestRateCalculator:
    """
    Calculator for Interest Rate Conversion (Nominal to Effective)
    
    Formula: EAR = (1 + r/n)^n - 1
    
    Example:
        >>> calc = InterestRateCalculator()
        >>> ear = calc.calculate(0.12, 12)  # 12% nominal, monthly compounding
        >>> print(f'Effective Annual Rate: {ear:.4f}')
    """
    
    def __init__(self):
        """Create an Interest Rate Conversion calculator"""
        self._handle = lib.ir_calculator_create()
        if self._handle == ffi.NULL:
            raise RuntimeError("Failed to create IR calculator")
    
    def calculate(self, nominal_rate: float, compounding_periods: int) -> float:
        """
        Convert nominal interest rate to effective annual rate
        
        Args:
            nominal_rate: Nominal annual interest rate (e.g., 0.12 for 12%)
            compounding_periods: Number of compounding periods per year
                                (e.g., 12 for monthly, 4 for quarterly)
        
        Returns:
            Effective annual rate (EAR)
        
        Raises:
            ValueError: If compounding_periods <= 0 or nominal_rate <= -1
        
        Example:
            >>> calc.calculate(0.06, 12)  # 6% nominal, monthly
            0.0617
        """
        result = ffi.new("double*")
        
        # Call C function
        ret = lib.ir_calculator_calculate(
            self._handle, nominal_rate, compounding_periods, result
        )
        
        if ret != 0:
            error_msg = ffi.string(lib.ir_calculator_get_error(self._handle)).decode('utf-8')
            raise ValueError(error_msg)
        
        return result[0]
    
    def __del__(self):
        """Cleanup calculator resources"""
        if hasattr(self, '_handle') and self._handle != ffi.NULL:
            lib.ir_calculator_destroy(self._handle)
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.__del__()
