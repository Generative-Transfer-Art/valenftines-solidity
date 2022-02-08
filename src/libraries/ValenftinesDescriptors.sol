// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Base64} from "base64/base64.sol";

import {HexStrings} from "./HexStrings.sol";

import {Valenftines, Valentine} from 'src/Valenftines.sol';

library ValenftinesDescriptors {
    function tokenURI(uint256 id, address valenftines) public view returns (string memory) {
        (, , , uint24 requitedTokenId, address to, address from) = Valenftines(valenftines).valentineInfo(id);
        uint256 copy = Valenftines(valenftines).matchOf(id);
        return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{"name":"'
                                    '#',
                                    Strings.toString(id),
                                    _tokenName(id, requitedTokenId, valenftines),
                                    '", "description":"',
                                    'Valenftines are on-chain art for friends and lovers. They display the address of the sender and recipient along with messages picked by the minter. When the Valenftine is transferred back to the most recent sender, love is REQUITED and the NFT transforms and clones itself so both parties have a copy.',
                                    '", "attributes": [',
                                    tokenAttributes(id, requitedTokenId, to, from),
                                    ']',
                                    ', "image": "'
                                    'data:image/svg+xml;base64,',
                                    Base64.encode(copy > 0 ? svgImage(copy, valenftines) : svgImage(id, valenftines)),
                                    '"}'
                                )
                            )
                        )
                )
            );
    }

    function _tokenName(uint256 tokenId, uint24 requitedTokenId, address valenftines) private view returns(string memory){
        uint256 copy = Valenftines(valenftines).matchOf(tokenId);
        return requitedTokenId == 0 && copy == 0 ?
                '' : 
                string(
                    abi.encodePacked(
                        ' (match of #',
                        copy == 0 ? 
                            Strings.toString(requitedTokenId)
                            : Strings.toString(copy) 
                        , 
                        ')'
                    )
                );
    }

    function tokenAttributes(uint256 tokenId, uint24 requitedTokenId, address to, address from) public view returns(string memory) {
        return string(
            abi.encodePacked(
                '{',
                '"trait_type": "Love",', 
                '"value":"',
                requitedTokenId == 0 ? 'UNREQUITED' : 'REQUITED',
                '"}',
                requitedTokenId == 0 ? '' : string(abi.encodePacked(
                    ', {',
                    '"trait_type": "Speed",', 
                    '"value":"',
                    isFast(to, from) ? 'fast' : 'slow',
                    '"}',
                    ', {',
                    '"trait_type": "bloom",', 
                    '"value":"',
                    isSmall(to, from) ? 'small' : 'large',
                    '"}'
                ))
            )
        );
    }

    /// TOKEN ART 

    function svgImage(
        uint256 tokenId, 
        address valenftines
    ) 
        public view returns (bytes memory)
    {
        (, , , uint24 requitedTokenId, address to, address from) = Valenftines(valenftines).valentineInfo(tokenId);
        return abi.encodePacked(
            '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="400" height="400" class="container" ',
	            'viewBox="0 0 400 400" style="enable-background:new 0 0 400 400;" xml:space="preserve">',
            styles(tokenId),
            '<defs>',
                '<g id="heart">',
                    '<path d="M79.2-43C71.2-78.4,30.8-84.9,5-60.9c-2.5,2.3-6.4,2.1-8.8-0.3c-25-25.9-75.1-15-76.7,28.2C-82.6,22.3-14,75.2,1.5,75.1C17.3,75.1,91.3,10.7,79.2-43z"/>',
                '</g>',
                '<radialGradient id="rainbow" cx="58%" cy="50%" fr="0%" r="',
                isSmall(to, from) ? '50' : '300',
                '%" spreadMethod="repeat">',
                '<stop offset="0%" style="stop-color:#ffb9b9" />',
                '<stop offset="30%" style="stop-color:#fff7ad" />',
                '<stop offset="50%" style="stop-color:#97fff3" />',
                '<stop offset="80%" style="stop-color:#cfbcff" />',
                '<stop offset="100%" style="stop-color:#ffb9b9" />',
                '</radialGradient>',
            '</defs>',

            '<rect ',
            requitedTokenId != 0 ? 'fill="url(#rainbow)"' : 'class="background"',
            ' width="400" height="400"/>',

            '<animate xlink:href="#rainbow" ',
                'attributeName="fr" ',
                'dur="',
                isFast(to, from) ? '6' : '20',
                's" ',
                'values="0%;',
                isSmall(to, from) ? '50' : '300',
                '%" ',
                'repeatCount="indefinite"',
            '/>',

            '<animate xlink:href="#rainbow" ',
                'attributeName="r" ',
                'dur="',
                isFast(to, from) ? '6' : '20',
                's" ',
                'values="',
                isSmall(to, from) ? '50%;100%' : '300%;600%',
                '" ',
                'repeatCount="indefinite"',
            '/>',
           
            heartsSVGs(tokenId, valenftines),
            '</svg>'
        );
    }

    function styles(uint256 tokenId) private pure returns(bytes memory) {
        return abi.encodePacked(
            '<style type="text/css">',
                '.container{font-size:28px; font-family: monospace, monospace; font-weight: 500; letter-spacing: 2px;}',
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
                '.background{fill:#',
                backgroundColor(tokenId),
                ';}',
            '</style>'
        );
    }

    function backgroundColor(uint256 tokenId) private pure returns(string memory) {
        uint i = tokenId % 6;
        return (i < 1 ? 'FFDBDB' : 
            ( i < 2 ? 'A2E2FF' : 
                (i < 3 ? 'E8D1FF' : 
                    (i < 4 ? 'FFF6AE' : 
                        (i < 5 ? 'FFD7AF' : 'C8FFDF')))));
    }

    function heartsSVGs(
        uint256 tokenId,
        address valenftines
    ) 
        public view returns (bytes memory)
    {
        (uint8 h1, uint8 h2, uint8 h3, uint24 requitedTokenId, address to, address from) = Valenftines(valenftines).valentineInfo(tokenId);
        // bool requited = requitedTokenId != 0;
        return abi.encodePacked(
            addrHeart(true, tokenId, requitedTokenId != 0, from),

            addrHeart(false, tokenId, requitedTokenId != 0, to),

            textHeart(1, h1, tokenId, requitedTokenId != 0, to, from),
            textHeart(2, h2, tokenId, requitedTokenId != 0, from, to),
            textHeart(3, h3, tokenId, requitedTokenId != 0, address(this), from),

            emptyHeart(true, tokenId, requitedTokenId != 0, to),
            emptyHeart(false, tokenId, requitedTokenId != 0, from)
        );
    }

    function addrHeart(bool first, uint256 tokenId, bool requited, address account) private pure returns (bytes memory) {
        string memory xy = first ? '93,96' : '236,209';
        return abi.encodePacked(
            '<g transform="translate(',
            xy,
            ') rotate(',
            rotation(tokenId + (first ? 100 : 101)),
            ')">',
                '<use xlink:href="#heart" class="whiteheart',
                requited ? '' : 'outline',
                '"/>',
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