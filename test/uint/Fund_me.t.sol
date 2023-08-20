//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe public fundMe;
    address USER = makeAddr("user");
    uint256 public constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 public constant STARTING_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;
    
    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testDemo() public {
        console.log("Hello !");
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerAddress() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testGetVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testCheckConversionRate() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testUpdateFundersDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFundToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCallWithdrew() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrewWithSingleFunction() public funded {
        //Arrange
        uint256 StartingOwnerBalance = fundMe.getOwner().balance;
        uint256 StartingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 EndingOwnerBalance = fundMe.getOwner().balance;
        uint256 EndingFundMeBalance = address(fundMe).balance;
        assertEq(EndingFundMeBalance, 0);
        assertEq(StartingOwnerBalance + StartingFundMeBalance, EndingOwnerBalance);
    }

    function testWithdrewWithMultipleFunction() public funded {
        //Arrange
        uint160 StartingNoOfMultipleFunders = 1;
        uint160 TotalNoOfMultipleFunders = 10;
        for (uint160 i = StartingNoOfMultipleFunders; i < TotalNoOfMultipleFunders; i++) {
            /**
             * vm.prank() + vm.deal() = hoax()
             */
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();

            uint256 StartingOwnerBalance = fundMe.getOwner().balance;
            uint256 StartingFundMeBalance = address(fundMe).balance;
            vm.startPrank(fundMe.getOwner());
            fundMe.withdraw();
            vm.stopPrank();

            assert(address(fundMe).balance == 0);
            assertEq(StartingFundMeBalance + StartingOwnerBalance, fundMe.getOwner().balance);
        }
    }
}
