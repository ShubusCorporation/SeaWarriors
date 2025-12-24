// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/*
  const max = TOTAL_PICTURES;
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
import {SeaWarriors} from "src/SeaWarriors.sol";

contract SeaWarriorsTest is Test {
    TestSeaWarriors public seaWarriors;
    address public owner;
    address public user;
    uint256 public initialBalance;
    mapping(uint256 => bool) alreadyHas;

    // Настроим тестовую среду
    function setUp() public {
        owner = address(0x123);
        user = address(0x456);

        seaWarriors = new TestSeaWarriors(owner);

        // Инициализация баланса для пользователя
        initialBalance = 10 ether;
        vm.deal(user, initialBalance); // даем пользователю начальный баланс
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
    function testLoad() public {
        uint256 numberOfPurchases = 100;
        uint256 remainedPictures = seaWarriors.TOTAL_PICTURES();

        for (uint256 i = 0; i < numberOfPurchases; i++) {
            uint256 payment = 0.0001 ether + i * 0.0001 ether;

            // Проверяем, что покупка прошла корректно
            vm.prank(user);
            try seaWarriors.buy{value: payment}() returns (uint256 tokenId) {
                uint256 metadataId = seaWarriors.getMetadataOf(tokenId);

                console.log("Purchase number: ", i + 1);
                console.log("Payment amount:", payment);
                console.log("TokenId: ", tokenId);
                console.log("MetadataId: ", metadataId);

                assertTrue(metadataId > 0 && metadataId <= seaWarriors.TOTAL_PICTURES(), "MetadataId out of range");
                remainedPictures--;
                alreadyHas[metadataId] = true;
            } catch (bytes memory reason) {
                // Селекторы ошибок
                bytes4 alreadyOwnsSelector = bytes4(keccak256("AlreadyOwns(address,uint256)"));
                bytes4 insufficientFundsSelector = bytes4(keccak256("InsufficientFundsToBuyNew(address,uint256)"));
                bytes4 alreadyCompletedSelector = bytes4(keccak256("AlreadyCompleted(address)"));

                // forge-lint: disable-next-line(unsafe-typecast):
                bytes4 errorSelector = bytes4(reason);

                if (reason.length >= 68 && errorSelector == alreadyOwnsSelector) {
                    // AlreadyOwns(address buyer, uint256 metadataId)
                    // Структура: 4 байта селектор + 32 байта address + 32 байта uint256
                    // В bytes memory: первые 32 байта - длина, затем данные
                    address buyer;
                    uint256 metadataId;
                    assembly {
                        // reason указывает на структуру bytes memory
                        // Первые 32 байта (0x00-0x1F) - длина массива
                        // Данные начинаются с offset 0x20
                        // Селектор: байты 0x20-0x23 (4 байта)
                        // Address: байты 0x24-0x43 (32 байта, адрес в правой части)
                        // MetadataId: байты 0x44-0x63 (32 байта)
                        let dataPtr := add(reason, 0x20) // указатель на начало данных
                        let addrPtr := add(dataPtr, 0x04) // указатель на адрес (после селектора)
                        // Маскируем адрес до 20 байт (160 бит)
                        buyer := and(mload(addrPtr), 0xffffffffffffffffffffffffffffffffffffffff)
                        let metadataPtr := add(addrPtr, 0x20) // указатель на metadataId
                        metadataId := mload(metadataPtr)
                    }
                    console.log("AlreadyOwns error caught for purchase number:", i + 1);
                    console.log("Buyer:", buyer);
                    console.log("MetadataId already owned:", metadataId);
                    console.log("Original payment:", payment);
                    assertTrue(metadataId > 0 && metadataId <= seaWarriors.TOTAL_PICTURES(), "MetadataId out of range");
                    assertTrue(alreadyHas[metadataId], "Wrong Error: MetadataId is not already owned");
                    assertEq(buyer, user, "Buyer address mismatch when already has item");
                } else if (reason.length >= 68 && errorSelector == insufficientFundsSelector) {
                    // InsufficientFundsToBuyNew(address buyer, uint256 funds)
                    // Структура: 4 байта селектор + 32 байта address + 32 байта uint256
                    address buyer;
                    uint256 funds;
                    assembly {
                        let dataPtr := add(reason, 0x20) // указатель на начало данных
                        let addrPtr := add(dataPtr, 0x04) // указатель на адрес (после селектора)
                        buyer := and(mload(addrPtr), 0xffffffffffffffffffffffffffffffffffffffff)
                        let fundsPtr := add(addrPtr, 0x20) // указатель на funds
                        funds := mload(fundsPtr)
                    }
                    console.log("InsufficientFundsToBuyNew error caught for purchase number:", i + 1);
                    console.log("Buyer:", buyer);
                    console.log("Funds:", funds);
                    console.log("Original payment:", payment);
                    assertEq(buyer, user, "Buyer address mismatch");
                    // Это нормальная ситуация, когда все доступные metadataId уже куплены
                } else if (reason.length >= 36 && errorSelector == alreadyCompletedSelector) {
                    // AlreadyCompleted(address buyer)
                    // Структура: 4 байта селектор + 32 байта address
                    // В bytes memory: первые 32 байта - длина, затем данные
                    address buyer;
                    assembly {
                        // reason указывает на структуру bytes memory
                        // Первые 32 байта (0x00-0x1F) - длина массива
                        // Данные начинаются с offset 0x20
                        // Селектор: байты 0x20-0x23 (4 байта)
                        // Address: байты 0x24-0x43 (32 байта, адрес в правой части)
                        let dataPtr := add(reason, 0x20) // указатель на начало данных
                        let addrPtr := add(dataPtr, 0x04) // указатель на адрес (после селектора)
                        // Маскируем адрес до 20 байт (160 бит)
                        buyer := and(mload(addrPtr), 0xffffffffffffffffffffffffffffffffffffffff)
                    }
                    console.log("AlreadyCompleted error caught for purchase number:", i + 1);
                    console.log("Buyer:", buyer);
                    console.log("Original payment:", payment);
                    assertEq(remainedPictures, 0, "Wrong Error: Collection is not completed");
                    assertEq(buyer, user, "Buyer address mismatch when collection is completed");
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
        assertEq(
            address(owner).balance - initialOwnerBalance, userPayment, "Owner's balance should increase after withdraw"
        );
        // Проверяем, что баланс контракта стал нулевым (или почти нулевым)
        assertEq(address(seaWarriors).balance, 0, "Contract balance should be zero after withdraw");
    }

    // Тест на ошибку ArtistShouldBeEOA - нельзя установить контракт как художника
    function testArtistShouldBeEOA() public {
        // Создаем простой контракт для теста
        MockContract mockContract = new MockContract();

        // Попытка установить контракт как художника должна вернуть ошибку
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(SeaWarriors.ArtistShouldBeEOA.selector));
        seaWarriors.setArtist(address(mockContract));
    }

    // Тест на успешную установку EOA как художника
    function testSetArtistEOA() public {
        address artist = address(0x789);

        vm.prank(owner);
        seaWarriors.setArtist(artist);

        assertEq(seaWarriors._artist(), artist, "Artist should be set correctly");
    }

    // Тест на ошибку OwnerShouldNotBeArtist - владелец не может быть художником
    function testOwnerShouldNotBeArtist() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(SeaWarriors.OwnerShouldNotBeArtist.selector));
        seaWarriors.setArtist(owner);
    }

    // Тест на ошибку AlreadyCompleted - пользователь купил все картины (TOTAL_PICTURES)
    function testAlreadyCompleted() public {
        uint256 val = 0.0001 ether;
        uint256 iterations = 0;

        // Покупаем все картины, перехватывая InsufficientFundsToBuyNew
        while (seaWarriors.getItemsPurchased(user) < seaWarriors.TOTAL_PICTURES()) {
            iterations++;
            assertLt(iterations, 101, "Can not complete the whole collection!");
            vm.prank(user);
            try seaWarriors.buy{value: val}() {
            // Покупка успешна
            }
            catch (bytes memory reason) {
                // Селектор ошибки InsufficientFundsToBuyNew
                bytes4 insufficientFundsSelector = bytes4(keccak256("InsufficientFundsToBuyNew(address,uint256)"));

                // forge-lint: disable-next-line(unsafe-typecast):
                bytes4 errorSelector = bytes4(reason);

                if (reason.length >= 68 && errorSelector == insufficientFundsSelector) {
                    val *= 2;
                } else {
                    revert(string(reason));
                }
            }
        }

        assertEq(
            seaWarriors.getItemsPurchased(user), seaWarriors.TOTAL_PICTURES(), "The collection should be completed"
        );

        // Попытка купить еще одну должна вернуть ошибку AlreadyCompleted
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(SeaWarriors.AlreadyCompleted.selector, user));
        seaWarriors.buy{value: val}();
    }

    // Тест что после burn AlreadyCompleted не приходит - можно снова покупать
    function testAfterBurnCanBuyAgain() public {
        uint256[] memory tokenIds = new uint256[](seaWarriors.TOTAL_PICTURES());
        uint256 val = 0.1 ether;

        // Покупаем все картины
        for (uint256 i = 0; i < seaWarriors.TOTAL_PICTURES(); i++) {
            vm.prank(owner);
            tokenIds[i] = seaWarriors.safeMint(owner, i + 1);
        }
        assertEq(
            seaWarriors.getItemsPurchased(owner), seaWarriors.TOTAL_PICTURES(), "The collection should be completed"
        );

        // Проверяем, что покупка 14-й картинки невозможна
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(SeaWarriors.AlreadyCompleted.selector, owner));
        seaWarriors.buy{value: val}();

        // Сжигаем один токен
        vm.prank(owner);
        seaWarriors.burn(tokenIds[0]);

        assertEq(seaWarriors.getItemsPurchased(owner), 12, "1 token should be burned");

        // Теперь должна быть возможность купить снова
        vm.prank(owner);
        uint256 newTokenId = seaWarriors.buy{value: 0.0001 ether}();
        assertGt(newTokenId, 0, "Should be able to buy after burn");

        // Проверяем, что _hasItem обновился после burn
        uint256 burnedMetadataId = seaWarriors.getMetadataOf(tokenIds[0]);
        assertFalse(seaWarriors.getHasItem(owner, burnedMetadataId), "Should not have item after burn");
    }

    // Тест на ошибку InsufficientFunds - недостаточно средств для покупки
    function testInsufficientFunds() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(SeaWarriors.InsufficientFunds.selector));
        seaWarriors.buy{value: 0.00001 ether}(); // Меньше минимальной суммы 0.0001 ether
    }

    // Тест на ошибку WrongMetadataId при safeMint
    function testWrongMetadataId() public {
        // Начало выполнения с правами владельца
        vm.startPrank(owner);

        // Логирование и проверка для случая с 0
        vm.expectRevert(abi.encodeWithSelector(SeaWarriors.WrongMetadataId.selector, 0));
        seaWarriors.safeMint(user, 0); // metadataId должен быть > 0

        uint256 upperValue = seaWarriors.TOTAL_PICTURES() + 1;
        vm.expectRevert(abi.encodeWithSelector(SeaWarriors.WrongMetadataId.selector, upperValue));
        seaWarriors.safeMint(user, upperValue); // metadataId должен быть <= TOTAL_PICTURES

        vm.stopPrank();
    }

    // Тест на ошибку AlreadyOwns при safeMint
    function testAlreadyOwnsSafeMint() public {
        uint256 metadataId = 5;

        vm.prank(owner);
        seaWarriors.safeMint(user, metadataId);

        // Попытка сминтить тот же metadataId должна вернуть ошибку
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(SeaWarriors.AlreadyOwns.selector, user, metadataId));
        seaWarriors.safeMint(user, metadataId);
    }

    // Тест на ошибку InsufficientFundsToBuyNew - все доступные metadataId уже куплены
    function testInsufficientFundsToBuyNew() public {
        // Покупаем все картинки с metadataId от 1 до TOTAL_PICTURES
        // Для этого нужно купить TOTAL_PICTURES раз, но с разными суммами чтобы получить разные metadataId
        // Или купить все возможные metadataId через safeMint, а потом попытаться купить

        vm.prank(user);
        uint256 tokenId = seaWarriors.buy{value: 5 ether}(); // Average value to
        uint256 metadataId = seaWarriors.getMetadataOf(tokenId);

        // Сначала сминтим все возможные metadataId пользователю
        for (uint256 i = 1; i <= seaWarriors.TOTAL_PICTURES() - 2; i++) {
            if (i == metadataId) continue;
            vm.prank(owner);
            seaWarriors.safeMint(user, i);
        }

        // Теперь попытка купить должна вернуть InsufficientFundsToBuyNew
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(SeaWarriors.InsufficientFundsToBuyNew.selector, user, 0.0001 ether));
        seaWarriors.buy{value: 0.0001 ether}();
    }

    // Тест на ошибку NotEnoughBalance при withdraw
    function testNotEnoughBalance() public {
        // Контракт имеет баланс 0 или <= 1 wei
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(SeaWarriors.NotEnoughBalance.selector));
        seaWarriors.withdraw();
    }

    // Тест на withdraw с художником - средства делятся пополам
    function testWithdrawWithArtist() public {
        address artist = address(0x789);
        vm.deal(artist, 0);

        vm.prank(owner);
        seaWarriors.setArtist(artist);

        uint256 payment = 1 ether;
        vm.prank(user);
        seaWarriors.buy{value: payment}();

        uint256 initialOwnerBalance = address(owner).balance;
        uint256 initialArtistBalance = address(artist).balance;

        vm.prank(owner);
        seaWarriors.withdraw();

        // Проверяем, что владелец и художник получили по половине
        assertEq(address(owner).balance - initialOwnerBalance, payment / 2, "Owner should receive half");
        assertEq(address(artist).balance - initialArtistBalance, payment / 2, "Artist should receive half");
    }

    // Тест на pause/unpause функциональность
    function testPauseUnpause() public {
        vm.prank(owner);
        seaWarriors.pause();

        // Покупка должна быть невозможна когда контракт на паузе
        vm.prank(user);
        vm.expectRevert();
        seaWarriors.buy{value: 0.0001 ether}();

        vm.prank(owner);
        seaWarriors.unpause();

        // После unpause покупка должна работать
        vm.prank(user);
        uint256 tokenId = seaWarriors.buy{value: 0.0001 ether}();
        assertEq(tokenId, 0, "Should be able to buy after unpause");
    }

    // Тест на transfer и обновление _hasItem
    function testTransferUpdatesHasItem() public {
        address recipient = address(0x999);

        vm.prank(user);
        uint256 tokenId = seaWarriors.buy{value: 0.0001 ether}();
        uint256 metadataId = seaWarriors.getMetadataOf(tokenId);

        // Проверяем, что у user есть этот item
        assertTrue(seaWarriors.getHasItem(user, metadataId), "User should have item");
        assertFalse(seaWarriors.getHasItem(recipient, metadataId), "Recipient should not have item");

        // Переводим токен
        vm.prank(user);
        seaWarriors.transferFrom(user, recipient, tokenId);

        // Проверяем, что _hasItem обновился
        assertFalse(seaWarriors.getHasItem(user, metadataId), "User should not have item after transfer");
        assertTrue(seaWarriors.getHasItem(recipient, metadataId), "Recipient should have item after transfer");
    }

    // Тест на burn и обновление _itemsPurchased
    function testBurnUpdatesItemsPurchased() public {
        // Покупаем несколько токенов
        vm.prank(user);
        uint256 tokenId1 = seaWarriors.buy{value: 0.0001 ether}();

        vm.prank(user);
        seaWarriors.buy{value: 0.0001 ether}();

        // Сжигаем один токен
        vm.prank(user);
        seaWarriors.burn(tokenId1);

        // Теперь можно купить еще один (было 2, стало 1, можно купить до TOTAL_PICTURES)
        vm.prank(user);
        uint256 tokenId3 = seaWarriors.buy{value: 0.0001 ether}();
        assertGt(tokenId3, 0, "Should be able to buy after burn");
    }
}

// Вспомогательный контракт для тестирования ArtistShouldBeEOA
contract MockContract {
    function dummy() public pure returns (uint256) {
        return 1;
    }
}
