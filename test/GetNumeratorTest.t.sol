// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {TestSeaWarriors} from "./TestSeaWarriors.sol";

// ========== ОТДЕЛЬНЫЙ КОНТРАКТ ДЛЯ ТЕСТОВ getNumerator ==========
contract GetNumeratorTest is Test {
    TestSeaWarriors public seaWarriors;
    address public owner;
    uint256 private constant MIN_NUMERATOR = 10;
    uint256 private constant MAX_NUMERATOR = 1000;

    // Настроим тестовую среду
    function setUp() public {
        owner = address(0x123);
        seaWarriors = new TestSeaWarriors(owner);
    }

    // ========== ТЕСТЫ ДЛЯ getNumerator ==========

    // Базовый тест: бонусный платеж (currentPayment > averagePayment)
    function testGetNumerator_BonusPayment() view public {
        uint256 currentPayment = 0.002 ether;
        uint256 averagePayment = 0.001 ether;
        uint256 initialNumerator = 90;
        
        console.log("=== testGetNumerator_BonusPayment ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        assertGt(result, initialNumerator, "Numerator should increase for bonus payment");
    }

    // Базовый тест: платеж ниже среднего (currentPayment < averagePayment)
    function testGetNumerator_BelowAveragePayment() view public {
        uint256 currentPayment = 0.0005 ether;
        uint256 averagePayment = 0.001 ether;
        uint256 initialNumerator = 90;
        
        console.log("=== testGetNumerator_BelowAveragePayment ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        assertLt(result, initialNumerator, "Numerator should decrease for below average payment");
    }

    // Edge case: currentPayment == averagePayment (rem = 0)
    function testGetNumerator_EqualPayment() view public {
        uint256 currentPayment = 0.001 ether;
        uint256 averagePayment = 0.001 ether;
        uint256 initialNumerator = 90;
        
        console.log("=== testGetNumerator_EqualPayment ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        // rem = 0, rem < avg5p, должен вернуть исходный numerator
        assertEq(result, initialNumerator, "Numerator should remain unchanged when payment equals average");
    }

    // Edge case: averagePayment = 0 (avg5p = 0)
    function testGetNumerator_ZeroAveragePayment() view public {
        uint256 currentPayment = 0.001 ether;
        uint256 averagePayment = 0;
        uint256 initialNumerator = 90;
        
        console.log("=== testGetNumerator_ZeroAveragePayment ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        assertEq(result, initialNumerator, "Numerator should remain unchanged when averagePayment is 0");
    }

    // Edge case: averagePayment < 20 (avg5p = 0)
    function testGetNumerator_SmallAveragePayment() view public {
        uint256 currentPayment = 0.001 ether;
        uint256 averagePayment = 10; // меньше 20, avg5p = 0
        uint256 initialNumerator = 90;
        
        console.log("=== testGetNumerator_SmallAveragePayment ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        assertEq(result, MAX_NUMERATOR, "Numerator should be MAX when currentPayment >> averagePaymant");
    }

    // Edge case: small difference
    function testGetNumerator_SmallRemainder() view public {
        uint256 currentPayment = 0.00101 ether;
        uint256 averagePayment = 0.001 ether;
        uint256 initialNumerator = 90;
        
        console.log("=== testGetNumerator_SmallRemainder ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        assertGt(result, initialNumerator, "Numerator should be increased");
    }

    // Edge case: numerator достигает MAX_NUMERATOR (1000)
    function testGetNumerator_MaxNumerator() view public {
        uint256 currentPayment = 10 ether;
        uint256 averagePayment = 0.001 ether;
        uint256 initialNumerator = 950;
        
        console.log("=== testGetNumerator_MaxNumerator ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        // Должен быть ограничен MAX_NUMERATOR = 1000
        assertEq(result, 1000, "Numerator should be capped at MAX_NUMERATOR (1000)");
        assertLe(result, 1000, "Numerator should not exceed MAX_NUMERATOR");
    }

    // Edge case: numerator достигает MIN_NUMERATOR (10)
    function testGetNumerator_MinNumerator() view public {
        uint256 currentPayment = 0.0001 ether;
        uint256 averagePayment = 10 ether;
        uint256 initialNumerator = 50;
        
        console.log("=== testGetNumerator_MinNumerator ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        // Должен быть ограничен MIN_NUMERATOR = 10
        assertEq(result, 10, "Numerator should be capped at MIN_NUMERATOR (10)");
        assertGe(result, 10, "Numerator should not be below MIN_NUMERATOR");
    }

    // Edge case: numerator < coeff (при не бонусе, должен стать MIN_NUMERATOR)
    function testGetNumerator_NumeratorLessThanCoeff() public view {
        uint256 currentPayment = 0.0001 ether;
        uint256 averagePayment = 0.001 ether;
        uint256 initialNumerator = 30;
        
        console.log("=== testGetNumerator_NumeratorLessThanCoeff ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        assertEq(result, 10, "Numerator should be set to MIN_NUMERATOR when numerator < coeff");
    }

    // Тест с большими значениями
    function testGetNumerator_LargeValues() public view {
        uint256 currentPayment = 1000 ether;
        uint256 averagePayment = 100 ether;
        uint256 initialNumerator = 500;
        
        console.log("=== testGetNumerator_LargeValues ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        assertEq(result, 1000, "Numerator should be capped at MAX_NUMERATOR for large values");
    }

    // Тест с очень маленькими значениями
    function testGetNumerator_VerySmallValues() public view {
        uint256 currentPayment = 100;
        uint256 averagePayment = 50;
        uint256 initialNumerator = 90;
        
        console.log("=== testGetNumerator_VerySmallValues ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        assertGt(result, initialNumerator, "Numerator should increase even with small values");
    }

    // Тест: серия изменений numerator
    function testGetNumerator_SeriesOfChanges() public view {
        uint256 averagePayment = 0.001 ether;
        uint256 numerator = 90;
        
        console.log("=== testGetNumerator_SeriesOfChanges ===");
        console.log("Starting numerator:", numerator);
        console.log("Average payment:", averagePayment);
        console.log("---");
        
        // Серия платежей выше среднего
        uint256[] memory payments = new uint256[](5);
        payments[0] = 0.0015 ether;
        payments[1] = 0.002 ether;
        payments[2] = 0.0025 ether;
        payments[3] = 0.003 ether;
        payments[4] = 0.0035 ether;
        
        for (uint256 i = 0; i < payments.length; i++) {
            console.log("Step", i + 1, "- Payment:", payments[i]);
            numerator = seaWarriors.callGetNumerator(payments[i], averagePayment, numerator);
            console.log("  Result numerator:", numerator);
        }
        
        console.log("Final numerator:", numerator);
        console.log("---");
        
        assertGt(numerator, 90, "Numerator should increase after series of bonus payments");
    }

    // Тест: граничное значение avg5p (averagePayment = 20)
    function testGetNumerator_Avg5pBoundary() public view {
        uint256 currentPayment = 0.002 ether;
        uint256 averagePayment = 20; // avg5p = 1
        uint256 initialNumerator = 90;
        
        console.log("=== testGetNumerator_Avg5pBoundary ===");
        console.log("currentPayment:", currentPayment);
        console.log("averagePayment:", averagePayment);
        console.log("initialNumerator:", initialNumerator);
        
        uint256 result = seaWarriors.callGetNumerator(currentPayment, averagePayment, initialNumerator);
        
        console.log("result numerator:", result);
        console.log("---");
        
        // avg5p = 20 / 20 = 1
        // rem = 0.002 ether = 2000000000000000 wei
        // rem >= avg5p, coeff = (2000000000000000 * 5) / 1 = очень большое число
        // numerator будет ограничен MAX_NUMERATOR
        assertLe(result, 1000, "Numerator should be within bounds");
    }
}
