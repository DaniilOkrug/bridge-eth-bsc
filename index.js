require('dotenv').config();
const Web3 = require("web3");
const ethData = require('./data.json');

const web3Eth = new Web3(process.env.ETH_NODE_URL);

const bridgeEth = new web3Eth.eth.Contract(ethData.abi, ethData.address);

bridgeEth.events.CreateArticle({fromBlock: 0, step: 0})
    .on('data', async event => {
        console.log(event);
    });
