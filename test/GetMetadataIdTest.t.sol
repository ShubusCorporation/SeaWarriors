// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {TestMockedSeaWarriors as TestSeaWarriors} from "./TestSeaWarriors.sol";

// ========== ТЕСТЫ ДЛЯ getMetadataId С РАЗНЫМИ ЗНАЧЕНИЯМИ НУМЕРАТОРОВ ==========
contract GetMetadataIdTest is Test {
    TestSeaWarriors public seaWarriors;
    address public owner;

    // Настроим тестовую среду
    function setUp() public {
        owner = address(0x123);
        seaWarriors = new TestSeaWarriors(owner);
    }

    function setMockNumerator(uint256 numerator) internal {
        seaWarriors.setMockedNumerator(numerator);
    }

    // Тест: минимальный нумератор (MIN_NUMERATOR = 10)
    function testGetMetadataId_MinNumerator() public {
        uint256 numerator = 10;
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_MinNumerator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: максимальный нумератор (MAX_NUMERATOR = 1000)
    function testGetMetadataId_MaxNumerator() public {
        uint256 numerator = 1000;
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_MaxNumerator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: дефолтный нумератор (90)
    function testGetMetadataId_DefaultNumerator() public {
        uint256 numerator = 90;
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_DefaultNumerator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: нумератор меньше минимального (граничное условие)
    function testGetMetadataId_BelowMinNumerator() public {
        uint256 numerator = 5; // меньше MIN_NUMERATOR
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_BelowMinNumerator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: нумератор больше максимального (граничное условие)
    function testGetMetadataId_AboveMaxNumerator() public {
        uint256 numerator = 2000; // больше MAX_NUMERATOR
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_AboveMaxNumerator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: нумератор = 0 (граничное условие)
    function testGetMetadataId_ZeroNumerator() public {
        uint256 numerator = 0;
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_ZeroNumerator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        // При нулевом нумераторе все значения curr будут 0, summ будет 0
        // random будет 0, и функция вернет 1 (fallback)
        assertEq(result, 1, "MetadataId should be 1 when numerator is 0");
    }

    // Тест: нумератор = 1 (очень маленькое значение)
    function testGetMetadataId_OneNumerator() public {
        uint256 numerator = 1;
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_OneNumerator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: нумератор = 50 (среднее значение между MIN и дефолтным)
    function testGetMetadataId_MidNumerator() public {
        uint256 numerator = 50;
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_MidNumerator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: нумератор = 500 (среднее значение между дефолтным и MAX)
    function testGetMetadataId_HighNumerator() public {
        uint256 numerator = 500;
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_HighNumerator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: нумератор = 100 (делитель, граничное условие)
    function testGetMetadataId_EqualDenominator() public {
        uint256 numerator = 100; // равен denominator
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_EqualDenominator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        // При numerator = denominator, curr будет оставаться равным initial (1250)
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: нумератор > 100 (больше denominator, значения увеличиваются)
    function testGetMetadataId_AboveDenominator() public {
        uint256 numerator = 150; // больше denominator
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_AboveDenominator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: нумератор < 100 (меньше denominator, значения уменьшаются)
    function testGetMetadataId_BelowDenominator() public {
        uint256 numerator = 50; // меньше denominator
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        console.log("=== testGetMetadataId_BelowDenominator ===");
        console.log("Mocked numerator:", numerator);
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: totalSales = 0 (не должен вызывать getNumerator, использует дефолтный 90)
    function testGetMetadataId_ZeroTotalSales() public {
        uint256 numerator = 200; // это значение не должно использоваться
        setMockNumerator(numerator);
        
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0;
        uint256 totalSales = 0;
        
        console.log("=== testGetMetadataId_ZeroTotalSales ===");
        console.log("Mocked numerator:", numerator, "(should not be used)");
        console.log("currentPayment:", currentPayment);
        console.log("totalPayments:", totalPayments);
        console.log("totalSales:", totalSales);
        console.log("Expected: should use default numerator = 90");
        
        uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
        
        console.log("result metadataId:", result);
        console.log("---");
        
        assertGe(result, 1, "MetadataId should be at least 1");
        assertLe(result, 13, "MetadataId should be at most 13");
    }

    // Тест: серия вызовов с разными нумераторами
    function testGetMetadataId_SeriesOfNumerators() public {
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        uint256[] memory numerators = new uint256[](7);
        numerators[0] = 10;   // MIN
        numerators[1] = 50;
        numerators[2] = 90;   // Default
        numerators[3] = 100;   // Equal to denominator
        numerators[4] = 500;
        numerators[5] = 1000;  // MAX
        numerators[6] = 1500;  // Above MAX
        
        console.log("=== testGetMetadataId_SeriesOfNumerators ===");
        console.log("Testing with different numerator values");
        console.log("---");
        
        for (uint256 i = 0; i < numerators.length; i++) {
            setMockNumerator(numerators[i]);
            uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
            
            console.log("Numerator:", numerators[i], "-> MetadataId:", result);
            
            assertGe(result, 1, "MetadataId should be at least 1");
            assertLe(result, 13, "MetadataId should be at most 13");
        }
        
        console.log("---");
    }

    // Тест: проверка распределения при разных нумераторах (множественные вызовы)
    function testGetMetadataId_DistributionAnalysis() public {
        uint256 currentPayment = 0.001 ether;
        uint256 totalPayments = 0.01 ether;
        uint256 totalSales = 10;
        
        uint256[] memory numerators = new uint256[](3);
        numerators[0] = 10;   // MIN - должен давать больше вероятность ранних metadataId
        numerators[1] = 90;   // Default
        numerators[2] = 1000;  // MAX - должен давать больше вероятность поздних metadataId
        
        console.log("=== testGetMetadataId_DistributionAnalysis ===");
        console.log("Analyzing distribution with different numerators");
        console.log("---");
        
        for (uint256 n = 0; n < numerators.length; n++) {
            setMockNumerator(numerators[n]);
            
            // Делаем несколько вызовов для анализа распределения
            uint256[14] memory counts; // индексы 1-13 для metadataId
            
            console.log("Numerator:", numerators[n]);
            for (uint256 i = 0; i < 100; i++) {
                uint256 result = seaWarriors.callGetMetadataId(currentPayment, totalPayments, totalSales);
                counts[result]++;
            }
            
            console.log("Distribution (100 calls):");
            for (uint256 i = 1; i <= 13; i++) {
                if (counts[i] > 0) {
                    //console.log("  MetadataId", i, ":", counts[i], "times");
                      console.log("  MetadataId", i);
                }
            }
            console.log("---");
        }
    }
}
