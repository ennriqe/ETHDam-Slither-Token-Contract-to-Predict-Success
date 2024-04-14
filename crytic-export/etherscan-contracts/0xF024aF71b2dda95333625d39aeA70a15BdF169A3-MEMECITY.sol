/**

 _____ ______   _______   _____ ______   _______           ________  ___  _________    ___    ___ 
|\   _ \  _   \|\  ___ \ |\   _ \  _   \|\  ___ \         |\   ____\|\  \|\___   ___\ |\  \  /  /|
\ \  \\\__\ \  \ \   __/|\ \  \\\__\ \  \ \   __/|        \ \  \___|\ \  \|___ \  \_| \ \  \/  / /
 \ \  \\|__| \  \ \  \_|/_\ \  \\|__| \  \ \  \_|/__       \ \  \    \ \  \   \ \  \   \ \    / / 
  \ \  \    \ \  \ \  \_|\ \ \  \    \ \  \ \  \_|\ \       \ \  \____\ \  \   \ \  \   \/  /  /  
   \ \__\    \ \__\ \_______\ \__\    \ \__\ \_______\       \ \_______\ \__\   \ \__\__/  / /    
    \|__|     \|__|\|_______|\|__|     \|__|\|_______|        \|_______|\|__|    \|__|\___/ /     
                                                                                     \|___|/      

Meme City is a collection based on the ERC404x token standard, consisting of 1,000 buildings,
coins, stickers, and characters that reside on the blockchain.


Telegram: https://t.me/MemeCity404
Twitter: https://twitter.com/MemeCity404
Website: https://memecity404.io


*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.20;

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    error Unauthorized();
    error InvalidOwner();

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    constructor(address _owner) {
        if (_owner == address(0x0)) revert InvalidOwner();

        owner = _owner;

        emit OwnershipTransferred(address(0x0), _owner);
    }

    function transferOwnership(address _owner) public virtual onlyOwner {
        if (_owner == address(0x0)) revert InvalidOwner();

        owner = _owner;

        emit OwnershipTransferred(msg.sender, _owner);
    }

    function revokeOwnership() public virtual onlyOwner {
        owner = address(0x0);

        emit OwnershipTransferred(msg.sender, address(0x0));
    }
}

abstract contract ERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721Receiver.onERC721Received.selector;
    }
}

library Packer
{
    struct Data
    {
        uint64 _popFrontIndex;
        uint64 _popFrontSign;
        uint64 _nextInternalIndex;
        uint64 _len;
        mapping(uint256 => uint256) _values;
    }

    error OutOfBounds();
    error UnevenEdit();
    error InsaneBulk();

    function push(Data storage self, uint256 valuesInElement, uint256 bitsInValue, uint256 value) internal returns(uint256) {
        unchecked {
            if (self._nextInternalIndex == valuesInElement || self._nextInternalIndex == 0)
            {
                self._values[self._len++] = value;
                self._nextInternalIndex = 1;
            }
            else
            {
                self._values[self._len - 1] += value << (self._nextInternalIndex++ * bitsInValue);
            }

            return (self._len - 1) * valuesInElement + self._nextInternalIndex - 1;
        }
    }

    function pushMany(Data storage self, uint256 valuesInElement, uint256 bitsInValue, uint256[] memory values) internal returns(uint256[] memory) {
        uint256 nextInternalIndex = self._nextInternalIndex;
        uint256 len = self._len;

        uint256 addLen = values.length;
        uint256[] memory returnIndexes = new uint256[](addLen);
        unchecked {
            uint256 currentValue = self._values[len - 1];
            for (uint256 i = 0; i < addLen; ++i) {
                if (nextInternalIndex == valuesInElement || nextInternalIndex == 0)
                {
                    self._values[len - 1] = currentValue;
                    self._values[len++] = values[i];
                    nextInternalIndex = 1;

                    currentValue = values[i];
                }
                else
                {
                    currentValue += values[i] << (nextInternalIndex++ * bitsInValue);
                }

                returnIndexes[i] = (len - 1) * valuesInElement + nextInternalIndex - 1;
            }

            self._values[len - 1] = currentValue;
        }

        self._nextInternalIndex = uint64(nextInternalIndex);
        self._len = uint64(len);

        return returnIndexes;
    }

    function get(Data storage self, uint256 valuesInElement, uint256 bitsInValue, uint256 index) internal view returns(uint256) {
        unchecked
        {
            if (self._len == 0 || index >= (self._len - 1) * valuesInElement + self._nextInternalIndex) {
                revert OutOfBounds();
            }

            uint256 arrIndex = index / valuesInElement;
            uint256 internalIndex = index % valuesInElement;
            uint256 number = self._values[arrIndex];

            if (internalIndex < valuesInElement - 1) {
                number = number >> internalIndex * bitsInValue;
                return number - ((number >> bitsInValue) << bitsInValue);
            }
            else {
                return number >> internalIndex * bitsInValue;
            }
        }
    }

    function edit(Data storage self, uint256 valuesInElement, uint256 bitsInValue, uint256 index, uint256 value) internal {
        unchecked
        {
            if (self._len == 0 || index >= (self._len - 1) * valuesInElement + self._nextInternalIndex) {
                revert OutOfBounds();
            }

            _edit(self, valuesInElement, bitsInValue, index, value);
        }
    }

    function editMany(Data storage self, uint256 valuesInElement, uint256 bitsInValue, uint256[] memory indexes, uint256[] memory values) internal {
        uint256 len = self._len;
        uint256 editLen = indexes.length;

        if (editLen != values.length) {
            revert UnevenEdit();
        }

        if (len == 0) {
            revert OutOfBounds();
        }
        
        unchecked {
            uint256 trueLen = (len - 1) * valuesInElement + self._nextInternalIndex;

            for (uint256 i = 0; i < editLen; ++i) {
                uint256 index = indexes[i];
                uint256 value = values[i];
            
                if (index >= trueLen) {
                    revert OutOfBounds();
                }

                _edit(self, valuesInElement, bitsInValue, index, value);
            }
        }
    }

    function _edit(Data storage self, uint256 valuesInElement, uint256 bitsInValue, uint256 index, uint256 value) private {
        unchecked {
            uint256 arrIndex = index / valuesInElement;
            uint256 internalIndex = index % valuesInElement;
            uint256 number = self._values[arrIndex];
            uint256 shift = internalIndex * bitsInValue;

            if (internalIndex < valuesInElement - 1) {
                number = number >> shift;
                uint256 oldValue = number - ((number >> bitsInValue) << bitsInValue);

                self._values[arrIndex] = self._values[arrIndex] - (oldValue << shift) + (value << shift);
            }
            else {
                self._values[arrIndex] = self._values[arrIndex] - (number >> shift << shift) + (value << shift);
            }
        }
    }

    function pop(Data storage self, uint256 valuesInElement, uint256 bitsInValue) internal returns(uint256) {
        unchecked
        {
            if (self._len == 0) {
                revert OutOfBounds();
            }

            uint256 arrIndex = self._len - 1;
            uint256 internalIndex = self._nextInternalIndex - 1;
            uint256 number = self._values[arrIndex];
            uint256 shift = internalIndex * bitsInValue;
            uint256 oldValue = number >> shift;

            number -= oldValue << shift;

            if (internalIndex == 0) {
                self._nextInternalIndex = uint64(valuesInElement);
                --self._len;
            }
            else {
                --self._nextInternalIndex;
                self._values[arrIndex] = number;
            }

            return oldValue;
        }
    }

    function popMany(Data storage self, uint256 valuesInElement, uint256 bitsInValue, uint256 amount) internal returns(uint256[] memory) {
        uint256 nextInternalIndex = self._nextInternalIndex;
        uint256 len = self._len;

        unchecked {
            if (len == 0 || amount > (len - 1) * valuesInElement + self._nextInternalIndex) {
                revert OutOfBounds();
            }
        }

        uint256[] memory returnValues = new uint256[](amount);
        unchecked {
            uint256 number = self._values[len - 1];
            for (uint256 i = 0; i < amount; ++i) {
                uint256 shift = (nextInternalIndex - 1) * bitsInValue;
                uint256 oldValue = number >> shift;

                number -= oldValue << shift;

                if (nextInternalIndex == 1) {
                    nextInternalIndex = uint128(valuesInElement);
                    --len;

                    number = self._values[len - 1];
                }
                else {
                    --nextInternalIndex;
                }

                returnValues[i] = oldValue;
            }

            if (len > 0) {
                self._values[len - 1] = number;
            }
        }

        self._nextInternalIndex = uint64(nextInternalIndex);
        self._len = uint64(len);

        return returnValues;
    }

    function pull(Data storage self, uint256 valuesInElement, uint256 bitsInValue, uint256 index) internal returns(uint256) {
        uint256 len = self._len;
        if (len == 0) {
            revert OutOfBounds();
        }
        
        unchecked
        {
            uint256 lastIndex = (len - 1) * valuesInElement + self._nextInternalIndex - 1;

            if (index == lastIndex) {
                return pop(self, valuesInElement, bitsInValue);
            }

            return _pull(self, valuesInElement, bitsInValue, index);
        }
    }

    function pullFront(Data storage self, uint256 valuesInElement, uint256 bitsInValue) internal returns(uint256) {
        uint256 len = self._len;
        if (len == 0) {
            revert OutOfBounds();
        }
        
        unchecked
        {
            uint256 lastIndex = (len - 1) * valuesInElement + self._nextInternalIndex - 1;
            uint256 index = _nextPullFrontIndex(self, uint64(lastIndex));

            if (index == lastIndex) {
                return pop(self, valuesInElement, bitsInValue);
            }

            return _pull(self, valuesInElement, bitsInValue, index);
        }
    }

    function pullFrontMany(Data storage self, uint256 valuesInElement, uint256 bitsInValue, uint256 amount) internal returns(uint256[] memory) {
        uint256 len = self._len;
        if (len == 0) {
            revert OutOfBounds();
        }
        
        uint256[] memory returnValues = new uint256[](amount);
        unchecked
        {
            uint256 lastIndex = (len - 1) * valuesInElement + self._nextInternalIndex - 1;

            if (amount > lastIndex + 1) {
                revert OutOfBounds();
            }

            for (uint256 i = 0; i < amount; ++i) {
                uint256 index = _nextPullFrontIndex(self, uint64(lastIndex));

                if (index == lastIndex) {
                    returnValues[i] = pop(self, valuesInElement, bitsInValue);
                    --lastIndex;
                    continue;
                }

                returnValues[i] = _pull(self, valuesInElement, bitsInValue, index);
                --lastIndex;
            }

            return returnValues;
        }
    }

    function _nextPullFrontIndex(Data storage self, uint64 lastIndex) private returns(uint256) {
        unchecked {
            uint64 index = self._popFrontIndex;
            if (self._popFrontSign == 1) {
                if (index < lastIndex) {
                    ++index;
                }
                else {
                    self._popFrontSign = 0;
                    index = lastIndex;
                }
            }
            else {
                if (index > 0) {
                    --index;
                }
                else {
                    self._popFrontSign = 1;
                    index = 0;
                }
            }

            self._popFrontIndex = index;

            return index;
        }
    }

    function _pull(Data storage self, uint256 valuesInElement, uint256 bitsInValue, uint256 index) private returns(uint256) {
        unchecked {
            uint256 arrIndex = index / valuesInElement;
            uint256 internalIndex = index % valuesInElement;

            uint256 number = self._values[arrIndex];
            uint256 shift = internalIndex * bitsInValue;
            uint256 lastValue = pop(self, valuesInElement, bitsInValue);

            uint256 oldValue;
            if (internalIndex < valuesInElement - 1) {
                number = number >> shift;
                oldValue = number - ((number >> bitsInValue) << bitsInValue);
            }
            else {
                oldValue = number >> shift;
            }

            self._values[arrIndex] = self._values[arrIndex] - (oldValue << shift) + (lastValue << shift);

            return oldValue;
        }
    }

    function length(Data storage self, uint256 valuesInElement) internal view returns(uint256) {
        unchecked {
            if (self._len == 0) {
                return 0;
            }

            return (self._len - 1) * valuesInElement + self._nextInternalIndex;
        }
    }
    
    function getBulk(Data storage self, uint256 valuesInElement, uint256 bitsInValue, uint256 indexFrom, uint256 indexTo) internal view returns(uint256[] memory) {
        if (indexFrom > indexTo || indexFrom > 2 ** 32 || indexTo > 2 ** 32) {
            revert InsaneBulk();
        }

        unchecked
        {
            uint256 len = indexTo - indexFrom + 1;

            if (self._len == 0 || indexFrom + len - 1 >= (self._len - 1) * valuesInElement + self._nextInternalIndex) {
                revert OutOfBounds();
            }

            uint256[] memory result = new uint256[](len);

            uint256 arrIndex = indexFrom / valuesInElement;
            uint256 internalIndex = indexFrom % valuesInElement;
            uint256 number = self._values[arrIndex];

            uint256 counterIndex;
            while (counterIndex < len) {
                if (internalIndex < valuesInElement - 1) {
                    uint256 temp = number >> internalIndex * bitsInValue;
                    result[counterIndex] = temp - ((temp >> bitsInValue) << bitsInValue);

                    ++internalIndex;
                }
                else {
                    result[counterIndex] = number >> internalIndex * bitsInValue;

                    ++arrIndex;
                    internalIndex = 0;
                    number = self._values[arrIndex];
                }

                ++counterIndex;
            }

            return result;
        }
    }

    function getWhole(Data storage self, uint256 index) internal view returns(uint256) {
        return self._values[index];
    }
}

abstract contract ERC404XStorage {
    using Packer for Packer.Data;

    uint256 public immutable bIV;
    uint256 public immutable vIE;

    /// @dev Array of owned ids in native representation
    mapping(address => Packer.Data) public _owned;

    /// @dev Tracks indices for the _owned mapping
    Packer.Data internal _ownedIndex;

    Packer.Data public _burned;

    /// @dev Addresses whitelisted from minting / burning for gas savings (pairs, routers, etc)
    mapping(address => uint256) internal _erc721TransferExempt;

    constructor(uint256 _max) {
        uint256 _bitsInValue = Math.log2(_max + 1);
        if (2 ** _bitsInValue < _max + 1) {
            ++_bitsInValue;
        }

        require(_bitsInValue > 0 && _bitsInValue <= 18, "ERC404X: 18 bits is a hard maximum, 15 bits is a recommended maximum");

        bIV = _bitsInValue;
        vIE = 256 / _bitsInValue;

        _ownedIndex.push(vIE, bIV, 0);
    }

    function getOwned(address account, uint256 indexFrom, uint256 indexTo) external view returns(uint256[] memory) {
        uint256 len = _owned[account].length(vIE);
        if (len == 0) {
            return new uint256[](1);
        }

        if (_erc721TransferExempt[account] == 1) {
            if (indexFrom >= len) {
                return new uint256[](1);
            }
            
            unchecked {
                if (indexTo >= len) {
                    indexTo = len - 1;
                }
            }
        }

        return _owned[account].getBulk(vIE, bIV, indexFrom, indexTo);
    }

    function getAllOwned(address account) external view returns(uint256[] memory) {
        uint256 len = _owned[account].length(vIE);
        if (len == 0) {
            return new uint256[](1);
        }

        unchecked {
            return _owned[account].getBulk(vIE, bIV, 0, len - 1);
        }
    }

    function getBurned(uint256 indexFrom, uint256 indexTo) external view returns(uint256[] memory) {
        uint256 len = _burned.length(vIE);
        if (len == 0) {
            return new uint256[](1);
        }

        if (indexFrom >= len) {
            return new uint256[](1);
        }
        
        unchecked {
            if (indexTo >= len) {
                indexTo = len - 1;
            }
        }

        return _burned.getBulk(vIE, bIV, indexFrom, indexTo);
    }

    function getAllBurned() external view returns(uint256[] memory) {
        uint256 len = _burned.length(vIE);
        if (len == 0) {
            return new uint256[](1);
        }
        
        unchecked {
            return _burned.getBulk(vIE, bIV, 0, len - 1);
        }
    }
}


/// @notice ERC404X
///         A gas-efficient, mixed ERC20 / ERC721 implementation
///         with native liquidity and fractionalization.
///
///         An upgraded iteration of ERC404 for increased gas efficiency and built-in reshuffler.
///
/// @dev    In order to support full functionality of ERC20 and ERC721
///         supply assumptions are made that slightly constraint usage.
///         Ensure decimals are sufficiently large (standard 18 recommended)
///         as ids are effectively encoded in the lowest range of amounts.
///
///         NFTs are spent on ERC20 functions in a FILO queue, this is by
///         design.
///
abstract contract ERC404X is ERC165, IERC721, IERC721Metadata, IERC721Enumerable, Ownable, ERC404XStorage {
    using Packer for Packer.Data;

    // Events
    event ERC20Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event ERC721Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    // Errors
    error NotFound();
    error AlreadyExists();
    error InvalidRecipient();
    error InvalidSender();
    error UnsafeRecipient();

    // Metadata
    /// @dev Token name
    string public name;

    /// @dev Token symbol
    string public symbol;

    /// @dev Decimals for fractional representation
    uint8 public immutable decimals;

    /// @dev Total supply in fractionalized representation
    uint256 public immutable totalSupply;

    /// @dev Current mint counter, monotonically increasing to ensure accurate ownership
    uint256 public minted;

    // Mappings
    /// @dev Balance of user in fractional representation
    mapping(address => uint256) public balanceOf;

    /// @dev Allowance of user in fractional representation
    mapping(address => mapping(address => uint256)) public allowance;

    /// @dev Approval in native representaion
    mapping(uint256 => address) public getApproved;

    /// @dev Approval for all in native representation
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev Owner of id in native representation
    mapping(uint256 => address) internal _ownerOf;

    mapping(uint256 => uint256) private _reshuffleTempAlreadyEdited;
    mapping(uint256 => uint256) private _reshuffleTempNotEditedYet;

    uint256 immutable unit;

    // Constructor
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalNativeSupply,
        address _owner
    ) Ownable(_owner) ERC404XStorage(_totalNativeSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalNativeSupply * (10 ** decimals);

        balanceOf[_owner] = totalSupply;

        _erc721TransferExempt[_owner] = 1;

        unit = 10 ** decimals;
    }

    /// @notice Initialization function to set pairs / etc
    ///         saving gas by avoiding mint / burn on unnecessary targets
    function setERC721TransferExempt(address target, bool state) public onlyOwner {
        _erc721TransferExempt[target] = state ? 1 : 0;
    }

    function erc721TransferExempt(address target) public view returns(bool) {
        return _erc721TransferExempt[target] == 1 ? true : false;
    }

    /// @notice Function to find owner of a given native token
    function ownerOf(uint256 id) public view virtual returns (address owner) {
        owner = _ownerOf[id];

        if (owner == address(0x0) || owner == address(0x1)) {
            revert NotFound();
        }
    }

    /// @notice tokenURI must be implemented by child contract
    function tokenURI(uint256 id) public view virtual returns (string memory);

    /// @notice Function for token approvals
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function approve(
        address spender,
        uint256 amountOrId
    ) public virtual {
        if (amountOrId <= minted && amountOrId > 0) {
            address owner = _ownerOf[amountOrId];

            if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
                revert Unauthorized();
            }

            getApproved[amountOrId] = spender;

            emit Approval(owner, spender, amountOrId);
        } else {
            allowance[msg.sender][spender] = amountOrId;

            emit Approval(msg.sender, spender, amountOrId);
        }
    }

    /// @notice Function native approvals
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Function for mixed transfers
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function transferFrom(
        address from,
        address to,
        uint256 amountOrId
    ) public virtual {
        if (amountOrId <= minted) {
            if (from != _ownerOf[amountOrId]) {
                revert InvalidSender();
            }

            if (to == address(0x0) || to == address(0x1)) {
                revert InvalidRecipient();
            }

            if (
                msg.sender != from &&
                !isApprovedForAll[from][msg.sender] &&
                msg.sender != getApproved[amountOrId]
            ) {
                revert Unauthorized();
            }

            balanceOf[from] -= unit;

            unchecked {
                balanceOf[to] += unit;
            }

            _ownerOf[amountOrId] = to;
            delete getApproved[amountOrId];

            uint256 originalOwnedIndex = _ownedIndex.get(vIE, bIV, amountOrId);

            uint256 updatedId = _owned[from].pull(vIE, bIV, originalOwnedIndex);
            uint256 pushedIndex = _owned[to].push(vIE, bIV, amountOrId);

            _ownedIndex.edit(vIE, bIV, updatedId, originalOwnedIndex);
            _ownedIndex.edit(vIE, bIV, amountOrId, pushedIndex);

            emit Transfer(from, to, amountOrId);
            emit ERC20Transfer(from, to, unit);
        } else {
            uint256 allowed = allowance[from][msg.sender];

            if (allowed != type(uint256).max)
                allowance[from][msg.sender] = allowed - amountOrId;

            _transfer(from, to, amountOrId);
        }
    }

    /// @notice Function for fractional transfers
    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    /// @notice Function for native transfers with contract support
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721Receiver(to).onERC721Received(msg.sender, from, id, "") !=
            ERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    /// @notice Function for native transfers with contract support and callback data
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
            ERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    /// @notice Internal function for fractional transfers
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (to == address(0x0) || to == address(0x1)) {
            revert InvalidRecipient();
        }

        uint256 balanceBeforeSender = balanceOf[from];
        uint256 balanceBeforeReceiver = balanceOf[to];

        balanceOf[from] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }

        uint256 toBurn = (balanceBeforeSender / unit) - (balanceOf[from] / unit);
        uint256 toMint = (balanceOf[to] / unit) - (balanceBeforeReceiver / unit);

        // if the address was unwhitelisted and has less NFTs to burn than its floored ERC-20 balance
        if (_erc721TransferExempt[from] == 0) {
            uint256 fromLen = _owned[from].length(vIE);
            if (fromLen < toBurn) {
                bulkMint(fromLen - toBurn, to);              
            }
        }

        if (_erc721TransferExempt[from] == 0 && _erc721TransferExempt[to] == 0) {
            uint256 toTransfer = Math.min(toBurn, toMint);
            bulkTransfer(toTransfer, from, to);

            if (toBurn > toMint) {
                _burn(from);
            }
            else if (toMint > toBurn) {
                _mint(to);
            }
        }
        else if (_erc721TransferExempt[from] == 1 && _erc721TransferExempt[to] == 0) {
            // if the address is whitelisted but has tokens, treat it as a regular transfer
            uint256 fromLen = _owned[from].length(vIE);
            if (fromLen > 0) {
                toBurn = Math.min(toBurn, fromLen);
                uint256 toTransfer = Math.min(toBurn, toMint);
                bulkTransfer(toTransfer, from, to);
                
                if (toMint >= toTransfer) {
                    toMint -= toTransfer;
                }
                else {
                    toMint = 0;
                }

                if (toBurn > toTransfer) {
                    _burn(from);
                }
            }

            bulkMint(toMint, to);
        }
        else if (_erc721TransferExempt[from] == 0 && _erc721TransferExempt[to] == 1) {
            bulkBurn(toBurn, from);
        }

        emit ERC20Transfer(from, to, amount);
        return true;
    }

    function bulkTransfer(uint256 toTransfer, address from, address to) internal virtual {
        if (toTransfer == 1) {
            uint256 id = _owned[from].pop(vIE, bIV);
            uint256 pushedIndex = _owned[to].push(vIE, bIV, id);

            _ownerOf[id] = to;
            _ownedIndex.edit(vIE, bIV, id, pushedIndex);
            delete getApproved[id];

            emit Transfer(from, to, id);
        }
        else if (toTransfer > 0) {
            uint256[] memory ids = _owned[from].popMany(vIE, bIV, toTransfer);
            uint256[] memory indexes = _owned[to].pushMany(vIE, bIV, ids);

            _ownedIndex.editMany(vIE, bIV, ids, indexes);

            unchecked {
                for (uint256 i = 0; i < toTransfer; ++i) {
                    uint256 id = ids[i];

                    _ownerOf[id] = to;
                    delete getApproved[id];

                    emit Transfer(from, to, id);
                }
            }
        }
    }

    function bulkMint(uint256 toMint, address to) internal virtual {
        if (toMint == 1) {
            _mint(to);
        }
        else if (toMint > 0) {
            unchecked {
                if (minted < totalSupply / unit) {
                    for (uint256 i = 0; i < toMint; ++i) {
                        _mint(to);
                    }
                }
                else {
                    uint256[] memory ids = _burned.pullFrontMany(vIE, bIV, toMint);
                    uint256[] memory indexes = _owned[to].pushMany(vIE, bIV, ids);

                    _ownedIndex.editMany(vIE, bIV, ids, indexes);

                    for (uint256 i = 0; i < toMint; ++i) {
                        uint256 id = ids[i];

                        _ownerOf[id] = to;

                        emit Transfer(address(0x1), to, id);
                    }
                }
            }
        }
    }

    function _mint(address to) internal virtual {
        uint256 id;
        if (minted < totalSupply / unit) {
            id = ++minted;
            _ownedIndex.push(vIE, bIV, _owned[to].push(vIE, bIV, id));

             emit Transfer(_ownerOf[id], to, id);
        }
        else {
            id = _burned.pullFront(vIE, bIV);
            _ownedIndex.edit(vIE, bIV, id, _owned[to].push(vIE, bIV, id));

            emit Transfer(address(0x1), to, id);
        }

        _ownerOf[id] = to;
    }

    function bulkBurn(uint256 toBurn, address from) internal virtual {
        if (toBurn == 1) {
            _burn(from);
        }
        else if (toBurn > 0) {
            uint256[] memory ids = _owned[from].popMany(vIE, bIV, toBurn);
            _burned.pushMany(vIE, bIV, ids);

            unchecked {
                for (uint256 i = 0; i < toBurn; ++i) {
                    uint256 id = ids[i];

                    _ownerOf[id] = address(0x1);
                    delete getApproved[id];

                    emit Transfer(from, address(0x1), id);
                }
            }
        }
    }

    function _burn(address from) internal virtual {
        uint256 id = _owned[from].pop(vIE, bIV);

        _burned.push(vIE, bIV, id);

        _ownerOf[id] = address(0x1);
        delete getApproved[id];

        emit Transfer(from, address(0x1), id);
    }

    function reshuffle(uint256[] memory indexesToEdit, uint256[] memory valuesToPlace, uint256[] memory currentIndexes) public virtual {
        uint256 len = indexesToEdit.length;
        require(len == valuesToPlace.length && len == currentIndexes.length, "ERC404X: reshuffle input length mismatch");

        Packer.Data storage data = _owned[msg.sender];

        unchecked {
            for (uint256 i = 0; i < len; ++i) {
                require(data.get(vIE, bIV, currentIndexes[i]) == valuesToPlace[i], "ERC404X: reshuffle input contains wrong value");
            }
        }

        uint256 editedLen;
        uint256 notEditedLen;
        unchecked {
            for (uint256 i = 0; i < len; ++i) {
                uint256 indexToEdit = indexesToEdit[i];
                uint256 currentIndex = currentIndexes[i];

                if (_reshuffleTempNotEditedYet[indexToEdit] == 0) {
                    _reshuffleTempAlreadyEdited[indexToEdit] = 1;
                    ++editedLen;
                }
                else {
                    _reshuffleTempNotEditedYet[indexToEdit] = 0;
                    --notEditedLen;
                }

                if (_reshuffleTempAlreadyEdited[currentIndex] == 0) {
                    _reshuffleTempNotEditedYet[currentIndex] = 1;
                    ++notEditedLen;
                }
                else {
                    _reshuffleTempAlreadyEdited[currentIndex] = 0;
                    --editedLen;
                }
            }
        }

        data.editMany(vIE, bIV, indexesToEdit, valuesToPlace);
        _ownedIndex.editMany(vIE, bIV, currentIndexes, indexesToEdit);

        require(editedLen == 0 && notEditedLen == 0, "ERC404X: reshuffle input incorrect");
    }

    function _setNameSymbol(
        string memory _name,
        string memory _symbol
    ) internal {
        name = _name;
        symbol = _symbol;
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
        if (_erc721TransferExempt[owner] == 1) {
            if (index >= _owned[owner].length(vIE)) {
                return 0;
            }
        }

        return _owned[owner].get(vIE, bIV, index);
    }

    function tokenByIndex(uint256 index) external pure override returns (uint256) {
        index;
        return 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

contract MEMECITY is ERC404X {
    string public dataURI;
    string public baseTokenURI;
    
    string[] colors = ["Blue", "Pink", "Black", "Grey", "Yellow", "Orange"];
    string[] shapes = ["Short", "Medium", "Tall"];
    string[] tags = ["Benance", "Bonk", "TwitterX", "Hodl", "Nvidia", "Wif", "Wagmi", "Bobo", "WallStreetBets", "BTC"];
    string[] coins = ["Bitcoin", "Ethereum", "Tesla", "McDonalds", "DogeCoin", "ShibaInu", "Uniswap", "FTX", "Terra", "Solana"];
    string[] ids = ["Cybertruck", "Wojak", "ElonMusk", "ATM", "Shiba", "Pepe", "Ape", "Bogdanoff", "Vitalik", "Optimus", "Squid", "SmurfCat"];

    constructor() ERC404X("Meme City", "MEMECITY", 18, 1000, msg.sender) {
        dataURI = "https://memecity404.io/nft/";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setDataURI(string memory _dataURI) public onlyOwner {
        dataURI = _dataURI;
    }

    function setTokenURI(string memory _tokenURI) public onlyOwner {
        baseTokenURI = _tokenURI;
    }

    function setNameSymbol(
        string memory _name,
        string memory _symbol
    ) public onlyOwner {
        _setNameSymbol(_name, _symbol);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (bytes(baseTokenURI).length > 0) {
            return string.concat(baseTokenURI, Strings.toString(id));
        } else {
            uint256 seed = uint256(keccak256(abi.encodePacked(id + 1))) % 100;
            string memory image;
            string memory _type;
            string memory _color;
            string memory _shape;
            string memory _coin;
            string memory _tag;
            string memory _id;

            if (seed < 60) {
                _type = "Building";
                _color = colors[(seed + id) % colors.length];
                _shape = shapes[(seed + id) % shapes.length];
            } else if (seed < 75) {
                _type = "Sticker";
                _tag = tags[(seed + id) % tags.length];
            } else if (seed < 90) {
                _type = "Logo";
                _coin = coins[(seed + id) % coins.length];
            } else {
                _type = "Character";
                _id = ids[(seed + id) % ids.length];
            }

            image = generateImageURI(_type, _color, _shape, _tag, _coin, _id);

            // Construct the JSON metadata
            string memory jsonPreImage = string.concat(
                string.concat(
                    string.concat('{"name": "Meme City #', Strings.toString(id)),
                    '","description":"A collection of 1,000 buildings, coins, stickers, and characters that reside on the blockchain.","external_url":"https://memecity404.io","image":"'
                ),
                string.concat(dataURI, image)
            );
            string memory jsonPostImage = '';
            if (keccak256(bytes(_type)) == keccak256(bytes("Building"))) {
                jsonPostImage = string.concat(
                    '","attributes":[{"trait_type":"Type","value":"',_type
                );
                jsonPostImage = string.concat(jsonPostImage, '"},{"trait_type":"Color","value":"',_color);
                jsonPostImage = string.concat(jsonPostImage, '"},{"trait_type":"Shape","value":"',_shape);
            } else if (keccak256(bytes(_type)) == keccak256(bytes("Sticker"))) {
                jsonPostImage = string.concat(
                    '","attributes":[{"trait_type":"Type","value":"',_type
                );
                jsonPostImage = string.concat(jsonPostImage, '"},{"trait_type":"Tag","value":"',_tag);
            } else if (keccak256(bytes(_type)) == keccak256(bytes("Logo"))) {
                jsonPostImage = string.concat(
                    '","attributes":[{"trait_type":"Type","value":"',_type
                );
                jsonPostImage = string.concat(jsonPostImage, '"},{"trait_type":"Coin","value":"',_coin);
            } else {
                jsonPostImage = string.concat(
                    '","attributes":[{"trait_type":"Type","value":"',_type
                );
                jsonPostImage = string.concat(jsonPostImage, '"},{"trait_type":"ID","value":"',_id);
            }
            string memory jsonPostTraits = '"}]}';

            // Return the complete token URI
            return string.concat(
                "data:application/json;utf8,",
                string.concat(
                    string.concat(jsonPreImage, jsonPostImage),
                    jsonPostTraits
                )
            );
        }
    }

    function generateImageURI(
        string memory _type,
        string memory _color,
        string memory _shape,
        string memory _tag,
        string memory _coin,
        string memory _id
    ) internal pure returns (string memory) {
        if (keccak256(bytes(_type)) == keccak256(bytes("Building"))) {
            return string.concat(string.concat(string.concat("Building_", _color), "_"), _shape, ".jpg");
        } else if (keccak256(bytes(_type)) == keccak256(bytes("Sticker"))) {
            return string.concat("Sticker_", _tag, ".jpg");
        } else if (keccak256(bytes(_type)) == keccak256(bytes("Logo"))) {
            return string.concat("Logo_", _coin, ".jpg");
        } else {
            return string.concat("Character_", _id, ".jpg");
        }
    }
}