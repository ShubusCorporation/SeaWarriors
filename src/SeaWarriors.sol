// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity 0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

contract SeaWarriors is ERC721, ERC721URIStorage, ERC721Pausable, Ownable, ERC721Burnable, ReentrancyGuard {
    using Strings for uint256;

    event Purchase(address indexed buyer, uint256 tokenId, uint256 metadataId);

    error InsufficientFunds();
    error ZeroBalance();
    error WrongMetadataId(uint256 id);
    error AlreadyOwns(uint256 metadataId);
    error WithdrawFailed(uint256 amount);

    uint256 private _nextTokenId;
    uint256 private _totalPayments;
    uint256 private _totalSales;
    uint256 private _seed;

    // Gas efficiency: constant variables do not occupy a storage slot, as their values are embedded directly in the bytecode
    uint256 private constant TOTAL_PICTURES = 13;
    uint256 private constant MIN_NUMERATOR = 10;
    uint256 private constant MAX_NUMERATOR = 1000;

    mapping(address => mapping(uint256 => bool)) internal _hasItem;
    mapping(uint256 => uint256) internal _metadataOf; // tokenId --> metadataId

    constructor(address initialOwner)
        ERC721("Sea Warriors", "ABYSSWARS")
        Ownable(initialOwner)
    {
        _seed = uint256(keccak256(
            abi.encodePacked(blockhash(block.number - 1), block.timestamp)
        ));
    }

    // forge-lint: disable-next-line(mixed-case-function):
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://Qmf2UPHvAqCXk2kMgPquSacNQWdckpHRGKRikevdbK6SG9/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 metadataId)
        public
        onlyOwner
        returns (uint256)
    {
        require(!_hasItem[to][metadataId], AlreadyOwns(metadataId));
        require(metadataId > 0 && metadataId <= TOTAL_PICTURES, WrongMetadataId(metadataId));

        uint256 tokenId = _nextTokenId++;
        _metadataOf[tokenId] = metadataId;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataId.toString());
        return tokenId;
    }

    function buy() 
        public
        payable
        whenNotPaused
        nonReentrant
        returns(uint256)
    {
        require(msg.value >= 0.0001 ether, InsufficientFunds());
        uint256 tokenId = _nextTokenId++;
        uint256 metadataId = getMetadataId(msg.value, _totalPayments, _totalSales);
        uint256 originalId = metadataId;

        while (_hasItem[msg.sender][metadataId]) {
            if (--metadataId == 0) revert AlreadyOwns(originalId);
        }
        require(metadataId > 0 && metadataId <= TOTAL_PICTURES, WrongMetadataId(metadataId));

        unchecked {
            _totalPayments += msg.value;
            _totalSales++;
        }
        _metadataOf[tokenId] = metadataId;
        emit Purchase(msg.sender, tokenId, metadataId);

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataId.toString());

        if (_totalSales % 5 == 0) {
            _seed = uint256(keccak256(
                abi.encodePacked(_seed, blockhash(block.number - 1))
            ));
        }
        return tokenId;
    }

    // With array cash:
    // transaction cost    101996 gas 
    // execution cost      80932 gas

    // Without array:
    // transaction cost	101237 gas 
    // execution cost	80173 gas 

    function getMetadataId(
        uint256 currentPayment,
        uint256 totalPayments,
        uint256 totalSales
    ) 
    internal
    view
    returns(uint256) 
    {
        uint256 numerator = 90;
        uint256 denominator = 100;

        if (totalSales > 0) {
            numerator = getNumerator(currentPayment,  totalPayments / totalSales, numerator);
        }
        console.log("== Implementation ==");
        console.log("numerator = ", numerator);

        uint256 initial = 1250;
        uint256 curr = initial;
        uint256 summ;

        for(uint256 i = 0; i < TOTAL_PICTURES; i++) {
            unchecked {
                curr = curr * numerator / denominator;
                summ += curr;
                console.log(i + 1, "): ", curr);
            }
        }
        uint256 random = getRandom(summ);
        console.log("random: ", random, " summ: ", summ);
        console.log("====");

        curr = initial;
        summ = 0;

        for(uint256 i = 0; i < TOTAL_PICTURES; i++) {
            unchecked {
                curr = curr * numerator / denominator;
                summ += curr;
            }
            if (summ >= random) {
                return i + 1;
            }
        }
        return 1;
    }

    function getNumerator(
        uint256 currentPayment,
        uint256 averagePayment,
        uint256 numerator
    ) internal 
      view
      virtual
      returns(uint256)
    {
        if (currentPayment == 0) {
            return MIN_NUMERATOR;
        }
        if (averagePayment == 0) {
            return numerator;
        }
        bool isBonus = currentPayment > averagePayment;
        uint256 rawCoeff;

        if (isBonus) {
            rawCoeff = averagePayment * 100 / currentPayment;

            if (rawCoeff == 0) {
                return MAX_NUMERATOR;
            }
            uint256 coeff = 100 / rawCoeff;

            if (coeff == 1) numerator += (100 - rawCoeff);
               else numerator *= coeff;
            
            if (numerator > MAX_NUMERATOR) 
                numerator = MAX_NUMERATOR;
        }
        else {
            rawCoeff = currentPayment * 100 / averagePayment;

            if (rawCoeff == 0) {
                return MIN_NUMERATOR;
            }
            uint256 coeff = 100 - rawCoeff;

            if (numerator > coeff) numerator -= coeff;
                else numerator = MIN_NUMERATOR;
        }
        return numerator;
    }

    function getRandom(uint256 N) private view returns (uint256) {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    _seed,
                    blockhash(block.number - 1),
                    block.prevrandao, // instead of `difficulty` in old versions
                    block.number
                )
            )
        );
        return randomHash % (N + 1); // [0..N]
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, ZeroBalance());
        (bool success, ) = owner().call{value: balance}("");
        require(success, WithdrawFailed(balance));
    }

    // The following functions are overrides required by Solidity.
    // forge-lint: disable-next-line(mixed-case-function):
    function _setTokenURI(uint256 tokenId, string memory metadataId) 
        internal 
        override(ERC721URIStorage) 
    {
        metadataId = string.concat(metadataId, ".json");
        super._setTokenURI(tokenId, metadataId);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address from)
    {
        from = super._update(to, tokenId, auth);
        uint256 metadataId = _metadataOf[tokenId];

        if (from != address(0)) { // !mint || transfer || burn
            _hasItem[from][metadataId] = false;
        }
        if (to != address(0)) { // transfer || mint
            _hasItem[to][metadataId] = true;
        }
        else { // burn
            delete _metadataOf[tokenId];
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}