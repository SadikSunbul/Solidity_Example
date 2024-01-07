// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {} //Para kabul eder bu contract

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "caller is not owner"); //sadece owner cagıra bılır bu fonksıyonu
        payable(msg.sender).transfer(_amount); //parayı owneren hesabına transfer eder
    }

    function getBalance() external view returns (uint) {
        return address(this).balance; //cuzdanda bırıken para mıktarını doner
    }
}
