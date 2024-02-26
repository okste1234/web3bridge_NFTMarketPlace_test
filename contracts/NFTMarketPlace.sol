// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

error NOT_A_SELLER();
error INSUFFICIENT_FUND();
error NOT_LISTED();
error NFT_NOT_FOUND();
error ALREADY_LISTED();
error NOT_OWNER();

contract NFTMarketPlace is ERC721, Ownable, ERC721URIStorage {
    uint256 nextTokenId;

    struct Transaction {
        string description;
        uint256 amount;
        address seller;
        bool isListed;
    }

    mapping(uint256 => Transaction) public transaction;

    mapping(address => bool) private validSeller;

    constructor(address _owner) ERC721("WCXNFT", "WCX") Ownable(_owner) {}

    event successful(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount
    );

    function createSale(
        uint256 _tokenId,
        string memory _description,
        uint256 _amount
    ) external {
        if (!validSeller[msg.sender]) {
            revert NOT_A_SELLER();
        }

        if (msg.sender != ownerOf(_tokenId)) {
            revert NOT_OWNER();
        }

        if (transaction[_tokenId].isListed) {
            revert ALREADY_LISTED();
        }

        Transaction storage newSale = transaction[_tokenId];

        newSale.amount = _amount;
        newSale.isListed = true;
        newSale.description = _description;
        newSale.seller = msg.sender;
    }

    function buy(uint256 tokenId) external payable {
        if (tokenId > nextTokenId) {
            revert NFT_NOT_FOUND();
        }

        if (!transaction[tokenId].isListed) {
            revert NOT_LISTED();
        }

        if (msg.value < transaction[tokenId].amount) {
            revert INSUFFICIENT_FUND();
        }

        address sellerAddress = transaction[tokenId].seller;

        payable(sellerAddress).transfer(transaction[tokenId].amount);

        _safeTransfer(sellerAddress, msg.sender, tokenId);

        transaction[tokenId].isListed = false;

        emit successful(msg.sender, tokenId, transaction[tokenId].amount);
    }

    function addSeller(address _seller) external onlyOwner {
        validSeller[_seller] = true;
    }

    function safeMint(address _to, string memory _uri) external onlyOwner {
        uint256 _tokenId = nextTokenId++;
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
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
