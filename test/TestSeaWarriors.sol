// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {TestSeaWarriors} from "src/SeaWarriors.sol";

contract TestMockedSeaWarriors is TestSeaWarriors {
    uint256 public _getNumeratorResult;

    constructor(address initialOwner) TestSeaWarriors(initialOwner) {}

    function setMockedNumerator(uint256 value) public {
        _getNumeratorResult = value;
    }

    function getNumerator(
        uint256 currentPayment,
        uint256 averagePayment,
        uint256 numerator
    ) internal view override returns (uint256) {
        return _getNumeratorResult;
    }

    function callGetMetadataId(
        uint256 currentPayment,
        uint256 totalPayments,
        uint256 totalSales
    ) 
    public
    view
    returns(uint256) 
    {
       return super.getMetadataId(currentPayment, totalPayments, totalSales);
    }
}
