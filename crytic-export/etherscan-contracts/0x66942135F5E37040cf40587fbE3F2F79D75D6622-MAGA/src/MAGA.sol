// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// forgefmt: disable-start
/**

The DJT $MAGA Token
@MAGADJT_ (twitter/no telegram)


$$\      $$\  $$$$$$\  $$\   $$\ $$$$$$$$\                                                             
$$$\    $$$ |$$  __$$\ $$ | $$  |$$  _____|                                                            
$$$$\  $$$$ |$$ /  $$ |$$ |$$  / $$ |                                                                  
$$\$$\$$ $$ |$$$$$$$$ |$$$$$  /  $$$$$\                                                                
$$ \$$$  $$ |$$  __$$ |$$  $$<   $$  __|                                                               
$$ |\$  /$$ |$$ |  $$ |$$ |\$$\  $$ |                                                                  
$$ | \_/ $$ |$$ |  $$ |$$ | \$$\ $$$$$$$$\                                                             
\__|     \__|\__|  \__|\__|  \__|\________|                                                            
                                                                                                       
                                                                                                       
                                                                                                       
 $$$$$$\  $$\      $$\ $$$$$$$$\ $$$$$$$\  $$$$$$\  $$$$$$\   $$$$$$\                                  
$$  __$$\ $$$\    $$$ |$$  _____|$$  __$$\ \_$$  _|$$  __$$\ $$  __$$\                                 
$$ /  $$ |$$$$\  $$$$ |$$ |      $$ |  $$ |  $$ |  $$ /  \__|$$ /  $$ |                                
$$$$$$$$ |$$\$$\$$ $$ |$$$$$\    $$$$$$$  |  $$ |  $$ |      $$$$$$$$ |                                
$$  __$$ |$$ \$$$  $$ |$$  __|   $$  __$$<   $$ |  $$ |      $$  __$$ |                                
$$ |  $$ |$$ |\$  /$$ |$$ |      $$ |  $$ |  $$ |  $$ |  $$\ $$ |  $$ |                                
$$ |  $$ |$$ | \_/ $$ |$$$$$$$$\ $$ |  $$ |$$$$$$\ \$$$$$$  |$$ |  $$ |                                
\__|  \__|\__|     \__|\________|\__|  \__|\______| \______/ \__|  \__|                                
                                                                                                       
                                                                                                       
                                                                                                       
 $$$$$$\  $$$$$$$\  $$$$$$$$\  $$$$$$\ $$$$$$$$\        $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$\ $$\   $$\ 
$$  __$$\ $$  __$$\ $$  _____|$$  __$$\\__$$  __|      $$  __$$\ $$  __$$\ $$  __$$\ \_$$  _|$$$\  $$ |
$$ /  \__|$$ |  $$ |$$ |      $$ /  $$ |  $$ |         $$ /  $$ |$$ /  \__|$$ /  $$ |  $$ |  $$$$\ $$ |
$$ |$$$$\ $$$$$$$  |$$$$$\    $$$$$$$$ |  $$ |         $$$$$$$$ |$$ |$$$$\ $$$$$$$$ |  $$ |  $$ $$\$$ |
$$ |\_$$ |$$  __$$< $$  __|   $$  __$$ |  $$ |         $$  __$$ |$$ |\_$$ |$$  __$$ |  $$ |  $$ \$$$$ |
$$ |  $$ |$$ |  $$ |$$ |      $$ |  $$ |  $$ |         $$ |  $$ |$$ |  $$ |$$ |  $$ |  $$ |  $$ |\$$$ |
\$$$$$$  |$$ |  $$ |$$$$$$$$\ $$ |  $$ |  $$ |         $$ |  $$ |\$$$$$$  |$$ |  $$ |$$$$$$\ $$ | \$$ |
 \______/ \__|  \__|\________|\__|  \__|  \__|         \__|  \__| \______/ \__|  \__|\______|\__|  \__|
.........................................................................................................................................................
.........................................................................................................................................................
.........................................................................................................................................................
......................:::................................................................................................................................
.....................:----:..............................................................................................................................
.....................------:.............................................................................................................................
.....................:=====-.................................................:...........................................................................
.....................:==+++-........................................::-====+++++++++=-:..................................................................
.....................:=++++-....................................:-==++++++++++==+++=++===---:............................................................
.............::--------===+=:.................................:=+++++=====++============++++==-:.........................................................
............:-------------==:...............................-=++++++++=====++=++================-:.......................................................
............----=+===-----=+-:............................-++****+++++====================++======:......................................................
..........:-------====+++**+=:..........................-+*****++++==============++++++++++****+++-......................................................
..........-=========-----=**=-.........................-*#**++++++==================++++++**+++**=:......................................................
..........-++====-=--=---=++=-.........................=*#*+++++++====================+++++++*++-........................................................
..........----==+++++++++***+-.........................=#*++++++========--============+=+++++++=-........................................................
.........:-=======-----=*##*+-........................:+#**++++===========================+++++==:.......................................................
.........:=+++========-=+*%*=:........................-*#*++=======-----===++++++**####*++++++++=:.......................................................
.........:-===++++++*******+-.........................:+#*+===========+**#####+==*#%%%%%%#*+++*++:.......................................................
.........:-=====--==+*%%%#+=..........................:+#*+==+======+*#%%%%%%*=--=###+++=+#*+++++-.......................................................
.........:+*++++=====+++++=:..........................-***+++=====+*#*+========--====+++++==++***+:......................................................
..........:+*++++****###*+=..........................:=**++++=====+++=+**++=-===--=+===---===+****-......................................................
...........:***#%%%%%%#*++*:.........................-****+++==========-----====--==++=---==++++**=......................................................
...........:*+##%%%%%%##**#:.........................:+##**++==+===--------=++====+++++=====+++***=......................................................
..........:.+++*#######**=:-:.........................-****++==+++==----===+*+#@%#%@%*+*++++++***=:......................................................
.........:+-:****#####*+--=+:.........................:=*+*#+=++++=======++*++*+***+++==+*+++++++=:......................................................
.........=%#-:*####**+--==#*:..........................:==+*===+++=+++++**+==============++++++*+=:......................................................
........:*%%*=:+*#*=--=++#%*:...........................:=======+++++++**+======++*****##*+==++++-.......................................................
........=%%%%*--*=.-=+++#%%#-............................-==-==+=+++++=++++*##+=====++++====++++-........................................................
.......:#%%%%%*++=+++++*%%%#-............................:====+++++++++===+==++*###***+++=++++*+:........................................................
.......+%%%%%%%*+=++++*%@@%#-.............................:+*#**++++++++++====++===========++++-.........................................................
......:*%%%%%%%@@%#%%@@@@%%#-..............................:+***++++++++++=======+==++++=+++++=:.........................................................
......+%%%%%%%@@@@@@@@@@@@@#-...............................:=**+++*+++++++++===+++++**++***++-..........................................................
.....=%%%%%%%%@@@@@@@@@@@@@#-.................................-+++++**++++********#######****+:..........................................................
....-#%%%%%@%@@@@@@@@@@@@@@%=...................................:=++++*****++*###########****=...........................................................
....*%%%%%%%@@@@@@@@@@@@@@@%+:...................................:++++++***++***#########****-:..........................................................
...-#%%%%%@%%@@@@@@@@@@@@@@%#-..................................:::-=*++*******######%###***=-:..........................................................
...+%%%%%@%%@@@@@@@@@@@@@@@@%-.................................:-:::::-=+***+**####%####**+-----.........................................................
..:*%%%%%%@@@@@@@@@@@@@@@@@@%=................................:*%=:....::--=+**#######**+=------*=:......................................................
..-#%%%%%%%%@@@@@@@@@@@@@@@@%=...............................-#%%%%=:.......:-=+*#%%%*=-::::-----%%*=:...................................................
..-#%%%%%%@@@@@@@@@@@@@@@@@@%=............................:=*%%%%%%%#-:........-+***###=:::::::--+%%%%#+-:...............................................
..-#%%%%%@@@@@@@@@@@@@@@@@@@@*-::::::::::::::..........:=#%%%%%%%%%%%%=:......##%%%*#%%%#=:::::::-=#%%%%%%%#*+=::........................................
..-#%%%%@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%###%%%%%%%%%%%%%%%%%+::..:+#####**####*+-::::::-=%%%%%%%%%%%%%%##*+=-::...............................
..-#%%%%@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+:.-**+=-+#*+*+--:-=-:::::--*%%%%%%%%%%%%%%%%%%%%%##*=-:.........................
..-#%%%%@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=:--::::-**+*-::::::::::::--%%%%%%%%%%%%%%%%%%%%%%%%%%%##*=-:...................
..-#@%%%%@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%-::::::+#***=::::::::::::::*%%%%%%%%%*#%%%%%%%%%%%%%%%%%%%%%#*-................
..-#@@%%@@@@@@@@@@@@@@@@@@@@@@@%%%%%@%@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=::::=*#*****-::..::::::::-%%%%%%%%%%+-+%%%%%%%%%%%%%%%%%%%%%%*:..............
..-#@@@%@@@@@@@@@@@@@@@@@@@@@@@%%%%%%@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#=:.:=##**+**++-::::::::.:-#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+:.............
..+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#=::=##**++**++::..::....:+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=.............
.-#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%-:###**++++++*::..:....:=#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#-............
.=#%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=%#***++++++*+::.......:*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#:...........
.-#%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%####***++++++++:.......:*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+:..........
..+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#***+++++++*=.......:+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#-..........
..:*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#****+++++++*:......:-#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@%%%%%%*:.........
...+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%@%%%%%%%%%%%%##***++**+++**......::#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@%%%%%%%=.........
...-%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%@%%%%%%%%%%%%#****+***++**-.....::#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@%%%%%%*:........
....=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%@%%%%%%%%%%%%#********+++**:.....:#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@%%%%%%%+........
.....=#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%@%%%%%%%%%%%#********+++**+.....:#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@%%%%%%%#-.......
......-*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%@@%%%%%%%%%%#*********++**+:...::#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*:......
........:*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@%%%%%%%%%#********++****=...::#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#-......
..........:=*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@%%%%%%%%%********+**+**+:::::#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*:.....
..............:=#%@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@%%%%%%%%#**************-::::#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+.....
..................:=*%@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@%%%%%%%%#***************:::-#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@%%%%%%%%%#-....
......................:-*%@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@%%%%%%%%***************-::-*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@%%%%%%%%%%#:...
...........................-*%@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@%%%%%%%#***************::-*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@%%%%%%%%%%+...
.............................:=*%@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@%%%%%%#***************::-*%%%%%%%%@%%%%%%%%%%%%%%%%%%%%%%@@@%%%%%%%%%@%=..
................................:*%@@@%@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@%%%%%#***************+:-*%%%%%%%%@%%%%%%%%%%%%%%%%%%%%%@@@@@@%%%%%%%@%#-.

             



In the heart of the greatest nation on Earth, amidst the bustling cities and the serene countryside, a new dawn rises. It's a call to the true believers, the patriots, the steadfast defenders of liberty and the American dream. This is more than a moment—it's our destiny unfolding.

The Vision:
We stand at a crossroads, where the legacy of our forebears and the hopes of future generations converge, faced with the choice to either uphold the torch of freedom or let it flicker in the shadows of tyranny. The DJT $MAGA Token emerges as the beacon of this era, a clarion call to rally the lovers of freedom, democracy, liberty and prosperity. The Constitution of the United States of America is not merely a document from our past; it is a living promise of liberty, a covenant with the future that we must tirelessly defend. In its wisdom, we find the blueprint for a society that respects the dignity of the individual and the sanctity of freedom.
Inspired by the unwavering spirit of DJT, this token is our standard in the battle to reclaim the essence of America: a land of unparalleled opportunity, where every voice is heard, and every dream can take flight.

The Mission:
Our mission is clear—fuel the resurgence of 'America First,' championing policies and ideals that prioritize the well-being of every American. To bring back America is to rekindle the flames of patriotism, to honor the sacrifices of those who came before us by committing ourselves to the principles of individualism and capitalism that have made this nation a beacon of hope and opportunity across the globe. With the DJT $MAGA Token, we weave the fabric of a community united by shared values and a common purpose: to secure a future where America continues to shine as the beacon of freedom and greatness.

The Strategy:
First, we align our efforts with the resurgence campaign, ensuring that every token transaction fortifies our resolve to see DJT return to the White House, steering America back to prosperity, strength, and unity. A portion of every transaction nurtures the roots of our movement, supporting the MAGA foundation and amplifying our message across the nation.
Our mission is clear: to champion the cause of the individual, to celebrate the entrepreneurial spirit that propels our economy forward, and to assert, without apology, that the pursuit of excellence and the rewards it brings are not just the foundation of American prosperity but the very essence of our national character.
Simultaneously, we support through donations key organizations and movements that further the MAGA cause. We inspire the younger generation of the great American past and how bright the American future can be.
We will restore faith in the American dream, where hard work and perseverance are rewarded, where innovation and ambition are encouraged, and where each citizen has the opportunity to achieve greatness on their own terms. We will honor our heroes, not just those who fought on battlefields, but also those who conquer in the marketplace, who innovate in the laboratory, and who inspire in the world.

The Call to Action:
Now is the time for courage, for action. This is our moment—our chance to stand shoulder to shoulder, to reclaim the promise of America for ourselves and for posterity. The DJT $MAGA Token is not just a currency; it's a declaration of our shared destiny, an investment in the America we believe in, an America where every day is a testament to greatness.
Join us as we embark on this journey, not just to witness history but to write it. Together, with the DJT $MAGA Token, we will breathe fire into the heart and soul of this land, igniting a new era of American greatness. This is our time. Now or never.
Let us then, with the courage of our forefathers and the unwavering belief in our shared destiny, pledge to rebuild an America that shines as a testament to the power of the individual, the resilience of our economy, and the enduring strength of our democratic ideals. This is our vision, our promise, and our duty—to reignite the mighty spirit of America and ensure that this great nation continues to be, now and forever, the land of the free and the home of the brave.

The Promise:
With every token, with every transaction, we build more than a campaign; we build a legacy. For the lovers of freedom, for the believers in the American dream, the DJT $MAGA Token is your banner. Under this banner, we march forward—united, invincible, unstoppable. Together, we are the architects of the future. This is your call to arms. Join us, and let's Make America Great Again, greater than ever before.

**/

// forgefmt: disable-end

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

/// @title MAGAToken
/// @notice Bigly gas optimized ERC20 token with fees
/// @author MAGA (@@MAGADJT_)
/// @author Modified from GasliteToken (https://github.com/PopPunkLLC/gaslite-core/blob/main/src/GasliteToken.sol)
/// @author Modified from Harrison (@PopPunkOnChain)
/// @author Modified from 0xjustadev (@0xjustadev)
/// @author Modified from (@GasliteGG)
contract MAGA is Ownable {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public immutable totalSupply;
    uint256 public immutable TAX_SWAP_THRESHOLD;
    uint256 public immutable MAX_TAX_SWAP;

    address private lpTokenRecipient;
    address public developmentWallet;
    address public magaWallet;

    uint8 public constant TRADING_DISABLED = 0;
    uint8 public constant TRADING_ENABLED = 1;
    uint8 public constant BUY_TOTAL_FEES = 10;            // BUY_TOTAL_FEES / 1000         =  1%
    uint8 public constant SELL_TOTAL_FEES = 10;           // SELL_TOTAL_FEES / 1000        =  1%
    uint8 public constant PERCENTAGE_FEE_TO_MAGA = 50;    // PERCENTAGE_FEE_TO_MAGA / 100  = 50%
    uint8 public tradingStatus = TRADING_DISABLED;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private automatedMarketMakerPairs;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    error ZeroAddress();
    error InsufficientAllowance();
    error InsufficientBalance();
    error CannotRemoveV2Pair();
    error WithdrawalFailed();
    error InvalidState();
    error TradingDisabled();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Constructor
    /// @param _name Name of the token
    /// @param _symbol Symbol of the token
    /// @param _totalSupply Total supply of the token
    /// @param _lpTokenRecipient Address to receive LP tokens
    /// @param _developmentWallet Address to receive fees
    /// @param _magaWallet Address to receive fees
    /// @param _uniswapV2RouterAddress Address of Uniswap V2 Router
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _lpTokenRecipient,
        address _developmentWallet,
        address _magaWallet,
        address _uniswapV2RouterAddress
    ) payable Ownable(_lpTokenRecipient) {
        if (_uniswapV2RouterAddress == address(0)) revert ZeroAddress();

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        lpTokenRecipient = _lpTokenRecipient;
        magaWallet = _magaWallet;
        developmentWallet = _developmentWallet;

        TAX_SWAP_THRESHOLD = _totalSupply * 10 / 10_000;
        MAX_TAX_SWAP = _totalSupply * 100 / 10_000;

        uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        automatedMarketMakerPairs[uniswapV2Pair] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_developmentWallet] = true;
        _isExcludedFromFees[_magaWallet] = true;

        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    receive() external payable {}

    /// @notice Adds liquidity to Uniswap
    function fundLP() external payable onlyOwner {
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this), totalSupply, 0, 0, lpTokenRecipient, block.timestamp
        );
    }

    /// @notice Gets balance of an address
    /// @param account Address to check balance of
    /// @return Balance of the address
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @notice Gets allowance of an address
    /// @param owner Address of the owner
    /// @param spender Address of the spender
    /// @return Allowance of the address
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice Approves an address to spend tokens
    /// @param spender Address of the spender
    /// @param amount Amount to approve
    /// @return True if successful
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @notice Internal approve
    /// @param owner Address of the owner
    /// @param spender Address of the spender
    /// @param amount Amount to approve
    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == address(0)) revert ZeroAddress();
        if (spender == address(0)) revert ZeroAddress();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice Transfers tokens to an address
    /// @param recipient Address of the recipient
    /// @param amount Amount to transfer
    /// @return True if successful
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Transfers tokens from an address to another address
    /// @param sender Address of the sender
    /// @param recipient Address of the recipient
    /// @param amount Amount to transfer
    /// @return True if successful
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) revert InsufficientAllowance();
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    /// @notice Internal transfer
    /// @param from Address of the sender
    /// @param to Address of the recipient
    function _transfer(address from, address to, uint256 amount) private {
        if (from == address(0)) revert ZeroAddress();
        if (to == address(0)) revert ZeroAddress();

        if (tradingStatus == TRADING_DISABLED) {
            if (from != owner() && from != magaWallet && from != developmentWallet && from != address(this) && to != owner()) {
                revert TradingDisabled();
            }
        }

        bool takeFee = true;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 senderBalance = _balances[from];
        if (senderBalance < amount) revert InsufficientBalance();

        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && SELL_TOTAL_FEES > 0) {
                fees = (amount * SELL_TOTAL_FEES) / 1000;
            } else if (automatedMarketMakerPairs[from] && BUY_TOTAL_FEES > 0) {
                fees = (amount * BUY_TOTAL_FEES) / 1000;
            }

            if (fees > 0) {
                uint256 tokenBalance = balanceOf(address(this));
                if (tokenBalance > TAX_SWAP_THRESHOLD && to == uniswapV2Pair) {
                    uint256 minOfAll;
                    if (tokenBalance < MAX_TAX_SWAP) minOfAll = tokenBalance < amount ? tokenBalance : amount;
                    else minOfAll = MAX_TAX_SWAP < amount ? MAX_TAX_SWAP : amount;

                    uint256 preEthBalance = address(this).balance;
                    // this.swapTokensForEth(minOfAll);

                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = uniswapV2Router.WETH();
                    _approve(address(this), address(uniswapV2Router), minOfAll);
                    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                        minOfAll,
                        0,
                        path,
                        address(this),
                        block.timestamp
                    );

                    uint256 ethBalance = address(this).balance - preEthBalance;
                    if (ethBalance > 0) {
                        uint256 magaETHFees = ethBalance * PERCENTAGE_FEE_TO_MAGA / 100;
                        payable(magaWallet).transfer(magaETHFees);
                        payable(developmentWallet).transfer(ethBalance - magaETHFees);
                    }

                }
                unchecked {
                    amount = amount - fees;
                    _balances[from] -= fees;
                    _balances[address(this)] += fees;
                }
                emit Transfer(from, address(this), fees);
            }
        }
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }


    /// @notice Enables trading
    function enableTrading() public onlyOwner {
        tradingStatus = TRADING_ENABLED;
    }

    /// @notice Sets AMM pair
    /// @param pair Address of the pair
    /// @param value True if AMM pair
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        if (pair == uniswapV2Pair) revert CannotRemoveV2Pair();
        automatedMarketMakerPairs[pair] = value;
    }

    /// @notice Withdraw tokens from the contract
    /// @param token Address of the token
    /// @param to Address to withdraw to
    function withdrawToken(address token, address to) external onlyOwner {
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(token), to, _contractBalance);
    }

    /// @notice Withdraw ETH from the contract
    /// @param addr Address to withdraw to
    function withdrawETH(address addr) external onlyOwner {
        if (addr == address(0)) revert ZeroAddress();

        (bool success,) = addr.call{value: address(this).balance}("");
        if (!success) revert WithdrawalFailed();
    }
}