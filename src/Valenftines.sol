// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Base64} from "base64/base64.sol";

import {HexStrings} from "src/libraries/HexStrings.sol";

/// Reverts
/// 1 - value less than mint fee
/// 2 - mint started yet 
/// 3 - mint ended
contract Valenftines is ERC721, Ownable {
    struct Valentine {
        uint8 h1;
        uint8 h2;
        uint8 h3;
        uint24 requitedTokenId;
        address to;
        address from;
    }

    uint256 earlymintStartTimestamp; 
    uint256 mintStartTimestamp;
    uint256 mintEndTimestamp;
    mapping(uint256 => Valentine) public valentineInfo;
    mapping(uint256 => uint256) public copyOf;
    mapping(uint8 => uint8) public mintCost;

    uint24 private _nonce;

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        
        // Valentine storage v = valentineInfo[id];
        return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{"name":"'
                                    '#',
                                    Strings.toString(id),
                                    _tokenName(id),
                                    '", "description":"',
                                    'Valenftines are on-chain art for friends and lovers. They display the address of the sender and recipient along with messages picked by the minter. When the Valenftine is transferred back to the most recent sender, love is REQUITED and the NFT transforms and clones itself so both parties have a copy.',
                                    '", "attributes": [',
                                    tokenAttributes(id),
                                    ']',
                                    ', "image": "'
                                    'data:image/svg+xml;base64,',
                                    Base64.encode(svgImage(id)),
                                    '"}'
                                )
                            )
                        )
                )
            );
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
        if (v.requitedTokenId == 0 && copyOf[id] == 0){
            if(to == v.from){
                _mint(from, ++_nonce);
                v.requitedTokenId = _nonce;
                copyOf[_nonce] = id;
            } else {
                v.from = from;
                v.to = to;
            }
        }
    }

    /// Token metadata 

    function _tokenName(uint256 tokenId) private view returns(string memory){
        uint256 copy = copyOf[tokenId];
        uint24 requitedId = valentineInfo[tokenId].requitedTokenId;
        return requitedId == 0 ?
                '' : 
                string(
                    abi.encodePacked(
                        ' (requited love from #',
                        copy == 0 ? 
                            Strings.toString(requitedId)
                            : Strings.toString(copy) 
                        , 
                        ')'
                    )
                );
    }

    function tokenAttributes(uint256 tokenId) public view returns(string memory) {
        Valentine memory v = valentineInfo[tokenId];
        return string(
            abi.encodePacked(
                '{',
                '"trait_type": "Love",', 
                '"value":"',
                valentineInfo[tokenId].requitedTokenId == 0 ? 'UNREQUITED' : 'REQUITED',
                '"}',
                valentineInfo[tokenId].requitedTokenId == 0 ? '' :
                ', {',
                '"trait_type": "Speed",', 
                '"value":"',
                isFast(v.to, v.from) ? 'fast' : 'slow',
                '"}',
                ', {',
                '"trait_type": "bloom",', 
                '"value":"',
                isSmall(v.to, v.from) ? 'small' : 'large',
                '"}'
            )
        );
    }

    /// TOKEN ART 

    function svgImage(uint256 tokenId) public view returns (bytes memory){
        Valentine memory v = valentineInfo[tokenId];
        return abi.encodePacked(
            '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="400" height="400" class="container" ',
	            'viewBox="0 0 400 400" style="enable-background:new 0 0 400 400;" xml:space="preserve">',
            '<style type="text/css">',
                '.container{margin: 60px auto; font-size:28px; font-family: monospace, monospace; font-weight: 500; letter-spacing: 2px;}',
                '.whitetext{fill:#ffffff; text-anchor:middle;}',
                '.blacktext{fill:#000000; text-anchor:middle;}',
                '.pinktext{fill:#FA0F95; text-anchor:middle;}',
                '.whiteheart{fill:#ffffff;}',
                '.whiteheartoutline{fill:#ffffff; stroke: #000000; stroke-width: 6px;}',
                '.black{fill:#000000;}',
                '.pink{fill:#FFC9DF;}',
                '.blue{fill:#A2E2FF;}',
                '.orange{fill:#FFCC99;}',
                '.green{fill:#A4FFCA;}',
                '.purple{fill:#DAB5FF;}',
                '.yellow{fill:#FFF6AE;}',
                '.lightpink{fill:#FFDBDB;}',
            '</style>',
            '<defs>',
                '<g id="heart">',
                    '<path d="M79.2-43C71.2-78.4,30.8-84.9,5-60.9c-2.5,2.3-6.4,2.1-8.8-0.3c-25-25.9-75.1-15-76.7,28.2C-82.6,22.3-14,75.2,1.5,75.1C17.3,75.1,91.3,10.7,79.2-43z"/>',
                '</g>',
                '<radialGradient id="rainbow" cx="58%" cy="50%" fr="0%" r="',
                isSmall(v.to, v.from) ? '50' : '300',
                '%" spreadMethod="repeat">',
                '<stop offset="0%" style="stop-color:#ffb9b9" />',
                '<stop offset="30%" style="stop-color:#fff7ad" />',
                '<stop offset="50%" style="stop-color:#97fff3" />',
                '<stop offset="80%" style="stop-color:#cfbcff" />',
                '<stop offset="100%" style="stop-color:#ffb9b9" />',
                '</radialGradient>',
            '</defs>',

            '<rect fill="url(#rainbow)" width="400" height="400"/>',

            '<animate xlink:href="#rainbow" ',
                'attributeName="fr" ',
                'dur="',
                isFast(v.to, v.from) ? '6' : '20',
                's" ',
                'values="0%;',
                isSmall(v.to, v.from) ? '50' : '300',
                '%" ',
                'repeatCount="indefinite"',
            '/>',

            '<animate xlink:href="#rainbow" ',
                'attributeName="r" ',
                'dur="',
                isFast(v.to, v.from) ? '6' : '20',
                's" ',
                'values="',
                isSmall(v.to, v.from) ? '50%;100%' : '300%;600%',
                '" ',
                'repeatCount="indefinite"',
            '/>',
           
            heartsSVGs(tokenId),
            '</svg>'
        );
    }

    function heartsSVGs(uint256 tokenId) private view returns (bytes memory){
        Valentine memory v = valentineInfo[tokenId];
        bool requited = v.requitedTokenId != 0;
        return abi.encodePacked(
            addrHeart(true, tokenId, requited, v.from),

            addrHeart(false, tokenId, requited, v.to),

            textHeart(1, v.h1, tokenId, requited, v.to, v.from),
            textHeart(2, v.h2, tokenId, requited, v.from, v.to),
            textHeart(3, v.h3, tokenId, requited, address(this), v.from),

            emptyHeart(true, tokenId, requited, v.to),
            emptyHeart(false, tokenId, requited, v.from)
        );
    }

    function addrHeart(bool first, uint256 tokenId, bool requited, address account) public pure returns (bytes memory) {
        string memory xy = first ? '93,96' : '236,209';
        return abi.encodePacked(
            '<g transform="translate(',
            xy,
            ') rotate(',
            rotation(tokenId + (first ? 100 : 101)),
            ')">',
                '<use xlink:href="#heart" class="whiteheart"/>',
                '<text class="',
                requited ? 'pinktext' : 'blacktext',
                '">',
                    '<tspan x="0" y="-10">',
                    HexStrings.partialHexString(uint160(account), 4, 40),
                    '</tspan>',
                '</text>',
            '</g>'
        );
    }

    function textHeart(uint256 index, uint8 heartType, uint256 tokenId, bool requited, address addr1, address addr2) private pure returns (bytes memory) {
        string memory xy = (index < 2 ? '327,62' :
                                index < 3 ? '102,325' : '340,344');
        return abi.encodePacked(
            '<g transform="translate(',
            xy,
            ') rotate(',
            rotation(tokenId + 101 + index),
            ')">',
                '<use xlink:href="#heart" class="',
                requited ? heartColorClass(addr1, addr2) : 'black',
                '"/>',
                '<text class="',
                requited ? 'pinktext' : 'whitetext',
                '">',
                    heartMessageTspans(heartType),
                '</text>',
            '</g>'
        );
    }

    function heartMessageTspans(uint8 heartType) private pure returns(bytes memory){
        return (heartType < 2 ? gm() :
                    (heartType < 3 ? toTheMoon() : bestFren()));
    }

    function emptyHeart(bool first, uint256 tokenId, bool requited, address account) private view returns (bytes memory) {
        string memory xy = first ? '-40,210' : '460,190';
        return abi.encodePacked(
            '<g transform="translate(',
            xy,
            ') rotate(',
            rotation(tokenId + (first ? 104 : 105)),
            ')">',
                '<use xlink:href="#heart" class="',
                requited ? heartColorClass(account, address(this)) : 'black',
                '"/>',
            '</g>'
        );
    }

    function rotation(uint256 n) private pure returns (string memory) {
        uint256 r = n % 30;
        bool isPos = (n % 2) > 0 ? true : false;
        return string(
            abi.encodePacked(
                isPos ? '' : '-',
                Strings.toString(r)
            )
        );
    }

    function heartColorClass(address addr1, address addr2) private pure returns(string memory){
        uint256 i = numberFromAddresses(addr1, addr2, 100) % 6;
        return (i < 1 ? 'pink' : 
            (i < 2 ? 'blue' : 
                (i < 3 ? 'orange' : 
                    (i < 4 ? 'green' : 
                        (i < 5 ? 'purple' : 'yellow')))));

    }

    function isFast(address addr1, address addr2) private pure returns(bool){
        // flip addresses so possible but rare to be fast and small 
        return numberFromAddresses(addr2, addr1, 100) < 21;
    }

    function isSmall(address addr1, address addr2) private pure returns(bool){
        return numberFromAddresses(addr1, addr2, 100) < 21;
    }

    // gives a number from address where 
    // numberFromAddresses(addr1, addr2, mod) != numberFromAddresses(addr2, addr1, mod)
    function numberFromAddresses(address addr1, address addr2, uint256 mod) private pure returns(uint256) {
        return ((uint160(addr1) % 201) + (uint160(addr2) % 100)) % mod;
    } 

    function gm() private pure returns(bytes memory){
        return oneLineText("GM");
    }

    function zeroXZeroX() private pure returns(bytes memory){
        return oneLineText("0x0x");
    }

    function wagmi() private pure returns(bytes memory){
        return oneLineText("WAGMI");
    }
    
    function bullishForYou() private pure returns(bytes memory){
        return twoLineText("BULLISH", "4YOU");
    }

    function beMine() private pure returns(bytes memory){
        return twoLineText("BE", "MINE");
    }

    function toTheMoon() private pure returns(bytes memory){
        return twoLineText("2THE", "MOON");
    }

    function coolCat() private pure returns(bytes memory){
        return twoLineText("COOL", "CAT");
    }

    function cutiePie() private pure returns(bytes memory){
        return twoLineText("CUTIE", "PIE");
    }

    function bestFren() private pure returns(bytes memory){
        return twoLineText("BEST", "FREN");
    }

    function bigFan() private pure returns(bytes memory){
        return twoLineText("BIG", "FAN");
    }
    
    function coinBae() private pure returns(bytes memory){
        return twoLineText("COIN", "BAE");
    }

    function sayIDAO() private pure returns(bytes memory){
        return twoLineText("SAY I", "DAO");
    }

    function myDegen() private pure returns(bytes memory){
        return twoLineText("MY", "DEGEN");
    }

    function payMyTaxes() private pure returns(bytes memory){
        return twoLineText("PAY MY", "TAXES");
    }

    function upOnly() private pure returns(bytes memory){
        return twoLineText("UP", "ONLY");
    }

    function lilMfer() private pure returns(bytes memory){
        return twoLineText("LIL", "MFER");
    }

    function onboardMe() private pure returns(bytes memory){
        return twoLineText("ONBOARD", "ME");
    }

    function letsMerge() private pure returns(bytes memory){
        return twoLineText("LETS", "MERGE");
    }

    function hodlMe() private pure returns(bytes memory){
        return twoLineText("HODL", "ME");
    }

    function looksRare() private pure returns(bytes memory){
        return twoLineText("LOOKS", "RARE");
    }

    function wenRing() private pure returns(bytes memory){
        return twoLineText("WEN", "RING");
    }

    function simpForYou() private pure returns(bytes memory){
        return twoLineText("SIMP", "4U");
    }

    function idMintYou() private pure returns(bytes memory){
        return threeLineText('ID', 'MINT', 'YOU');
    }

    function oneLineText(string memory text) private pure returns(bytes memory){
        return abi.encodePacked(
            '<tspan x="0" y="-10">',
            text,
            '</tspan>'
        );
    }

    function twoLineText(string memory line1, string memory line2) private pure returns(bytes memory){
        return abi.encodePacked(
            '<tspan x="0" y="-15">',
            line1,
            '</tspan>',
            '<tspan x="0" y="20">',
            line2,
            '</tspan>'
        );
    }

    function threeLineText(string memory line1, string memory line2, string memory line3) private pure returns(bytes memory){
        return abi.encodePacked(
            '<tspan x="0" y="-25">',
            line1,
            '</tspan>',
            '<tspan x="0" y="10">',
            line2,
            '</tspan>',
            '<tspan x="0" y="45">',
            line3,
            '</tspan>'
        );
    }
}
