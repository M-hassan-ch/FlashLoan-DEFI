import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import abi from '../artifacts/contracts/interfaces/IERC20.sol/IERC20.json';
import { MinEthersFactory } from "../typechain-types/common";
import { FlashLoan, IERC20 } from "../typechain-types";

describe("Flash Loan", function () {
  let provider;
  let flashLoanContract: FlashLoan;
  let busdInstance;
  const WHALE = "0xe47ECeCa49C1EBd786899ad8D1eE8a10eE7a7845"//"0x8fe348f2f890046719aacea910f01d772dc20a65"
  const BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
  const WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
  const CROX = "0x2c094F5A7D1146BB93850f629501eB749f6Ed491";
  const CAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82";
  const DECIMALS = 18;

  async function deployFlashLoanContract() {
    const contract = await ethers.getContractFactory("FlashLoan");
    const deployedContract = await contract.deploy();
    return deployedContract;
  }

  const parseUnits = (number: string) => {
    return ethers.parseUnits(number, DECIMALS);
  }

  const sendToken = async (contract: any, senderAddres: string, receiverAddress: string, amount: string) => {
    const fund_amount = parseUnits(amount);
    const whale = await ethers.getSigner(senderAddres);
    await contract.connect(whale).transfer(receiverAddress, fund_amount);
  };

  const fundContract = async (contract: any, senderAddres: string, receiverAddress: string, amount: string) => {
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [senderAddres],
    });
    await sendToken(contract, senderAddres, receiverAddress, amount);
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [senderAddres],
    });
  };

  beforeEach(async () => {
    provider = await ethers.getDefaultProvider();
    flashLoanContract = await deployFlashLoanContract();
    const flashLoanContractAddress = await flashLoanContract.getAddress();
    busdInstance = await (await ethers.getContractFactory("Token")).attach(BUSD);

    const whaleBalance = await provider.getBalance(WHALE);
    expect(whaleBalance).to.not.deep.equal(1);

    await fundContract(busdInstance, WHALE, flashLoanContractAddress, "10");
  })

  it("Ensures contract to be funded", async function () {
    const contractBalance = await flashLoanContract?.getBalanceOfToken(BUSD);
    expect(contractBalance).to.deep.equal(ethers.parseEther("10"));
  });

  it("Should execute the arbitrage", async function () {
    await expect(flashLoanContract?.initiateArbitrage(BUSD, parseUnits("5"))).to.not.be.reverted;
  });
});
