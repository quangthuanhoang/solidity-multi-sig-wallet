// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./token.sol"
contract MultisigWallet {
event Deposit(address indexed sender, uint amount, uint balance);
event SubmitTransaction(
address indexed owner,
uint indexed txIndex,
address indexed to,
uint value,
bytes data
);
event ConfirmTransaction(address indexed owner, uint indexed txIndex);
event RevokeConfirmation(address indexed owner, uint indexed txIndex);
event ExecuteTransaction(address indexed owner, uint indexed txIndex);

address[] public owners;
mapping(address => bool) public isOwner;
uint public numConfirmationsRequired;

Token[] public token1;

struct Transaction {
address to;
uint value;
bytes data;
bool executed;
uint numConfirmations;
bool cancel;
address addressToken;
address by;
}

mapping(uint => mapping(address => bool)) public isConfirmed;

Transaction[] public transactions;
constructor (){
isOwner[msg.sender] = true;
owners.push(msg.sender);
numConfirmationsRequired = 1;
}

modifier onlyOwner() {
require(isOwner[msg.sender], "not owner");
_;
}

modifier txExists(uint _txIndex) {
require(_txIndex < transactions.length, "tx does not exist");
_;
}

modifier notExecuted(uint _txIndex) {
require(!transactions[_txIndex].executed, "tx already executed");
_;
}

modifier notConfirmed(uint _txIndex) {
require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
_;
}
modifier ownTrans(uint _txIndex) {
require(transactions[_txIndex].by == msg.sender, "not the creator of the transaction");
_;
}
modifier notCancel(uint _txIndex) {
require(!transactions[_txIndex].cancel, "tx already canceled");
_;
}

function createOwner(address _owner) public onlyOwner {
    require(_owner != address(0), "aaaa");
    require(!isOwner[_owner], "already the owner");
    isOwner[_owner] = true;
    owners.push(_owner);
}

function addNumConfirmationsRequired(uint _num) public onlyOwner {
    require(owners.length >= _num," < owners");
    numConfirmationsRequired = _num;
}

function createToken(string memory name, string memory symbol, uint value) public returns (Token) {
Token toke = new Token(name, symbol,value);
token1.push(toke);
return toke;
}

function getBal(uint ind) public view returns (address x, string memory y, string memory t, uint z) {
x = Token(token1[ind]).addr();
y = Token(token1[ind]).name();
t = Token(token1[ind]).symbol();
z = Token(token1[ind]).balanceOf(x);
}

receive() external payable {
emit Deposit(msg.sender, msg.value, address(this).balance);
}

function submitTransaction(
address _to,
uint _value,
bytes memory _data,
address _addressToken
) public onlyOwner {
uint txIndex = transactions.length;

transactions.push(
Transaction({
to : _to,
value : _value,
data : _data,
executed : false,
numConfirmations : 0,
cancel : false,
by : msg.sender,
addressToken : _addressToken
})
);

emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
}

function confirmTransaction(uint _txIndex)
public
onlyOwner
txExists(_txIndex)
notExecuted(_txIndex)
notConfirmed(_txIndex)
notCancel(_txIndex)
{
Transaction storage transaction = transactions[_txIndex];
transaction.numConfirmations += 1;
isConfirmed[_txIndex][msg.sender] = true;

emit ConfirmTransaction(msg.sender, _txIndex);
}

function executeTransaction(uint _txIndex)
public
onlyOwner
txExists(_txIndex)
notExecuted(_txIndex)
notCancel(_txIndex)
{
Transaction storage transaction = transactions[_txIndex];

require(
transaction.numConfirmations >= numConfirmationsRequired,
"cannot execute tx"
);

transaction.executed = true;

Token(transaction.addressToken).transfer(transaction.to, transaction.value);

emit ExecuteTransaction(msg.sender, _txIndex);
}

function revokeConfirmation(uint _txIndex)
public
onlyOwner
txExists(_txIndex)
notExecuted(_txIndex)
notCancel(_txIndex)
{
Transaction storage transaction = transactions[_txIndex];

require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

transaction.numConfirmations -= 1;
isConfirmed[_txIndex][msg.sender] = false;

emit RevokeConfirmation(msg.sender, _txIndex);
}

function getTokenCount() public view returns (uint){
return token1.length;
}

function getOwners() public view returns (address[] memory) {
return owners;
}

function getToken() public view returns (Token[] memory) {
return token1;
}

function getTransactionCount() public view returns (uint) {
return transactions.length;
}

function getTransaction(uint _txIndex)
public
view
returns (
address to,
uint value,
bytes memory data,
bool executed,
uint numConfirmations,
address addressToken,
address by,
bool cancel
)
{
Transaction storage transaction = transactions[_txIndex];

return (
transaction.to,
transaction.value,
transaction.data,
transaction.executed,
transaction.numConfirmations,
transaction.addressToken,
transaction.by,
transaction.cancel
);
}
}
