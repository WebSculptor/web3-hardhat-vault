// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define the contract
contract Vault {
    // Define state variables
    address public owner; // Address of the contract owner
    mapping(address => uint256) public grants; // Mapping to track granted amounts for each beneficiary
    mapping(address => uint256) public claimTimers; // Mapping to track unlock time for each beneficiary

    // Define events
    event GrantOffered(
        address indexed donor,
        address indexed beneficiary,
        uint256 amount,
        uint256 unlockTime
    ); // Event emitted when a grant is offered
    event GrantClaimed(address indexed beneficiary, uint256 amount); // Event emitted when a grant is claimed

    // Constructor function to set the contract owner
    constructor() {
        owner = msg.sender; // Set the owner to the address deploying the contract
    }

    // Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action"); // Ensure only the owner can execute the function
        _; // Continue executing the function
    }

    // Function for a donor to offer a grant to a beneficiary
    function offerGrant(
        address _beneficiary,
        uint256 _unlockTime
    ) external payable {
        // Check if the sent amount is greater than 0 and the beneficiary address is valid
        require(msg.value > 0, "Amount must be greater than 0");
        require(_beneficiary != address(0), "Invalid beneficiary address");
        // Check if the unlock time is in the future
        require(
            _unlockTime > block.timestamp,
            "Unlock time must be in the future"
        );

        // Increment the granted amount for the beneficiary
        grants[_beneficiary] += msg.value;
        // Set the unlock time for the beneficiary
        claimTimers[_beneficiary] = _unlockTime;

        // Emit an event indicating the grant offer
        emit GrantOffered(msg.sender, _beneficiary, msg.value, _unlockTime);
    }

    // Function for a beneficiary to claim a grant
    function claimGrant() external {
        // Get the granted amount and unlock time for the caller
        uint256 amount = grants[msg.sender];
        uint256 unlockTime = claimTimers[msg.sender];

        // Check if there is a grant available for the caller and if it's time to claim
        require(amount > 0, "No grant available for the caller");
        require(
            block.timestamp >= unlockTime,
            "Grant is not yet available for claiming"
        );

        // Reset the granted amount and unlock time for the caller
        grants[msg.sender] = 0;
        claimTimers[msg.sender] = 0;
        // Transfer the granted amount to the caller
        payable(msg.sender).transfer(amount);

        // Emit an event indicating the grant claim
        emit GrantClaimed(msg.sender, amount);
    }

    // Function for the owner to withdraw Ether from the contract
    function withdraw(uint256 _amount) external onlyOwner {
        // Check if the withdrawal amount is available in the contract balance
        require(
            _amount <= address(this).balance,
            "Insufficient balance in the contract"
        );

        // Transfer the specified amount to the owner
        payable(owner).transfer(_amount);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
