pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 1 ether;
  bool public openForWithdraw = false;

  uint256 public deadline = block.timestamp + 30 seconds;

  event Stake(address _staker, uint256 _amount);

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake(uint256 _amount) public payable {
    require(msg.value == _amount);
    balances[msg.sender] += _amount;
    emit Stake(msg.sender, _amount);
  }

  modifier onlyAfterDeadline() {
    require (timeLeft() == 0, "deadline has not been reached yet");
    _;
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() onlyAfterDeadline public {
    console.log("contract balance is %d", address(this).balance);

    require(exampleExternalContract.completed == false); // h: execute() should be called once only

    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else if (address(this).balance < threshold) {
      openForWithdraw = true;
    }
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  // for now, withdraw() withdraws all funds of a user
  function withdraw() onlyAfterDeadline public {
    require(openForWithdraw == true);
    msg.sender.transfer(balances[msg.sender]);
    balances[msg.sender] = 0;
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (deadline <= now) {
      return 0;
    } else {
      return deadline - now;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake(msg.value);
  }
}
