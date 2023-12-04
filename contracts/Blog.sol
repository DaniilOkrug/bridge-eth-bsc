// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Blog {
    struct Article {
        string title;
        string content;
        address payable author;
        uint price;
        address token;
        uint ethPrice;
        uint createdAt;
    }

    uint private articleIndex = 0;
    address private admin = 0xF290AFD9f301d145D4398bB1afd7166AB8a81271;

    mapping(uint => Article) private articles;
    mapping(address => mapping(uint => bool)) public accessGranted;

    event CreateArticle(uint id, address owner);
    event AccessGranted(uint id, address recipient);

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    constructor() {}

    function createArticle(
        string memory title, 
        string memory content,
        uint price,
        address token,
        uint ethPrice
    ) external {
        require(price >= 0, "Wrong token price");
        require(ethPrice >= 0, "Wrong eth price");

        articles[articleIndex] = Article({
            title: title,
            content: content,
            author: payable(msg.sender),
            price: price,
            token: token,
            ethPrice: ethPrice,
            createdAt: block.timestamp
        });

        emit CreateArticle(articleIndex, msg.sender);

        accessGranted[msg.sender][articleIndex] = true;

        articleIndex += 1;
    }

    /* Buy with native blockchain token */
    function buyAccess(uint index) public payable {
        require(index >= 0 && index < articleIndex, "Article doesn't exists");
        require(!accessGranted[msg.sender][index], "Access alredy granted");
        
        Article storage article = articles[index];
        require(msg.value >= article.price, "Wrong transfer amount");

        if (article.ethPrice > 0) {
            article.author.transfer(article.price);
        }

        accessGranted[msg.sender][index] = true;

        emit AccessGranted(index, msg.sender);
    }

    /* Buy with stablecoin of the article */
    function buyAccessWithToken(uint index) external {
        require(index >= 0 && index < articleIndex, "Article doesn't exists");
        require(!accessGranted[msg.sender][index], "Access alredy granted");

        Article storage article = articles[index];

        if (article.price > 0) {
            IERC20 tokenPayment = IERC20(article.token);
            tokenPayment.transferFrom(msg.sender, article.author, article.price);
        }

        accessGranted[msg.sender][index] = true;

        emit AccessGranted(index, msg.sender);
    }

    function readArticle(uint index) external  view returns (
        string memory title,
        string memory content,
        uint createdAt
    ) {
        require(index >= 0 && index < articleIndex, "Article doesn't exists");
        require(accessGranted[msg.sender][index], "Access not granted");

        Article storage article = articles[index];

        return (article.title, article.content, article.createdAt);
    }

    function getArticle(uint index) external view returns (
        uint id,
        string memory title,
        uint price,
        address tokenAddress,
        uint ethPrice,
        uint createdAt,
        address author,
        bool hasAccess
    ) {
        require(index >= 0 && index < articleIndex, "Article doesn't exists");
        Article storage article = articles[index];
        bool isAccessGranted = accessGranted[msg.sender][index];

        return (
            index,
            article.title,
            article.price,
            article.token,
            article.ethPrice,
            article.createdAt,
            article.author,
            isAccessGranted
        );
    }

    function getArticlesLength() public  view returns (uint) {
        return articleIndex;
    }

    function _getArticle(uint index) onlyAdmin external view returns (
        string memory title,
        string memory content,
        address owner,
        uint price,
        address token,
        uint ethPrice,
        uint createdAt
    ) {
        Article storage article = articles[index];

        return (
            article.title,
            article.content,
            article.author,
            article.price,
            article.token,
            article.ethPrice,
            article.createdAt
        );
    }

    function _createArticle(
        uint index,
        string memory title, 
        string memory content, 
        address author, 
        uint price,
        address token,
        uint ethPrice,
        uint createdAt
    ) onlyAdmin external  {
        articles[index] = Article({
            title: title,
            content: content,
            author: payable(author),
            price: price,
            token: token,
            ethPrice: ethPrice,
            createdAt: createdAt
        });

        accessGranted[author][index] = true;
        articleIndex = index + 1;
    }

    function _grantAccess(uint index, address buyer) onlyAdmin external {
        accessGranted[buyer][index] = true;
    }
}
