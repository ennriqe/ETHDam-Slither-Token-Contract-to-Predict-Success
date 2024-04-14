// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MintOperations} from "./MintOperation.sol";

type OpIndex is uint256;

library OpIndices {
    function prev(OpIndex self) internal pure returns (OpIndex) {
        return OpIndex.wrap(OpIndex.unwrap(self) - 1);
    }

    function next(OpIndex self) internal pure returns (OpIndex) {
        return OpIndex.wrap(OpIndex.unwrap(self) + 1);
    }
}

library MintOperationArrays {
    struct Array {
        MintOperations.Op[] _array;
    }

    function at(
        MintOperationArrays.Array storage self,
        OpIndex opIndex
    ) internal view returns (MintOperations.Op storage) {
        return self._array[OpIndex.unwrap(opIndex)];
    }

    function length(MintOperationArrays.Array storage self) internal view returns (OpIndex) {
        return OpIndex.wrap(self._array.length);
    }

    function push(MintOperationArrays.Array storage self) internal returns (MintOperations.Op storage) {
        return self._array.push();
    }
}
