// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {StdUtils} from "../../lib/forge-std/test/StdUtils.t.sol";


contract TestFundMe is Test {
    FundMe public fundMe;

    //First method to add Ether
    // uint256 public constant STARTING_BALANCE = 10 ether;

    uint256 public constant SEND_BALANCE = 0.1 ether;
    address alice = makeAddr("alice");

    function setUp() public {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(alice, 1 ether);
        //Second Method to add Ether
        //vm.deal(alice, STARTING_BALANCE);
    }

    function testMinimunUsd() public {
        uint256 balance = fundMe.MINIMUM_USD();
        assertEq(balance, 5e18);
    }

    function testSendFund() public {
        // first way
        // deal(alice, 1 ether);
        // vm.prank(alice);

        // Second way
        hoax(alice, SEND_BALANCE);

        //Send ETH
        fundMe.fund{value: SEND_BALANCE}();

        uint256 Balance = fundMe.getAddressToAmountFunded(alice);
        assertEq(Balance, SEND_BALANCE);
    }

    function testOwner() public {
        console.log("Owner of Contract:", fundMe.getOwner());
        address owner = fundMe.getOwner();
        console.log("Who Call the function:", msg.sender);
        assertEq(owner, msg.sender);
    }

    function testFailOwner() public {
        console.log("Owner of Contract:", fundMe.getOwner());
        address owner = fundMe.getOwner();
        console.log("Who Call the function:", alice);
        assertEq(owner, alice);
    }

    function testUpdateFundersDataStructure() public {
        vm.prank(alice);
        console.log("Address of Alice Funder:", alice);
        fundMe.fund{value: SEND_BALANCE}();
        address funders = fundMe.getFunders(0);
        console.log("Funder:", funders);
        assertEq(funders, alice);
    }

    function testFailWhoFundIsNotFunder() public {
        vm.prank(alice);
        console.log("Address of Alice:", alice);
        fundMe.fund{value: SEND_BALANCE}();
        address funders = fundMe.getFunders(0);
        console.log("Funder:", funders);
        console.log("Who not Funded:", address(1));
        assertEq(funders, address(1));
    }

    function testVersion() public {
        uint256 Version = fundMe.getVersion();
        console.log("Version Of Contract:", Version);
        console.log("Correct Version Of Contract:", 4);
        assertEq(Version, 4);
    }

    function testCallOnlyOwner() public {
        address owner = fundMe.getOwner();
        console.log("Address of Owner:", owner);
        console.log("Address of Admin:", msg.sender);
        assertEq(owner, msg.sender);
    }

    function testFailWhoCallNotOwner() public {
        address owner = fundMe.getOwner();
        console.log("Address of Owner:", owner);
        console.log("Address of Admin:", msg.sender);
        console.log("Address of Normal User:", alice);

        assertEq(owner, alice);
    }

    function testCheckConversionRate() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testErrorNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(FundMe.NotOwner.selector);
        fundMe.withdraw();
    }

    modifier funded() {
        vm.prank(alice);
        fundMe.fund{value: SEND_BALANCE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(alice);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrewWithSingleFunction() public funded {
        //Arrange
        uint256 BeforeOwnerBalance = fundMe.getOwner().balance;
        console.log("Before Owner Balance:", BeforeOwnerBalance);

        uint256 BeforeFundMeBalance = address(fundMe).balance;
        console.log("Before FundMe Balance:", BeforeFundMeBalance);

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 AfterOwnerBalance = fundMe.getOwner().balance;
        console.log("After Owner Balance:", AfterOwnerBalance);

        uint256 AfterFundMeBalance = address(fundMe).balance;
        console.log("After FundMe Balance:", AfterFundMeBalance);

        assertEq(AfterFundMeBalance, 0);
        assertEq(BeforeFundMeBalance + BeforeOwnerBalance, AfterOwnerBalance);
    }

    function testWithdrewWithMultipleFunction() public funded {
        uint160 StartingNoOfMultipleFunders = 1;
        uint160 TotalNoOfMultipleFunders = 10;

        for (uint160 i = StartingNoOfMultipleFunders; i < TotalNoOfMultipleFunders; i++) {
            hoax(address(i), SEND_BALANCE);
            fundMe.fund{value: SEND_BALANCE}();

            uint256 BeforeOwnerBalance = fundMe.getOwner().balance;
            console.log("Before Owner Balance:", BeforeOwnerBalance);

            uint256 BeforeFundMeBalance = address(fundMe).balance;
            console.log("Before FundMe Balance:", BeforeFundMeBalance);
            vm.startPrank(fundMe.getOwner());
            fundMe.withdraw();

            uint256 AfterOwnerBalance = fundMe.getOwner().balance;
            console.log("After Owner Balance:", AfterOwnerBalance);
             uint256 AfterFundMeBalance = address(fundMe).balance;
            console.log("After FundMe Balance:", AfterFundMeBalance);

            vm.stopPrank();
            
            assert(address(fundMe).balance == 0);
            assertEq(BeforeOwnerBalance + BeforeFundMeBalance, fundMe.getOwner().balance);
        }
    }
}
