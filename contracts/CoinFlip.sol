// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CoinFlip is Ownable, Pausable {
    using SafeMath for uint256;

    function rand() public view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
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
    Bet[] public bets;
    
    constructor (uint _minimumBet, uint _maximumBet, uint _returnRate) {
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

    function placeBet(bool _heads) public payable whenNotPaused {
        require((msg.value >= minimumBet) && (msg.value <= maximumBet), "Bet amount must be between minimumBet and maximumBet");

        bool result = _headsOrTails(_heads);
        if (result) {
            // win
            uint256 winAmount = (msg.value).mul(returnRate).div(100);
            uint256 transferAmount = winAmount + msg.value;

            if (address(this).balance < winAmount) {
                // user wins, but contract has not enough balance to cover
                // give gamler all the money 

                betsCounter++;
                bets.push(Bet({
                    addr: msg.sender,
                    blockNumber: block.number,
                    heads: _heads,
                    win: true,
                    winAmount: winAmount,
                    transferred: address(this).balance
                }));

                emit resultInfo(betsCounter, "win", address(this).balance);

                payable(msg.sender).transfer(address(this).balance);
            }
            else {
                // user wins, contract has enough balance to cover
                
                betsCounter++;
                bets.push(Bet({
                    addr: msg.sender,
                    blockNumber: block.number,
                    heads: _heads,
                    win: true,
                    winAmount: winAmount,
                    transferred: transferAmount
                }));

                emit resultInfo(betsCounter, "win", transferAmount);

                payable(msg.sender).transfer(transferAmount);
            }
        } else {

            betsCounter++;
            bets.push(Bet({
                addr: msg.sender,
                blockNumber: block.number,
                heads: _heads,
                win: false,
                winAmount: 0,
                transferred: 0
            }));

            emit resultInfo(betsCounter, "lose", 0);
        }
    }

    function didGamblerWin(address gambler) public view returns(bool) {
        for (uint i=betsCounter.sub(1); i>0; i--) {
            if (bets[i].addr == gambler) {
                return bets[i].win;
            }
        }
        return false;
    }

    function insertFunds() public payable onlyOwner {
        payable(address(this)).call{value: msg.value};
    }

    function showFunds() public view onlyOwner returns (uint) {
        return address(this).balance;
    }

    function withdrawFunds(uint percentage) public onlyOwner {
        uint256 amount = address(this).balance.mul(percentage).div(100);
        payable(address(owner())).transfer(amount);
    }

    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
}