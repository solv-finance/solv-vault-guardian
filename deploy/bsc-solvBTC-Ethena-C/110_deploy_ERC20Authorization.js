module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (
    await deployments.get("bsc-solvBTC-Ethena-C-SolvVaultGuardianForSafe13")
  ).address;

  const spenders = [
    [
      "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // BTCB
      [
        "0xb816018e5d421e8b809a4dc01af179d86056ebdf", // OpenEndFundShare
        "0xe16cec2f385ea7a382772334a44506a865f98562", // OpenEndFundRedemption
      ],
    ],
  ];

  const receivers = [
    [
      "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // BTCB
      [
        "0x667cc3145f9f63bd796a1a62ef504aaa160550e5", // receiver
      ],
    ],
  ];

  const deployName = "bsc-solvBTC-Ethena-C-ERC20Authorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20Authorization",
    args: [caller, spenders, receivers],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["bsc-solvBTC-Ethena-C-ERC20Authorization"];
