pragma solidity ^0.5.10;

contract Storage {
    event Data(bytes32 indexed id, address from, uint timestamp, string data);
    event DataIndexedByFromAddr(address indexed from, bytes32 indexed id, uint timestamp, string data);
    function store(string memory data) public {
        bytes32 id = keccak256(abi.encodePacked(data));
        emit Data(id, msg.sender, now, data);
        emit DataIndexedByFromAddr(msg.sender, id, now, data);
    }
}

contract StorageBatch {
    function batchStore(bytes memory data) public {
        assembly {
            let p := add(data, 20)
            let storageAddress := and(mload(p), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            p := add(p, 2)
            let remaining := and(mload(p), 0xFFFF)
            p := add(p, 32)
            let buf := mload(0x40)
            mstore(buf, 0x131a068000000000000000000000000000000000000000000000000000000000)
            mstore(add(buf, 32), 0x0000002000000000000000000000000000000000000000000000000000000000)
            mstore(add(buf, 64), 0x0000003b00000000000000000000000000000000000000000000000000000000)
            for { } gt(remaining, 0) { remaining := sub(remaining, 1) } {
                mstore(add(buf, 68), mload(p))
                p := add(p, 32)
                mstore(add(buf, 100), mload(p))
                p := add(p, 27)
                let r := call(gas, storageAddress, 0, buf, 127, 0, 0)
                if iszero(r) {
                    revert(0, 0)
                }
            }
        }
    }
}