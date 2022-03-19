// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CoinFlip is Ownable{
    using SafeMath for uint256;

    function rand() public view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp +
            block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return (seed - ((seed / 1000) * 1000));
    }
    
    struct Bet {
        address addr; // gambler's address
        uint blockNumber; // block number of placeBet tx
        bool heads; // true for heads, false for tails
        bool win; // true if gambler wins
        uint256 winAmount; // wager amount in wei
        uint256 transferred; // amount of wei transferred to gambler
    }
    
    uint256 public minimumBet;
    uint256 public maximumBet;
    uint256 public returnRate;
    uint256 public betsCounter;
    mapping (uint => Bet) public bets;
    
    constructor (uint _returnRate, uint _minimumBet, uint _maximumBet) {
        returnRate = _returnRate;
        minimumBet = _minimumBet;
        maximumBet = _maximumBet;
        betsCounter = 0;
    }

    event resultInfo(uint256 _id, string _result, uint256 _transferred);

    function _headsOrTails(bool heads) private view returns (bool) {
        uint256 r = rand();
        if (r < uint256(500)) {
            return heads;
        } else {
            return !heads;
        }
    }

    function placeBet(bool _heads) public payable {
        require((msg.value >= minimumBet) && (msg.value <= maximumBet), "Bet amount must be between minimumBet and maximumBet");

        bool result = _headsOrTails(_heads);
        if (result) {
            // win
            if (address(this).balance < msg.value * (returnRate / 100)) {
                // user wins, but contract has not enough balance to cover
                // give gamler all the money 

                bets[betsCounter++] = Bet({
                    addr: msg.sender,
                    blockNumber: block.number,
                    heads: _heads,
                    win: true,
                    winAmount: address(this).balance,
                    transferred: address(this).balance
                });

                emit resultInfo(betsCounter, "win", address(this).balance);

                payable(msg.sender).transfer(address(this).balance);
            }
            else {
                // user wins, contract has enough balance to cover

                bets[betsCounter++] = Bet({
                    addr: msg.sender,
                    blockNumber: block.number,
                    heads: _heads,
                    win: true,
                    winAmount: msg.value * (returnRate / 100),
                    transferred: msg.value + msg.value * (returnRate / 100)
                });

                emit resultInfo(betsCounter, "win", msg.value + msg.value * (returnRate / 100));

                payable(msg.sender).transfer(msg.value + msg.value * (returnRate / 100));
            }
        } else {
            emit resultInfo(betsCounter, "lose", 0);
        }
    }
}