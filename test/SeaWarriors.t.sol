// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {SeaWarriors} from "src/SeaWarriors.sol";

contract SeaWarriorsTest is Test {
  SeaWarriors public instance;

  function setUp() public {
    address initialOwner = vm.addr(1);
    instance = new SeaWarriors(initialOwner);
  }

  function testName() public view {
    assertEq(instance.name(), "Sea Warriors");
  }
}
