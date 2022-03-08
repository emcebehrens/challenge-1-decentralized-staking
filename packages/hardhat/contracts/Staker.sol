// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  // state variables
  ExampleExternalContract public exampleExternalContract;

  mapping ( address => uint256 ) public balances;
  uint256 public constant _threshold = 1 ether;
  uint256 public _deadline = block.timestamp + 30 seconds;
  bool private openForWithdraw = false;

  // events
  event Stake(address, uint256);

  // modifiers
  modifier notCompleted() {
      require(!exampleExternalContract.completed(), "already completed");
      // Underscore is a special character only used inside
      // a function modifier and it tells Solidity to
      // execute the rest of the code.
      _;
  }

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  // The balance of this contract will be automatically updated.
  function stake() public payable {
    //uint deposit_amount = msg.value / 1 gwei;
    //require(deposit_amount <= type(uint64).max, "stake: deposit value too high");

    balances[msg.sender] += msg.value;

    console.log("function stake", msg.sender, balances[msg.sender]);

    emit Stake(msg.sender, balances[msg.sender]);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted {
    console.log("function execute", timeLeft(), openForWithdraw);
    if ((timeLeft() == 0) && (!openForWithdraw))
    {
      console.log("expired", address(this).balance);
      if (address(this).balance >= _threshold) {
        console.log("saving into external contract" );
        exampleExternalContract.complete{value: address(this).balance}();
      } else {
        // if the `threshold` was not met, allow everyone to call a `withdraw()` function
        console.log("enbaled withdraw" );
        openForWithdraw = true;
      }
    }
  }

  // Add a `withdraw(address payable)` function lets users withdraw their balance
  function withdraw(address payable _to) external notCompleted {
      //require(msg.sender == owner, "caller is not owner");
      if (openForWithdraw) {
        console.log("function withdraw", msg.sender );
        
        // This function is no longer recommended for sending Ether.
        //_to.transfer(_balances[msg.sender]);

        // Send returns a boolean value indicating success or failure.
        // This function is not recommended for sending Ether.
        bool sent = _to.send(balances[msg.sender]);
        require(sent, "Failed to send Ether");
        balances[msg.sender] = 0;
      } else {
        console.log("withdraw NOT open" );
      }
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    //console.log("timeLeft:");
    //console.log("\tdeadline", _deadline);
    //console.log("\ttimestamp", block.timestamp);
    //for no-transaction calls this value can be anything from zero to a random number depending on the EVM implementation
    if (block.timestamp >= _deadline) {
      return 0;
    }
    return (_deadline - block.timestamp);
  }

  // Add the `receive()` special function that receives eth and calls stake()
  // This function cannot have arguments, cannot return anything and must have external visibility and payable state mutability.
  receive() external payable { 
    stake();
  }

}
