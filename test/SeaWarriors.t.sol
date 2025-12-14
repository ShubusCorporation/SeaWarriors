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
import {SeaWarriors} from "src/SeaWarriors.sol";

contract TestSeaWarriors is SeaWarriors {
    constructor(address initialOwner) SeaWarriors(initialOwner) {}

    // Публичная обертка для доступа к internal методу
    function getMetadataOf(uint256 tokenId) public view returns (uint256) {
        return _metadataOf[tokenId];
    }

    function getHasItem(address holder, uint256 item) public view returns (bool) {
        return _hasItem[holder][item];
    }
}


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
        initialBalance = 1 ether;
        vm.deal(user, initialBalance);  // даем пользователю начальный баланс
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
        uint256 payment1 = 0.0005 ether;
        uint256 payment2 = 0.001 ether;

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
        uint256 payment3 = 0.002 ether;
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
            uint256 tokenId = seaWarriors.buy{value: payment}();
            uint256 metadataId = seaWarriors.getMetadataOf(tokenId);

            // Логируем для каждого теста
            console.log("Purchase number: ", i + 1);
            console.log("Payment amount:", payment);
            console.log("TokenId: ", tokenId);
            console.log("MetadataId: ", metadataId);

            // Проверка, что значение метаданных изменяется
            assertTrue(metadataId > 0 && metadataId <= 13, "MetadataId out of range");
        }
    }

    // Проверка баланса владельца после вывода средств
    function testWithdraw() public {
        uint256 initialOwnerBalance = address(owner).balance;

        // Производим вывод средств
        vm.prank(owner);
        seaWarriors.withdraw();

        // Логируем баланс владельца
        console.log("Owner's balance after withdraw: ", address(owner).balance);

        // Проверяем, что баланс владельца увеличился
        assertGt(address(owner).balance, initialOwnerBalance, "Owner's balance should increase after withdraw");
    }
}
