// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CircleQueue is OwnableUpgradeable{
    uint256[] private ids;
    address[] private owners;
    uint256[] private times;

    uint256 private front = 0;
    uint256 private back = 0;
    uint256 private capacity = 10000;

    mapping(address => bool) private allowedCallers;


    modifier onlyAllowedCaller() {
        require(allowedCallers[msg.sender], "Caller is not allowed");
        _;
    }
    function initialize() public initializer{
        __Ownable_init();
    }
    function setAllowedCaller(address _caller, bool _status) public onlyOwner {
        allowedCallers[_caller] = _status;
    }

    function enqueue(uint256 id, address owner, uint256 time) public onlyAllowedCaller {
        require((back + 1) % capacity != front, "Queue is full"); // 确保队列未满

        // 检查是否需要扩容（动态数组会自动扩容，但这里控制最大容量）
        if (ids.length < capacity) {
            ids.push(id);
            owners.push(owner);
            times.push(time);
        } else {
            ids[back] = id;
            owners[back] = owner;
            times[back] = time;
        }

        back = (back + 1) % capacity;
    }

    function dequeue() public onlyAllowedCaller returns (uint256, address, uint256)  {
        require(front != back, "Queue is empty"); // 确保队列不为空

        uint256 id = ids[front];
        address owner = owners[front];
        uint256 time = times[front];

        front = (front + 1) % capacity;

        return (id, owner, time);
    }

    function peek(uint256 _index) public view returns (uint256, address, uint256) {
        require(front != back, "Queue is empty"); // 确保队列不为空
        require(_index <= size(), "End index out of bounds");
        uint256 index = (front + _index) % capacity;
        return (ids[index], owners[index], times[index]);
    }

    function isEmpty() public view returns (bool) {
        return front == back;
    }

    function isFull() public view returns (bool) {
        return (back + 1) % capacity == front;
    }

    function size() public view returns (uint256) {
        if (back >= front) {
            return back - front;
        } else {
            return capacity - front + back; // 处理循环队列的情况
        }
    }

    function getCapacity() public view returns (uint256) {
        return capacity;
    }
  
    function getIdsByRange(uint256 start, uint256 end) public view returns (uint256[] memory) {
        require(start <= end, "Start index must be less than or equal to end index");
        require(end <= size(), "End index out of bounds");
        
        uint256 rangeSize = end - start;
        uint256[] memory rangeIds = new uint256[](rangeSize);
        
        for (uint256 i = 0; i < rangeSize; i++) {
            uint256 index = (front + start + i) % capacity;
            rangeIds[i] = ids[index];
        }
        
        return rangeIds;
    }

}
