// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContributionSystem {
    struct Participant {
        uint id;
        uint depositAmount;
        bool receivedFunds;
        bool exists;
        uint lastDepositTime;
    }

    address public host;
    uint public startTime;
    uint public dayRange;
    uint public expectedNumber;
    uint public contributionAmount;
    uint public currentParticipants;
    mapping(address => Participant) public participants;
    address[] public participantList;

    event Deposit(address indexed participant, uint amount);
    event FundsTransferred(uint amount);
    event ParticipantRemoved(address participant);

    constructor(uint _dayRange, uint _expectedNumber, uint _contributionAmount) {
        host = msg.sender;
        startTime = block.timestamp;
        dayRange = _dayRange;
        expectedNumber = _expectedNumber;
        contributionAmount = _contributionAmount;
    }

    modifier onlyHost() {
        require(msg.sender == host, "Only the host can call this function");
        _;
    }

    modifier canJoin() {
        require(currentParticipants < expectedNumber, "The maximum number of participants has been reached");
        require(block.timestamp < startTime + dayRange * 1 days, "Contribution period has ended");
        require(participants[msg.sender].id == 0, "You are already a participant");
        _;
    }

    function join() external payable canJoin {
        currentParticipants++;
        participants[msg.sender] = Participant(currentParticipants, msg.value, false, true, block.timestamp);
        participantList.push(msg.sender);
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {
        require(participants[msg.sender].id != 0, "You are not a participant");
        require(msg.value == contributionAmount, "Please send the exact contribution amount");

        participants[msg.sender].depositAmount += msg.value;
        participants[msg.sender].lastDepositTime = block.timestamp;
        emit Deposit(msg.sender, msg.value);
    }

    function distributeFunds() external onlyHost {
        require(block.timestamp >= startTime + dayRange * 1 days, "Contribution period has not ended yet");

        uint totalAmount = address(this).balance;

        for (uint i = 0; i < participantList.length; i++) {
            address participantAddress = participantList[i];
            if (!participants[participantAddress].receivedFunds) {
                payable(participantAddress).transfer(contributionAmount);
                participants[participantAddress].receivedFunds = true;
                emit FundsTransferred(contributionAmount);
            }
        }
    }

    function automaticParticipantRemoval() external {
        require(block.timestamp >= startTime + dayRange * 1 days, "Contribution period has not ended yet");

        for (uint i = 0; i < participantList.length; i++) {
            address participantAddress = participantList[i];
            if (participants[participantAddress].exists &&
                !participants[participantAddress].receivedFunds &&
                block.timestamp >= participants[participantAddress].lastDepositTime + dayRange * 1 days) {
                removeParticipant(participantAddress);
            }
        }
    }

    function removeParticipant(address participant) internal {
        currentParticipants--;
        delete participants[participant];
        emit ParticipantRemoved(participant);
    }

    function withdraw() external onlyHost {
        require(block.timestamp >= startTime + dayRange * 1 days, "Contribution period has not ended yet");

        uint totalAmount = address(this).balance;
        payable(host).transfer(totalAmount);
    }
}
