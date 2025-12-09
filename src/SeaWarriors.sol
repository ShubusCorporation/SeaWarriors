// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity 0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SeaWarriors is ERC721, ERC721URIStorage, ERC721Pausable, Ownable, ERC721Burnable {
    using Strings for uint256;
    error InsufficientFunds();
    error WrongmetadataId();

    uint256 private _nextTokenId;
    uint256 private _totalPayments;
    uint256 private _totalSales;
    uint256 private constant TOTAL_PICTURES = 13;

    mapping(uint256 => uint256) private _tokenIDTometadataId;

    constructor(address initialOwner)
        ERC721("Sea Warriors", "ABYSSWARS")
        Ownable(initialOwner)
    {}

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
        require(metadataId > 0 && metadataId <= TOTAL_PICTURES, WrongmetadataId());
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataId.toString());
        return tokenId;
    }

    function buy() 
        public
        payable
        whenNotPaused
    {
        require(msg.value >= 0.0001 ether, InsufficientFunds());
        uint256 tokenId = _nextTokenId++;
        uint256 metadataId = getmetadataId(msg.value);
        require(metadataId > 0 && metadataId <= TOTAL_PICTURES, InsufficientFunds());

        unchecked {
            _totalPayments += msg.value;
            _totalSales++;
        }
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataId.toString());
    }


    function getmetadataId(uint256 currentPayment) private view returns(uint256) {
        uint256 numerator = 90;
        uint256 denominator = 100;

        if (_totalSales > 0) {
            numerator = getNumerator(currentPayment, numerator);
        }

        uint256 initial = 1250;
        uint256 curr = initial;
        uint256 summ;
        uint256[TOTAL_PICTURES] memory arr;

        for(uint256 i = 0; i < TOTAL_PICTURES; i++) {
            curr = curr * numerator / denominator;
            summ += curr;
            arr[i] = curr;
        }

        uint256 random = getRandom(summ);
        uint256 currentSumm;

        for(uint256 i = 0; i < TOTAL_PICTURES; i++) {
            currentSumm += arr[i];

            if (currentSumm >= random) {
                return i + 1;
            }
        }
        return 1;
    }

    function getNumerator(uint256 currentPayment, uint256 numerator) private view returns(uint256) {
        uint256 avg = _totalPayments / _totalSales;
        bool isBonus = currentPayment > avg;
        uint256 rem;

        if (isBonus) {
            rem = currentPayment - avg;
        }
        else {
            rem = avg - currentPayment;
        }
        uint256 avg5p = avg / 20;

        if (rem > avg5p) {
          uint256 coeff = rem * 5 / avg5p;

          if (isBonus) {
            numerator += coeff;
          }
          else {
            if (numerator > coeff) numerator -= coeff;
            else numerator = 10;
          }
        }
        return numerator;
    }

    function getRandom(uint256 N) private view returns (uint256) {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    msg.sender,
                    block.prevrandao // instead of `difficulty` in old versions
                )
            )
        );
        return randomHash % (N + 1); // [0..N]
    }

    // The following functions are overrides required by Solidity.

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
        returns (address)
    {
        return super._update(to, tokenId, auth);
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