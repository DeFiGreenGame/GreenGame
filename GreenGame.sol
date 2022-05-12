// ----------------------------------------------------------------------------
// GreenGame™ Main Contract (2022)
// Version: 0.0.1
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// ----------------------------------------------------------------------------

pragma solidity 0.8.13;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) { c = a + b; require(c >= a); }
    function sub(uint a, uint b) internal pure returns (uint c) { require(b <= a); c = a - b; }
    function mul(uint a, uint b) internal pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); }
    function div(uint a, uint b) internal pure returns (uint c) { require(b > 0); c = a / b; }
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address from, address to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract GreenGame is Ownable {
    using SafeMath for uint;

    struct Table {
        uint thValue;
        uint charityShare;
        uint refShare;
        uint donationsCount;
        uint donationShare;
        uint refDonationShare;
        uint maxDonationsCount;
    }

    Table[] public tables;

    address public charityAddress;
    address public rootAddress;

    mapping(address => uint) public address2table;
    uint[][] public jumpValues;
    mapping(uint => mapping(uint => uint)) public value2table;
    mapping(uint => address[]) public tableAddresses;
    mapping(uint => mapping(address => uint)) donationsCountReceivedAlready;

    mapping(address => address) public parents;

    event InvestmentReceived(address initiator, uint tableNum, address refferalAddress, uint amount);
    event ReferralRewardSent(address initiator, address receiver, uint amount);
    event DonationRewardSent(address initiator, address receiver, uint amount);
    event ReferralDonationRewardSent(address initiator, address receiver, uint amount);
    event CharitySent(address initiator, address receiver, uint amount);

    constructor() {
        charityAddress = msg.sender;
        rootAddress = msg.sender;

        // Zero Table
        tables.push(Table(0, 0, 0, 0, 0, 0, 0));

        // League #1
        appendTable(100000_000000_000000, 10, 25, 5, 8, 5, 30, false);
        appendTable(200000_000000_000000, 10, 25, 5, 8, 5, 30, false);
        appendTable(400000_000000_000000, 10, 25, 5, 8, 5, 30, false);
        appendTable(800000_000000_000000, 10, 25, 5, 8, 5, 30, false);

        // League #2
        appendTable(1_600000_000000_000000, 10, 25, 5, 9, 4, 40, false);
        appendTable(3_200000_000000_000000, 10, 25, 5, 9, 4, 40, false);
        appendTable(6_400000_000000_000000, 10, 25, 5, 9, 4, 40, false);

        // League #3
        appendTable(12_500000_000000_000000, 10, 25, 5, 10, 3, 50, false);
        appendTable(25_000000_000000_000000, 10, 25, 5, 10, 3, 50, false);

        // League #4
        appendTable(50_000000_000000_000000, 10, 25, 5, 11, 2, 0, false);

        rebuildJumpValues();
        parents[rootAddress] = rootAddress;
    }

    receive() external payable {
        process(msg.value, msg.sender, rootAddress);
    }

    function buy(address parent) external payable {
        if (address2table[parent] < 1) {
            parent = rootAddress;
        }
        process(msg.value, msg.sender, parent);
    }

    function process(uint value, address sender, address parent) private {
        require(value > 0);
        require(parent != address(0));
        uint currentTable = address2table[sender];
        uint newTable = value2table[currentTable][value];
        require(newTable > currentTable);

        emit InvestmentReceived(sender, newTable, parent, value);

        // Get table params
        Table memory t = tables[newTable];

        uint total = 0;

        // Ref
        uint refValue = value.mul(t.refShare).div(100);
        uint winnerReward = value.mul(t.donationShare).div(100);
        uint winnerParentReward = value.mul(t.refDonationShare).div(100);

        payout(parent, refValue);
        emit ReferralRewardSent(sender, parent, refValue);
        total = total.add(refValue);

        for (uint i = 1; i <= t.donationsCount; i++){
            address winner = tableAddresses[newTable][random(tableAddresses[newTable].length, i)];
            payout(parents[winner], winnerParentReward);
            emit DonationRewardSent(sender, parents[winner], winnerParentReward);
            total = total.add(winnerParentReward);
            if (donationsCountReceivedAlready[newTable][winner] > t.maxDonationsCount){
                winner = rootAddress;
            } else {
                donationsCountReceivedAlready[newTable][winner]++;
            }
            payout(winner, winnerReward);
            emit DonationRewardSent(sender, winner, winnerReward);
            total = total.add(winnerReward);
        }

        address2table[sender] = newTable;
        for (uint i = currentTable; i < newTable; i++){
            tableAddresses[i + 1].push(sender);
        }
        parents[sender] = parent;

        payout(charityAddress, value.sub(total));
        emit CharitySent(sender, charityAddress, value.sub(total));
    }

    function getTableAddressesCount(uint num) public view returns (uint) {
        return tableAddresses[num].length;
    }

    function getTablesCount() public view returns (uint) {
        return tables.length;
    }

    function getTableThreshold(uint num) public view returns (uint) {
        require (num <= tables.length);
        return tables[num].thValue;
    }

    function appendTable(uint thValue, uint charityShare, uint refShare, uint donationsCount, uint donationShare, uint refDonationShare, uint maxDonationsCount, bool forceRebuildJUmpValues) public onlyOwner {
        setTableParams(tables.length, thValue, charityShare, refShare, donationsCount, donationShare, refDonationShare, maxDonationsCount, forceRebuildJUmpValues);
        tableAddresses[tables.length - 1].push(rootAddress);
    }

    function setTableParams(uint num, uint thValue, uint charityShare, uint refShare, uint donationsCount, uint donationShare, uint refDonationShare, uint maxDonationsCount, bool forceRebuildJUmpValues) public onlyOwner {
        Table memory t = Table(thValue, charityShare, refShare, donationsCount, donationShare, refDonationShare, maxDonationsCount);
        require(num > 0);
        require(num <= tables.length);
        require(t.thValue > 0);
        require(t.charityShare + t.refShare + t.donationsCount.mul(t.donationShare) + t.donationsCount.mul(t.refDonationShare) == 100);

        // if it's not a first table
        if (num > 1) {
            // it should be greater than prev threshold
            require(t.thValue > tables[num - 1].thValue);
        }
        // if it's not a last table or a new one
        if (num < tables.length - 1) {
            // it should be less that next threshold
            require(t.thValue < tables[num + 1].thValue);
        }

        if (num == tables.length) {
            tables.push(t);
        } else {
            tables[num].thValue = t.thValue;
        }

        if (forceRebuildJUmpValues) {
            rebuildJumpValues();
        }
    }

    function rebuildJumpValues() public onlyOwner {
        if (jumpValues.length > 0) {
            for (uint i = 0; i < tables.length; i++) {
                for (uint j = 0; j < tables.length; j++) {
                    uint val = jumpValues[i][j];
                    value2table[i][val] = 0;
                }
            }
        }
        delete jumpValues;

        // Initial state of Jump Matrix
        uint accum = 0;
        jumpValues.push([0]);
        for (uint j = 1; j < tables.length; j++) {
            accum = accum.add(tables[j].thValue);
            jumpValues[0].push(accum);
            // reversed mapping from sum to target table
            value2table[0][accum] = j;
        }

        // Rest part of Jump Matrix
        for (uint i = 1; i < tables.length; i++) {
            jumpValues.push([0]);
            for (uint j = 1; j < tables.length; j++) {
                if (j < i) {
                    jumpValues[i].push(0);
                } else {
                    jumpValues[i].push(jumpValues[i - 1][j].sub(jumpValues[i - 1][i]));
                    value2table[i][jumpValues[i - 1][j].sub(jumpValues[i - 1][i])] = j;
                }
            }
        }

        address2table[rootAddress] = tables.length;
    }

    function random(uint max, uint salt) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp.mul(salt), block.difficulty, msg.sender))) % max;
    }

    function payout(address receiver, uint value) private {
        require(receiver != address(0));
        payable(receiver).transfer(value);
    }

    // Admin Functions

    function setnewCharityAddress(address newCharityAddress) public onlyOwner {
        require(newCharityAddress != address(0));
        charityAddress = newCharityAddress;
    }

    function setnewRootAddress(address newRootAddress) public onlyOwner {
        require(newRootAddress != address(0));
        rootAddress = newRootAddress;
    }
}