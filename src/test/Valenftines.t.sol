// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "src/Valenftines.sol";
import "forge-std/Vm.sol";

contract ContractTest is DSTest {
    Vm vm = Vm(HEVM_ADDRESS);
    Valenftines valenftines;
    uint256 earlymintStartTimestamp = 2; 
    uint256 mintStartTimestamp = 4;
    uint256 mintEndTimestamp = 6;
    bytes32 merkleRoot = 'test'; 

    function setUp() public {
        valenftines = new Valenftines(
            earlymintStartTimestamp,
            mintStartTimestamp,
            mintEndTimestamp,
            merkleRoot
        );
    }

    function testMint() public {
        address mintTo = address(1);
        vm.warp(5);
        valenftines.mint(mintTo, 1, 2, 3);
        assertEq(valenftines.ownerOf(1), mintTo);
    }

    function testMintValentineInfo() public {
        address mintTo = address(1);
        vm.warp(5);
        valenftines.mint(mintTo, 1, 2, 3);

        (uint8 h1, uint8 h2, uint8 h3, uint24 requitedTokenId, address to, address from) = valenftines.valentineInfo(1);
        assertEq(from, address(this));
        assertEq(to, mintTo);
        assertEq(requitedTokenId, 0);
        assertEq(h1, 1);
        assertEq(h2, 2);
        assertEq(h3, 3);
    }

    function testRequitedTransfer() public {
        address mintTo = address(1);
        vm.warp(5);
        valenftines.mint(mintTo, 1, 2, 3);

        vm.prank(mintTo);
        valenftines.transferFrom(mintTo, address(this), 1);
        assertEq(valenftines.ownerOf(1), address(this));

        (uint8 h1, uint8 h2, uint8 h3, uint24 requitedTokenId, address to, address from) = valenftines.valentineInfo(1);
        assertEq(from, address(this));
        assertEq(to, mintTo);
        assertEq(requitedTokenId, 2);
        assertEq(h1, 1);
        assertEq(h2, 2);
        assertEq(h3, 3);
        // check copy
        assertEq(valenftines.ownerOf(2), mintTo);
        assertEq(valenftines.copyOf(2), 1);
        assertEq(valenftines.copyOf(1), 0);

    }

    function testNonRequitedTransfer() public {
        address mintTo = address(1);
        vm.warp(5);
        valenftines.mint(mintTo, 1, 2, 3);

        vm.prank(mintTo);
        valenftines.transferFrom(mintTo, address(2), 1);

        (uint8 h1, uint8 h2, uint8 h3, uint24 requitedTokenId, address to, address from) = valenftines.valentineInfo(1);
        assertEq(from, mintTo);
        assertEq(to, address(2));
        assertEq(requitedTokenId, 0);
        assertEq(h1, 1);
        assertEq(h2, 2);
        assertEq(h3, 3);
    }

    function testTokenURI() public {
        vm.warp(5);
        valenftines.mint(0x8aDc376F33Fd467FdF3293Df4eAe7De6Fd5CcAf1, 1, 2, 3);
        // emit log_string(valenftines.tokenURI(1));

        vm.prank(0x8aDc376F33Fd467FdF3293Df4eAe7De6Fd5CcAf1);
        valenftines.transferFrom(0x8aDc376F33Fd467FdF3293Df4eAe7De6Fd5CcAf1, address(this), 1);
        emit log_string(valenftines.tokenURI(1));
        // emit log_string(string(valenftines.svgImage(1)));
    }
}
