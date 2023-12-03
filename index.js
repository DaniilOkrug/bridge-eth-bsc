require('dotenv').config();
const Web3 = require("web3");
const conn_data = require('./data.json');

const web3Eth = new Web3(process.env.ETH_NODE_URL);
const web3Poly = new Web3(process.env.POLYGON_NODE_URL);

const { address: adminEth } = web3Eth.eth.accounts.wallet.add(process.env.PRIVATE_KEY_ADMIN);
const { address: adminPoly } = web3Poly.eth.accounts.wallet.add(process.env.PRIVATE_KEY_ADMIN);

const bridgeEth = new web3Eth.eth.Contract(conn_data.abi, conn_data.address_eth);
const bridgePoly = new web3Poly.eth.Contract(conn_data.abi, conn_data.address_poly);

bridgeEth.events.CreateArticle({fromBlock: 0, step: 0})
    .on('data', async eventData => {
        try {
            const { returnValues } = eventData;
            const { id, owner } = returnValues;
        
            // Получаем данные статьи из Ethereum
            const article = await bridgeEth.methods._getArticle(id).call({
                from: adminEth,
            });
            console.log('ETH Article', article);

            const estimatedGas = await bridgePoly.methods._createArticle(
                id,
                article.title,
                article.content,
                owner,
                article.price,
                article.token,
                article.ethPrice,
                article.createdAt
            ).estimateGas({ from: adminPoly });
            const gasLimit = Math.floor(estimatedGas * 1.2);

            await bridgePoly.methods._createArticle(
                id,
                article.title,
                article.content,
                owner,
                article.price,
                article.token,
                article.ethPrice,
                article.createdAt
            ).send({ from: adminPoly, gas: gasLimit });
        } catch (error) {
            console.error(error);
        }
    })
    .on('error', console.error);

bridgeEth.events.AccessGranted({fromBlock: 0, step: 0})
    .on('data', async eventData => {
        try {
            const { returnValues } = eventData;
            const { id, recipient } = returnValues;
        
            console.log('ETH Grant Access', id, recipient);

            const estimatedGas = await bridgePoly.methods._grantAccess(
                id,
                recipient
            ).estimateGas({ from: adminPoly });
            const gasLimit = Math.floor(estimatedGas * 1.2);

            await bridgePoly.methods._grantAccess(
                id,
                recipient
            ).send({ from: adminPoly, gas: gasLimit });
        } catch (error) {
            console.error(error);
        }
    })
    .on('error', console.error);

bridgePoly.events.CreateArticle({fromBlock: 0, step: 0})
    .on('data', async eventData => {
        const { returnValues } = eventData;
        const { id, owner } = returnValues;
    
        const article = await bridgePoly.methods._getArticle(id).call({
            from: adminPoly,
        });
        console.log('Poly Article', article);

        const estimatedGas = await bridgeEth.methods._createArticle(
            id,
            article.title,
            article.content,
            owner,
            article.price,
            article.token,
            article.ethPrice,
            article.createdAt
        ).estimateGas({ from: adminEth });
        const gasLimit = Math.floor(estimatedGas * 1.2);

        await bridgeEth.methods._createArticle(
            id,
            article.title,
            article.content,
            owner,
            article.price,
            article.token,
            article.ethPrice,
            article.createdAt
        ).send({ from: adminEth, gas: gasLimit });
    })
    .on('error', console.error);

bridgePoly.events.AccessGranted({fromBlock: 0, step: 0})
    .on('data', async eventData => {
        try {
            const { returnValues } = eventData;
            const { id, recipient } = returnValues;
        
            console.log('Poly Grant Access', id, recipient);

            const estimatedGas = await bridgeEth.methods._grantAccess(
                id,
                recipient
            ).estimateGas({ from: adminEth });
            const gasLimit = Math.floor(estimatedGas * 1.2);

            await bridgeEth.methods._grantAccess(
                id,
                recipient
            ).send({ from: adminEth, gas: gasLimit });
        } catch (error) {
            console.error(error);
        }
    })
    .on('error', console.error);