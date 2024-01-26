module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("mantle-WETH-A-SolvVaultGuardianForSafe13")).address;
  console.log("caller ", caller);

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";

  const spenders = [
    [
      "0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111", // WETH
      [
        "0x788dC3af7B62708b752d483a6E30d1Cf23c3EaAe", // OpenEndFundShare
        "0x9b8a1B5d2f1BcC95d1CEab97FA9e063464418925", // OpenEndFundRedemption
        "0x319B69888b0d11cEC22caA5034e25FfFBDc88421", // Agni-SwapRouter
        "0xCFa5aE7c2CE8Fadc6426C1ff872cA45378Fb7cF3", // Lendle-LendingPool
      ],
    ],
    [
      "0xcDA86A272531e8640cD7F1a92c01839911B90bb0", // METH
      [
        "0x319B69888b0d11cEC22caA5034e25FfFBDc88421", // Agni-SwapRouter
        "0xCFa5aE7c2CE8Fadc6426C1ff872cA45378Fb7cF3", // Lendle-LendingPool
      ]
    ]
  ];

  let deployName = "mantle-WETH-A-ERC20ApproveAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20ApproveAuthorization",
    args: [ safeMultiSendContract, caller, spenders ],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["mantle-WETH-A-ERC20ApproveAuthorization"];
