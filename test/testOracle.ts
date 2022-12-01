import { getRandomValues } from "node:crypto"
import { ethers } from "ethers";
import { TEST_PRIVATE, COORD_ADDR, COORD_ABI } from "./constants";
import Web3 from "web3";
import { AbiItem } from "web3-utils"
import { Log, TransactionConfig } from "web3-core"


async function startOracle() {

    const web3 = new Web3("ws://127.0.0.1:8545/");

    console.log("START");

    const account = web3.eth.accounts.privateKeyToAccount(TEST_PRIVATE);

    const oracle = new web3.eth.Contract(COORD_ABI as AbiItem[], COORD_ADDR);

    const subscriber = web3.eth.subscribe("logs", {
        address: COORD_ADDR,
        topics: ["0xe35c7731b78e4fdccf88aa9e3183b28a6411926bb46cc024976ecc8dfee4e32d"]
    }, async (err, log) => {
        if (err) { console.log(err); return; }

        const [_, reqId, numWords] = log.topics;
        const len = parseInt(numWords);
        console.log(`REQUEST ID: ${reqId}`);
        console.log(`NUM WORDS: ${len}`);

        const randomness = Array.from(getRandomValues(Buffer.alloc(len)));

        const sendResponse = oracle.methods.sendResponse(reqId, randomness);

        const tx: TransactionConfig  = {
            from: account.address,
            to: COORD_ADDR,
            value: "0x0",
            gas: web3.utils.toHex(500_000),
            maxFeePerGas: web3.utils.toWei("20", "Gwei"),
            maxPriorityFeePerGas: web3.utils.toWei("5", "Gwei"),
            nonce: await web3.eth.getTransactionCount(account.address),
            data: sendResponse.encodeABI(),
        }

        const signedTx = await account.signTransaction(tx);

        try {
            const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction as string);
            console.log(receipt);
        } catch(e) {
            console.log(e);
        }

    });

}

startOracle().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
