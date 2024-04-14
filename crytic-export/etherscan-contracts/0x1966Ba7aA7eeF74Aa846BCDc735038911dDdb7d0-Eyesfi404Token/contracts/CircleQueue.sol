pragma solidity ^0.8.0;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CircleQueue is UUPSUpgradeable, OwnableUpgradeable{
    uint256[] private ids;
    address[] private owners;
    uint256[] private times;

    uint256 private front;
    uint256 private back;
    uint256 private capacity;

    mapping(address => bool) private allowedCallers;


    modifier onlyAllowedCaller() {
        require(allowedCallers[msg.sender], "Caller is not allowed");
        _;
    }
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        front = 0;
        back = 0;
        capacity = 10000;
    }
    function setAllowedCaller(address _caller, bool _status) public onlyOwner {
        allowedCallers[_caller] = _status;
    }

    function enqueue(uint256 id, address owner, uint256 time) public onlyAllowedCaller {
        require((back + 1) % capacity != front, "Queue is full");

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
        require(front != back, "Queue is empty"); 

        uint256 id = ids[front];
        address owner = owners[front];
        uint256 time = times[front];

        front = (front + 1) % capacity;

        return (id, owner, time);
    }

    function peek(uint256 _index) public view returns (uint256, address, uint256) {
        require(front != back, "Queue is empty"); 
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
            return capacity - front + back; 
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

    function _authorizeUpgrade(address) internal override onlyOwner {}

    uint256[43] private __gap;
}
