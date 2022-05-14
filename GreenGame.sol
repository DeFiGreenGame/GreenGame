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

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
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
        uint8 charityShare;
        uint8 refShare;
        uint8 donationsCount;
        uint8 donationShare;
        uint8 refDonationShare;
        uint8 maxDonationsCount;
    }

    Table[] public tables;

    address public charityAddress;
    address public rootAddress;

    mapping(address => uint8) public address2table;
    uint[][] public jumpValues;
    mapping(uint8 => mapping(uint => uint8)) public value2table;
    mapping(uint8 => address[]) public tableAddresses;
    mapping(uint8 => mapping(address => uint)) public donationsCountReceivedAlready;

    mapping(uint8 => mapping(address => uint)) public refTableSum;
    mapping(uint8 => mapping(address => uint)) public missedRefTableSum;
    mapping(uint8 => mapping(address => uint)) public donationTableSum;
    mapping(uint8 => mapping(address => uint)) public donationRefTableSum;
    mapping(uint8 => mapping(address => uint)) public missedDonationRefTableSum;

    mapping(address => uint) public refSum;
    mapping(address => uint) public missedRefSum;
    mapping(address => uint) public donationSum;
    mapping(address => uint) public donationRefSum;
    mapping(address => uint) public missedDonationRefSum;


    mapping(address => address) public parents;

    event InvestmentReceived(uint8 table, address initiator, address refferal, uint amount);
    event ReferralRewardSent(uint8 table, address initiator, address receiver, uint amount);
    event DonationRewardSent(uint8 table, address initiator, address receiver, uint amount);
    event DonationReferralRewardSent(uint8 table, address initiator, address receiver, uint amount);
    event CharitySent(uint8 table, address initiator, address receiver, uint amount);

    constructor(address root, address charity) {
        rootAddress = root;
        charityAddress = charity;

        // Zero Table
        tables.push(Table(0, 0, 0, 0, 0, 0, 0));

        // League #1
        appendTable(100000_000000_000000, 10, 25, 5, 8, 5, 30, false); // 100000000000000000
        appendTable(200000_000000_000000, 10, 25, 5, 8, 5, 30, false); // 200000000000000000
        appendTable(400000_000000_000000, 10, 25, 5, 8, 5, 30, false); // 400000000000000000
        appendTable(800000_000000_000000, 10, 25, 5, 8, 5, 30, false); // 800000000000000000

        // League #2
        appendTable(1_600000_000000_000000, 10, 25, 5, 9, 4, 40, false); // 1600000000000000000
        appendTable(3_200000_000000_000000, 10, 25, 5, 9, 4, 40, false); // 3200000000000000000
        appendTable(6_400000_000000_000000, 10, 25, 5, 9, 4, 40, false); // 6400000000000000000

        // League #3
        appendTable(12_500000_000000_000000, 10, 25, 5, 10, 3, 50, false); // 12500000000000000000
        appendTable(25_000000_000000_000000, 10, 25, 5, 10, 3, 50, false); // 25000000000000000000

        // League #4
        appendTable(50_000000_000000_000000, 10, 25, 5, 11, 2, 0, false); // 50000000000000000000

        rebuildJumpValues();
    }

    receive() external payable {
        buy(parents[msg.sender]);
    }

    function buy(address parent) public payable {
        if ((parents[msg.sender] != parent) && (parents[msg.sender] != address(0))) {
            return process(msg.value, msg.sender, parents[msg.sender]);
        }
        if (parent == address(0)) {
            return process(msg.value, msg.sender, rootAddress);
        }
        return process(msg.value, msg.sender, parent);
    }

    function process(uint value, address sender, address parent) private {
        require(value > 0);
        require(parent != address(0));
        uint8 currentTable = address2table[sender];
        uint8 newTable = value2table[currentTable][value];
        require(newTable > currentTable);

        emit InvestmentReceived(newTable, sender, parent, value);

        // Get table params
        Table memory t = tables[newTable];

        // Sum counter
        uint total = 0;

        // Ref
        uint refValue = value.mul(t.refShare).div(100);
        uint winnerReward = value.mul(t.donationShare).div(100);
        uint winnerParentReward = value.mul(t.refDonationShare).div(100);

        // Direct Ref Payout
        payoutReferralReward(newTable, sender, parent, refValue);
        total = total.add(refValue);

        for (uint8 i = 1; i <= t.donationsCount; i++){
            // Donation Ref Payout
            address winner = tableAddresses[newTable][random(tableAddresses[newTable].length, i)];
            payoutDonationReferralReward(newTable, sender, parents[winner], winnerParentReward);
            total = total.add(winnerParentReward);

            // Donation Payout
            payoutDonationReward(newTable, sender, winner, winnerReward);
            total = total.add(winnerReward);
        }

        address2table[sender] = newTable;
        for (uint8 i = currentTable; i < newTable; i++){
            tableAddresses[i + 1].push(sender);
        }
        parents[sender] = parent;

        payout(charityAddress, value.sub(total));
        emit CharitySent(newTable, sender, charityAddress, value.sub(total));
    }

    function payoutDonationReward(uint8 tableNum, address sender, address winner, uint value) private {
        Table memory t = tables[tableNum];
        if (t.maxDonationsCount == 0) {
            donationsCountReceivedAlready[tableNum][winner]++;
        } else {
            if (donationsCountReceivedAlready[tableNum][winner] > t.maxDonationsCount){
                winner = rootAddress;
            } else {
                donationsCountReceivedAlready[tableNum][winner]++;
            }
        }
        donationTableSum[tableNum][winner] = donationTableSum[tableNum][winner].add(value);
        payout(winner, value);
        emit DonationRewardSent(tableNum, sender, winner, value);
    }

    function payoutDonationReferralReward(uint8 tableNum, address sender, address winnerParent, uint value) private {
        uint8 i = 0;
        while ((address2table[winnerParent] < tableNum) && (i < 10)) {
            missedDonationRefTableSum[tableNum][winnerParent] = missedDonationRefTableSum[tableNum][winnerParent].add(value);
            missedDonationRefSum[winnerParent] = missedDonationRefSum[winnerParent].add(value);
            if (winnerParent == address(0)) {
                winnerParent = rootAddress;
                break;
            }
            winnerParent = parents[winnerParent];
            i++;
        }
        if (i == 10) {
            winnerParent = rootAddress;
        }
        if (i == 0) {
            donationRefTableSum[tableNum][winnerParent] = donationRefTableSum[tableNum][winnerParent].add(value);
            donationRefSum[winnerParent] = donationRefSum[winnerParent].add(value);
        }
        payout(winnerParent, value);
        emit DonationReferralRewardSent(tableNum, sender, winnerParent, value);
    }

    function payoutReferralReward(uint8 tableNum, address sender, address parent, uint value) private {
        uint8 i = 0;
        while ((address2table[parent] < tableNum) && (i < 10)) {
            missedRefTableSum[tableNum][parent] = missedRefTableSum[tableNum][parent].add(value);
            missedRefSum[parent] = missedRefSum[parent].add(value);
            if (parent == address(0)) {
                parent = rootAddress;
                break;
            }
            parent = parents[parent];
            i++;
        }
        if (i == 10) {
            parent = rootAddress;
        }
        refTableSum[tableNum][parent] = refTableSum[tableNum][parent].add(value);
        refSum[parent] = refSum[parent].add(value);
        payout(parent, value);
        emit ReferralRewardSent(tableNum, sender, parent, value);
    }

    function getTableAddressesCount(uint8 num) public view returns (uint) {
        return tableAddresses[num].length;
    }

    function getTablesCount() public view returns (uint) {
        return tables.length;
    }

    function getTableThreshold(uint8 num) public view returns (uint) {
        require (num <= tables.length);
        return tables[num].thValue;
    }

    function appendTable(uint thValue, uint8 charityShare, uint8 refShare, uint8 donationsCount, uint8 donationShare, uint8 refDonationShare, uint8 maxDonationsCount, bool forceRebuildJUmpValues) public onlyOwner {
        setTableParams(uint8(tables.length), thValue, charityShare, refShare, donationsCount, donationShare, refDonationShare, maxDonationsCount, forceRebuildJUmpValues);
        tableAddresses[uint8(tables.length - 1)].push(rootAddress);
    }

    function setTableParams(uint8 num, uint thValue, uint8 charityShare, uint8 refShare, uint8 donationsCount, uint8 donationShare, uint8 refDonationShare, uint8 maxDonationsCount, bool forceRebuildJUmpValues) public onlyOwner {
        Table memory t = Table(thValue, charityShare, refShare, donationsCount, donationShare, refDonationShare, maxDonationsCount);
        require(num > 0);
        require(num <= tables.length);
        require(t.thValue > 0);
        require(t.charityShare + t.refShare + t.donationsCount * t.donationShare + t.donationsCount * t.refDonationShare == 100);

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
            for (uint8 i = 0; i < tables.length; i++) {
                for (uint8 j = 0; j < tables.length; j++) {
                    uint val = jumpValues[i][j];
                    value2table[i][val] = 0;
                }
            }
        }
        delete jumpValues;

        // Initial state of Jump Matrix
        uint accum = 0;
        jumpValues.push([0]);
        for (uint8 j = 1; j < tables.length; j++) {
            accum = accum.add(tables[j].thValue);
            jumpValues[0].push(accum);
            // reversed mapping from sum to target table
            value2table[0][accum] = j;
        }

        // Rest part of Jump Matrix
        for (uint8 i = 1; i < tables.length; i++) {
            jumpValues.push([0]);
            for (uint8 j = 1; j < tables.length; j++) {
                if (j < i) {
                    jumpValues[i].push(0);
                } else {
                    jumpValues[i].push(jumpValues[i - 1][j].sub(jumpValues[i - 1][i]));
                    value2table[i][jumpValues[i - 1][j].sub(jumpValues[i - 1][i])] = j;
                }
            }
        }

        address2table[rootAddress] = uint8(tables.length);
    }

    function random(uint max, uint8 salt) public view returns(uint) {
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
        address2table[newRootAddress] = address2table[rootAddress];
        rootAddress = newRootAddress;
        for (uint8 i = 0; i < tables.length; i++) {
            tableAddresses[i][0] = rootAddress;
        }
    }

    // for any accidentally lost funds
    function withdraw() public onlyOwner {
        payout(owner, address(this).balance);
    }

    // for any tokens lost and might be acccidentally sent to this contract
    function withdrawToken(address _tokenContract, uint256 _amount) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }
}
