// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "ds-test/test.sol";
import "../KotH.sol";
import "./Hevm.sol";
import "./TestToken.sol";

contract KotHTest is DSTest {
    Hevm vm = Hevm(HEVM_ADDRESS);
    KotH CuT;
    TestToken token;
    uint256 reign;
    event Captured(address indexed king, uint256 indexed amount);

    function setUp() public {
        token = new TestToken();
        reign = 100;
        CuT = new KotH(address(token), reign);
        // default expiry for KotH is 0, must warp beyond this time
        // to fulfil capture requirement.
        vm.warp(1);
    }

    function testCapture_EqualToCurrent_Reverts() public {
        // first contribution must be greater than 0.
        token.mint(address(this), 1);
        token.approve(address(CuT), 1);
        CuT.capture(1);

        token.mint(address(this), 1);
        token.approve(address(CuT), 1);
        vm.expectRevert("must contribute more than current king");
        CuT.capture(1);
    }

    function testCapture_LowerThanCurrent_Reverts() public {
        // first contribution must be greater than 0.
        token.mint(address(this), 3);
        token.approve(address(CuT), 3);
        CuT.capture(3);

        token.mint(address(this), 2);
        token.approve(address(CuT), 2);
        vm.expectRevert("must contribute more than current king");
        CuT.capture(2);
    }

    function testCapture_LargerAmount_RecievesExistingFunds() public {
        // setup
        // first contribution must be greater than 0.
        token.mint(address(this), 1);
        token.approve(address(CuT), 1);
        CuT.capture(1);

        // act
        token.mint(address(this), 2);
        token.approve(address(CuT), 2);
        CuT.capture(2);

        // assert
        assertEq(1, token.balanceOf(address(this)));
    }

    function testCapture_EmitsEvent() public {
        // setup
        token.mint(address(this), 1);
        token.approve(address(CuT), 1);
        CuT.capture(1);

        // act
        token.mint(address(this), 2);
        token.approve(address(CuT), 2);

        // assert
        vm.expectEmit(true, true, false, false);
        emit Captured(address(this), 2);
        CuT.capture(2);
    }

    function testCapture_PastExpiry_Reverts() public {
        // setup
        token.mint(address(this), 1);
        token.approve(address(CuT), 1);
        CuT.capture(1);
        vm.warp(reign + 1);

        // act assert
        token.mint(address(this), 2);
        token.approve(address(CuT), 2);
        vm.expectRevert("round has been won");
        CuT.capture(2);
    }

    function testClaimVictory_AsKing_RecievesBounty() public {
        // setup
        uint256 captureAmount = 2;
        token.mint(address(this), captureAmount);
        token.approve(address(CuT), captureAmount);
        CuT.capture(captureAmount);
        uint256 beforeBalance = token.balanceOf(address(this));
        vm.warp(reign + 1);

        // act
        CuT.claimVictory();

        // assert
        assertEq(beforeBalance + captureAmount, token.balanceOf(address(this)));
    }

    function testClaimVictory_NotKing_Reverts() public {
        // setup
        token.mint(address(this), 1);
        token.approve(address(CuT), 1);
        CuT.capture(1);
        vm.warp(reign);

        // act assert
        vm.startPrank(address(1));
        vm.expectRevert("must be king to claim victory");
        CuT.claimVictory();
    }
}
