// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import {Valenftines} from "src/Valenftines.sol";
import "forge-std/Vm.sol";
import "src/libraries/ValenftinesDescriptors.sol";
import {ERC721Enumerable} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import 'src/libraries/HexStrings.sol';

contract ContractTest is DSTest {
    Vm vm = Vm(HEVM_ADDRESS);
    Valenftines valenftines;
    uint256 earlymintStartTimestamp = 2; 
    uint256 mintStartTimestamp = 4;
    uint256 mintEndTimestamp = 6;
    bytes32 merkleRoot = 0x070e8db97b197cc0e4a1790c5e6c3667bab32d733db7f815fbe84f5824c7168d;
    address gtapHolder = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    bytes32[] proofArray;
    bytes32 proof = 0x00314e565e0574cb412563df634608d76f5c59d9f817e85966100ec1d48005c0;

    function setUp() public {
        valenftines = new Valenftines(
            earlymintStartTimestamp,
            mintStartTimestamp,
            mintEndTimestamp,
            merkleRoot
        );
        proofArray.push(proof);
        vm.deal(gtapHolder, 1e20);
    }

    function testMint() public {
        address mintTo = address(1);
        vm.warp(mintStartTimestamp + 1);
        valenftines.mint{value: 3e16}(mintTo, 1, 2, 3);
        assertEq(valenftines.ownerOf(1), mintTo);
    }

    function testMintTooEarly() public {
        vm.warp(mintStartTimestamp);
        vm.expectRevert("2");
        valenftines.mint{value: 3e16}(address(1), 1, 2, 3);
    }

    function testMintTooLate() public {
        vm.warp(mintEndTimestamp);
        vm.expectRevert("3");
        valenftines.mint{value: 3e16}(address(1), 1, 2, 3);
    }

    function testMintInvalidHeartType() public {
        vm.warp(mintStartTimestamp + 1);
        vm.expectRevert("7");
        valenftines.mint{value: 3e16}(address(1), 0, 2, 3);
    }

    function testMintInvalidHeartType2() public {
        vm.warp(mintStartTimestamp + 1);
        vm.expectRevert("7");
        valenftines.mint{value: 3e16}(address(1), 1, 24, 3);
    }

    function testMintValentineInfo() public {
        address mintTo = address(1);
        vm.warp(5);
        valenftines.mint{value: 3e16}(mintTo, 1, 2, 3);

        Valentine memory v = valenftines.valentineInfo(1);
        assertEq(v.from, address(this));
        assertEq(v.to, mintTo);
        assertEq(v.requitedTokenId, 0);
        assertEq(v.h1, 1);
        assertEq(v.h2, 2);
        assertEq(v.h3, 3);
    }

    function testGtapMint() public {
        address mintTo = address(1);
        vm.warp(mintStartTimestamp - 1);
        vm.prank(gtapHolder);
        valenftines.gtapMint{value: 15e15}(mintTo, 1, 2, 3, proofArray);
        assertEq(valenftines.ownerOf(1), mintTo);

        Valentine memory v = valenftines.valentineInfo(1);
        assertEq(v.from, gtapHolder);
        assertEq(v.to, mintTo);
        assertEq(v.requitedTokenId, 0);
        assertEq(v.h1, 1);
        assertEq(v.h2, 2);
        assertEq(v.h3, 3);
    }

    function testGtapFailSecondMint() public {
        vm.warp(mintStartTimestamp - 1);
        vm.startPrank(gtapHolder);
        valenftines.gtapMint{value: 15e15}(address(1), 1, 2, 3, proofArray);
        vm.expectRevert("5");
        valenftines.gtapMint{value: 15e15}(address(1), 1, 2, 3, proofArray);
        vm.stopPrank();
    }

    function testGtapFailTooLate() public {
        vm.warp(mintStartTimestamp);
        vm.prank(gtapHolder);
        vm.expectRevert("4");
        valenftines.gtapMint{value: 15e15}(address(1), 1, 2, 3, proofArray);
    }

    function testGtapFailFeeTooLow() public {
        vm.warp(mintStartTimestamp);
        vm.prank(gtapHolder);
        vm.expectRevert("1");
        valenftines.gtapMint{value: 15e15 - 1}(address(1), 1, 2, 3, proofArray);
    }

    function testRequitedTransfer() public {
        address mintTo = address(1);
        vm.warp(5);
        valenftines.mint{value: 3e16}(mintTo, 1, 2, 3);

        vm.prank(mintTo);
        valenftines.transferFrom(mintTo, address(this), 1);
        assertEq(valenftines.ownerOf(1), address(this));

        Valentine memory v = valenftines.valentineInfo(1);
        assertEq(v.from, address(this));
        assertEq(v.to, mintTo);
        assertEq(v.requitedTokenId, 2);
        assertEq(v.h1, 1);
        assertEq(v.h2, 2);
        assertEq(v.h3, 3);
        // check copy
        assertEq(valenftines.ownerOf(2), mintTo);
        assertEq(valenftines.matchOf(2), 1);
        assertEq(valenftines.matchOf(1), 0);

    }

    function testNonRequitedTransfer() public {
        address mintTo = address(1);
        vm.warp(5);
        valenftines.mint{value: 3e16}(mintTo, 1, 2, 3);

        vm.prank(mintTo);
        valenftines.transferFrom(mintTo, address(2), 1);

        Valentine memory v = valenftines.valentineInfo(1);
        assertEq(v.from, mintTo);
        assertEq(v.to, address(2));
        assertEq(v.requitedTokenId, 0);
        assertEq(v.h1, 1);
        assertEq(v.h2, 2);
        assertEq(v.h3, 3);
    }

    function testTokenURI() public {
        vm.warp(5);
        valenftines.mint{value: 3e16}(0x8aDc376F33Fd467FdF3293Df4eAe7De6Fd5CcAf1, 1, 2, 3);
        // emit log_string(valenftines.tokenURI(1));

        vm.prank(0x8aDc376F33Fd467FdF3293Df4eAe7De6Fd5CcAf1);
        valenftines.transferFrom(0x8aDc376F33Fd467FdF3293Df4eAe7De6Fd5CcAf1, address(this), 1);
        // emit log_string(valenftines.tokenURI(1));
        // emit log_string(valenftines.tokenURI(2));
    }

}
