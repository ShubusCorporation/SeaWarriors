// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

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
