// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ValenftinesDescriptors} from "src/libraries/ValenftinesDescriptors.sol";

struct Valentine {
    uint8 h1;
    uint8 h2;
    uint8 h3;
    uint24 requitedTokenId;
    address to;
    address from;
}

interface IValenftines {
    function valentineInfo(uint256 tokenId) external returns (
        uint8 h1,
        uint8 h2,
        uint8 h3,
        uint24 requitedTokenId,
        address to,
        address from
    );

    function matchOf(uint256 tokenId) external returns (uint256);
}

/// Reverts
/// 1 - value less than mint fee
/// 2 - mint started yet 
/// 3 - mint ended
contract Valenftines is ERC721, Ownable, IValenftines {
    uint256 earlymintStartTimestamp; 
    uint256 mintStartTimestamp;
    uint256 mintEndTimestamp;
    mapping(uint256 => Valentine) public valentineInfo;
    mapping(uint256 => uint256) public matchOf;
    mapping(uint8 => uint8) public mintCost;

    uint24 private _nonce;

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        ValenftinesDescriptors.tokenURI(id, this);
        // Valentine storage v = valentineInfo[id];
        // return string(
        //         abi.encodePacked(
        //             'data:application/json;base64,',
        //                 Base64.encode(
        //                     bytes(
        //                         abi.encodePacked(
        //                             '{"name":"'
        //                             '#',
        //                             Strings.toString(id),
        //                             _tokenName(id),
        //                             '", "description":"',
        //                             'Valenftines are on-chain art for friends and lovers. They display the address of the sender and recipient along with messages picked by the minter. When the Valenftine is transferred back to the most recent sender, love is REQUITED and the NFT transforms and clones itself so both parties have a copy.',
        //                             '", "attributes": [',
        //                             tokenAttributes(id),
        //                             ']',
        //                             ', "image": "'
        //                             'data:image/svg+xml;base64,',
        //                             Base64.encode(svgImage(id)),
        //                             '"}'
        //                         )
        //                     )
        //                 )
        //         )
        //     );
    }

    constructor(
        uint256 _earlymintStartTimestamp, 
        uint256 _mintStartTimestamp, 
        uint256 _mintEndTimestamp
    ) 
        ERC721("Valenftines", "GTAP3")
    {
        earlymintStartTimestamp = _earlymintStartTimestamp;
        mintStartTimestamp = _mintStartTimestamp;
        mintEndTimestamp = _mintEndTimestamp;
    }

    // Mint

    function mint(address to, uint8 h1, uint8 h2, uint8 h3) payable external returns(uint256 id) {
        require(heartMintCostWei(h1) + heartMintCostWei(h2) + heartMintCostWei(h3) <= msg.value, '1');
        require(block.timestamp > mintStartTimestamp, '2');
        require(block.timestamp < mintEndTimestamp, '3');
        
        id = ++_nonce;
        Valentine storage v = valentineInfo[id];
        v.from = msg.sender;
        v.to = to;
        v.h1 = h1;
        v.h2 = h2;
        v.h3 = h3;
        _safeMint(to, id);
    }

    function heartMintCostWei(uint8 heartType) public pure returns(uint256) {
        return (heartType < 11 ? 1e16 : 
            (heartType < 18 ? 2e16 : 
                (heartType < 23 ? 1e17 : 1e18)));
    }

    /// Transfer

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        _beforeTransfer(from, to, id);
        super.transferFrom(from, to, id);
    } 

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        _beforeTransfer(from, to, id);
        super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual override {
        _beforeTransfer(from, to, id);
        super.safeTransferFrom(from, to, id, data);
    }

    function _beforeTransfer(
        address from,
        address to,
        uint256 id
    ) private {
        Valentine storage v = valentineInfo[id];
        if (v.requitedTokenId == 0 && matchOf[id] == 0){
            if(to == v.from){
                _mint(from, ++_nonce);
                v.requitedTokenId = _nonce;
                matchOf[_nonce] = id;
            } else {
                v.from = from;
                v.to = to;
            }
        }
    }

    /// Token metadata 

    
}
