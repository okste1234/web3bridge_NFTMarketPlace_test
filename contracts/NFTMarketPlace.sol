// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

error NOT_SELLER();

contract NFTMarketPlace is ERC721, Ownable, ERC721URIStorage {
    uint256 private nextTokenId;

    event PurchaseMade(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    struct Sale {
        address seller;
        string name;
        uint256 price;
        bool isActive;
    }

    mapping(uint256 => Sale) public sales;
    mapping(address => bool) private isSeller;

    constructor(
        address _initialOwner
    ) ERC721("WCXNFT", "WCX") Ownable(_initialOwner) {}

    function addSeller(address _seller) external onlyOwner {
        isSeller[_seller] = true;
    }

    function safeMint(address to, string memory uri) external onlyOwner {
        uint256 _tokenId = nextTokenId++;
        _safeMint(to, _tokenId);
        _setTokenURI(_tokenId, uri);
    }

    function listForSale(
        uint256 tokenId,
        uint256 _price,
        string calldata _name
    ) external {
        require(isSeller[msg.sender], "Caller is not a seller");
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(!sales[tokenId].isActive, "NFT is already listed for sale");
        sales[tokenId] = Sale(msg.sender, _name, _price, true);
    }

    function buy(uint256 tokenId) external payable {
        require(sales[tokenId].isActive, "NFT not listed for sale");
        require(msg.value >= sales[tokenId].price, "Insufficient funds");

        address seller = sales[tokenId].seller;

        payable(seller).transfer(sales[tokenId].price);

        _safeTransfer(seller, msg.sender, tokenId);

        sales[tokenId].isActive = false;

        emit PurchaseMade(msg.sender, tokenId, sales[tokenId].price);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// 1000000000000000000
