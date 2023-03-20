// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC5192} from "./interface/IERC5192.sol";

contract SoulBoundToken is ERC721, Ownable,AccessControl,ERC721URIStorage,IERC5192  {
    using Counters for Counters.Counter;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    string public baseURI;
    bool private isLocked;
    
    event Attest(address indexed to, uint256 indexed tokenId);
    event Revoke(address indexed to, uint256 indexed tokenId);

    error ErrLocked();
    error ErrNotFound();

    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _baseURI
    ) 

    ERC721(_name, _symbol) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setBaseURI(_baseURI);
        isLocked = true;
    }

    modifier checkLock() {
        if (isLocked) revert ErrLocked();
        _;
    }

    function locked(uint256 tokenId) external view returns (bool) {
        if (!_exists(tokenId)) revert ErrNotFound();
        return isLocked;
    }

    function safeMint(address to) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, baseURI);
        emit Attest(to, tokenId);  
    }

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only the owner of the token can burn it.");
        _burn(tokenId);
        emit Revoke(msg.sender, tokenId);
    }


    function _beforeTokenTransfer(address from, address to, uint256 , uint256 ) pure override internal{
        require(from == address(0) || to == address(0), "This a Soulbound token. It cannot be transferred. It can only be burned by the token owner.");
    }


    function approve(address approved, uint256 tokenId) public override checkLock {
        super.approve(approved, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        checkLock
    {
        super.setApprovalForAll(operator, approved);
    }

    function revoke(uint256 tokenId) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
        emit Revoke(ownerOf(tokenId), tokenId);
        _burn(tokenId);
        
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function _burn(uint256 tokenId) internal override(ERC721,ERC721URIStorage) {
        super._burn(tokenId);
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
        virtual
        override(AccessControl,ERC721)
        returns (bool)
    {
        return interfaceId == type(IERC5192).interfaceId
        || super.supportsInterface(interfaceId);
    }
}
