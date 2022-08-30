// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;
//import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";//????
//import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; //* позволяет контракту хранить на себе NFT
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

//import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";//???

contract LiquidityExamples is IERC721Receiver {
    uint24 public constant poolFee = 3000;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    mapping(uint256 => Deposit) public deposits;

    constructor(INonfungiblePositionManager _nonfungiblePositionManager) {
        nonfungiblePositionManager = _nonfungiblePositionManager;
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata //data
    ) external override returns (bytes4) {
        //!по идее  как только прислали токен,сразу создаем депозит
        //!или нет,не особо выкупаю зачемм нам тут эта функция
        _createDeposit(operator, tokenId);
        return this.onERC721Received.selector;
    }

    function _createDeposit(address owner, uint256 tokenId) internal {
        (
            ,
            ,
            address token0,
            address token1,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(tokenId);
        deposits[tokenId] = Deposit({
            owner: owner,
            liquidity: liquidity,
            token0: token0,
            token1: token1
        });
    }

    //Creates a new position wrapped in a NFT
    function mintNewPosition(
        address token0,
        address token1,
        uint256 amount0ToMint,
        uint256 amount1ToMint
    )
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        //Here we approve the nonfungiblePositionManager to use the contracts' tokens
        TransferHelper.safeApprove(
            token0,
            address(nonfungiblePositionManager),
            amount0ToMint
        );
        TransferHelper.safeApprove(
            token1,
            address(nonfungiblePositionManager),
            amount1ToMint
        );

        TransferHelper.safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            amount0ToMint
        );
        TransferHelper.safeTransferFrom(
            token1,
            msg.sender,
            address(this),
            amount1ToMint
        );

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager
            .MintParams({
                token0: token0,
                token1: token1,
                fee: poolFee,
                tickLower: 0, //TickMath.MIN_TICK,
                tickUpper: 0, //TickMath.MAX_TICK,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            }); //Creates a new position wrapped in a NFT
        //! надо еще создать пул моего токена на какой-нибудь еще токен
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(params);

        _createDeposit(msg.sender, tokenId);

        if (amount0 < amount0ToMint) {
            TransferHelper.safeApprove(
                token0,
                address(nonfungiblePositionManager),
                0
            );
            uint256 refund0 = amount0ToMint - amount0;
            TransferHelper.safeTransfer(token0, msg.sender, refund0);
        }

        if (amount1 < amount1ToMint) {
            TransferHelper.safeApprove(
                token1,
                address(nonfungiblePositionManager),
                0
            );
            uint256 refund1 = amount1ToMint - amount1;
            TransferHelper.safeTransfer(token1, msg.sender, refund1);
        }
    }

    /// @notice Collects the fees associated with provided liquidity
    /// @dev The contract must hold the erc721 token before it can collect fees
    /// @param tokenId The id of the erc721 token
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collectAllFees(uint256 tokenId)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        // Caller must own the ERC721 position
        // Call to safeTransfer will trigger `onERC721Received` which must return the selector else transfer will fail
        //nonfungiblePositionManager идет как токен тут
        nonfungiblePositionManager.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        // set amount0Max and amount1Max to uint256.max to collect all fees
        // alternatively can set recipient to msg.sender and avoid another transaction in `sendToOwner`
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        // send collected feed back to owner
        _sendToOwner(tokenId, amount0, amount1);
    }

    /// @notice Transfers funds to owner of NFT
    /// @param tokenId The id of the erc721
    /// @param amount0 The amount of token0
    /// @param amount1 The amount of token1
    function _sendToOwner(
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1
    ) internal {
        // get owner of contract
        address owner = deposits[tokenId].owner;

        address token0 = deposits[tokenId].token0;
        address token1 = deposits[tokenId].token1;
        // send collected fees to owner
        TransferHelper.safeTransfer(token0, owner, amount0);
        TransferHelper.safeTransfer(token1, owner, amount1);
    }
}
