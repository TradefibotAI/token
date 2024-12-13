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

contract TDFI is
    ERC20,
    ERC20Burnable,
    ERC20Permit
{
    uint256 public immutable maxSupply;

   // Project Wallets 
    address public constant reserveWallet = 
        address(0x245bf5E201F54Ef490897C1524C478791430DF0F); 
    uint256 public constant reservePercentage = 40; 
 
    address public constant airDropWallet = 
        address(0x0d6c9c8B20E486742b31e1D0592E33686C7F038C); 
    uint256 public constant airDropPercentage = 40; 
 
    address public constant publicPresaleWallet = 
        address(0xF193C174165d1fd7adc4D2DD70ceF5747D75Aec5); 
    uint256 public constant publicPresalePercentage = 380; 
 
    address public constant privatePresaleWallet = 
        address(0x1820ff6D2EEb9D9Af2C2148ceB8096fcB9FC8ce6); 
    uint256 public constant privatePresalePercentage = 20; 
 
    address public constant liquidityWarrantyWallet = 
        address(0xF8726B9943bAEb52Db32ec2C80D90c0e9B519044); 
    uint256 public constant liquidityWarrantyPercentage = 400; 
 
    address public constant developmentWallet = 
        address(0xeD75eBa6932caF1F84FAe3a11651B10bAb315Bc3); 
    uint256 public constant developmentPercentage = 60; 
 
    address public constant marketingWallet = 
        address(0x522140F9970e5497e5568cc09C69ab3FF9F2F6eF); 
    uint256 public constant marketingPercentage = 60;

    IUniswapV2Router02 private uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public immutable projectWallet;
    address public immutable jackpotWallet;
    address public immutable burnWallet;

    uint16 public immutable sellTax;

    mapping(address => bool) public automatedMarketMakerPairs;

    address public admin;

    constructor(
        uint256 setMaxSupply
    ) ERC20("Tradefi.bot", "TDFI") ERC20Permit("Tradefi.bot") {

        admin = msg.sender;

        // Defining the MaxSupply
        maxSupply = setMaxSupply;

        // Uniswap Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        sellTax = 5;
        projectWallet = publicPresaleWallet;
        jackpotWallet = reserveWallet;
        burnWallet = liquidityWarrantyWallet;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // Mint the initial supply
        _initalSupply();
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action");
        _;
    }

    function updateAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    // Initial Supply
    function _initalSupply() private {
        _mint(reserveWallet, (maxSupply * reservePercentage) / 1000);
        _mint(airDropWallet, (maxSupply * airDropPercentage) / 1000);
        _mint(
            publicPresaleWallet,
            (maxSupply * publicPresalePercentage) / 1000
        );
        _mint(
            privatePresaleWallet,
            (maxSupply * privatePresalePercentage) / 1000
        );
        _mint(
            liquidityWarrantyWallet,
            (maxSupply * liquidityWarrantyPercentage) / 1000
        );
        _mint(marketingWallet, (maxSupply * marketingPercentage) / 1000);
        _mint(developmentWallet, (maxSupply * developmentPercentage) / 1000);
    }

    // events
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    // Uniswap logic functions

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyAdmin {
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

    // Logic for taxes
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        // Sell Taxes
        if (automatedMarketMakerPairs[to]) {
                    // Sell
                    uint256 _tax = (amount * sellTax) / 100;
                    uint256 _projectTax = (_tax * 25) / 100;
                    uint256 _burnTax = (_tax * 25) / 100;
                    uint256 _jackpotTax = _tax - _projectTax - _burnTax;
                    amount = amount - _tax;

                    super._transfer(from, projectWallet, _projectTax);
                    emit Transfer(from, projectWallet, _projectTax);

                     super._transfer(from, burnWallet, _burnTax);
                    emit Transfer(from, burnWallet, _burnTax);

                     super._transfer(from, jackpotWallet, _jackpotTax);
                    emit Transfer(from, jackpotWallet, _jackpotTax);


                    super._transfer(from, to, amount);
                    emit Transfer(from, to, amount);
        } else {
            super._transfer(from, to, amount);
            emit Transfer(from, to, amount);
        }
    }
}
