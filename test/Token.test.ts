import {expect} from "chai";
import {ethers} from "hardhat";
import { Token } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe('Token contract', function () {
    let token: Token;
    let owner:SignerWithAddress;
    let addr1:SignerWithAddress;
    let addr2:SignerWithAddress;

    before(async() => {
        [owner, addr1, addr2] = await ethers.getSigners();
        const Token = await ethers.getContractFactory("Token", owner);
        token = await Token.deploy();
    });
    it("Deployment should assign the total supply", async () => {
        const supply = await token.totalSupply();
        const ownerBalance = await token.balanceOf(owner.address);

        expect(supply).to.be.equal(ownerBalance, "Not equal totaly supply");
    });

    it("Transfer token to other accounts", async () => {
        
        await token.transfer(addr1.address, 50);
        const addr1Balance = await token.balanceOf(addr1.address);
        expect(addr1Balance).to.be.equal(50, "Not transferred");

        await token.transfer(addr2.address, 80);
        const addr2Balance = await token.balanceOf(addr2.address);
        expect(addr2Balance).to.be.equal(80, "Not transferred");
    });
});