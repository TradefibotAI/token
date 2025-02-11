// SPDX-License-Identifier: MIT

// Web: https://tradefi.bot/
//⁠ ⁠Whitepaper: https://docs.tradefi.bot/whitepaper
// Twitter: https://x.com/Tradefibot
// Telegram: https://t.me/TradefibotChat
// ⁠Instagram: https://www.instagram.com/tradefibot
// ⁠Youtube Channel: https://www.youtube.com/@Tradefibot

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TDFI is ERC20, ERC20Burnable, ERC20Permit {
    uint256 public immutable maxSupply = 150000000000000000000000000;

    // Project Wallets
    address public immutable seedPresaleWalletA = address(0xB3219929716d152025CBF44ae6251eFf1522c87b);
    uint256 public immutable seedPresalePercentage = 300;

    address public immutable privatePresaleWalletB =
        address(0x680CE202cb9a48791d069cA1D374c21D53Cd997E);
    uint256 public immutable privatePresalePercentageB = 170;

        address public immutable privatePresaleWalletC =
        address(0xce8F9545548156e29e259e3a51FF3C20413466F4);
    uint256 public immutable privatePresalePercentageC = 1350;

    address public immutable publicPresaleWallet =
        address(0x647cF37D0176E4De0422aC1e74802e645e00FD04);
    uint256 public immutable publicPresalePercentage = 38180;

    address public immutable liquidityWallet =
        address(0xAeBFDC682d88F1Aa79Deee769d58921381333D89);
    uint256 public immutable liquidityPercentage = 40000;

    address public immutable developmentWallet =
        address(0xe06ded0573864ef4Ee647Fa9A96b42397Fb871ee);
    uint256 public immutable developmentPercentage = 6000;

    address public immutable marketingWallet =
        address(0xE6B72b45217522538890FC1Ae9A0888bf40281D6);
    uint256 public immutable marketingPercentage = 6000;

    address public immutable treasuryWallet =
        address(0x92b4eFAf6A42E35a5A7Dbaf64fA58055803CCE1c);
    uint256 public immutable treasuryPercentage = 4000;

    address public immutable growthWallet =
        address(0x80f574A044F5D77ba94c29C04941288B182f88DF);
    uint256 public immutable growthPercentage = 4000;

    address public immutable dividendsWallet =
        address(0x441E1E6AD328d43C66e5D3d79D1959D2bc28185f);

    address public immutable burnWallet =
        address(0x000000000000000000000000000000000000dEaD);

    address public daoWallet =
        address(0x01BEED82101Dacf3a8D1f57d000878B20CdE901B);

    IUniswapV2Router02 private uniswapV2Router;
    address public immutable uniswapV2Pair;

    uint16 public immutable sellTax = 5;

    mapping(address => bool) public automatedMarketMakerPairs;


    constructor()
        ERC20("Tradefi.bot Token", "TDFI")
        ERC20Permit("Tradefi.bot Token")
    {
        // Uniswap Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // Mint the initial supply
        _initialSupply();
    }

    modifier onlyDAO() {
        require(
            msg.sender == daoWallet,
            "Only the DAO can perform this action"
        );
        _;
    }

    function updateDao(address _newDao) public onlyDAO {
        daoWallet = _newDao;
    }

    // Initial Supply
    function _initialSupply() private {
        _mint(seedPresaleWalletA, (maxSupply * seedPresalePercentage) / 1000);
        _mint(
            privatePresaleWalletB,
            (maxSupply * privatePresalePercentageB) / 1000
        );
        _mint(
            privatePresaleWalletC,
            (maxSupply * privatePresalePercentageC) / 1000
        );
        
        _mint(
            publicPresaleWallet,
            (maxSupply * publicPresalePercentage) / 1000
        );
        _mint(liquidityWallet, (maxSupply * liquidityPercentage) / 1000);
        _mint(marketingWallet, (maxSupply * marketingPercentage) / 1000);
        _mint(developmentWallet, (maxSupply * developmentPercentage) / 1000);
        _mint(treasuryWallet, (maxSupply * treasuryPercentage) / 1000);
        _mint(growthWallet, (maxSupply * growthPercentage) / 1000);
        
    }

    // events
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    // Manage AMM pairs by DAO
    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyDAO
    {
        require(
            pair != uniswapV2Pair,
            "The Uniswap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // Override transfer to apply sell tax for DEX trades
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (automatedMarketMakerPairs[to]) {
            // Sell
            uint256 fee = (amount * sellTax) / 100;
            uint256 treasuryAmount = (fee * 25) / 100;
            uint256 burnAmount = (fee * 25) / 100;
            uint256 dividendsAmount = fee - treasuryAmount - burnAmount;

            // Distribute tax
            super._transfer(from, treasuryWallet, treasuryAmount);
            emit Transfer(from, treasuryWallet, treasuryAmount);

            super._transfer(from, burnWallet, burnAmount);
            emit Transfer(from, burnWallet, burnAmount);

            super._transfer(from, dividendsWallet, dividendsAmount);
            emit Transfer(from, dividendsWallet, dividendsAmount);

            super._transfer(from, to, amount);
            emit Transfer(from, to, amount);
        } else {
            // Standard transfer for non-DEX trades
            super._transfer(from, to, amount);
            emit Transfer(from, to, amount);
        }
    }
}
