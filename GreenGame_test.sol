pragma solidity 0.8.13;
import "remix_tests.sol";
import "remix_accounts.sol";
import "GreenGame.sol";

contract GreenGameTest is GreenGame {
    address testCharity;
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;
    address acc5;
    address acc6;
    address acc7;
    address acc8;

    function beforeAll() public {
        // game = new GreenGame();
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
        acc5 = TestsAccounts.getAccount(5);
        acc6 = TestsAccounts.getAccount(6);
        acc7 = TestsAccounts.getAccount(7);
        acc8 = TestsAccounts.getAccount(8);
        testCharity = TestsAccounts.getAccount(9);
    }

    function checkInitialState1() public { Assert.equal(acc0, owner, "acc0 is the owner"); }
    function checkInitialState2() public { Assert.equal(charityAddress, owner, "charity address should be equal to owner address"); }
    function checkInitialState3() public { Assert.equal(rootAddress, owner, "root address should be equal to owner address"); }
    function checkInitialState4() public { Assert.equal(getTablesCount(), 11, "we should have 10 tables + 1 root tabled indexed as a 0"); }
    function checkInitialState5() public { Assert.equal(getTableThreshold(0), 0 ether, "[0] threshold should be equal to 0 BSC"); }
    function checkInitialState6() public { Assert.equal(getTableThreshold(1), 1 ether / 10, "[1] threshold should be equal to 0.1 BSC"); }
    function checkInitialState7() public { Assert.equal(getTableThreshold(2), 2 ether / 10, "[2] threshold should be equal to 0.2 BSC"); }
    function checkInitialState8() public { Assert.equal(getTableThreshold(3), 4 ether / 10, "[3] threshold should be equal to 0.4 BSC"); }
    function checkInitialState9() public { Assert.equal(getTableThreshold(4), 8 ether / 10, "[4] threshold should be equal to 0.8 BSC"); }
    function checkInitialState10() public { Assert.equal(getTableThreshold(5), 16 ether / 10, "[5] threshold should be equal to 1.6 BSC"); }
    function checkInitialState11() public { Assert.equal(getTableThreshold(6), 32 ether / 10, "[6] threshold should be equal to 3.2 BSC"); }
    function checkInitialState12() public { Assert.equal(getTableThreshold(7), 64 ether / 10, "[7] threshold should be equal to 6.4 BSC"); }
    function checkInitialState13() public { Assert.equal(getTableThreshold(8), 125 ether / 10, "[8] threshold should be equal to 12.5 BSC"); }
    function checkInitialState14() public { Assert.equal(getTableThreshold(9), 250 ether / 10, "[9] threshold should be equal to 25 BSC"); }
    function checkInitialState15() public { Assert.equal(getTableThreshold(10), 500 ether / 10, "[10] threshold should be equal to 50 BSC"); }

    function checkRandomTableParamsChange1() public {
        // optional change params
        setTableParams(5, 1_800000_000000_000000, 10, 25, 5, 9, 4, 40, true);
        Assert.equal(getTableThreshold(5), 18 ether / 10, "[5] threshold should be equal to 1.8 BSC");
    }

    function checkRandomTableParamsChange2() public {
        // returning back to initial params
        setTableParams(5, 1_600000_000000_000000, 10, 25, 5, 9, 4, 40, true);
        // nothing should be changed
        checkInitialState10();
    }

    /// #sender: account-1
    /// #value: 100
    function checkNonAdminRandomTableParamsChange() public payable {
        // the low level call will return `false` if its execution reverts
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodeWithSignature(
                "setTableParams(uint,uint,uint,uint,uint,uint,uint,uint,bool)",
                5, 1_800000_000000_000000, 10, 25, 5, 9, 4, 40, true
            )
        );
        if (success) {
            Assert.equal(true, false, "it should not be available for everyone to set table params");
        } else {
            Assert.equal(false, false, "it should not be available for everyone to set table params");
        }
        // nothing should be changed
        checkInitialState10();
    }

        // 0 ->
    function checkJumpTableAtInitialState1() public { Assert.equal(jumpValues[0][1], 1 ether / 10, "jump from 0 to 1 has incorrect cost"); }
    function checkJumpTableAtInitialState2() public { Assert.equal(jumpValues[0][2], 3 ether / 10, "jump from 0 to 2 has incorrect cost"); }
    function checkJumpTableAtInitialState3() public { Assert.equal(jumpValues[0][3], 7 ether / 10, "jump from 0 to 3 has incorrect cost"); }
    function checkJumpTableAtInitialState4() public { Assert.equal(jumpValues[0][4], 15 ether / 10, "jump from 0 to 4 has incorrect cost"); }
    function checkJumpTableAtInitialState5() public { Assert.equal(jumpValues[0][5], 31 ether / 10, "jump from 0 to 5 has incorrect cost"); }
    function checkJumpTableAtInitialState6() public { Assert.equal(jumpValues[0][6], 63 ether / 10, "jump from 0 to 6 has incorrect cost"); }
    function checkJumpTableAtInitialState7() public { Assert.equal(jumpValues[0][7], 127 ether / 10, "jump from 0 to 7 has incorrect cost"); }
    function checkJumpTableAtInitialState8() public { Assert.equal(jumpValues[0][8], 252 ether / 10, "jump from 0 to 8 has incorrect cost"); }
    function checkJumpTableAtInitialState9() public { Assert.equal(jumpValues[0][9], 502 ether / 10, "jump from 0 to 9 has incorrect cost"); }
    function checkJumpTableAtInitialState10() public { Assert.equal(jumpValues[0][10], 1002 ether / 10, "jump from 0 to 10 has incorrect cost"); }
        // 1 ->
    function checkJumpTableAtInitialState11() public { Assert.equal(jumpValues[1][2], 2 ether / 10, "jump from 1 to 2 has incorrect cost"); }
    function checkJumpTableAtInitialState12() public { Assert.equal(jumpValues[1][3], 6 ether / 10, "jump from 1 to 3 has incorrect cost"); }
    function checkJumpTableAtInitialState13() public { Assert.equal(jumpValues[1][4], 14 ether / 10, "jump from 1 to 4 has incorrect cost"); }
    function checkJumpTableAtInitialState14() public { Assert.equal(jumpValues[1][5], 30 ether / 10, "jump from 1 to 5 has incorrect cost"); }
    function checkJumpTableAtInitialState15() public { Assert.equal(jumpValues[1][6], 62 ether / 10, "jump from 1 to 6 has incorrect cost"); }
    function checkJumpTableAtInitialState16() public { Assert.equal(jumpValues[1][7], 126 ether / 10, "jump from 1 to 7 has incorrect cost"); }
    function checkJumpTableAtInitialState17() public { Assert.equal(jumpValues[1][8], 251 ether / 10, "jump from 1 to 8 has incorrect cost"); }
    function checkJumpTableAtInitialState18() public { Assert.equal(jumpValues[1][9], 501 ether / 10, "jump from 1 to 9 has incorrect cost"); }
    function checkJumpTableAtInitialState19() public { Assert.equal(jumpValues[1][10], 1001 ether / 10, "jump from 1 to 10 has incorrect cost"); }
        // 2 ->
    function checkJumpTableAtInitialState20() public { Assert.equal(jumpValues[2][3], 4 ether / 10, "jump from 2 to 3 has incorrect cost"); }
    function checkJumpTableAtInitialState21() public { Assert.equal(jumpValues[2][4], 12 ether / 10, "jump from 2 to 4 has incorrect cost"); }
    function checkJumpTableAtInitialState22() public { Assert.equal(jumpValues[2][5], 28 ether / 10, "jump from 2 to 5 has incorrect cost"); }
    function checkJumpTableAtInitialState23() public { Assert.equal(jumpValues[2][6], 60 ether / 10, "jump from 2 to 6 has incorrect cost"); }
    function checkJumpTableAtInitialState24() public { Assert.equal(jumpValues[2][7], 124 ether / 10, "jump from 2 to 7 has incorrect cost"); }
    function checkJumpTableAtInitialState25() public { Assert.equal(jumpValues[2][8], 249 ether / 10, "jump from 2 to 8 has incorrect cost"); }
    function checkJumpTableAtInitialState26() public { Assert.equal(jumpValues[2][9], 499 ether / 10, "jump from 2 to 9 has incorrect cost"); }
    function checkJumpTableAtInitialState27() public { Assert.equal(jumpValues[2][10], 999 ether / 10, "jump from 2 to 10 has incorrect cost"); }
        // 3 ->
    function checkJumpTableAtInitialState28() public { Assert.equal(jumpValues[3][4], 8 ether / 10, "jump from 3 to 4 has incorrect cost"); }
    function checkJumpTableAtInitialState29() public { Assert.equal(jumpValues[3][5], 24 ether / 10, "jump from 3 to 5 has incorrect cost"); }
    function checkJumpTableAtInitialState30() public { Assert.equal(jumpValues[3][6], 56 ether / 10, "jump from 3 to 6 has incorrect cost"); }
    function checkJumpTableAtInitialState31() public { Assert.equal(jumpValues[3][7], 120 ether / 10, "jump from 3 to 7 has incorrect cost"); }
    function checkJumpTableAtInitialState32() public { Assert.equal(jumpValues[3][8], 245 ether / 10, "jump from 3 to 8 has incorrect cost"); }
    function checkJumpTableAtInitialState33() public { Assert.equal(jumpValues[3][9], 495 ether / 10, "jump from 3 to 9 has incorrect cost"); }
    function checkJumpTableAtInitialState34() public { Assert.equal(jumpValues[3][10], 995 ether / 10, "jump from 3 to 10 has incorrect cost"); }
        // 4 ->
    function checkJumpTableAtInitialState35() public { Assert.equal(jumpValues[4][5], 16 ether / 10, "jump from 4 to 5 has incorrect cost"); }
    function checkJumpTableAtInitialState36() public { Assert.equal(jumpValues[4][6], 48 ether / 10, "jump from 4 to 6 has incorrect cost"); }
    function checkJumpTableAtInitialState37() public { Assert.equal(jumpValues[4][7], 112 ether / 10, "jump from 4 to 7 has incorrect cost"); }
    function checkJumpTableAtInitialState38() public { Assert.equal(jumpValues[4][8], 237 ether / 10, "jump from 4 to 8 has incorrect cost"); }
    function checkJumpTableAtInitialState39() public { Assert.equal(jumpValues[4][9], 487 ether / 10, "jump from 4 to 9 has incorrect cost"); }
    function checkJumpTableAtInitialState40() public { Assert.equal(jumpValues[4][10], 987 ether / 10, "jump from 4 to 10 has incorrect cost"); }
        // 5 ->
    function checkJumpTableAtInitialState41() public { Assert.equal(jumpValues[5][6], 32 ether / 10, "jump from 5 to 6 has incorrect cost"); }
    function checkJumpTableAtInitialState42() public { Assert.equal(jumpValues[5][7], 96 ether / 10, "jump from 5 to 7 has incorrect cost"); }
    function checkJumpTableAtInitialState43() public { Assert.equal(jumpValues[5][8], 221 ether / 10, "jump from 5 to 8 has incorrect cost"); }
    function checkJumpTableAtInitialState44() public { Assert.equal(jumpValues[5][9], 471 ether / 10, "jump from 5 to 9 has incorrect cost"); }
    function checkJumpTableAtInitialState45() public { Assert.equal(jumpValues[5][10], 971 ether / 10, "jump from 5 to 10 has incorrect cost"); }
        // 6 ->
    function checkJumpTableAtInitialState46() public { Assert.equal(jumpValues[6][7], 64 ether / 10, "jump from 6 to 7 has incorrect cost"); }
    function checkJumpTableAtInitialState47() public { Assert.equal(jumpValues[6][8], 189 ether / 10, "jump from 6 to 8 has incorrect cost"); }
    function checkJumpTableAtInitialState48() public { Assert.equal(jumpValues[6][9], 439 ether / 10, "jump from 6 to 9 has incorrect cost"); }
    function checkJumpTableAtInitialState49() public { Assert.equal(jumpValues[6][10], 939 ether / 10, "jump from 6 to 10 has incorrect cost"); }
        // 7 ->
    function checkJumpTableAtInitialState50() public { Assert.equal(jumpValues[7][8], 125 ether / 10, "jump from 7 to 8 has incorrect cost"); }
    function checkJumpTableAtInitialState51() public { Assert.equal(jumpValues[7][9], 375 ether / 10, "jump from 7 to 9 has incorrect cost"); }
    function checkJumpTableAtInitialState52() public { Assert.equal(jumpValues[7][10], 875 ether / 10, "jump from 7 to 10 has incorrect cost"); }
        // 8 ->
    function checkJumpTableAtInitialState53() public { Assert.equal(jumpValues[8][9], 250 ether / 10, "jump from 8 to 9 has incorrect cost"); }
    function checkJumpTableAtInitialState54() public { Assert.equal(jumpValues[8][10], 750 ether / 10, "jump from 8 to 10 has incorrect cost"); }
        // 9 ->
    function checkJumpTableAtInitialState55() public { Assert.equal(jumpValues[9][10], 500 ether / 10, "jump from 9 to 10 has incorrect cost"); }

    /// #sender: account-1
    /// #value: 100000000000000000
    function checkTableBuy1() public payable {
        uint total = rootAddress.balance;
        Assert.equal(address2table[acc1], 0, "acc1 should be on table 0");
        buy(acc2);
        Assert.equal(address2table[acc1], 1, "acc1 should jumo to table 1");
        uint diff = rootAddress.balance - total;
        Assert.equal(diff, msg.value, "zero sum game");
    }

    function checkSettingCharity() public {
        setnewCharityAddress(testCharity);
        Assert.equal(charityAddress, testCharity, "charity address should be changed");
    }

    /// #sender: account-2
    /// #value: 100000000000000000
    function checkTableBuy2() public payable {
        uint total = charityAddress.balance + rootAddress.balance + acc1.balance;
        Assert.equal(address2table[acc2], 0, "acc2 should be on table 0");
        buy(acc1);
        Assert.equal(address2table[acc2], 1, "acc2 should jumo to table 1");
        uint diff = charityAddress.balance + rootAddress.balance + acc1.balance - total;
        Assert.equal(diff, msg.value, "zero sum game");
    }

    function checkSitsCount1() public { Assert.equal(getTableAddressesCount(1), 3, "1 table"); }
    function checkSitsCount2() public { Assert.equal(getTableAddressesCount(2), 1, "2 table (root)"); }
    function checkSitsCount3() public { Assert.equal(getTableAddressesCount(3), 1, "3 table (root)"); }
    function checkSitsCount4() public { Assert.equal(getTableAddressesCount(4), 1, "4 table (root)"); }
    function checkSitsCount5() public { Assert.equal(getTableAddressesCount(5), 1, "5 table (root)"); }
    function checkSitsCount6() public { Assert.equal(getTableAddressesCount(6), 1, "6 table (root)"); }
    function checkSitsCount7() public { Assert.equal(getTableAddressesCount(7), 1, "7 table (root)"); }
    function checkSitsCount8() public { Assert.equal(getTableAddressesCount(8), 1, "8 table (root)"); }
    function checkSitsCount9() public { Assert.equal(getTableAddressesCount(9), 1, "9 table (root)"); }
    function checkSitsCount10() public { Assert.equal(getTableAddressesCount(10), 1, "10 table (root)"); }

    /// #sender: account-3
    /// #value: 3100000000000000000
    function checkTableBuy3() public payable {
        uint charityBalance = charityAddress.balance;
        uint rootBalance = rootAddress.balance;
        uint acc1Balance = acc1.balance;

        Assert.equal(address2table[acc3], 0, "acc3 should be on table 0");
        buy(acc1);
        Assert.equal(address2table[acc3], 5, "acc3 should jump to table 5");

        uint diffCharity = charityAddress.balance - charityBalance;
        Assert.equal(diffCharity, msg.value / 10, "10% goes to charity");

        uint diffAcc1 = acc1.balance - acc1Balance;
        // Assert.equal(diffAcc1, msg.value / 4, "25% goes to parent");

        uint diffRoot = rootAddress.balance - rootBalance;
        uint remain = msg.value - diffCharity - diffAcc1;
        Assert.equal(diffRoot, remain, "all remain goes to root");

        Assert.equal(getTableAddressesCount(5), 2, "5 table (root)");
    }

    /// #sender: account-4
    /// #value: 3100000000000000000
    function checkTableBuy4() public payable {
        uint charityBalance = charityAddress.balance;
        uint rootBalance = rootAddress.balance;
        uint acc1Balance = acc1.balance;

        Assert.equal(address2table[acc4], 0, "acc4 should be on table 0");
        buy(acc1);
        Assert.equal(address2table[acc4], 5, "acc4 should jump to table 5");

        uint diffCharity = charityAddress.balance - charityBalance;
        Assert.equal(diffCharity, msg.value / 10, "10% goes to charity");

        Assert.equal(address(this).balance, 0, "0 should be on a contract");

        Assert.equal(getTableAddressesCount(5), 3, "5 table (root)");
    }

    /// #sender: account-0
    /// #value: 30000000000000000000
    function checkEnoughMoneyToBuy10TableFromAcc1() public payable {
        payable(acc1).transfer(msg.value);
        Assert.greaterThan(acc1.balance, uint(101000000000000000000), "acc1 balance should be greater than 101 BSC");
    }

    /// #sender: account-0
    /// #value: 30000000000000000000
    function checkEnoughMoneyToBuy10TableFromAcc2() public payable {
        payable(acc2).transfer(msg.value);
        Assert.greaterThan(acc2.balance, uint(101000000000000000000), "acc2 balance should be greater than 101 BSC");
    }

    /// #sender: account-1
    /// #value: 100100000000000000000
    function checkTableBuy5() public payable {
        uint charityBalance = charityAddress.balance;
        uint rootBalance = rootAddress.balance;
        uint acc3Balance = acc3.balance;

        Assert.equal(address2table[acc1], 1, "acc1 should be on table 1");
        buy(acc3);
        Assert.equal(address2table[acc1], 10, "acc1 should jump to table 10");

        uint diffCharity = charityAddress.balance - charityBalance;
        Assert.equal(diffCharity, msg.value / 10, "10% goes to charity");

        uint diffAcc3 = acc3.balance - acc3Balance;
        // Assert.equal(diffAcc3, msg.value / 4, "25% goes to parent");

        uint diffRoot = rootAddress.balance - rootBalance;
        uint remain = msg.value - diffCharity - diffAcc3;
        Assert.equal(diffRoot, remain, "all remain goes to root");

        Assert.equal(getTableAddressesCount(10), 2, "10 table (root)");
    }

    /// #sender: account-2
    /// #value: 100100000000000000000
    function checkTableBuy6() public payable {
        uint charityBalance = charityAddress.balance;
        uint rootBalance = rootAddress.balance;
        uint acc3Balance = acc3.balance;
        uint acc1Balance = acc1.balance;

        Assert.equal(address2table[acc2], 1, "acc1 should be on table 1");
        buy(acc3);
        Assert.equal(address2table[acc2], 10, "acc1 should jump to table 10");

        uint diffCharity = charityAddress.balance - charityBalance;
        Assert.equal(diffCharity, msg.value / 10, "10% goes to charity");

        Assert.equal(address(this).balance, 0, "0 should be on a contract");

        uint diffAcc1 = acc1.balance - acc1Balance;
        Assert.greaterThan(diffAcc1, uint(0), "Acc1 should get something");


        Assert.equal(getTableAddressesCount(10), 3, "10 table (root)");
    }

}