// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "ds-test/test.sol";
import "../KotH.sol";
import "./Hevm.sol";

contract KotHTest is DSTest {
    Hevm vm = Hevm(HEVM_ADDRESS);
    KotH CuT;

    function setUp() public {
        CuT = new KotH();
        // default expiry for KotH is 0, must warp beyond this time
        // to fulfil capture requirement.
        vm.warp(1);
    }

    function testCapture_EqualToCurrent_Reverts() public {
        // first contribution must be greater than 0.
        CuT.capture{value: 1}();

        vm.expectRevert("must contribute more than current king");
        CuT.capture{value: 1}();
    }

    function testCapture_LowerThanCurrent_Reverts() public {
        // first contribution must be greater than 0.
        CuT.capture{value: 2}();

        vm.expectRevert("must contribute more than current king");
        CuT.capture{value: 1}();
    }

    function testCapture_LargerAmount_RecievesExistingFunds() public {
        // setup
        CuT.capture{value: 1}();
        uint256 beforeClaimBalance = address(this).balance;

        // act
        CuT.capture{value: 2}();

        // assert
        assertEq(beforeClaimBalance, address(this).balance + 1);
    }

    function testCapture_PastExpiry_Reverts() public {
        // setup
        CuT.capture{value: 1}();
        vm.warp(20000);

        // act assert
        vm.expectRevert("round has been won");
        CuT.capture{value: 2}();
    }

    function testClaimVictory_AsKing_RecievesBounty() public {
        // setup
        uint256 captureAmount = 2;
        CuT.capture{value: captureAmount}();
        uint256 beforeBalance = address(this).balance;
        vm.warp(20000);

        // act
        CuT.claimVictory();

        // assert
        assertEq(beforeBalance + captureAmount, address(this).balance);
    }

    function testClaimVictory_NotKing_Reverts() public {
        // setup
        CuT.capture{value: 1}();
        vm.warp(20000);

        // act assert
        vm.startPrank(address(1));
        vm.expectRevert("must be king to claim victory");
        CuT.claimVictory();
    }

    fallback() external payable {}
}
