// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./token.sol";

contract MultisigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data,
        address addressToken,
        address by,
        bool cancel
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event CancelTransaction(address indexed owner, uint indexed txIndex);
    event SetNumConfirmation(uint indexed num);
    event CreateToken(address indexed addressToken, string name, string symbol, uint indexed value);
    event CreateOwner(address indexed ownerAddress);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    Token[] public token;

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
        emit CreateOwner(_owner);
    }

    function addNumConfirmationsRequired(uint _num) public onlyOwner {
        require(owners.length >= _num && _num > 0, " < owners");
        numConfirmationsRequired = _num;
        emit SetNumConfirmation(_num);
    }

    function createToken(string memory name, string memory symbol, uint value) public returns (Token) {
        Token toke = new Token(name, symbol, value);
        token.push(toke);
        emit CreateToken(address(toke),name,symbol,value);
        return toke;

    }

    function getToken(uint ind) public view returns (address addressToken, string memory name, string memory symbol, uint value) {
        address x = Token(token[ind]).addr();
        addressToken = address(token[ind]);
        name = Token(token[ind]).name();
        symbol = Token(token[ind]).symbol();
        value = Token(token[ind]).balanceOf(x);
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

        transactions.push(Transaction({
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

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data, _addressToken, msg.sender, false);
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

    function cancelTransaction(uint _txIndex) public txExists(_txIndex) notExecuted(_txIndex) notCancel(_txIndex) {
        Transaction storage tran = transactions[_txIndex];
        require(tran.by == msg.sender, 'not creator transaction');
        tran.cancel = true;
        emit CancelTransaction(msg.sender, _txIndex);

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
        return token.length;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTokens() public view returns (Token[] memory) {
        return token;
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
