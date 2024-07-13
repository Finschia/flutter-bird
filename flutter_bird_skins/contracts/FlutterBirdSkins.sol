// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/sstore2/SSTORE2.sol";
import "./lib/Memory.sol";

struct Token {
    uint256 bytesLength;
    address[] addresses;
}

contract FlutterBirdSkins is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 private _maxSupply = 1000;
    uint256 private _mintPrice = 0.01 ether;

    mapping(uint256 => Token) private tokens;

    constructor() ERC721("FlutterBirdSkins", "FBS") {}

    event SkinMinted(uint256 indexed tokenId);

    error TokenDoesNotExist();

    function mintSkin(uint256 newTokenId) public payable {
        require(newTokenId < _maxSupply, "invalid tokenId. must be #999");
        require(msg.value >= _mintPrice, "insufficient funds");

        _safeMint(msg.sender, newTokenId);

        emit SkinMinted(newTokenId);
    }

    /**
     * @notice returns a list of tokenIds that are owned by the given address
   */
    function getTokensForOwner(address _owner) public view returns (uint[] memory) {
        uint[] memory _tokensOfOwner = new uint[](ERC721.balanceOf(_owner));
        uint i;

        for (i = 0; i < ERC721.balanceOf(_owner); i++) {
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
        }
        return (_tokensOfOwner);
    }

    /**
     * @notice returns a list of boolean values indicating whether the skin with that index has been minted already.
   */
    function getMintedTokenList() public view returns (bool[] memory) {
        bool[] memory _unmintedTokes = new bool[](_maxSupply);
        uint i;

        for (i = 0; i < _maxSupply; i++) {
            if (_exists(i)) {
                _unmintedTokes[i] = true;
            }
        }
        return _unmintedTokes;
    }

    function appendUri(uint256 tokenId, bytes[] calldata values) public onlyOwner {
        for (uint256 i = 0; i < values.length; i++) {
            tokens[tokenId].addresses.push(SSTORE2.write(values[i]));
            tokens[tokenId].bytesLength += values[i].length;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        bytes memory uri = new bytes(tokens[tokenId].bytesLength);
        (uint256 uriAddr, ) = Memory.fromBytes(uri);
        for (uint256 i = 0; i < tokens[tokenId].addresses.length; i++) {
            bytes memory data = SSTORE2.read(tokens[tokenId].addresses[i]);
            (uint256 dataAddr, uint256 dataLen) = Memory.fromBytes(data);
            Memory.copy(dataAddr, uriAddr, dataLen);
            uriAddr += dataLen;
        }
        return string(uri);
    }

    // function setTokenUri(uint256 tokenId, string memory _tokenURI) public {
    //     require(
    //         _isApprovedOrOwner(_msgSender(), tokenId),
    //         "ERC721: transfer caller is not owner nor approved"
    //     );
    //     _setTokenURI(tokenId, _tokenURI);
    // }

    // function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    //     require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
    //     _tokenURIs[tokenId] = _tokenURI;
    // }
}
