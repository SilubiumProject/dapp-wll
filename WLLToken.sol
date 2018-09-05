pragma solidity ^0.4.18;

contract SafeMath {
  constructor() public {
  }
  
  function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
    uint256 z = _x + _y;
    assert(z >= _x);
    return z;
  }
  
  function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
    assert(_x >= _y);
    return _x - _y;
  }
  
  function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
    uint256 z = _x * _y;
    assert(_x == 0 || z / _x == _y);
    return z;
  }
}

/**
WLLoken Standard Token implementation
*/
contract WLLoken is SafeMath {
  uint8 public constant decimals = 8; // it's recommended to set decimals to 8 in Silubium
  address public owner;
  address public manager;
  bool private managerSet = false;

  string public constant name = 'Worldless Token';
  string public constant symbol = 'WLL';
  uint256 public totalSupply = 10**10 * 10**uint256(decimals);
  uint256 public currentSupply = 0;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;
  mapping (address => bool) public isApprovedMiner;
  
  uint public approvedMinerAmount = 0;
  address[] private approvedMinerAddresses;
  mapping(address => uint) private approvedMinerNum;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event ApproveMiner(address indexed _miner);
  event RemoveMiner(address indexed _miner);

  constructor() public {
    owner = msg.sender;
    balanceOf[owner] = totalSupply;
  }
  
  modifier onlyOwner{
    require(msg.sender == owner);
    _;
  }
  
  // owner can't transfer WLL to other addresses
  modifier isNotOwner{
    require(msg.sender != owner);
    _;
  }
  
  // validates an address - currently only checks that it isn't null
  modifier validAddress(address _address) {
    require(_address != 0x0);
    _;
  }
    
  // approves of the miner or recharges WLL to miner
  modifier onlyManager(){
    require(msg.sender == manager);
    _;
  }

  // validates a miner    
  modifier mintAuth(address _address){
    require(isApprovedMiner[_address]);
    _;
  }

  // changes owner ,the handover of power
  function changeOwner(address _address) public validAddress(_address) onlyOwner returns (bool success){
    require(balanceOf[_address] == 0);
    balanceOf[_address] = balanceOf[owner];
    balanceOf[owner] = 0;
    owner = _address;
    emit Transfer(msg.sender, _address, balanceOf[_address]);
    return true;
  }

  //sets a single manager  
  function initialManager(address _address, uint256 _value) public validAddress(_address) onlyOwner returns (bool success){
    require(!managerSet);
    require(balanceOf[_address] == 0);
    currentSupply = _value;
    require(currentSupply <= totalSupply);
    manager = _address;
    balanceOf[manager] = currentSupply;
    managerSet = true;
    balanceOf[owner] = safeSub(balanceOf[owner], _value);
    emit Transfer(owner, manager, _value);
    return true;
  }
  
  //changes manager  
  function changeManager(address _address) public validAddress(_address) onlyOwner returns (bool success){
    require(managerSet);
    require(balanceOf[_address] == 0);
    emit Transfer(manager, _address, balanceOf[manager]);
    balanceOf[_address] = balanceOf[manager]; 
    balanceOf[manager] = 0;
    manager = _address;
    return true;
  }
	
  function transfer(address _to, uint256 _value) public isNotOwner validAddress(_to) returns (bool success){
    balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
    balanceOf[_to] = safeAdd(balanceOf[_to], _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public isNotOwner validAddress(_from) validAddress(_to) returns (bool success){
    allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
    balanceOf[_from] = safeSub(balanceOf[_from], _value);
    balanceOf[_to] = safeAdd(balanceOf[_to], _value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public isNotOwner validAddress(_spender) returns (bool success){
    require(_value == 0 || allowance[msg.sender][_spender] == 0);
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  
  // disable pay SLU to this contract
  function () public payable{
    revert();
  }
    
  function approveMiner(address _miner) public validAddress(_miner) onlyManager() returns (bool success){
    require(isApprovedMiner[_miner] == false);
    isApprovedMiner[_miner] = true;
    approvedMinerAddresses.push(_miner);
    approvedMinerAmount = approvedMinerAmount+1;
    approvedMinerNum[_miner] = approvedMinerAddresses.length - 1;
    emit ApproveMiner(_miner);
    return true;
  }
  
  // gets all approved miners' addresses
  function getApprovedAddress (uint _index) public onlyManager view returns (address)
  {
     require(_index<approvedMinerAddresses.length);
     return  approvedMinerAddresses[_index];
  }
  
  function removeMiner(address _miner) public validAddress(_miner) onlyManager() returns (bool success){
    require(isApprovedMiner[_miner] == true);
    isApprovedMiner[_miner] = false;
    approvedMinerAmount = approvedMinerAmount-1;
    delete approvedMinerAddresses[approvedMinerNum[_miner]];
    emit RemoveMiner(_miner);
    return true;
  }
  
  // recharges WLL to miner
  function mint(address _receiver, uint256 _value) public validAddress(_receiver) onlyManager() mintAuth(_receiver) returns (bool success){
    currentSupply = safeAdd(currentSupply, _value);
    require(currentSupply <= totalSupply);
    balanceOf[_receiver] = safeAdd(balanceOf[_receiver], _value);
    balanceOf[owner] = safeSub(balanceOf[owner], _value);
    emit Transfer(owner, _receiver, _value);
    return true;
  }

  // recycles the WLL
  function recycle(address _spender, uint256 _value)  public validAddress(_spender) onlyManager() returns (bool success){
    require(balanceOf[_spender] >= _value);
    balanceOf[_spender] = safeSub(balanceOf[_spender], _value);
    currentSupply = safeSub(currentSupply, _value); 
    balanceOf[owner] = safeAdd(balanceOf[owner], _value);
    emit Transfer(_spender, owner, _value);
    return true;
  }
}
