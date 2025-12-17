// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SeaWarriors} from "src/SeaWarriors.sol";

contract TestSeaWarriors is SeaWarriors {
    constructor(address initialOwner) SeaWarriors(initialOwner) {}

    function getMetadataOf(uint256 tokenId) public view returns (uint256) {
        return _metadataOf[tokenId];
    }

    function getHasItem(address holder, uint256 item) public view returns (bool) {
        return _hasItem[holder][item];
    }

    function callGetNumerator(
        uint256 currentPayment,
        uint256 averagePayment,
        uint256 numerator
    ) public view returns (uint256) {
        return super.getNumerator(currentPayment, averagePayment, numerator);
    }
}

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
