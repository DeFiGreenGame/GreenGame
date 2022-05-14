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
    struct Table {
        uint256 thValue;
        uint256 charityShare;
        uint256 refShare;
        uint256 donationsCount;
        uint256 donationShare;
        uint256 refDonationShare;
        uint256 maxDonationsCount;
    }

    Table[] public tables;

    address public charityAddress;
    address public rootAddress;

    mapping(address => uint256) public address2table;

    uint256[][] public jumpValues; // [table_from][table_to] => amount

    mapping(uint256 => mapping(uint256 => uint256)) public value2table;
    mapping(uint256 => address[]) public tableAddresses;
    mapping(uint256 => mapping(address => uint256)) public donationsCountReceivedAlready;

    mapping(uint256 => mapping(address => uint256)) public refTableSum;
    mapping(uint256 => mapping(address => uint256)) public missedRefTableSum;
    mapping(uint256 => mapping(address => uint256)) public donationTableSum;
    mapping(uint256 => mapping(address => uint256)) public donationRefTableSum;
    mapping(uint256 => mapping(address => uint256)) public missedDonationRefTableSum;

    mapping(address => uint256) public refSum;
    mapping(address => uint256) public missedRefSum;
    mapping(address => uint256) public donationSum;
    mapping(address => uint256) public donationRefSum;
    mapping(address => uint256) public missedDonationRefSum;

    mapping(uint256 => mapping(uint256 => uint256)) public refMatrix; // [table_from][table_to] => ref
    mapping(uint256 => mapping(uint256 => uint256)) public donationMatrix; // [table_from][table_to] => donation
    mapping(uint256 => mapping(uint256 => uint256)) public donationRefMatrix; // [table_from][table_to] => donation ref
    mapping(uint256 => mapping(uint256 => uint256)) public charityMatrix; // [table_from][table_to] => charity

    mapping(address => address) public parents;

    event InvestmentReceived(uint256 table, address initiator, address refferal, uint256 amount);
    event ReferralRewardSent(uint256 table, address initiator, address receiver, uint256 amount);
    event DonationRewardSent(uint256 table, address initiator, address receiver, uint256 amount);
    event DonationReferralRewardSent(uint256 table, address initiator, address receiver, uint256 amount);
    event CharitySent(uint256 table, address initiator, address receiver, uint256 amount);

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

    // buy without parent passed explicitly
    receive() external payable {
        if (parents[msg.sender] == address(0)) { // no parent found
            process(msg.value, msg.sender, rootAddress);
        } else {
            process(msg.value, msg.sender, parents[msg.sender]);
        }
        // buy(parents[msg.sender]);
    }

    // buy with parent
    function buy(address parent) public payable {
        require(parent != address(0));
        if (parents[msg.sender] != parent) { // prevent an attempt to change parent
            process(msg.value, msg.sender, parents[msg.sender]);
        } else {
            process(msg.value, msg.sender, parent);
        }
        // if ((parents[msg.sender] != parent) && (parents[msg.sender] != address(0))) {
        //     parent = parents[msg.sender];
        // }
        // if (parent == address(0)) {
        //     parent = rootAddress;
        // }
        // process(msg.value, msg.sender, parent);
    }

    function process(uint256 value, address sender, address parent) private {
        require(value > 0);
        uint256 currentTable = address2table[sender];
        uint256 newTable = value2table[currentTable][value];
        require(newTable > currentTable);

        emit InvestmentReceived(newTable, sender, parent, value);

        // Get table params
        Table memory t = tables[newTable];

        // Direct Ref Payout
        payoutReferralReward(newTable, sender, parent, refMatrix[currentTable][newTable]);

        for (uint256 i = 1; i <= t.donationsCount; i++){
            // Donation Ref Payout
            address winner = tableAddresses[newTable][random(tableAddresses[newTable].length, i)];
            payoutDonationReferralReward(newTable, sender, parents[winner], donationRefMatrix[currentTable][newTable]);

            // Donation Payout
            payoutDonationReward(newTable, sender, winner,  donationMatrix[currentTable][newTable]);
        }

        address2table[sender] = newTable;
        for (uint256 i = currentTable; i < newTable; i++){
            tableAddresses[i + 1].push(sender);
        }
        parents[sender] = parent;

        payout(charityAddress, charityMatrix[currentTable][newTable]);
        emit CharitySent(newTable, sender, charityAddress, charityMatrix[currentTable][newTable]);
    }

    function payoutDonationReward(uint256 tableNum, address sender, address winner, uint256 value) private {
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
        donationTableSum[tableNum][winner] += value;
        payout(winner, value);
        emit DonationRewardSent(tableNum, sender, winner, value);
    }

    function payoutDonationReferralReward(uint256 tableNum, address sender, address winnerParent, uint256 value) private {
        uint256 i = 0;
        while ((address2table[winnerParent] < tableNum) && (i < 5)) {
            missedDonationRefTableSum[tableNum][winnerParent] += value;
            missedDonationRefSum[winnerParent] += value;
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
            donationRefTableSum[tableNum][winnerParent] += value;
            donationRefSum[winnerParent] += value;
        }
        payout(winnerParent, value);
        emit DonationReferralRewardSent(tableNum, sender, winnerParent, value);
    }

    function payoutReferralReward(uint256 tableNum, address sender, address parent, uint256 value) private {
        uint256 i = 0;
        while ((address2table[parent] < tableNum) && (i < 5)) {
            missedRefTableSum[tableNum][parent] += value;
            missedRefSum[parent] += value;
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
        refTableSum[tableNum][parent] += value;
        refSum[parent] += value;
        payout(parent, value);
        emit ReferralRewardSent(tableNum, sender, parent, value);
    }

    function getTableAddressesCount(uint256 num) public view returns (uint256) {
        return tableAddresses[num].length;
    }

    function getTablesCount() public view returns (uint256) {
        return tables.length;
    }

    function getTableThreshold(uint256 num) public view returns (uint256) {
        require (num <= tables.length);
        return tables[num].thValue;
    }

    function appendTable(uint256 thValue, uint256 charityShare, uint256 refShare, uint256 donationsCount, uint256 donationShare, uint256 refDonationShare, uint256 maxDonationsCount, bool forceRebuildJUmpValues) public onlyOwner {
        setTableParams(tables.length, thValue, charityShare, refShare, donationsCount, donationShare, refDonationShare, maxDonationsCount, forceRebuildJUmpValues);
        tableAddresses[tables.length - 1].push(rootAddress);
    }

    function setTableParams(uint256 num, uint256 thValue, uint256 charityShare, uint256 refShare, uint256 donationsCount, uint256 donationShare, uint256 refDonationShare, uint256 maxDonationsCount, bool forceRebuildJUmpValues) public onlyOwner {
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
            for (uint256 i = 0; i < tables.length; i++) {
                for (uint256 j = 0; j < tables.length; j++) {
                    value2table[i][jumpValues[i][j]] = 0;
                }
            }
        }
        delete jumpValues;

        // Initial state of Jump Matrix
        uint256 accum = 0;
        jumpValues.push([0]);
        for (uint256 j = 1; j < tables.length; j++) {
            accum += tables[j].thValue;
            jumpValues[0].push(accum);
            // reversed mapping from sum to target table
            value2table[0][accum] = j;
            refMatrix[0][j] = accum * tables[j].refShare / 100;
            donationMatrix[0][j] = accum * tables[j].donationShare / 100;
            donationRefMatrix[0][j] = accum * tables[j].refDonationShare / 100;
            charityMatrix[0][j] = accum * tables[j].charityShare / 100;
        }

        // Rest part of Jump Matrix
        uint256 val;
        for (uint256 i = 1; i < tables.length; i++) {
            jumpValues.push([0]);
            for (uint256 j = 1; j < tables.length; j++) {
                if (j < i) {
                    jumpValues[i].push(0);
                } else {
                    val = jumpValues[i - 1][j] - jumpValues[i - 1][i];
                    jumpValues[i].push(val);
                    value2table[i][val] = j;

                    refMatrix[i][j] = val * tables[j].refShare / 100;
                    donationMatrix[i][j] = val * tables[j].donationShare / 100;
                    donationRefMatrix[i][j] = val * tables[j].refDonationShare / 100;
                    charityMatrix[i][j] = val * tables[j].charityShare / 100;
                }
            }
        }

        address2table[rootAddress] = uint256(tables.length);
    }

    function random(uint256 max, uint256 salt) public view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp * salt, block.difficulty, msg.sender))) % max;
    }

    function payout(address receiver, uint256 value) private {
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
        for (uint256 i = 0; i < tables.length; i++) {
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
