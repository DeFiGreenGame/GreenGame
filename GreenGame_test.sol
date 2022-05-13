pragma solidity 0.8.13;
import "remix_tests.sol";
import "remix_accounts.sol";
import "GreenGame.sol";

contract GreenGameTest is GreenGame {
    address acc0;
    address acc1;
    address acc2;
    address acc3;

    function beforeAll() public {
        // game = new GreenGame();
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
    }

    function checkInitialState() public {
        Assert.equal(acc0, owner, "acc0 is the owner");
        Assert.equal(charityAddress, owner, "charity address should be equal to owner address");
        Assert.equal(rootAddress, owner, "root address should be equal to owner address");
        Assert.equal(getTablesCount(), 11, "we should have 10 tables + 1 root tabled indexed as a 0");
        Assert.equal(getTableThreshold(0), 0 ether, "[0] threshold should be equal to 0 BSC");
        Assert.equal(getTableThreshold(1), 1 ether / 10, "[1] threshold should be equal to 0.1 BSC");
        Assert.equal(getTableThreshold(2), 2 ether / 10, "[2] threshold should be equal to 0.2 BSC");
        Assert.equal(getTableThreshold(3), 4 ether / 10, "[3] threshold should be equal to 0.4 BSC");
        Assert.equal(getTableThreshold(4), 8 ether / 10, "[4] threshold should be equal to 0.8 BSC");
        Assert.equal(getTableThreshold(5), 16 ether / 10, "[5] threshold should be equal to 1.6 BSC");
        Assert.equal(getTableThreshold(6), 32 ether / 10, "[6] threshold should be equal to 3.2 BSC");
        Assert.equal(getTableThreshold(7), 64 ether / 10, "[7] threshold should be equal to 6.4 BSC");
        Assert.equal(getTableThreshold(8), 125 ether / 10, "[8] threshold should be equal to 12.5 BSC");
        Assert.equal(getTableThreshold(9), 250 ether / 10, "[9] threshold should be equal to 25 BSC");
        Assert.equal(getTableThreshold(10), 500 ether / 10, "[10] threshold should be equal to 50 BSC");
    }

    function checkRandomTableParamsChange() public {
        // optional change params
        setTableParams(5, 1_800000_000000_000000, 10, 25, 5, 9, 4, 40, true);
        Assert.equal(getTableThreshold(5), 18 ether / 10, "[5] threshold should be equal to 1.8 BSC");
        // returning back to initial params
        setTableParams(5, 1_600000_000000_000000, 10, 25, 5, 9, 4, 40, true);
        // nothing should be changed
        checkInitialState();
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
        checkInitialState();
    }

    function checkJumpTableAtInitialState() public {
        // 0 ->
        Assert.equal(jumpValues[0][1], 1 ether / 10, "jump from 0 to 1 has incorrect cost");
        Assert.equal(jumpValues[0][2], 3 ether / 10, "jump from 0 to 2 has incorrect cost");
        Assert.equal(jumpValues[0][3], 7 ether / 10, "jump from 0 to 3 has incorrect cost");
        Assert.equal(jumpValues[0][4], 15 ether / 10, "jump from 0 to 4 has incorrect cost");
        Assert.equal(jumpValues[0][5], 31 ether / 10, "jump from 0 to 5 has incorrect cost");
        Assert.equal(jumpValues[0][6], 63 ether / 10, "jump from 0 to 6 has incorrect cost");
        Assert.equal(jumpValues[0][7], 127 ether / 10, "jump from 0 to 7 has incorrect cost");
        Assert.equal(jumpValues[0][8], 252 ether / 10, "jump from 0 to 8 has incorrect cost");
        Assert.equal(jumpValues[0][9], 502 ether / 10, "jump from 0 to 9 has incorrect cost");
        Assert.equal(jumpValues[0][10], 1002 ether / 10, "jump from 0 to 10 has incorrect cost");
        // 1 ->
        Assert.equal(jumpValues[1][2], 2 ether / 10, "jump from 1 to 2 has incorrect cost");
        Assert.equal(jumpValues[1][3], 6 ether / 10, "jump from 1 to 3 has incorrect cost");
        Assert.equal(jumpValues[1][4], 14 ether / 10, "jump from 1 to 4 has incorrect cost");
        Assert.equal(jumpValues[1][5], 30 ether / 10, "jump from 1 to 5 has incorrect cost");
        Assert.equal(jumpValues[1][6], 62 ether / 10, "jump from 1 to 6 has incorrect cost");
        Assert.equal(jumpValues[1][7], 126 ether / 10, "jump from 1 to 7 has incorrect cost");
        Assert.equal(jumpValues[1][8], 251 ether / 10, "jump from 1 to 8 has incorrect cost");
        Assert.equal(jumpValues[1][9], 501 ether / 10, "jump from 1 to 9 has incorrect cost");
        Assert.equal(jumpValues[1][10], 1001 ether / 10, "jump from 1 to 10 has incorrect cost");
        // 2 ->
        Assert.equal(jumpValues[2][3], 4 ether / 10, "jump from 2 to 3 has incorrect cost");
        Assert.equal(jumpValues[2][4], 12 ether / 10, "jump from 2 to 4 has incorrect cost");
        Assert.equal(jumpValues[2][5], 28 ether / 10, "jump from 2 to 5 has incorrect cost");
        Assert.equal(jumpValues[2][6], 60 ether / 10, "jump from 2 to 6 has incorrect cost");
        Assert.equal(jumpValues[2][7], 124 ether / 10, "jump from 2 to 7 has incorrect cost");
        Assert.equal(jumpValues[2][8], 249 ether / 10, "jump from 2 to 8 has incorrect cost");
        Assert.equal(jumpValues[2][9], 499 ether / 10, "jump from 2 to 9 has incorrect cost");
        Assert.equal(jumpValues[2][10], 999 ether / 10, "jump from 2 to 10 has incorrect cost");
        // 3 ->
        Assert.equal(jumpValues[3][4], 8 ether / 10, "jump from 3 to 4 has incorrect cost");
        Assert.equal(jumpValues[3][5], 24 ether / 10, "jump from 3 to 5 has incorrect cost");
        Assert.equal(jumpValues[3][6], 56 ether / 10, "jump from 3 to 6 has incorrect cost");
        Assert.equal(jumpValues[3][7], 120 ether / 10, "jump from 3 to 7 has incorrect cost");
        Assert.equal(jumpValues[3][8], 245 ether / 10, "jump from 3 to 8 has incorrect cost");
        Assert.equal(jumpValues[3][9], 495 ether / 10, "jump from 3 to 9 has incorrect cost");
        Assert.equal(jumpValues[3][10], 995 ether / 10, "jump from 3 to 10 has incorrect cost");
        // 4 ->
        Assert.equal(jumpValues[4][5], 16 ether / 10, "jump from 4 to 5 has incorrect cost");
        Assert.equal(jumpValues[4][6], 48 ether / 10, "jump from 4 to 6 has incorrect cost");
        Assert.equal(jumpValues[4][7], 112 ether / 10, "jump from 4 to 7 has incorrect cost");
        Assert.equal(jumpValues[4][8], 237 ether / 10, "jump from 4 to 8 has incorrect cost");
        Assert.equal(jumpValues[4][9], 487 ether / 10, "jump from 4 to 9 has incorrect cost");
        Assert.equal(jumpValues[4][10], 987 ether / 10, "jump from 4 to 10 has incorrect cost");
        // 5 ->
        Assert.equal(jumpValues[5][6], 32 ether / 10, "jump from 5 to 6 has incorrect cost");
        Assert.equal(jumpValues[5][7], 96 ether / 10, "jump from 5 to 7 has incorrect cost");
        Assert.equal(jumpValues[5][8], 221 ether / 10, "jump from 5 to 8 has incorrect cost");
        Assert.equal(jumpValues[5][9], 471 ether / 10, "jump from 5 to 9 has incorrect cost");
        Assert.equal(jumpValues[5][10], 971 ether / 10, "jump from 5 to 10 has incorrect cost");
        // 6 ->
        Assert.equal(jumpValues[6][7], 64 ether / 10, "jump from 6 to 7 has incorrect cost");
        Assert.equal(jumpValues[6][8], 189 ether / 10, "jump from 6 to 8 has incorrect cost");
        Assert.equal(jumpValues[6][9], 439 ether / 10, "jump from 6 to 9 has incorrect cost");
        Assert.equal(jumpValues[6][10], 939 ether / 10, "jump from 6 to 10 has incorrect cost");
        // 7 ->
        Assert.equal(jumpValues[7][8], 125 ether / 10, "jump from 7 to 8 has incorrect cost");
        Assert.equal(jumpValues[7][9], 375 ether / 10, "jump from 7 to 9 has incorrect cost");
        Assert.equal(jumpValues[7][10], 875 ether / 10, "jump from 7 to 10 has incorrect cost");
        // 8 ->
        Assert.equal(jumpValues[8][9], 250 ether / 10, "jump from 8 to 9 has incorrect cost");
        Assert.equal(jumpValues[8][10], 750 ether / 10, "jump from 8 to 10 has incorrect cost");
        // 9 ->
        Assert.equal(jumpValues[9][10], 500 ether / 10, "jump from 9 to 10 has incorrect cost");
    }
}