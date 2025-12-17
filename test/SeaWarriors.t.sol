// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/*
  const max = 13;
  const initial = 1250;

  for (let coeff = 0.1; coeff < 2.0; coeff+=0.1) {
    let curr = initial;
    let arr = new Array(max);
    let summ = 0;

    for (let i=0; i < max; i++) {
      curr = Math.floor(curr * coeff);
      arr[i] = curr;
      summ += curr;
      
    }

    for (let i = 0; i < max; i++) {
      console.log(`${ arr[i] } --> ${ Math.floor(arr[i] * 100 / summ) }% from ${ summ }`);

    }
    console.log("----------------------------------------");
  }
*/

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {TestSeaWarriors} from "./TestSeaWarriors.sol";

contract SeaWarriorsTest is Test {
    TestSeaWarriors public seaWarriors;
    address public owner;
    address public user;
    uint256 public initialBalance;

    // Настроим тестовую среду
    function setUp() public {
        owner = address(0x123);
        user = address(0x456);
        
        seaWarriors = new TestSeaWarriors(owner);

        // Инициализация баланса для пользователя
        initialBalance = 10 ether;
        vm.deal(user, initialBalance);  // даем пользователю начальный баланс
        vm.deal(owner, initialBalance);
    }

    // Тест на изменение metadataId в зависимости от суммы
    function testMetadataIdChangeOnPayment() public {
        uint256 payment1 = 0.0005 ether;
        uint256 payment2 = 0.001 ether;
        
        // Покупаем первый токен
        vm.prank(user);
        uint256 tokenId1 = seaWarriors.buy{value: payment1}();
        uint256 metadataId1 = seaWarriors.getMetadataOf(tokenId1);

        console.log("Token 1 purchased with payment:", payment1);
        console.log("Token 1 MetadataId:", metadataId1);

        // Покупаем второй токен
        vm.prank(user);
        uint256 tokenId2 = seaWarriors.buy{value: payment2}();
        uint256 metadataId2 = seaWarriors.getMetadataOf(tokenId2);

        console.log("Token 2 purchased with payment:", payment2);
        console.log("Token 2 MetadataId:", metadataId2);

        // Проверяем, что метаданные изменились, так как суммы разные
        assertTrue(metadataId1 != metadataId2, "MetadataId should be different");
    }

    // Тест на количество изменений metadataId в зависимости от общего количества покупок
    function testMetadataIdChangeOnTotalPayments() public {
        uint256 payment1 = 0.0001 ether;
        uint256 payment2 = 0.002 ether;

        // Покупаем несколько токенов
        vm.prank(user);
        uint256 tokenId1 = seaWarriors.buy{value: payment1}();
        uint256 metadataId1 = seaWarriors.getMetadataOf(tokenId1);

        console.log("Token 1 purchased with payment:", payment1);
        console.log("Token 1 MetadataId:", metadataId1);

        vm.prank(user);
        uint256 tokenId2 = seaWarriors.buy{value: payment2}();
        uint256 metadataId2 = seaWarriors.getMetadataOf(tokenId2);

        console.log("Token 2 purchased with payment:", payment2);
        console.log("Token 2 MetadataId:", metadataId2);

        assertTrue(metadataId1 != metadataId2, "MetadataId should be different");

        // Делаем еще покупку с другим значением
        uint256 payment3 = 0.04 ether;
        vm.prank(user);
        uint256 tokenId3 = seaWarriors.buy{value: payment3}();
        uint256 metadataId3 = seaWarriors.getMetadataOf(tokenId3);

        console.log("Token 3 purchased with payment:", payment3);
        console.log("Token 3 MetadataId:", metadataId3);

        // Проверяем, что новый metadataId изменился
        assertTrue(metadataId2 != metadataId3, "MetadataId should be different");
        assertTrue(metadataId1 != metadataId3, "MetadataId should be different");
    }

    // Нагрузочное тестирование, много покупок
    function testLoadTest() public {
        uint256 totalPayments = 0;
        uint256 numberOfPurchases = 100;
        
        for (uint256 i = 0; i < numberOfPurchases; i++) {
            uint256 payment = 0.0001 ether + i * 0.00005 ether;
            totalPayments += payment;

            // Проверяем, что покупка прошла корректно
            vm.prank(user);
            try seaWarriors.buy{value: payment}() returns (uint256 tokenId) {
            uint256 metadataId = seaWarriors.getMetadataOf(tokenId);

            // Логируем для каждого теста
            console.log("Purchase number: ", i + 1);
            console.log("Payment amount:", payment);
            console.log("TokenId: ", tokenId);
            console.log("MetadataId: ", metadataId);
            // Проверка, что значение метаданных изменяется
            assertTrue(metadataId > 0 && metadataId <= 13, "MetadataId out of range");
            } catch (bytes memory reason) {
                // Селектор ошибки AlreadyOwns(uint256) = keccak256("AlreadyOwns(uint256)")[0:4]
                bytes4 alreadyOwnsSelector = bytes4(keccak256("AlreadyOwns(uint256)"));
                
                // Проверяем, является ли это ошибкой AlreadyOwns
                // forge-lint: disable-next-line(unsafe-typecast):
                if (reason.length >= 36 && reason.length >= 4 && bytes4(reason) == alreadyOwnsSelector) {
                    // Декодируем параметр metadataId из ошибки (после 4 байт селектора)
                    uint256 metadataId;
                    assembly {
                        metadataId := mload(add(reason, 0x24))
                    }
                    // Логируем ошибку
                    console.log("AlreadyOwns error caught for purchase number:", i + 1);
                    console.log("MetadataId already owned:", metadataId);
                    console.log("Original payment:", payment);
                } else {
                    // Если это другая ошибка, пробрасываем её дальше
                    revert(string(reason));
                }
            }
        }
    }

    // Проверка баланса владельца после вывода средств
    function testWithdraw() public {
        uint256 initialOwnerBalance = address(owner).balance;
        // Сначала пополняем баланс контракта
        uint256 userPayment = 0.0035 ether;
        
        vm.prank(user);
        seaWarriors.buy{value: userPayment}();

        uint256 contractBalance = address(seaWarriors).balance;
        console.log("Contract balance before withdraw: ", contractBalance);
        assertGt(contractBalance, 0, "Contract should have balance from purchases");

        vm.prank(owner);
        seaWarriors.withdraw();

        console.log("Owner's balance after withdraw: ", address(owner).balance);
        // Проверяем, что баланс владельца увеличился
        assertEq(address(owner).balance - initialOwnerBalance, userPayment, "Owner's balance should increase after withdraw");       
        // Проверяем, что баланс контракта стал нулевым (или почти нулевым)
        assertEq(address(seaWarriors).balance, 0, "Contract balance should be zero after withdraw");
    }
}
