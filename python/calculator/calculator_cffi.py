"""
CFFI-based Python bindings for the Policy-Based Design Calculator
"""
import os
import platform
from cffi import FFI

ffi = FFI()

ffi.cdef("""
    typedef struct PVCalculator_t* PVCalculatorHandle;
    typedef struct FVCalculator_t* FVCalculatorHandle;
    typedef struct IRCalculator_t* IRCalculatorHandle;

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

def _candidate_library_paths() -> list[str]:
    here = os.path.dirname(__file__)
    pkg_root = os.path.abspath(os.path.join(here, ".."))
    repo_root = os.path.abspath(os.path.join(pkg_root, ".."))

    ext_native = "dylib" if platform.system() == "Darwin" else "so"

    return [
        os.path.join(pkg_root, "libcalculator_c_api.so"),
        os.path.join(pkg_root, f"libcalculator_c_api.{ext_native}"),
        os.path.join(here, "libcalculator_c_api.so"),
        os.path.join(here, f"libcalculator_c_api.{ext_native}"),
        os.path.join(repo_root, "build-bin", "lib", f"libcalculator_c_api_shared.{ext_native}"),
        os.path.join(repo_root, "bazel-bin", "lib", f"libcalculator_c_api_shared.{ext_native}"),
        "libcalculator_c_api.so",
        f"libcalculator_c_api.{ext_native}",
        "libcalculator_c_api_shared.so",
        f"libcalculator_c_api_shared.{ext_native}",
    ]

def _load_library():
    possible_paths = _candidate_library_paths()

    for path in possible_paths:
        if os.path.exists(path):
            return ffi.dlopen(path)

    last_resort = [
        "libcalculator_c_api.so",
        "libcalculator_c_api.dylib" if platform.system() == "Darwin" else None,
        "libcalculator_c_api_shared.so",
        "libcalculator_c_api_shared.dylib" if platform.system() == "Darwin" else None,
    ]

    for name in filter(None, last_resort):
        try:
            return ffi.dlopen(name)
        except OSError:
            pass

    raise RuntimeError(
        "Could not find calculator shared library.\n"
        f"Tried:\n  - " + "\n  - ".join(possible_paths)
    )

lib = _load_library()


# ============================================================================
# Safe base class to avoid double-free on __exit__ + __del__
# ============================================================================
class _BaseCalculator:
    _destroy_fn = None  # set in subclasses

    def close(self):
        """Free native resources exactly once."""
        h = getattr(self, "_handle", ffi.NULL)
        if h != ffi.NULL:
            try:
                self._destroy_fn(h)
            finally:
                self._handle = ffi.NULL  # <-- idempotent cleanup

    def __del__(self):
        # Never raise from __del__
        try:
            self.close()
        except Exception:
            pass

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
        return False


class PresentValueCalculator(_BaseCalculator):
    _destroy_fn = staticmethod(lib.pv_calculator_destroy)

    def __init__(self):
        self._handle = lib.pv_calculator_create()
        if self._handle == ffi.NULL:
            raise RuntimeError("Failed to create PV calculator")

    def calculate(self, discount_rate: float, cash_flows: list[float]) -> float:
        if not cash_flows:
            raise ValueError("cash_flows must not be empty")

        n = len(cash_flows)
        c_cash_flows = ffi.new("double[]", cash_flows)
        result = ffi.new("double*")

        ret = lib.pv_calculator_calculate(
            self._handle, discount_rate, c_cash_flows, n, result
        )

        if ret != 0:
            error_msg = ffi.string(
                lib.pv_calculator_get_error(self._handle)
            ).decode("utf-8")
            raise ValueError(error_msg)

        return result[0]


class FutureValueCalculator(_BaseCalculator):
    _destroy_fn = staticmethod(lib.fv_calculator_destroy)

    def __init__(self):
        self._handle = lib.fv_calculator_create()
        if self._handle == ffi.NULL:
            raise RuntimeError("Failed to create FV calculator")

    def calculate(self, principal: float, interest_rate: float, periods: int) -> float:
        result = ffi.new("double*")

        ret = lib.fv_calculator_calculate(
            self._handle, principal, interest_rate, periods, result
        )

        if ret != 0:
            error_msg = ffi.string(
                lib.fv_calculator_get_error(self._handle)
            ).decode("utf-8")
            raise ValueError(error_msg)

        return result[0]


class InterestRateCalculator(_BaseCalculator):
    _destroy_fn = staticmethod(lib.ir_calculator_destroy)

    def __init__(self):
        self._handle = lib.ir_calculator_create()
        if self._handle == ffi.NULL:
            raise RuntimeError("Failed to create IR calculator")

    def calculate(self, nominal_rate: float, compounding_periods: int) -> float:
        result = ffi.new("double*")

        ret = lib.ir_calculator_calculate(
            self._handle, nominal_rate, compounding_periods, result
        )

        if ret != 0:
            error_msg = ffi.string(
                lib.ir_calculator_get_error(self._handle)
            ).decode("utf-8")
            raise ValueError(error_msg)

        return result[0]

