import {ethers, run} from 'hardhat';

const sleep = (ms:number) => {
    return new Promise((resolve) => {
        setTimeout(resolve, ms);
    });
}

//module.exports = async() => {
async function main() {

    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy();
    await token.deployed();
    console.log("Token contract deployed:", token.address);

    await sleep(1000);

    try {
        await run("verify", {
            address: token.address,
            constructorArguments: []
        });
    } catch(e) {
        console.log(e);
    }
    console.log("Verified Token Contract");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.log(error);
        process.exit(1);
    });