module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("arb-pilot-SolvVaultGuardianForSafe13"))
    .address;

  console.log("caller ", caller);
  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";

  const spenders = [
    "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9", // USDT
    [
      "0x22799DAA45209338B7f938edf251bdfD1E6dCB32", // OpenEndFundShare
      "0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c", // OpenEndFundRedemption
    ],
  ];

  let deployName = "arb-pilot-ERC20ApproveAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20ApproveAuthorization",
    args: [safeMultiSendContract, caller, [spenders]],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["arb-pilot-ERC20ApproveAuthorization"];
