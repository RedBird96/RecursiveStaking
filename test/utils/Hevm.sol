// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface Hevm {
    function addr(uint256) external returns (address);
    function warp(uint256 x) external;
    function skip(uint256 x) external;
    function rewind(uint256 x) external;
    function roll(uint256 x) external;
    function deal(address who, uint256 amount) external;
    function etch(address who, bytes calldata code) external;
    function prank(address from) external;
    function startPrank(address from) external;
    function stopPrank() external;
    function expectRevert() external;
    function expectRevert(bytes4) external;
    function expectRevert(bytes calldata) external;
    function expectEmit(bool, bool, bool, bool) external;
    function expectEmit(bool, bool, bool, bool, address) external;
    function mockCall(address, bytes calldata, bytes calldata) external;
    function clearMockedCalls() external;
    function expectCall(address, bytes calldata) external;
    function startBroadcast() external;
    function stopBroadcast() external;
    function getCode(string calldata) external returns (bytes memory);
    function createSelectFork(string calldata urlOrAlias, uint256 block) external returns (uint256);
    function assume(bool) external;
    function chainId(uint256) external;
}
