module.exports = [
  "0xb34ac8c6761E6615e5332Ca1E7C9E6f2f523aDd3",
  [
    [],
    [
      [
        "0xdac17f958d2ee523a2206206994597c13d831ec7", // WBTC
        [
          "0xF98099decb7A4819f18c3F2C5FAa153A33740565", // receiver, Ethena Minter
        ],
      ],
      [
        "0x4c9EDD5852cd905f086C759E8383e09bff1E68B3", //USDE
        ["0x464D0cCff5E05F2aFC69561Fd849e46d96492203"], //AA
      ],
    ],
  ],
];

//npx hardhat verify --network arb 0xd3f0822A214A569851382a65Ce1cc8E13dAF7671 --constructor-args deploy-arguments/arb-solvBTC/ERC20Authorization.js
