// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity 0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

contract SeaWarriors is ERC721, ERC721URIStorage, ERC721Pausable, Ownable, ERC721Burnable, ReentrancyGuard {
    using Strings for uint256;

    event Purchase(address indexed buyer, uint256 tokenId, uint256 metadataId);

    error InsufficientFunds();
    error InsufficientFundsToBuyNew(address buyer, uint256 funds);
    error NotEnoughBalance();
    error WrongMetadataId(uint256 id);
    error AlreadyOwns(address buyer, uint256 metadataId);
    error AlreadyCompleted(address buyer);
    error WithdrawFailed(uint256 amount);
    error WithdrawToArtistFailed(address artist, uint256 amount);
    error ArtistShouldBeEOA();
    error OwnerShouldNotBeArtist();

    address public _artist;

    uint256 private _nextTokenId;
    uint256 private _totalPayments;
    uint256 private _totalSales;
    uint256 private _seed;

    // Gas efficiency: constant variables do not occupy a storage slot, as their values are embedded directly in the bytecode
    uint256 public constant TOTAL_PICTURES = 13;
    uint256 private constant MIN_NUMERATOR = 10;
    uint256 private constant MAX_NUMERATOR = 1000;
    uint256 private constant INITIAL_NUMERATOR = 50;

    mapping(address => mapping(uint256 => bool)) internal _hasItem; // buyer -> metadataId -> has
    mapping(uint256 => uint256) internal _metadataOf; // tokenId -> metadataId
    mapping(address => uint256) internal _itemsPurchased; // buyer -> how many items

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
        require(!_hasItem[to][metadataId], AlreadyOwns(to, metadataId));
        require(metadataId > 0 && metadataId <= TOTAL_PICTURES, WrongMetadataId(metadataId));

        uint256 tokenId = _nextTokenId++;
        _metadataOf[tokenId] = metadataId;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataId.toString());
        return tokenId;
    }

    function setArtist(address artist) public onlyOwner {
        require(artist.code.length == 0, ArtistShouldBeEOA());
        require(artist != owner(), OwnerShouldNotBeArtist());
        _artist = artist;
    }

    function buy() 
        public
        payable
        whenNotPaused
        nonReentrant
        returns(uint256)
    {
        require(_itemsPurchased[msg.sender] < TOTAL_PICTURES, AlreadyCompleted(msg.sender));
        require(msg.value >= 0.0001 ether, InsufficientFunds());
        uint256 tokenId = _nextTokenId++;
        uint256 metadataId = getMetadataId(msg.value, _totalPayments, _totalSales);
        console.log("original metadataId = ", metadataId);
        require(metadataId > 0 && metadataId <= TOTAL_PICTURES, WrongMetadataId(metadataId));

        while (_hasItem[msg.sender][metadataId]) {
            if (--metadataId == 0) {
                revert InsufficientFundsToBuyNew(msg.sender, msg.value);
            }
        }
        console.log("Applied metadataId = ", metadataId);
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
        uint256 numerator = INITIAL_NUMERATOR;
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
        require(balance > 1, NotEnoughBalance());
        address ownerAddr = owner();
        bool successOwner;

        if (_artist == address(0)) {
            (successOwner,) = ownerAddr.call{value: balance}("");
        }
        else {
            unchecked {
                balance /= 2;
            }
            (successOwner,) = ownerAddr.call{value: balance}("");
            (bool successArtist, ) = _artist.call{value: balance}("");
            require(successArtist, WithdrawToArtistFailed(_artist, balance));
        }
        require(successOwner, WithdrawFailed(balance));
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
            _itemsPurchased[to]++;
        }
        else { // burn
            delete _metadataOf[tokenId];
            _itemsPurchased[from]--;
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

contract TestSeaWarriors is SeaWarriors {
    constructor(address initialOwner) SeaWarriors(initialOwner) {}

    function getMetadataOf(uint256 tokenId) public view returns (uint256) {
        return _metadataOf[tokenId];
    }

    function getHasItem(address holder, uint256 item) public view returns (bool) {
        return _hasItem[holder][item];
    }

    function getItemsPurchased(address by) public view returns (uint256) {
        return _itemsPurchased[by];
    }

    function callGetNumerator(
        uint256 currentPayment,
        uint256 averagePayment,
        uint256 numerator
    ) public view returns (uint256) {
        return super.getNumerator(currentPayment, averagePayment, numerator);
    }
}
