// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Math } from "./libraries/Math.sol";
import { UQ112x112 } from "./libraries/UQ112x112.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IGenerator } from "./interfaces/IGenerator.sol";
import { IFactory } from "./interfaces/IFactory.sol";
import { IPair } from "./interfaces/IPair.sol";
import { IBorrower } from "./interfaces/IBorrower.sol";
import { IToken } from "./interfaces/IToken.sol";

contract Pair is IERC20, Initializable, IPair {
    
    string public constant override name = "P";
    string public constant override symbol = "LP";
    uint8 public constant override decimals = 18;
    uint public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] < value) revert();
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function _mint(address to, uint value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal {
        if (balanceOf[from] < value) revert();
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    address public router;
    address public factory;
    address public token0;
    address public token1;
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;
    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint16 public constant FEE_DENOMINATOR = 10000;
    address public baseToken;
    address public feeTaker;
    mapping(address => Fees) _fees;
    Fees public totalOwed;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    event FeeCollected(address indexed f, address indexed t, uint a);
    event Collected(address indexed f, address indexed t, uint a);
    event BuyBack(address indexed f, address indexed t, uint a);

    modifier onlyFactory() {
        require(msg.sender == factory);
        _;
    }
    
    constructor() {
        _disableInitializers();
    }

    /**
    * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
    * `onlyInitializing` functions can be used to initialize parent contracts.
    * Called only by the Router contract during the creation of the Pair.
     */
    function initialize(address _factory, address _token0, address _token1,  address _feeTaker, address _takeFeeIn) external initializer() {
        require(_factory != address(0) && _token0 != address(0) && _token1 != address(0) && (_feeTaker == address(0) ? _takeFeeIn == address(0) : _takeFeeIn != address(0)), "IV");
        factory = _factory;
        token0 = _token0;
        token1 = _token1;
        baseToken = _takeFeeIn;
        feeTaker = _feeTaker;
        router = msg.sender;
    }

    /**
     * @dev Accepts tokens in exchange for liquidity tokens.
     * Only callable by the Factory contract for this pair.
     */
    function mint(address to) external onlyFactory returns (uint liquidity) {
        uint112 _reserve0 = reserve0;
        uint112 _reserve1 = reserve1;
        IERC20 t0 = IERC20(token0);
        IERC20 t1 = IERC20(token1);
        uint balance0 = t0.balanceOf(address(this)) - totalOwed.amount0;
        uint balance1 = t1.balanceOf(address(this)) - totalOwed.amount1;
        uint amount0 = _takeFees(true, true, balance0 - _reserve0, factory, false);
        uint amount1 = _takeFees(false, true, balance1 - _reserve1, factory, false);
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - 10**3;
            _mint(address(0), 10**3); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                Math.muldiv(amount0, _totalSupply, _reserve0), 
                Math.muldiv(amount1, _totalSupply, _reserve1)
            );
        }
        require(liquidity > 0, "IM");
        _mint(to, liquidity);
        balance0 = t0.balanceOf(address(this)) - totalOwed.amount0;
        balance1 = t1.balanceOf(address(this)) - totalOwed.amount1;
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }


    /**
     * @dev Accepts liquidity tokens in exchange for tokens.
    * Only callable by the Factory contract for this pair.
     */
    function burn(address to) external onlyFactory returns (uint amount0, uint amount1) {
        require(totalSupply != 0, "ZS");
        uint112 _reserve0 = reserve0;
        uint112 _reserve1 = reserve1;
        uint liquidity = balanceOf[address(this)];
        uint _totalSupply = totalSupply;
        amount0 = _takeFees(true, true, Math.muldiv(liquidity, _reserve0, _totalSupply), factory, false); // using balances ensures pro-rata distribution
        amount1 = _takeFees(false, true, Math.muldiv(liquidity, _reserve1, _totalSupply), factory, false); // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "IB");
        _burn(address(this), liquidity);
        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);
        uint balance0 = IERC20(token0).balanceOf(address(this)) - totalOwed.amount0;
        uint balance1 = IERC20(token1).balanceOf(address(this)) - totalOwed.amount1;
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /**
     * @dev Borrow tokens from the pair and return them with a fee in the same transaction.
     */
    function borrow(address to, uint a, bool z, bytes calldata data) external {
        uint112 _reserve0 = reserve0;
        uint112 _reserve1 = reserve1;
        IERC20 token = IERC20(z ? token0 : token1);
        _safeTransfer(address(token), to, a);
        IGenerator r = IGenerator(router);
        require(r.allowLoans());
        uint16 borrowFee = r.borrowFee();
        IBorrower(to).onLoan(address(token), a, borrowFee, data);
        if (borrowFee > 0) _takeFees(z, false, Math.muldiv(a, borrowFee, FEE_DENOMINATOR), address(0), true);
        uint balance0 = IERC20(token0).balanceOf(address(this)) - totalOwed.amount0;
        uint balance1 = IERC20(token1).balanceOf(address(this)) - totalOwed.amount1;
        if (balance0 != _reserve0 || balance1 != _reserve1) revert();
    }

    /**
     * @dev Total fees taken by the feeTaker for a given address on swap.
     */
    function totalFee(address caller) public view returns (uint16) {
        return feeTaker == address(0) ? 0 : IGenerator(router).maxSwap2Fee(IToken(feeTaker).getTotalFee(caller));
    }

    /**
     * @dev Swap tokens for tokens.
     */
    function swap(
        address to,
        address caller,
        address f
    ) external returns (uint256 _amountOut) {
        if (msg.sender != router) caller = msg.sender;
        uint112 _reserve0 = reserve0;
        uint112 _reserve1 = reserve1;
        IERC20 tok0 = IERC20(token0);
        IERC20 tok1 = IERC20(token1);
        uint balance0 = tok0.balanceOf(address(this)) - totalOwed.amount0;
        uint balance1 = tok1.balanceOf(address(this)) - totalOwed.amount1;
        uint amount0In = balance0 - _reserve0;
        uint amount1In = balance1 - _reserve1;
        bool isToken0 = amount1In > 0;
        uint _amountIn = isToken0 ? amount1In : amount0In;
        require(_amountIn > 0, "IIO");
        address input = isToken0 ? address(tok1) : address(tok0);
        address token = routerFeeIn();
        address base = baseToken;
        address _feeTaker = feeTaker;
        uint16 denominator = FEE_DENOMINATOR;
        uint16 lpFee = IGenerator(router).pairFees(address(this)).lpFee;
        if (input == token) _amountIn = _takeFees(address(tok0) == token, false, _amountIn, f, false);
        if (_feeTaker != address(0) && (base == input)) {
            uint fee = Math.muldiv(_amountIn, totalFee(caller), denominator);
            if (fee > 0) {
                _safeApprove(base, _feeTaker, fee);
                IToken(_feeTaker).handleFee();
                _safeApprove(base, _feeTaker, 0);
                _amountIn -= fee;
            }
        }
        (uint reserveIn, uint reserveOut) = !isToken0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
        _amountOut = Math.muldiv(_amountIn, reserveOut, (reserveIn + _amountIn));
        require(_amountOut > 0 && _amountOut <= reserveOut, "IL");
        uint lpAmount = Math.muldiv(_amountOut, lpFee, denominator);
        if (_feeTaker != address(0) && (baseToken == (isToken0 ? address(tok0) : address(tok1)))) {
            uint16 tokenFee = totalFee(caller);
            uint fee = Math.muldiv(_amountOut, tokenFee + lpFee,denominator);
            _amountOut -= fee;
            fee -= lpAmount; // leave lpAmount in pool
            if (fee > 0) {
                _safeApprove(base, _feeTaker, fee);
                IToken(_feeTaker).handleFee();
                _safeApprove(base, _feeTaker, 0);
                _amountIn -= fee;
            }
        } else {
            _amountOut -= lpAmount; // leave lpAmount in pool
        }
        if ((isToken0 && (token == token0)) || (!isToken0 && (token == token1))) _amountOut = _takeFees(token0 == token, false, _amountOut, f, false);
        IERC20 tok = isToken0 ? tok0 : tok1;
        uint balBefore = tok.balanceOf(to);
        _safeTransfer(address(tok), to, _amountOut);
        _amountOut = tok.balanceOf(to) - balBefore;
        balance0 = tok0.balanceOf(address(this)) - totalOwed.amount0;
        balance1 = tok1.balanceOf(address(this)) - totalOwed.amount1;
        if (((balance0 - (isToken0 ? lpAmount : 0)) * (balance1 - (!isToken0 ? lpAmount : 0))) < uint(_reserve0) * _reserve1) revert();
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(caller, !isToken0 ? _amountIn : 0, isToken0 ? _amountIn : 0, isToken0 ? _amountOut : 0, !isToken0 ? _amountOut : 0, to);
    }

    /**
     * @dev Returns the amount of tokens that would be received for a given amount of tokens.
     */
    function amountOut(address input, uint _amountIn, address caller) external view returns (uint _amountOut) {
        uint _reserve0 = reserve0;
        uint _reserve1 = reserve1;
        address token = routerFeeIn();
        address output = input == token0 ? token1 : token0;
        uint16 tokenFee = totalFee(caller);
        IGenerator gen = IGenerator(router);
        IGenerator.Info memory fInfo = gen.pairFees(address(this));
        IGenerator.Info memory eInfo = gen.factoryInfo((msg.sender == factory || msg.sender == router) ? address(0) : msg.sender);
        uint16 denom = FEE_DENOMINATOR;
        uint16 tf = fInfo.teamFee + fInfo.burnFee + fInfo.referFee + fInfo.labFee + eInfo.teamFee + eInfo.referFee;
        if (input == token) _amountIn -= Math.muldiv(_amountIn, tf, denom);
        if (feeTaker != address(0) && input == baseToken) _amountIn -= Math.muldiv(_amountIn,tokenFee, denom);
        (uint reserveIn, uint reserveOut) = input == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
        _amountOut = Math.muldiv(_amountIn, reserveOut, reserveIn + _amountIn);
        if (feeTaker != address(0) && output == baseToken) {
            uint fee = Math.muldiv(_amountOut, tokenFee + fInfo.lpFee, denom);
            _amountOut = _amountOut - fee;
        } else {
            _amountOut -= Math.muldiv(_amountOut, fInfo.lpFee, denom);
        }
        if (input != token) _amountOut -= Math.muldiv(_amountOut, tf, denom);
    }

    /**
     * @dev Returns the amount of tokens that would be required to swap for a given amount of tokens.
     */
    function amountIn(address output, uint _amountOut, address caller) external view returns (uint _amountIn) {
        uint _reserve0 = reserve0;
        uint _reserve1 = reserve1;
        IGenerator gen = IGenerator(router);
        IGenerator.Info memory fInfo = gen.pairFees(address(this));
        IGenerator.Info memory eInfo = gen.factoryInfo((msg.sender == factory || msg.sender == router) ? address(0) : msg.sender);
        uint16 tf = fInfo.teamFee + fInfo.burnFee + fInfo.referFee + fInfo.labFee + eInfo.teamFee + eInfo.referFee;
        address input = output == token0 ? token1 : token0;
        uint16 tokenFee = totalFee(caller);
        address token = routerFeeIn();
        uint16 denom = FEE_DENOMINATOR;
        (uint reserveIn, uint reserveOut) = input == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
        if (input != token) _amountOut = Math.mulDivRoundingUp(_amountOut, denom, (denom - tf));
        _amountOut = Math.mulDivRoundingUp(_amountOut, denom, (denom - fInfo.lpFee + ((feeTaker != address(0) && output == baseToken) ? tokenFee : 0)));
        _amountIn = Math.mulDivRoundingUp(_amountOut, reserveIn, reserveOut - _amountOut);
        if (feeTaker != address(0) && input == baseToken) _amountIn = Math.mulDivRoundingUp(_amountIn, denom, (denom - tokenFee));
        if (input == token) _amountIn = Math.mulDivRoundingUp(_amountIn, denom, (denom - tf));
    }

    /**
     * @dev Returns the address for the token that fees will be taken in.
     */
    function routerFeeIn() public view returns (address) {
        IGenerator routerInterface = IGenerator(router);
        address WETH = routerInterface.WRAPPED_ETH();
        return token0 == WETH ? token0 : token1 == WETH ? token1 : routerInterface.stables(token0) ? token0 : routerInterface.stables(token1) ? token1 : token0;
    }

    /**
     * @dev Returns the amount of tokens that have been collected as fees for a given address.
     */
    function feeBalances(address f) external view returns (Fees memory) {
        return _fees[f];
    }

    /**
     * @dev Adds fees to a given address.
     */
    function _addFee(bool z, address f, uint a) internal {
          if (z) {
            _fees[f].amount0 += a;
            totalOwed.amount0 += a;
        } else {
            _fees[f].amount1 += a;
            totalOwed.amount1 += a;
        }
        emit FeeCollected(f, z ? token0 : token1, a);
    }

    /**
     * @dev Takes fees
     * @param z Whether the input token is token0.
    * @param lp Whether the fees are for liquidity provision.
    * @param a The amount of tokens to take fees on.
    * @param f An additional address to accept fees for that is not the router or factory.
     */
    function _takeFees(bool z, bool lp, uint a, address f, bool l) internal returns (uint) {
        IGenerator gen = IGenerator(router);
        IGenerator.Info memory fInfo = gen.pairFees(address(this));
        IGenerator.Info memory eInfo = gen.factoryInfo((l || f == factory || f == address(gen)) ? address(0) : f);
        uint16 eFee = eInfo.teamFee + eInfo.referFee;
        uint16 tf = (lp ? fInfo.lpFee : (fInfo.teamFee + fInfo.burnFee)) + fInfo.referFee + fInfo.labFee + eFee;
        uint _totalFee = l ? a : Math.muldiv(a, tf, FEE_DENOMINATOR);
        if (!l) {
            if (_totalFee == 0) return a;
            a -=_totalFee;
        }
        if (eFee > 0) {
            uint b = Math.muldiv(_totalFee, eFee, tf);
            _totalFee -= b;
            if (eInfo.referrer != address(0) && eInfo.referFee > 0) {
                uint r = Math.muldiv(b, eInfo.referFee, eFee);
                _addFee(z, eInfo.referrer, r);
                b -= r;
            }
            if (b > 0) _addFee(z, eInfo.teamAddress, b);
        }
        if (factory == address(gen)) {
            _addFee(z, address(gen), _totalFee);
        } else {
            if (fInfo.labFee > 0) {
                uint lab = Math.muldiv(_totalFee, fInfo.labFee, tf);
                _addFee(z, address(gen), lab);
                _totalFee -= lab;
            }
            if (_totalFee > 0 && fInfo.referFee > 0) {
                uint refer = Math.muldiv(_totalFee, fInfo.referFee, tf);
                if (refer > 0) {
                    _addFee(z, fInfo.referrer, refer);
                    _totalFee -= refer;
                }
            }
            if (_totalFee > 0) {
                _addFee(z, factory, _totalFee);
            }
        }
        return a;
    }

    /**
     * @dev Collects fees for a given address and token.
     */
    function collect(address f, address t) external {
        bool isZ = t == token0;
        uint _bal = isZ ? _fees[f].amount0 : _fees[f].amount1;
        if (_bal == 0) return;
        if (isZ) {
            _fees[f].amount0 = 0;
            totalOwed.amount0 -= _bal;
        } else {
            _fees[f].amount1 = 0;
            totalOwed.amount1 -= _bal;
        }
        if (f != router && f != factory) {
            _safeTransfer(t, f, _bal);
            emit Collected(f, t, _bal);
            return;
        }
        IGenerator gen = IGenerator(router);
        IGenerator.Info memory fInfo = gen.pairFees(address(this));
        if (fInfo.teamFee > 0) {
            uint teamDistribution = Math.muldiv(_bal, fInfo.teamFee, (fInfo.teamFee + fInfo.burnFee));
            _safeTransfer(t, fInfo.teamAddress, teamDistribution);
            emit Collected(f, t, teamDistribution);
            _bal -= teamDistribution;
        }
        if (_bal > 0 && fInfo.burnToken != address(0)) {
            if (t != fInfo.burnToken) {
                address pair = gen.pairs(f,t, fInfo.burnToken);
                if (pair == address(this)) {
                    uint112 _reserve0 = reserve0;
                    uint112 _reserve1 = reserve1;
                    (uint reserveInput, uint reserveOutput) = t == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
                    _bal = Math.muldiv(_bal, reserveOutput, reserveInput + _bal);
                    _safeTransfer(fInfo.burnToken, 0x000000000000000000000000000000000000dEaD, _bal);
                    emit Collected(f, t, _bal);
                    emit BuyBack(f, t, _bal);
                    uint balance0 = IERC20(token0).balanceOf(address(this)) - totalOwed.amount0;
                    uint balance1 = IERC20(token1).balanceOf(address(this)) - totalOwed.amount1;
                    _update(balance0, balance1, _reserve0, _reserve1);
                } else if (pair != address(0)) {
                    address[] memory pairs = new address[](1);
                    pairs[0] = pair;
                    _safeTransfer(t, pair, _bal);
                    emit Collected(f, t, _bal);
                    uint256 amount = gen.swapInternal(pairs, address(this), 0x000000000000000000000000000000000000dEaD);
                    emit BuyBack(f, t, amount);
                    assert(amount > 0);
                } else {
                    _safeTransfer(t, fInfo.teamAddress, _bal);
                    emit Collected(f, t, _bal);
                }
            } else {
                _safeTransfer(t, 0x000000000000000000000000000000000000dEaD, _bal);
                emit Collected(f, t, _bal);
                emit BuyBack(f, t, _bal);
            }
        }
    }

    /**
     * @dev Returns the reserves of token0, token1, and the block timestamp of the last update.
     */
    function getReserves() external view returns (
        uint112 _reserve0, 
        uint112 _reserve1, 
        uint32 _blockTimestampLast
    ) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) internal {
        if(value == 0) return;
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(bytes4(keccak256(bytes("transfer(address,uint256)"))), to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TF");
    }

    function _safeApprove(address token, address to, uint amount) internal {
        if(amount == 0) return;
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(bytes4(keccak256(bytes("approve(address,uint256)"))), to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SA");
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) internal {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "M");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.uqdiv(UQ112x112.encode(_reserve1), _reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.uqdiv(UQ112x112.encode(_reserve0), _reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }
 
}
