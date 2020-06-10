pragma solidity >=0.4.22 <0.7.0;

/**
 * @title Storage
 * @dev Store & retreive value in a variable
 */
contract CBAToken {

    string constant backingBlockchainName = "Bitcoin";
    string constant networkName = "private";
    uint256 totalSupply_;
    mapping(address => uint256) lockedBalances;
    mapping(address => uint256) balances;
    // address ibcServerPublicKeyAddress = 0x72ba7d8e73fe8eb666ea66babc8116a41bfb10e2;
    uint issueRequestId = 0;
    uint redeemRequestId = 0;
    
    struct IssueRequest{
        uint id;
        address ownerAddress;
        string backingAddress;
        string txHash;
        string blockHash;
        bool completed;
    }
    
    struct RedeemRequest{
        uint id;
        uint amount;
        address ownerAddress;
        string backingAddress;
        bool completed;
    }
    
    IssueRequest[] public issueRequests;
    RedeemRequest[] public redeemRequests;
    mapping(uint => address) requestOwners;
    
    // Issue Reqeust From User
    function issueRequest(string memory _backingAddress, string memory _txHash, string memory _blockHash, string memory _signature) public returns (uint){
        issueRequests.push(IssueRequest(issueRequestId, msg.sender, _backingAddress, _txHash, _blockHash, false));
        issueRequestId += 1;
        requestOwners[issueRequestId] = msg.sender;
        emit IssueRequestEvent(issueRequestId, msg.sender, _txHash, _blockHash, _signature);
    }
    
    function issue(uint _issueRequestId, uint256 _amount, string memory _backingAddress, string memory _txHash, string memory _blockHash, bool _result) public returns (uint){
        // require(msg.sender == ibcServerPublicKeyAddress);
        IssueRequest memory request = issueRequests[_issueRequestId];
        require(compareStrings(request.backingAddress, _backingAddress));
        require(compareStrings(request.txHash, _txHash));
        require(compareStrings(request.blockHash, _blockHash));
        require(_result == true);
        
        totalSupply_ += _amount;
        balances[msg.sender] += _amount;
    }
    
    // redeem Request from user.
    function redeemRequest(uint amount, string memory backingBlockchainAddress) public returns (uint){
        require(balances[msg.sender] >= amount);
        redeemRequests.push(RedeemRequest(redeemRequestId, amount, msg.sender, backingBlockchainAddress, false));
        redeemRequestId += 1;
        balances[msg.sender] -= amount;
        lockedBalances[msg.sender] += amount;
        emit RedeemRequestEvent(redeemRequestId, msg.sender, amount, backingBlockchainAddress);
    }
    
    function redeem(uint _redeemRequestId, uint _amount, address _ownerAddress, string memory _backingAddress, bool _result) public returns (uint){
        // require(msg.sender == ibcServerPublicKeyAddress);
        // TODO result에 txhash, blockhash 넣는건??
        RedeemRequest memory request = redeemRequests[_redeemRequestId];
        require(compareStrings(request.backingAddress, _backingAddress));
        require(request.ownerAddress == _ownerAddress);
        require(_result == true);
        
        // burn
        burn(msg.sender, _amount);
    }

    function totalSupply() public view returns (uint){
        return totalSupply_;
    }
    
    function balanceOf(address owner) public view returns (uint balance){
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns (bool success){
        require(to != address(0));
        require(value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - value;
        balances[to] = balances[to] + value;
        return true;
    }
    
    function burn(address _targetAddress, uint _amount) private {
        lockedBalances[_targetAddress] -= _amount;
        totalSupply_ -= _amount;
    }
    
    function getIssueReqeust(uint _id) public view returns (uint id, string memory backingAddress, string memory txHash){
        uint a = issueRequests[_id].id;
        string memory b = issueRequests[_id].backingAddress;
        string memory c = issueRequests[_id].txHash;
        return (a, b, c);
    }
    
    
    function compareStrings (string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );
    }

    event Transfer(address indexed from, address indexed to, uint tokens);
    event IssueRequestEvent(uint issueRequestId, address issuer, string txHash, string blockHash, string signature);
    event RedeemRequestEvent(uint redeemRequestId, address issuer, uint amount, string backingBlockchainAddress);

}
